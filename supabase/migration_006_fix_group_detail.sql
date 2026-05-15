-- Fix group_detail(): move row_number() out of jsonb_agg() to fix error 42803
-- "aggregate function calls cannot contain window function calls"

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
                'userId', ranked.user_id,
                'displayName', ranked.display_name,
                'avatarEmoji', ranked.avatar_emoji,
                'dailyTotalMinutes', ranked.daily_total_minutes,
                'rank', ranked.rk,
                'isCurrentUser', (ranked.user_id = auth.uid())
            )
            order by ranked.rk
        ), '[]'::jsonb)
    ) into result
    from (
        select
            m.user_id,
            u.display_name,
            u.avatar_emoji,
            ds.daily_total_minutes,
            row_number() over (
                order by coalesce(ds.daily_total_minutes, 9999) asc
            ) as rk
        from public.group_members m
        join public.users u on u.id = m.user_id
        left join public.daily_scores ds
            on ds.user_id = m.user_id
            and ds.score_date = current_date
        where m.group_id = group_detail.group_id
    ) ranked;

    return result;
end;
$$;
