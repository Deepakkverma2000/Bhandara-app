-- Run in Supabase → SQL Editor (safe to run multiple times)
-- Fixes: users.is_blocked, users.report_count, users.is_admin, reports table, etc.

-- ─── User moderation columns ───────────────────────────────────────────────────

alter table public.users add column if not exists is_blocked boolean default false;
alter table public.users add column if not exists report_count integer default 0;
alter table public.users add column if not exists is_admin boolean default false;

update public.users set is_blocked = false where is_blocked is null;
update public.users set report_count = 0 where report_count is null;
update public.users set is_admin = false where is_admin is null;

alter table public.users alter column is_blocked set default false;
alter table public.users alter column is_blocked set not null;
alter table public.users alter column report_count set default 0;
alter table public.users alter column report_count set not null;
alter table public.users alter column is_admin set default false;
alter table public.users alter column is_admin set not null;

-- ─── Link Bhandaras to poster account ────────────────────────────────────────

alter table public.bhandaras add column if not exists posted_by uuid references public.users(id) on delete set null;

-- ─── Reports table ───────────────────────────────────────────────────────────

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

drop trigger if exists on_bhandara_report_created on public.bhandara_reports;
create trigger on_bhandara_report_created
  after insert on public.bhandara_reports
  for each row execute function public.handle_bhandara_report();

-- Make Deepak admin (safe to run multiple times)
update public.users set is_admin = true where email = 'deepakpatel200000@gmail.com';

-- Link older listings to Google accounts when publisher name matches
update public.bhandaras b
set posted_by = u.id
from public.users u
where b.posted_by is null
  and lower(trim(b.publisher_name)) = lower(trim(coalesce(u.full_name, '')));
