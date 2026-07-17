-- Phase 2 amendments.
--
-- 1. `profiles.email` — the admin's staff list needs to show each waiter's
--    e-mail, but e-mail lives in auth.users, which client code can't read.
--    Denormalize it onto the profile at provisioning time.
-- 2. Company status guard — `companies_update_own_admin` (RLS) lets a
--    company admin update their own row, but `status` must remain
--    GTech-only: without this trigger an admin could reactivate their own
--    suspended company. RLS policies can't compare OLD vs NEW, so this
--    lives in a trigger. auth.uid() IS NULL means direct DB / service-role
--    access (migrations, edge functions), which stays allowed.

alter table public.profiles add column email text not null default '';

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, company_id, role, full_name, email)
  values (
    new.id,
    nullif(new.raw_user_meta_data ->> 'company_id', '')::uuid,
    coalesce((new.raw_user_meta_data ->> 'role')::public.user_role, 'waiter'),
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(new.email, '')
  );
  return new;
end;
$$;

create or replace function public.guard_company_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status is distinct from old.status
     and auth.uid() is not null
     and not public.is_master_admin() then
    raise exception 'Somente a GTech pode alterar o status da empresa.';
  end if;
  return new;
end;
$$;

create trigger companies_guard_status_change
  before update on public.companies
  for each row execute function public.guard_company_status_change();

revoke execute on function public.guard_company_status_change() from public, anon, authenticated;
