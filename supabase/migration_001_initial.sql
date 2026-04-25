-- AdKan -- Initial Database Migration
-- Run this in Supabase SQL Editor (Dashboard > SQL Editor > New Query)

-- EXTENSIONS
create extension if not exists "uuid-ossp";

-- TABLES

create table public.users (
    id           uuid primary key,
    display_name text not null default '',
    avatar_emoji text not null default '',
    created_at   timestamptz not null default now()
);

create table public.groups (
    id         uuid primary key default uuid_generate_v4(),
    name       text not null,
    type       text not null default 'friends',
    created_by uuid not null references public.users(id),
    created_at timestamptz not null default now()
);

create table public.group_members (
    group_id    uuid not null references public.groups(id) on delete cascade,
    user_id     uuid not null references public.users(id) on delete cascade,
    is_favorite boolean not null default false,
    joined_at   timestamptz not null default now(),
    primary key (group_id, user_id)
);

create table public.daily_scores (
    user_id             uuid not null references public.users(id) on delete cascade,
    score_date          date not null default current_date,
    daily_total_minutes integer not null default 0
        check (daily_total_minutes between 0 and 1440),
    synced_at           timestamptz not null default now(),
    primary key (user_id, score_date)
);

-- INDEXES
create index idx_daily_scores_date on public.daily_scores (score_date);
create index idx_group_members_user on public.group_members (user_id);

-- ROW LEVEL SECURITY

alter table public.users enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.daily_scores enable row level security;

-- Users: read own row + group peers, write own row only
create policy "users_select_own" on public.users
    for select using (auth.uid() = id);

create policy "users_select_group_peers" on public.users
    for select using (
        id in (
            select gm.user_id from public.group_members gm
            where gm.group_id in (
                select gm2.group_id from public.group_members gm2
                where gm2.user_id = auth.uid()
            )
        )
    );

create policy "users_insert_own" on public.users
    for insert with check (auth.uid() = id);

create policy "users_update_own" on public.users
    for update using (auth.uid() = id);

-- Groups: readable by members, creatable by authenticated users
create policy "groups_select_member" on public.groups
    for select using (
        id in (
            select group_id from public.group_members
            where user_id = auth.uid()
        )
    );

create policy "groups_insert_auth" on public.groups
    for insert with check (auth.uid() = created_by);

-- Group members: readable by co-members, writable by group creator or self
create policy "group_members_select" on public.group_members
    for select using (
        group_id in (
            select group_id from public.group_members
            where user_id = auth.uid()
        )
    );

create policy "group_members_insert" on public.group_members
    for insert with check (
        user_id = auth.uid()
        or exists (
            select 1 from public.groups
            where id = group_id and created_by = auth.uid()
        )
    );

create policy "group_members_delete" on public.group_members
    for delete using (
        user_id = auth.uid()
        or exists (
            select 1 from public.groups
            where id = group_id and created_by = auth.uid()
        )
    );

create policy "group_members_update" on public.group_members
    for update using (user_id = auth.uid());

-- Daily scores: own data + group peers (for leaderboard)
create policy "scores_select_own" on public.daily_scores
    for select using (auth.uid() = user_id);

create policy "scores_insert_own" on public.daily_scores
    for insert with check (auth.uid() = user_id);

create policy "scores_update_own" on public.daily_scores
    for update using (auth.uid() = user_id);

create policy "scores_select_group_peers" on public.daily_scores
    for select using (
        user_id in (
            select gm.user_id from public.group_members gm
            where gm.group_id in (
                select gm2.group_id from public.group_members gm2
                where gm2.user_id = auth.uid()
            )
        )
    );

-- RPC FUNCTIONS
--
-- Key design note: AdKanGroup and GroupMember Swift models have NO CodingKeys,
-- so the JSON keys returned by RPCs must be camelCase to match Swift properties.
-- LeaderboardEntry HAS CodingKeys mapping snake_case, so leaderboard_for
-- returns standard snake_case columns.

-- my_groups(): all groups the caller belongs to, with nested members
create or replace function public.my_groups()
returns jsonb
language plpgsql
security definer
as $$
declare
    result jsonb;
begin
    select coalesce(jsonb_agg(grp), '[]'::jsonb) into result
    from (
        select jsonb_build_object(
            'id', g.id,
            'name', g.name,
            'type', g.type,
            'isFavorite', coalesce(gm_self.is_favorite, false),
            'members', coalesce((
                select jsonb_agg(
                    jsonb_build_object(
                        'userId', m.user_id,
                        'displayName', u.display_name,
                        'avatarEmoji', u.avatar_emoji,
                        'dailyTotalMinutes', ds.daily_total_minutes,
                        'rank', null
                    )
                    order by coalesce(ds.daily_total_minutes, 9999) asc
                )
                from public.group_members m
                join public.users u on u.id = m.user_id
                left join public.daily_scores ds
                    on ds.user_id = m.user_id
                    and ds.score_date = current_date
                where m.group_id = g.id
            ), '[]'::jsonb)
        ) as grp
        from public.groups g
        join public.group_members gm_self
            on gm_self.group_id = g.id
            and gm_self.user_id = auth.uid()
        order by gm_self.is_favorite desc, g.created_at desc
    ) sub;

    return result;
end;
$$;

-- create_group(group_name, group_type): creates group + adds caller as member
create or replace function public.create_group(
    group_name text,
    group_type text default 'friends'
)
returns jsonb
language plpgsql
security definer
as $$
declare
    new_group_id uuid;
    creator_row  public.users;
    result       jsonb;
begin
    insert into public.groups (name, type, created_by)
    values (group_name, group_type, auth.uid())
    returning id into new_group_id;

    insert into public.group_members (group_id, user_id, is_favorite)
    values (new_group_id, auth.uid(), false);

    select * into creator_row from public.users where id = auth.uid();

    result := jsonb_build_object(
        'id', new_group_id,
        'name', group_name,
        'type', group_type,
        'isFavorite', false,
        'members', jsonb_build_array(
            jsonb_build_object(
                'userId', auth.uid(),
                'displayName', coalesce(creator_row.display_name, ''),
                'avatarEmoji', coalesce(creator_row.avatar_emoji, ''),
                'dailyTotalMinutes', null,
                'rank', 1
            )
        )
    );

    return result;
end;
$$;

-- group_detail(group_id): single group with members + today scores
create or replace function public.group_detail(group_id uuid)
returns jsonb
language plpgsql
security definer
as $$
declare
    result jsonb;
    g      public.groups;
    is_fav boolean;
begin
    if not exists (
        select 1 from public.group_members gm
        where gm.group_id = group_detail.group_id
            and gm.user_id = auth.uid()
    ) then
        raise exception 'Not a member of this group';
    end if;

    select * into g
    from public.groups
    where id = group_detail.group_id;

    select gm.is_favorite into is_fav
    from public.group_members gm
    where gm.group_id = group_detail.group_id
        and gm.user_id = auth.uid();

    select jsonb_build_object(
        'id', g.id,
        'name', g.name,
        'type', g.type,
        'isFavorite', coalesce(is_fav, false),
        'members', coalesce(jsonb_agg(
            jsonb_build_object(
                'userId', m.user_id,
                'displayName', u.display_name,
                'avatarEmoji', u.avatar_emoji,
                'dailyTotalMinutes', ds.daily_total_minutes,
                'rank', row_number() over (
                    order by coalesce(ds.daily_total_minutes, 9999) asc
                )
            )
        ), '[]'::jsonb)
    ) into result
    from public.group_members m
    join public.users u on u.id = m.user_id
    left join public.daily_scores ds
        on ds.user_id = m.user_id
        and ds.score_date = current_date
    where m.group_id = group_detail.group_id;

    return result;
end;
$$;

-- set_favorite_group(target_group_id, is_favorite): toggle favorite (max 1)
create or replace function public.set_favorite_group(
    target_group_id uuid,
    is_favorite     boolean
)
returns void
language plpgsql
security definer
as $$
begin
    if is_favorite then
        update public.group_members
        set is_favorite = false
        where user_id = auth.uid()
            and group_members.is_favorite = true;
    end if;

    update public.group_members
    set is_favorite = set_favorite_group.is_favorite
    where group_id = target_group_id
        and user_id = auth.uid();
end;
$$;

-- leaderboard_for(target_date): ranked scores across all your groups
-- Returns snake_case columns (LeaderboardEntry has CodingKeys)
create or replace function public.leaderboard_for(
    target_date date default current_date
)
returns table (
    user_id             uuid,
    display_name        text,
    avatar_emoji        text,
    daily_total_minutes integer,
    rank                bigint
)
language plpgsql
security definer
as $$
begin
    return query
    select distinct
        u.id as user_id,
        u.display_name,
        u.avatar_emoji,
        coalesce(ds.daily_total_minutes, 0) as daily_total_minutes,
        row_number() over (
            order by coalesce(ds.daily_total_minutes, 9999) asc
        ) as rank
    from public.users u
    inner join public.group_members gm
        on gm.user_id = u.id
    inner join public.group_members gm_self
        on gm_self.group_id = gm.group_id
        and gm_self.user_id = auth.uid()
    left join public.daily_scores ds
        on ds.user_id = u.id
        and ds.score_date = leaderboard_for.target_date
    order by rank;
end;
$$;

-- PERMISSIONS

grant usage on schema public to anon, authenticated;
grant select, insert, update on public.users to authenticated;
grant select, insert on public.groups to authenticated;
grant select, insert, update, delete on public.group_members to authenticated;
grant select, insert, update on public.daily_scores to authenticated;

grant execute on function public.my_groups() to authenticated;
grant execute on function public.create_group(text, text) to authenticated;
grant execute on function public.group_detail(uuid) to authenticated;
grant execute on function public.set_favorite_group(uuid, boolean) to authenticated;
grant execute on function public.leaderboard_for(date) to authenticated;
