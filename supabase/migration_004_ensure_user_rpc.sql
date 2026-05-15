-- Ensure user row exists (called after Apple Sign-In)
-- security definer bypasses RLS so the insert always works
create or replace function public.ensure_user(
    p_display_name text default '',
    p_avatar_emoji text default ''
)
returns void
language plpgsql
security definer
as $$
begin
    insert into public.users (id, display_name, avatar_emoji)
    values (auth.uid(), p_display_name, p_avatar_emoji)
    on conflict (id) do update
        set display_name = coalesce(nullif(excluded.display_name, ''), users.display_name),
            avatar_emoji = coalesce(nullif(excluded.avatar_emoji, ''), users.avatar_emoji);
end;
$$;

grant execute on function public.ensure_user(text, text) to authenticated;
