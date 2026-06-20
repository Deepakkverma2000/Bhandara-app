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
