-- AdKan -- Migration 003: Premium Server-Side Enforcement
-- Run this in Supabase SQL Editor AFTER migration_002_social.sql

-- PREMIUM STATUS COLUMNS on users

alter table public.users add column is_premium boolean not null default false;
alter table public.users add column is_trial boolean not null default false;
alter table public.users add column premium_expires_at timestamptz;

-- RPC: sync_premium_status
-- Called by the client after every StoreKit entitlement refresh.

create or replace function public.sync_premium_status(
    p_is_premium boolean,
    p_is_trial boolean default false,
    p_expires_at timestamptz default null
)
returns void
language plpgsql
security definer
as $$
begin
    update public.users
    set is_premium = p_is_premium,
        is_trial = p_is_trial,
        premium_expires_at = p_expires_at
    where id = auth.uid();
end;
$$;

-- RPC: add_member
-- Replaces direct INSERT to group_members. Validates:
-- 1. Caller is a member of the group
-- 2. Universal hard cap (40 members)
-- 3. Premium check for groups above free limit (3) — trial does NOT count

create or replace function public.add_member(
    target_group_id uuid,
    target_user_id uuid
)
returns void
language plpgsql
security definer
as $$
declare
    current_count int;
begin
    if not exists (
        select 1 from public.group_members
        where group_id = target_group_id and user_id = auth.uid()
    ) then
        raise exception 'Not a member of this group';
    end if;

    select count(*) into current_count
    from public.group_members
    where group_id = target_group_id;

    if current_count >= 40 then
        raise exception 'Group is full';
    end if;

    if current_count >= 3 then
        if not exists (
            select 1 from public.users
            where id = auth.uid() and is_premium = true and is_trial = false
        ) then
            raise exception 'Premium required';
        end if;
    end if;

    insert into public.group_members (group_id, user_id)
    values (target_group_id, target_user_id)
    on conflict do nothing;
end;
$$;

-- UPDATE create_group to enforce group count limit
-- Trial does NOT unlock group expansion.

create or replace function public.create_group(
    group_name text,
    group_type text default 'friends'
)
returns jsonb
language plpgsql
security definer
as $$
declare
    group_count int;
    new_group_id uuid;
    result jsonb;
begin
    select count(distinct group_id) into group_count
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
                'displayName', u.display_name,
                'avatarEmoji', u.avatar_emoji,
                'dailyTotalMinutes', null,
                'currentStreak', u.current_streak,
                'leagueBadge', u.league_badge,
                'rank', null
            )
        )
    ) into result
    from public.users u
    where u.id = auth.uid();

    return result;
end;
$$;

-- UNIVERSAL HARD CAP TRIGGER
-- Safety net: 40 members max per group, regardless of premium status.

create or replace function public.enforce_member_hard_cap()
returns trigger
language plpgsql
as $$
declare
    cnt int;
begin
    select count(*) into cnt
    from public.group_members
    where group_id = NEW.group_id;

    if cnt >= 40 then
        raise exception 'Group member hard cap exceeded';
    end if;

    return NEW;
end;
$$;

create trigger trg_member_hard_cap
    before insert on public.group_members
    for each row execute function public.enforce_member_hard_cap();

-- LOCK DOWN DIRECT INSERT
-- Only the add_member RPC (and create_group which also inserts) can add members.
-- The RPC runs as security definer so it bypasses this revoke.

revoke insert on public.group_members from authenticated;

-- PERMISSIONS

grant execute on function public.sync_premium_status(boolean, boolean, timestamptz) to authenticated;
grant execute on function public.add_member(uuid, uuid) to authenticated;
