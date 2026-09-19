-- ============================================================
-- Efatha Church App — Supabase schema (replaces Django backend)
-- Run in Supabase Dashboard > SQL Editor (paste + Run).
-- ============================================================

-- ---------- helpers ----------
create extension if not exists "uuid-ossp";

-- ---------- profiles (extends auth.users) ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  email text,
  role text not null default 'member'
    check (role in ('admin','chief_apostle','katibu_kiongozi','apostle','senior_pastor','bishop','editor','data_entry','member')),
  church_position text default 'muumini',
  membership_number text,
  first_name text default '',
  last_name text default '',
  middle_name text,
  gender text,
  date_of_birth date,
  marital_status text,
  phone_number text,
  profile_picture_url text,
  country text,
  region text,
  service_region text,
  city text,
  residence text,
  street text,
  house_number text,
  postal_address text,
  bio text,
  address text,
  receive_notifications boolean not null default true,
  preferred_language text not null default 'en',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, username, first_name, last_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email,'@',1)),
    coalesce(new.raw_user_meta_data->>'first_name',''),
    coalesce(new.raw_user_meta_data->>'last_name','')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------- sermons ----------
create table if not exists public.sermons (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  preacher text not null default '',
  description text not null default '',
  scripture_reference text default '',
  topics text default '',
  duration text,
  audio_url text,
  video_url text,
  thumbnail_url text,
  sermon_date timestamptz not null default now(),
  views integer not null default 0,
  category text not null default 'Sunday Service',
  uploaded_by uuid references public.profiles(id) on delete set null,
  is_featured boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists sermons_created_idx on public.sermons (created_at desc);
create index if not exists sermons_category_idx on public.sermons (category);

-- ---------- events ----------
create table if not exists public.events (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  description text not null default '',
  location text not null default '',
  start_date timestamptz not null,
  end_date timestamptz not null,
  banner_url text,
  requires_registration boolean not null default false,
  max_attendees integer,
  registration_deadline timestamptz,
  category text not null default 'other',
  organizer_id uuid references public.profiles(id) on delete set null,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.event_registrations (
  id uuid primary key default uuid_generate_v4(),
  event_id uuid not null references public.events(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  registered_at timestamptz not null default now(),
  attended boolean not null default false,
  unique(event_id, user_id)
);

-- ---------- prayers ----------
create table if not exists public.prayer_requests (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles(id) on delete cascade,
  title text not null,
  description text not null default '',
  is_anonymous boolean not null default false,
  is_answered boolean not null default false,
  priority text not null default 'NORMAL' check (priority in ('NORMAL','HIGH','URGENT')),
  category text not null default 'other',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prayer_supports (
  id uuid primary key default uuid_generate_v4(),
  prayer_request_id uuid not null references public.prayer_requests(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(prayer_request_id, user_id)
);

create table if not exists public.prayer_images (
  id uuid primary key default uuid_generate_v4(),
  prayer_request_id uuid not null references public.prayer_requests(id) on delete cascade,
  image_url text not null,
  caption text default '',
  uploaded_at timestamptz not null default now()
);

create table if not exists public.prayer_comments (
  id uuid primary key default uuid_generate_v4(),
  prayer_request_id uuid not null references public.prayer_requests(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------- testimonies ----------
create table if not exists public.testimonies (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles(id) on delete cascade,
  prayer_request_id uuid references public.prayer_requests(id) on delete set null,
  title text not null,
  content text not null default '',
  photo_url text,
  video_url text,
  thumbnail_url text,
  testimony_type text not null default 'regular',
  category text not null default 'other',
  is_anonymous boolean not null default false,
  is_approved boolean not null default false,
  is_featured boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.testimony_praises (
  id uuid primary key default uuid_generate_v4(),
  testimony_id uuid not null references public.testimonies(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(testimony_id, user_id)
);

-- ---------- giving (Pesapal records live here now) ----------
create table if not exists public.givings (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles(id) on delete set null,
  donor_name text default '',
  donor_email text default '',
  donor_phone text default '',
  amount numeric(10,2) not null,
  currency text not null default 'TZS',
  giving_type text not null,
  payment_method text not null default 'mpesa',
  transaction_ref text default '',
  merchant_reference text unique,
  pesapal_tracking_id text default '',
  confirmation_code text default '',
  payment_status text not null default 'pending',
  notes text default '',
  is_anonymous boolean not null default false,
  is_recurring boolean not null default false,
  recurring_frequency text default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists public.payment_transactions (
  id uuid primary key default uuid_generate_v4(),
  giving_id uuid not null references public.givings(id) on delete cascade,
  transaction_id text unique not null,
  order_tracking_id text default '',
  merchant_reference text not null,
  gateway text not null default 'pesapal',
  status text not null default 'initiated',
  amount numeric(10,2) not null,
  currency text not null,
  payment_method text default '',
  payment_account text default '',
  confirmation_code text default '',
  payment_status_description text default '',
  error_message text default '',
  request_data jsonb,
  response_data jsonb,
  callback_data jsonb,
  ip_address text,
  user_agent text default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz
);

-- ---------- announcements ----------
create table if not exists public.announcements (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  content text not null default '',
  image_url text,
  priority text not null default 'medium',
  is_published boolean not null default true,
  publish_date timestamptz not null default now(),
  expiry_date timestamptz,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------- live ----------
create table if not exists public.live_streams (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  youtube_url text not null,
  youtube_video_id text not null,
  description text not null default '',
  thumbnail_url text,
  status text not null default 'scheduled',
  scheduled_for timestamptz,
  viewer_count integer not null default 0,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.live_chat_messages (
  id uuid primary key default uuid_generate_v4(),
  live_stream_id uuid not null references public.live_streams(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete set null,
  user_name text not null default '',
  message text not null,
  created_at timestamptz not null default now()
);
create index if not exists chat_stream_idx on public.live_chat_messages (live_stream_id, created_at);

-- ---------- bible + hymns (per-user) ----------
create table if not exists public.bible_favorites (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  book text not null,
  chapter integer not null,
  verse integer not null,
  translation text not null default 'sw',
  created_at timestamptz not null default now(),
  unique(user_id, book, chapter, verse, translation)
);

create table if not exists public.bible_highlights (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  book text not null,
  chapter integer not null,
  verse integer not null,
  translation text not null default 'sw',
  color text not null default 'yellow',
  note text default '',
  created_at timestamptz not null default now()
);

create table if not exists public.hymn_favorites (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  hymn_number integer not null,
  created_at timestamptz not null default now(),
  unique(user_id, hymn_number)
);

-- ---------- Row Level Security (simple, usable defaults) ----------
alter table public.profiles enable row level security;
alter table public.sermons enable row level security;
alter table public.events enable row level security;
alter table public.event_registrations enable row level security;
alter table public.prayer_requests enable row level security;
alter table public.prayer_supports enable row level security;
alter table public.prayer_images enable row level security;
alter table public.prayer_comments enable row level security;
alter table public.testimonies enable row level security;
alter table public.testimony_praises enable row level security;
alter table public.givings enable row level security;
alter table public.payment_transactions enable row level security;
alter table public.announcements enable row level security;
alter table public.live_streams enable row level security;
alter table public.live_chat_messages enable row level security;
alter table public.bible_favorites enable row level security;
alter table public.bible_highlights enable row level security;
alter table public.hymn_favorites enable row level security;

-- Public read for published content; authenticated write.
-- (Tighten further per role with custom claims if needed.)

drop policy if exists "public read profiles" on public.profiles;
create policy "public read profiles" on public.profiles for select using (true);
drop policy if exists "users update own profile" on public.profiles;
create policy "users update own profile" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);
drop policy if exists "users insert own profile" on public.profiles;
create policy "users insert own profile" on public.profiles
  for insert with check (auth.uid() = id);

drop policy if exists "read active sermons" on public.sermons;
create policy "read active sermons" on public.sermons
  for select using (is_active = true);
drop policy if exists "auth write sermons" on public.sermons;
create policy "auth write sermons" on public.sermons
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "read published events" on public.events;
create policy "read published events" on public.events
  for select using (is_published = true);
drop policy if exists "auth write events" on public.events;
create policy "auth write events" on public.events
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- Generic authenticated read/write for community content:
-- events regs, prayers (+supports/images/comments), testimonies (+praises),
-- givings, transactions, announcements, live, bible, hymns.
-- (Run the block below once.)

do $$
declare t text;
begin
  foreach t in array array[
    'event_registrations','prayer_requests','prayer_supports','prayer_images',
    'prayer_comments','testimonies','testimony_praises','givings',
    'payment_transactions','announcements','live_streams','live_chat_messages',
    'bible_favorites','bible_highlights','hymn_favorites']
  loop
    execute format('drop policy if exists "auth all %s" on public.%I', t, t);
    execute format(
      'create policy "auth all %s" on public.%I for all using (auth.role() = ''authenticated'') with check (auth.role() = ''authenticated'')',
      t, t);
  end loop;
end $$;

-- Allow anon read on announcements + live streams (public pages)
drop policy if exists "anon read announcements" on public.announcements;
create policy "anon read announcements" on public.announcements
  for select using (is_published = true);
drop policy if exists "anon read live" on public.live_streams;
create policy "anon read live" on public.live_streams for select using (true);

-- ---------- storage buckets ----------
insert into storage.buckets (id, name, public)
values ('profiles','profiles', true),
       ('sermons','sermons', true),
       ('events','events', true),
       ('testimonies','testimonies', true),
       ('prayers','prayers', true),
       ('announcements','announcements', true)
on conflict (id) do nothing;

-- Public read on those buckets; authenticated upload/update/delete.
-- (Add via Dashboard > Storage > Policies if the lines below fail on your plan.)
create policy "public read storage" on storage.objects
  for select using (bucket_id in ('profiles','sermons','events','testimonies','prayers','announcements'));
create policy "auth write storage" on storage.objects
  for all using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');
