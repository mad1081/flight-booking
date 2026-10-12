-- Trigger execution by the database still works; API users must not invoke it.
revoke execute on function public.create_profile_for_user() from public, anon, authenticated;
