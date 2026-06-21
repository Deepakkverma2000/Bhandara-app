-- Bhandara Live — Supabase schema (safe to run multiple times)
-- Supabase Dashboard → SQL Editor → paste all → Run

-- ─── Bhandaras ───────────────────────────────────────────────────────────────

create table if not exists public.bhandaras (
  id uuid primary key default gen_random_uuid(),
  bhandara_name text not null,
  publisher_name text not null,
  street text not null,
  village text not null,
  pin_code text not null,
  date timestamptz not null,
  latitude double precision not null,
  longitude double precision not null,
  image_url text,
  created_at timestamptz not null default now()
);

alter table public.bhandaras enable row level security;

drop policy if exists "Public read bhandaras" on public.bhandaras;
create policy "Public read bhandaras"
  on public.bhandaras for select using (true);

drop policy if exists "Public insert bhandaras" on public.bhandaras;
create policy "Public insert bhandaras"
  on public.bhandaras for insert with check (true);

-- ─── Storage (invitation images) ─────────────────────────────────────────────

insert into storage.buckets (id, name, public)
values ('bhandara-images', 'bhandara-images', true)
on conflict (id) do nothing;

drop policy if exists "Public read bhandara images" on storage.objects;
create policy "Public read bhandara images"
  on storage.objects for select
  using (bucket_id = 'bhandara-images');

drop policy if exists "Public upload bhandara images" on storage.objects;
create policy "Public upload bhandara images"
  on storage.objects for insert
  with check (bucket_id = 'bhandara-images');

-- ─── Device tokens (push notifications) ────────────────────────────────────

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  device_id text not null unique,
  fcm_token text,
  platform text not null default 'unknown',
  latitude double precision,
  longitude double precision,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.device_tokens enable row level security;

drop policy if exists "Public read device_tokens" on public.device_tokens;
create policy "Public read device_tokens"
  on public.device_tokens for select using (true);

drop policy if exists "Public insert device_tokens" on public.device_tokens;
create policy "Public insert device_tokens"
  on public.device_tokens for insert with check (true);

drop policy if exists "Public update device_tokens" on public.device_tokens;
create policy "Public update device_tokens"
  on public.device_tokens for update using (true);

-- ─── In-app notifications ────────────────────────────────────────────────────

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  bhandara_id uuid references public.bhandaras(id) on delete cascade,
  title text not null,
  body text not null,
  created_at timestamptz not null default now()
);

alter table public.notifications enable row level security;

drop policy if exists "Public read notifications" on public.notifications;
create policy "Public read notifications"
  on public.notifications for select using (true);

drop policy if exists "Public insert notifications" on public.notifications;
create policy "Public insert notifications"
  on public.notifications for insert with check (true);

-- ─── Per-device read state ───────────────────────────────────────────────────

create table if not exists public.notification_reads (
  notification_id uuid references public.notifications(id) on delete cascade,
  device_id text not null,
  read_at timestamptz not null default now(),
  primary key (notification_id, device_id)
);

alter table public.notification_reads enable row level security;

drop policy if exists "Public read notification_reads" on public.notification_reads;
create policy "Public read notification_reads"
  on public.notification_reads for select using (true);

drop policy if exists "Public insert notification_reads" on public.notification_reads;
create policy "Public insert notification_reads"
  on public.notification_reads for insert with check (true);

drop policy if exists "Public update notification_reads" on public.notification_reads;
create policy "Public update notification_reads"
  on public.notification_reads for update using (true);

-- ─── Users (Google SSO profiles) ─────────────────────────────────────────────

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  full_name text,
  avatar_url text,
  is_blocked boolean not null default false,
  report_count integer not null default 0,
  is_admin boolean not null default false,
  created_at timestamptz not null default now(),
  last_login_at timestamptz not null default now()
);

alter table public.users add column if not exists is_blocked boolean not null default false;
alter table public.users add column if not exists report_count integer not null default 0;
alter table public.users add column if not exists is_admin boolean not null default false;

alter table public.users enable row level security;

drop policy if exists "Users read own profile" on public.users;
create policy "Users read own profile"
  on public.users for select
  using (auth.uid() = id);

drop policy if exists "Users update own profile" on public.users;
create policy "Users update own profile"
  on public.users for update
  using (auth.uid() = id);

drop policy if exists "Users insert own profile" on public.users;
create policy "Users insert own profile"
  on public.users for insert
  with check (auth.uid() = id);

alter table public.bhandaras add column if not exists posted_by uuid references public.users(id) on delete set null;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, email, full_name, avatar_url, last_login_at)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name'),
    coalesce(new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'picture'),
    now()
  )
  on conflict (id) do update set
    email = excluded.email,
    full_name = excluded.full_name,
    avatar_url = excluded.avatar_url,
    last_login_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ─── Bhandara reports ────────────────────────────────────────────────────────

create table if not exists public.bhandara_reports (
  id uuid primary key default gen_random_uuid(),
  bhandara_id uuid not null references public.bhandaras(id) on delete cascade,
  reporter_id uuid not null references public.users(id) on delete cascade,
  reported_user_id uuid references public.users(id) on delete set null,
  reason text not null check (char_length(trim(reason)) >= 5),
  created_at timestamptz not null default now(),
  unique (bhandara_id, reporter_id)
);

alter table public.bhandara_reports alter column reported_user_id drop not null;

alter table public.bhandara_reports enable row level security;

drop policy if exists "Users read own reports" on public.bhandara_reports;
create policy "Users read own reports"
  on public.bhandara_reports for select
  using (auth.uid() = reporter_id);

create or replace function public.handle_bhandara_report()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_count integer;
begin
  if new.reported_user_id is null then
    return new;
  end if;

  if exists (
    select 1
    from public.users
    where id = new.reported_user_id
      and email = 'unlinked-listings@internal.bhandara.local'
  ) then
    return new;
  end if;

  update public.users
  set report_count = report_count + 1
  where id = new.reported_user_id
  returning report_count into new_count;

  if new_count >= 10 then
    update public.users
    set is_blocked = true
    where id = new.reported_user_id;
  end if;

  return new;
end;
$$;

-- Link older Bhandaras to user accounts when publisher name matches Google profile name
update public.bhandaras b
set posted_by = u.id
from public.users u
where b.posted_by is null
  and lower(trim(b.publisher_name)) = lower(trim(coalesce(u.full_name, '')));

-- Make yourself admin (run once with your Google login email):
-- update public.users set is_admin = true where email = 'your@gmail.com';

drop trigger if exists on_bhandara_report_created on public.bhandara_reports;
create trigger on_bhandara_report_created
  after insert on public.bhandara_reports
  for each row execute function public.handle_bhandara_report();
