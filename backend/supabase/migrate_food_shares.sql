-- Food share posts — leftover food from events
-- Supabase Dashboard → SQL Editor → Run

create table if not exists public.food_share_posts (
  id uuid primary key default gen_random_uuid(),
  posted_by uuid not null references public.users(id) on delete cascade,
  contact_name text not null,
  phone_number text not null,
  event_name text,
  food_description text not null,
  quantity text,
  street text not null,
  village text not null,
  pin_code text not null,
  latitude double precision not null,
  longitude double precision not null,
  status text not null default 'open' check (status in ('open', 'accepted')),
  accepted_by uuid references public.users(id) on delete set null,
  accepted_by_name text,
  accepted_by_phone text,
  accepted_pickup_time timestamptz,
  accepted_plates_required integer,
  accepted_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists food_share_posts_status_idx on public.food_share_posts (status);
create index if not exists food_share_posts_posted_by_idx on public.food_share_posts (posted_by);
create index if not exists food_share_posts_created_at_idx on public.food_share_posts (created_at desc);

alter table public.food_share_posts enable row level security;

drop policy if exists "Public read food share posts" on public.food_share_posts;
create policy "Public read food share posts"
  on public.food_share_posts for select using (true);

-- Run if table already exists without accept detail columns:
alter table public.food_share_posts add column if not exists accepted_pickup_time timestamptz;
alter table public.food_share_posts add column if not exists accepted_plates_required integer;
