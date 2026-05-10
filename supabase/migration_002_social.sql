-- AdKan -- Migration 002: Social Competition System
-- Run this in Supabase SQL Editor AFTER migration_001_initial.sql

-- NEW COLUMNS ON users

alter table public.users add column profile_completed boolean not null default false;
alter table public.users add column current_streak int not null default 0;
alter table public.users add column longest_streak int not null default 0;
alter table public.users add column league_badge text not null default '';
alter table public.users add column league_updated_at date;

-- NEW COLUMNS ON groups (track ownership transfer)

alter table public.groups add column updated_at timestamptz not null default now();

-- PERFORMANCE INDEX for weekly aggregation

create index idx_daily_scores_user_date on public.daily_scores (user_id, score_date);

-- RPC: update_profile

create or replace function public.update_profile(
    new_display_name text,
    new_avatar_emoji text
)
returns void
language plpgsql
security definer
as $$
begin
    update public.users
    set display_name = new_display_name,
        avatar_emoji = new_avatar_emoji,
        profile_completed = true
    where id = auth.uid();
end;
$$;

-- RPC: update_streak
-- Calculates consecutive days under goal and updates user record.
-- Goal is stored client-side; passed as param so server can evaluate.

create or replace function public.update_streak(user_goal_minutes int default 120)
returns void
language plpgsql
security definer
as $$
declare
    streak_count int := 0;
    check_date date := current_date;
    daily_mins int;
begin
    loop
        select daily_total_minutes into daily_mins
        from public.daily_scores
        where user_id = auth.uid() and score_date = check_date;

        exit when daily_mins is null or daily_mins > user_goal_minutes;
        streak_count := streak_count + 1;
        check_date := check_date - 1;
    end loop;

    update public.users
    set current_streak = streak_count,
        longest_streak = greatest(longest_streak, streak_count)
    where id = auth.uid();
end;
$$;

-- RPC: update_league_badge
-- Sets league badge based on days-under-goal in the current week.

create or replace function public.update_league_badge(
    badge text
)
returns void
language plpgsql
security definer
as $$
begin
    update public.users
    set league_badge = badge,
        league_updated_at = current_date
    where id = auth.uid();
end;
$$;

-- RPC: leave_group
-- Handles ownership transfer when owner leaves.

create or replace function public.leave_group(target_group_id uuid)
returns void
language plpgsql
security definer
as $$
declare
    is_owner boolean;
    next_owner uuid;
begin
    select (g.created_by = auth.uid()) into is_owner
    from public.groups g where g.id = target_group_id;

    delete from public.group_members
    where group_id = target_group_id and user_id = auth.uid();

    if is_owner then
        select user_id into next_owner
        from public.group_members
        where group_id = target_group_id
        order by joined_at asc limit 1;

        if next_owner is not null then
            update public.groups
            set created_by = next_owner, updated_at = now()
            where id = target_group_id;
        else
            delete from public.groups where id = target_group_id;
        end if;
    end if;
end;
$$;

-- RPC: weekly_leaderboard_for
-- Returns ranked weekly totals across all caller's groups.
-- Replaces client-side 7x daily calls with single server aggregation.

create or replace function public.weekly_leaderboard_for(
    week_start date default (current_date - extract(dow from current_date)::int)::date
)
returns table (
    user_id             uuid,
    display_name        text,
    avatar_emoji        text,
    weekly_total_minutes bigint,
    current_streak      int,
    league_badge        text,
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
        coalesce(sum(ds.daily_total_minutes), 0)::bigint as weekly_total_minutes,
        u.current_streak,
        u.league_badge,
        row_number() over (
            order by coalesce(sum(ds.daily_total_minutes), 0) asc
        ) as rank
    from public.users u
    inner join public.group_members gm
        on gm.user_id = u.id
    inner join public.group_members gm_self
        on gm_self.group_id = gm.group_id
        and gm_self.user_id = auth.uid()
    left join public.daily_scores ds
        on ds.user_id = u.id
        and ds.score_date between week_start and week_start + interval '6 days'
    group by u.id, u.display_name, u.avatar_emoji, u.current_streak, u.league_badge
    order by rank;
end;
$$;

-- UPDATE EXISTING RPCs to include streak + badge

-- Updated leaderboard_for: now includes current_streak and league_badge
create or replace function public.leaderboard_for(
    target_date date default current_date
)
returns table (
    user_id             uuid,
    display_name        text,
    avatar_emoji        text,
    daily_total_minutes integer,
    current_streak      int,
    league_badge        text,
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
        u.current_streak,
        u.league_badge,
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

-- Updated my_groups: include streak + badge per member
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
            'createdBy', g.created_by,
            'members', coalesce((
                select jsonb_agg(
                    jsonb_build_object(
                        'userId', m.user_id,
                        'displayName', u.display_name,
                        'avatarEmoji', u.avatar_emoji,
                        'dailyTotalMinutes', ds.daily_total_minutes,
                        'currentStreak', u.current_streak,
                        'leagueBadge', u.league_badge,
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

-- Updated group_detail: include streak + badge + createdBy
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
        'createdBy', g.created_by,
        'members', coalesce(jsonb_agg(
            jsonb_build_object(
                'userId', m.user_id,
                'displayName', u.display_name,
                'avatarEmoji', u.avatar_emoji,
                'dailyTotalMinutes', ds.daily_total_minutes,
                'currentStreak', u.current_streak,
                'leagueBadge', u.league_badge,
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

-- PERMISSIONS

grant execute on function public.update_profile(text, text) to authenticated;
grant execute on function public.update_streak(int) to authenticated;
grant execute on function public.update_league_badge(text) to authenticated;
grant execute on function public.leave_group(uuid) to authenticated;
grant execute on function public.weekly_leaderboard_for(date) to authenticated;
