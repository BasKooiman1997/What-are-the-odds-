-- =============================================
-- WHAT ARE THE ODDS — Supabase Schema
-- Voer dit uit in de Supabase SQL Editor
-- =============================================

-- 1. PROFILES (uitgebreide gebruikersinfo)
create table profiles (
  id uuid references auth.users on delete cascade primary key,
  username text not null unique,
  avatar_color text default 'av-yellow',
  created_at timestamp with time zone default now(),
  opdracht_uitgevoerd boolean default null  -- null = nog niet ingevuld, true = uitgevoerd, false = geweigerd
);

-- RLS aan voor profiles
alter table profiles enable row level security;
create policy "Profielen zijn voor iedereen leesbaar" on profiles for select using (true);
create policy "Gebruikers kunnen eigen profiel aanmaken" on profiles for insert with check (auth.uid() = id);
create policy "Gebruikers kunnen eigen profiel bijwerken" on profiles for update using (auth.uid() = id);

-- 2. GROUPS
create table groups (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  invite_code text not null unique,
  created_by uuid references profiles(id),
  created_at timestamp with time zone default now(),
  opdracht_uitgevoerd boolean default null  -- null = nog niet ingevuld, true = uitgevoerd, false = geweigerd
);

alter table groups enable row level security;
-- SELECT: leesbaar voor iedereen (nodig voor invite_code lookup bij aansluiten)
create policy "Groepen zijn voor iedereen leesbaar" on groups for select using (true);
-- INSERT: ingelogde gebruiker mag groepen aanmaken
create policy "Ingelogde gebruikers kunnen groepen aanmaken" on groups for insert with check (auth.uid() is not null);

-- 3. GROUP MEMBERS
create table group_members (
  group_id uuid references groups(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  joined_at timestamp with time zone default now(),
  primary key (group_id, user_id)
);

alter table group_members enable row level security;
create policy "Leden kunnen lid zijn" on group_members for select using (true);
create policy "Gebruikers kunnen zichzelf toevoegen" on group_members for insert with check (auth.uid() = user_id);

-- 4. GAMES
create table games (
  id uuid default gen_random_uuid() primary key,
  group_id uuid references groups(id) on delete cascade,
  challenger_id uuid references profiles(id),
  challenged_id uuid references profiles(id),
  opdracht text not null,
  odds integer not null,
  mode text default 'manual', -- 'manual' of 'random'
  challenger_num integer,
  challenged_num integer,
  winner_id uuid references profiles(id),
  loser_id uuid references profiles(id),
  created_at timestamp with time zone default now(),
  opdracht_uitgevoerd boolean default null  -- null = nog niet ingevuld, true = uitgevoerd, false = geweigerd
);

alter table games enable row level security;
create policy "Games leesbaar door groepsleden" on games for select
  using (exists (select 1 from group_members where group_id = games.group_id and user_id = auth.uid()));
create policy "Groepsleden kunnen games aanmaken" on games for insert
  with check (exists (select 1 from group_members where group_id = games.group_id and user_id = auth.uid()));
create policy "Deelnemers kunnen games bijwerken" on games for update
  using (auth.uid() in (challenger_id, challenged_id));

-- =============================================
-- KLAAR! Je database is geconfigureerd.
-- =============================================

-- =============================================
-- UPDATE (voeg toe als je de tabel al hebt)
-- =============================================
-- alter table games add column if not exists opdracht_uitgevoerd boolean default null;
