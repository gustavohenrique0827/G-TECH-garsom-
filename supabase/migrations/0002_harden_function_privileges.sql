-- Lock down the internal RLS-helper / trigger functions flagged by the
-- Supabase security advisor: they must never be callable directly over
-- PostgREST as a public RPC endpoint.

alter function public.set_updated_at() set search_path = public;

-- current_role/current_company_id/is_master_admin are used *inside* RLS
-- policies evaluated as `authenticated`, so that role keeps EXECUTE; anon
-- and the public pseudo-role do not need (and should not have) it.
-- Note: `authenticated` still shows up in the advisor because these are
-- necessarily callable as RPC too (Postgres has no way to grant EXECUTE
-- "only from within a policy") — accepted, since each only ever returns
-- facts about the caller's own profile.
revoke execute on function public.current_role() from public, anon;
revoke execute on function public.current_company_id() from public, anon;
revoke execute on function public.is_master_admin() from public, anon;
grant execute on function public.current_role() to authenticated;
grant execute on function public.current_company_id() to authenticated;
grant execute on function public.is_master_admin() to authenticated;

-- handle_new_user / audit_company_status_change only ever run as trigger
-- bodies (invoked internally, independent of the caller's grants) — no
-- role should be able to call them directly as an RPC.
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.audit_company_status_change() from public, anon, authenticated;
