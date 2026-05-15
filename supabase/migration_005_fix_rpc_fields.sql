-- Fix RPC responses to include isCurrentUser and remove non-existent column references

-- 1. Fix my_groups(): add isCurrentUser to member JSON
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
                        'rank', null,
                        'isCurrentUser', (m.user_id = auth.uid())
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

-- 2. Fix create_group(): remove non-existent column refs, add isCurrentUser
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
    group_count  integer;
begin
    select count(*) into group_count
    from public.group_members
    where user_id = auth.uid();

    if not exists (
        select 1 from public.users
        where id = auth.uid() and is_premium = true and is_trial = false
    ) and group_count >= 3 then
        raise exception 'Group limit reached';
    end if;

    new_group_id := uuid_generate_v4();

    insert into public.groups (id, name, type, created_by)
    values (new_group_id, group_name, group_type, auth.uid());

    insert into public.group_members (group_id, user_id)
    values (new_group_id, auth.uid());

    select jsonb_build_object(
        'id', new_group_id,
        'name', group_name,
        'type', group_type,
        'isFavorite', false,
        'createdBy', auth.uid(),
        'members', jsonb_build_array(
            jsonb_build_object(
                'userId', auth.uid(),
                'displayName', coalesce(u.display_name, ''),
                'avatarEmoji', coalesce(u.avatar_emoji, ''),
                'dailyTotalMinutes', null,
                'currentStreak', null,
                'leagueBadge', null,
                'rank', 1,
                'isCurrentUser', true
            )
        )
    ) into result
    from public.users u
    where u.id = auth.uid();

    return result;
end;
$$;

-- 3. Fix group_detail(): add isCurrentUser to member JSON
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
                ),
                'isCurrentUser', (m.user_id = auth.uid())
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
