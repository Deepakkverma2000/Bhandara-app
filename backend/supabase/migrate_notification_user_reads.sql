-- Per-user notification read state (fixes same-device / multi-account bell icon)
-- Supabase Dashboard → SQL Editor → Run

alter table public.notification_reads add column if not exists user_id uuid references public.users(id) on delete cascade;

create unique index if not exists notification_reads_user_unique
  on public.notification_reads (notification_id, user_id)
  where user_id is not null;
