-- GTech Garçom — initial schema.
--
-- Design notes (deliberate simplifications vs. the full table list in the
-- product brief, to avoid duplicating what Supabase already provides):
--   * No `sessions` table — auth.sessions (Supabase Auth) already owns this.
--   * No `files` table — Supabase Storage tracks its own objects; add one
--     only if per-file business metadata is needed later.
--   * No generic `logs` table — infra/runtime logs live in Supabase's own
--     log explorer; `audit_logs` below covers *domain* events instead.
--   * No `qr_codes` table — the QR/NFC URL is always
--     `/r/{company_id}/m/{table_id}`, derived from `restaurant_tables.id`.
--     `access_tags` below is inventory metadata (which physical medium
--     exists for a table), not a second copy of the URL.
--   * `company_users` is folded into `profiles.company_id` — a human here
--     belongs to exactly one company (or none, for master_admin), so a
--     many-to-many join table would be pure overhead.
--   * Calls have no accept/finish state machine (see spec): a call is
--     "active" purely by being within `CallRecord.activeWindow` of
--     `created_at`. That's computed in the app, not stored.

create extension if not exists "pgcrypto";

-- ── Enums ───────────────────────────────────────────────────────────────

create type public.user_role as enum ('master_admin', 'admin', 'waiter');
create type public.company_status as enum ('active', 'suspended', 'cancelled');
create type public.subscription_status as enum ('trialing', 'active', 'past_due', 'canceled');
create type public.access_medium as enum ('qr', 'nfc');

-- ── Tables ──────────────────────────────────────────────────────────────

create table public.plans (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  price_cents integer not null default 0,
  max_tables integer,
  max_waiters integer,
  features jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  logo_url text,
  primary_color text,
  google_review_url text,
  status public.company_status not null default 'active',
  plan_id uuid references public.plans (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- One row per authenticated human, 1:1 with auth.users. company_id is null
-- only for master_admin; every admin/waiter belongs to exactly one company.
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  company_id uuid references public.companies (id) on delete cascade,
  role public.user_role not null,
  full_name text not null default '',
  avatar_url text,
  created_at timestamptz not null default now(),
  constraint profiles_company_matches_role check (
    (role = 'master_admin' and company_id is null) or
    (role <> 'master_admin' and company_id is not null)
  )
);

create table public.restaurant_tables (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies (id) on delete cascade,
  label text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (company_id, label)
);

-- Inventory of the physical QR prints / NFC chips deployed for a table.
-- The URL they encode is never stored here — it's always derived as
-- /r/{company_id}/m/{table_id}.
create table public.access_tags (
  id uuid primary key default gen_random_uuid(),
  table_id uuid not null references public.restaurant_tables (id) on delete cascade,
  medium public.access_medium not null,
  note text,
  created_at timestamptz not null default now()
);

-- One row per "chamar garçom" tap. table_label is denormalized so the
-- Supabase realtime `.stream()` API (no joins) can render the queue
-- directly. See CallRecord in the Flutter app for the "active window" rule.
create table public.calls (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies (id) on delete cascade,
  table_id uuid not null references public.restaurant_tables (id) on delete cascade,
  table_label text not null,
  created_at timestamptz not null default now()
);

create index calls_company_created_idx on public.calls (company_id, created_at desc);
create index calls_table_created_idx on public.calls (table_id, created_at desc);

create table public.menu_categories (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies (id) on delete cascade,
  name text not null,
  "position" integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.menu_items (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.menu_categories (id) on delete cascade,
  -- Denormalized from menu_categories.company_id so RLS policies here don't
  -- need a subquery join — cheaper checks on a hot public-read path.
  company_id uuid not null references public.companies (id) on delete cascade,
  name text not null,
  description text,
  price numeric(10, 2) not null default 0,
  image_url text,
  is_available boolean not null default true,
  "position" integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index menu_items_category_idx on public.menu_items (category_id, "position");

-- Extended per-company presentation config beyond what's on `companies`
-- (name/logo/google link) — free-form so the design system can evolve
-- without another migration per new theme knob.
create table public.restaurant_settings (
  company_id uuid primary key references public.companies (id) on delete cascade,
  theme jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies (id) on delete cascade,
  plan_id uuid not null references public.plans (id),
  status public.subscription_status not null default 'trialing',
  current_period_end timestamptz,
  created_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  body text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  push_token text not null,
  platform text not null,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  unique (user_id, push_token)
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid references public.companies (id) on delete set null,
  actor_id uuid references auth.users (id) on delete set null,
  action text not null,
  entity text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- ── Helper functions (SECURITY DEFINER to dodge RLS self-recursion) ──────

create or replace function public.current_role()
returns public.user_role
language sql
security definer
stable
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.current_company_id()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select company_id from public.profiles where id = auth.uid();
$$;

create or replace function public.is_master_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select coalesce((select role from public.profiles where id = auth.uid()) = 'master_admin', false);
$$;

-- ── updated_at maintenance ────────────────────────────────────────────────

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger companies_set_updated_at before update on public.companies
  for each row execute function public.set_updated_at();
create trigger restaurant_tables_set_updated_at before update on public.restaurant_tables
  for each row execute function public.set_updated_at();
create trigger menu_categories_set_updated_at before update on public.menu_categories
  for each row execute function public.set_updated_at();
create trigger menu_items_set_updated_at before update on public.menu_items
  for each row execute function public.set_updated_at();

-- ── New-user provisioning ─────────────────────────────────────────────────
-- Public self-signup is intentionally not exposed in the app. Admin/waiter
-- accounts are created via the Supabase Admin API (service role, from a
-- future `invite-user` Edge Function) passing role/company_id/full_name in
-- user_metadata; this trigger turns that into the matching profile row.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, company_id, role, full_name)
  values (
    new.id,
    nullif(new.raw_user_meta_data ->> 'company_id', '')::uuid,
    coalesce((new.raw_user_meta_data ->> 'role')::public.user_role, 'waiter'),
    coalesce(new.raw_user_meta_data ->> 'full_name', '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ── Row Level Security ────────────────────────────────────────────────────

alter table public.plans enable row level security;
alter table public.companies enable row level security;
alter table public.profiles enable row level security;
alter table public.restaurant_tables enable row level security;
alter table public.access_tags enable row level security;
alter table public.calls enable row level security;
alter table public.menu_categories enable row level security;
alter table public.menu_items enable row level security;
alter table public.restaurant_settings enable row level security;
alter table public.subscriptions enable row level security;
alter table public.notifications enable row level security;
alter table public.devices enable row level security;
alter table public.audit_logs enable row level security;

-- plans: every authenticated user can read (admins need to see plan
-- features); only GTech manages them.
create policy plans_select_authenticated on public.plans
  for select to authenticated using (true);
create policy plans_write_master_admin on public.plans
  for all to authenticated using (public.is_master_admin()) with check (public.is_master_admin());

-- companies: public storefront fields are readable by anon (client PWA
-- resolves company name/logo/review link this way); tenants see their own
-- row; GTech sees and manages everything.
create policy companies_select_public_active on public.companies
  for select to anon using (status = 'active');
create policy companies_select_own on public.companies
  for select to authenticated using (
    public.is_master_admin() or id = public.current_company_id()
  );
create policy companies_update_own_admin on public.companies
  for update to authenticated using (
    public.current_role() = 'admin' and id = public.current_company_id()
  ) with check (
    public.current_role() = 'admin' and id = public.current_company_id()
  );
create policy companies_write_master_admin on public.companies
  for all to authenticated using (public.is_master_admin()) with check (public.is_master_admin());

-- profiles: see yourself always; admins see their own company's staff;
-- GTech sees everyone. No client-facing insert policy — rows are only
-- created by the handle_new_user trigger (SECURITY DEFINER, bypasses RLS).
create policy profiles_select_self on public.profiles
  for select to authenticated using (id = auth.uid());
create policy profiles_select_company_admin on public.profiles
  for select to authenticated using (
    public.current_role() = 'admin' and company_id = public.current_company_id()
  );
create policy profiles_select_master_admin on public.profiles
  for select to authenticated using (public.is_master_admin());
create policy profiles_update_self on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- Only self-service columns are writable by the user themselves — role and
-- company_id changes must go through GTech/admin tooling, not the app.
revoke update on public.profiles from authenticated;
grant update (full_name, avatar_url) on public.profiles to authenticated;

-- restaurant_tables: table_id/company_id act as bearer identifiers handed
-- out via QR/NFC (same trust model as a unique share link), so anon can
-- resolve a specific table; staff of the company and GTech manage them.
create policy restaurant_tables_select_public on public.restaurant_tables
  for select to anon using (true);
create policy restaurant_tables_select_staff on public.restaurant_tables
  for select to authenticated using (
    public.is_master_admin() or company_id = public.current_company_id()
  );
create policy restaurant_tables_write_admin on public.restaurant_tables
  for all to authenticated using (
    public.is_master_admin() or
    (public.current_role() = 'admin' and company_id = public.current_company_id())
  ) with check (
    public.is_master_admin() or
    (public.current_role() = 'admin' and company_id = public.current_company_id())
  );

create policy access_tags_select_staff on public.access_tags
  for select to authenticated using (
    public.is_master_admin() or exists (
      select 1 from public.restaurant_tables t
      where t.id = access_tags.table_id and t.company_id = public.current_company_id()
    )
  );
create policy access_tags_write_admin on public.access_tags
  for all to authenticated using (
    public.is_master_admin() or exists (
      select 1 from public.restaurant_tables t
      where t.id = access_tags.table_id
        and t.company_id = public.current_company_id()
        and public.current_role() = 'admin'
    )
  ) with check (
    public.is_master_admin() or exists (
      select 1 from public.restaurant_tables t
      where t.id = access_tags.table_id
        and t.company_id = public.current_company_id()
        and public.current_role() = 'admin'
    )
  );

-- calls: anon may create a call only for a table that really belongs to the
-- company_id it claims, and may read calls back (needed for the client's
-- own "already called" cooldown state — there's no anon identity to scope
-- this further; a call row only holds a timestamp + table label, so this
-- is an accepted trade-off of the no-login client model). Staff read their
-- company's calls; GTech reads everything.
create policy calls_insert_public on public.calls
  for insert to anon with check (
    exists (
      select 1 from public.restaurant_tables t
      where t.id = calls.table_id and t.company_id = calls.company_id
    )
  );
create policy calls_select_public on public.calls
  for select to anon using (true);
create policy calls_select_staff on public.calls
  for select to authenticated using (
    public.is_master_admin() or company_id = public.current_company_id()
  );
create policy calls_delete_master_admin on public.calls
  for delete to authenticated using (public.is_master_admin());

-- menu_categories / menu_items: public read (the digital menu), staff of
-- the company manage their own, GTech manages everything.
create policy menu_categories_select_public on public.menu_categories
  for select to anon using (true);
create policy menu_categories_select_staff on public.menu_categories
  for select to authenticated using (
    public.is_master_admin() or company_id = public.current_company_id()
  );
create policy menu_categories_write_admin on public.menu_categories
  for all to authenticated using (
    public.is_master_admin() or
    (public.current_role() = 'admin' and company_id = public.current_company_id())
  ) with check (
    public.is_master_admin() or
    (public.current_role() = 'admin' and company_id = public.current_company_id())
  );

create policy menu_items_select_public on public.menu_items
  for select to anon using (is_available);
create policy menu_items_select_staff on public.menu_items
  for select to authenticated using (
    public.is_master_admin() or company_id = public.current_company_id()
  );
create policy menu_items_write_admin on public.menu_items
  for all to authenticated using (
    public.is_master_admin() or
    (public.current_role() = 'admin' and company_id = public.current_company_id())
  ) with check (
    public.is_master_admin() or
    (public.current_role() = 'admin' and company_id = public.current_company_id())
  );

-- restaurant_settings: staff of the company + GTech only (not exposed to
-- the client PWA yet — see companies for the public-facing subset).
create policy restaurant_settings_select_staff on public.restaurant_settings
  for select to authenticated using (
    public.is_master_admin() or company_id = public.current_company_id()
  );
create policy restaurant_settings_write_admin on public.restaurant_settings
  for all to authenticated using (
    public.is_master_admin() or
    (public.current_role() = 'admin' and company_id = public.current_company_id())
  ) with check (
    public.is_master_admin() or
    (public.current_role() = 'admin' and company_id = public.current_company_id())
  );

-- subscriptions: the company's own admin can see its subscription; only
-- GTech manages billing.
create policy subscriptions_select_own on public.subscriptions
  for select to authenticated using (
    public.is_master_admin() or company_id = public.current_company_id()
  );
create policy subscriptions_write_master_admin on public.subscriptions
  for all to authenticated using (public.is_master_admin()) with check (public.is_master_admin());

-- notifications / devices: strictly own-row.
create policy notifications_select_own on public.notifications
  for select to authenticated using (user_id = auth.uid());
create policy notifications_update_own on public.notifications
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy devices_manage_own on public.devices
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- audit_logs: append-only from triggers (SECURITY DEFINER, bypasses RLS);
-- no direct insert policy for humans. Read is admin-own-company / GTech.
create policy audit_logs_select_staff on public.audit_logs
  for select to authenticated using (
    public.is_master_admin() or
    (public.current_role() = 'admin' and company_id = public.current_company_id())
  );

-- ── Illustrative audit trigger ────────────────────────────────────────────
-- Logs company status changes (suspend/cancel/reactivate). More triggers
-- (menu edits, table changes, ...) follow the same pattern in later phases.

create or replace function public.audit_company_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status is distinct from old.status then
    insert into public.audit_logs (company_id, actor_id, action, entity, entity_id, metadata)
    values (
      new.id,
      auth.uid(),
      'status_changed',
      'company',
      new.id,
      jsonb_build_object('from', old.status, 'to', new.status)
    );
  end if;
  return new;
end;
$$;

create trigger companies_audit_status_change
  after update on public.companies
  for each row execute function public.audit_company_status_change();

-- ── Realtime ───────────────────────────────────────────────────────────────
-- `calls` is the only table the app streams via Supabase Realtime.

alter publication supabase_realtime add table public.calls;
