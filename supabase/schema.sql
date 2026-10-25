-- Project CREATE production backend schema
-- Run this entire file in Supabase Dashboard > SQL Editor.
-- Student accounts are created through Supabase Auth. Never store passwords in app tables.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  grade_section text not null default '',
  role text not null default 'student' check (role in ('student','teacher','admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.student_progress (
  user_id uuid primary key references auth.users(id) on delete cascade,
  learning_state jsonb not null default '{"xp":0,"done":[],"drafts":{},"checks":{}}'::jsonb,
  quest_progress jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  topic_id text not null,
  score integer not null default 0 check (score >= 0),
  total_questions integer not null default 10 check (total_questions > 0),
  submitted_at timestamptz not null default now()
);

create table if not exists public.workspace_drafts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  topic_id text not null,
  title text not null default 'My ICT PETA',
  content text not null default '',
  updated_at timestamptz not null default now(),
  unique (user_id, topic_id)
);

create index if not exists quiz_attempts_user_submitted_idx
  on public.quiz_attempts (user_id, submitted_at desc);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists student_progress_set_updated_at on public.student_progress;
create trigger student_progress_set_updated_at before update on public.student_progress
for each row execute function public.set_updated_at();

drop trigger if exists workspace_drafts_set_updated_at on public.workspace_drafts;
create trigger workspace_drafts_set_updated_at before update on public.workspace_drafts
for each row execute function public.set_updated_at();

-- Create a student profile automatically for each new Auth account.
-- Role is always forced to 'student'; users cannot grant themselves teacher/admin access.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, grade_section, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(new.raw_user_meta_data ->> 'grade_section', ''),
    'student'
  )
  on conflict (id) do nothing;

  insert into public.student_progress (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Protect role changes, even if a client attempts to update its own profile.
create or replace function public.protect_profile_role()
returns trigger language plpgsql as $$
begin
  if new.role is distinct from old.role then
    raise exception 'Profile roles can only be changed by a trusted administrator.';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_protect_role on public.profiles;
create trigger profiles_protect_role before update on public.profiles
for each row execute function public.protect_profile_role();

alter table public.profiles enable row level security;
alter table public.student_progress enable row level security;
alter table public.quiz_attempts enable row level security;
alter table public.workspace_drafts enable row level security;

drop policy if exists "Students can read own profile" on public.profiles;
create policy "Students can read own profile" on public.profiles
for select to authenticated using (id = (select auth.uid()));

drop policy if exists "Students can update own non-role profile fields" on public.profiles;
create policy "Students can update own non-role profile fields" on public.profiles
for update to authenticated using (id = (select auth.uid()))
with check (id = (select auth.uid()));

drop policy if exists "Students can read own progress" on public.student_progress;
create policy "Students can read own progress" on public.student_progress
for select to authenticated using (user_id = (select auth.uid()));

drop policy if exists "Students can insert own progress" on public.student_progress;
create policy "Students can insert own progress" on public.student_progress
for insert to authenticated with check (user_id = (select auth.uid()));

drop policy if exists "Students can update own progress" on public.student_progress;
create policy "Students can update own progress" on public.student_progress
for update to authenticated using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

drop policy if exists "Students can read own quiz attempts" on public.quiz_attempts;
create policy "Students can read own quiz attempts" on public.quiz_attempts
for select to authenticated using (user_id = (select auth.uid()));

drop policy if exists "Students can insert own quiz attempts" on public.quiz_attempts;
create policy "Students can insert own quiz attempts" on public.quiz_attempts
for insert to authenticated with check (user_id = (select auth.uid()));

drop policy if exists "Students can read own workspace drafts" on public.workspace_drafts;
create policy "Students can read own workspace drafts" on public.workspace_drafts
for select to authenticated using (user_id = (select auth.uid()));

drop policy if exists "Students can insert own workspace drafts" on public.workspace_drafts;
create policy "Students can insert own workspace drafts" on public.workspace_drafts
for insert to authenticated with check (user_id = (select auth.uid()));

drop policy if exists "Students can update own workspace drafts" on public.workspace_drafts;
create policy "Students can update own workspace drafts" on public.workspace_drafts
for update to authenticated using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

-- No public/anonymous policies are created. Use only the Supabase publishable/anon key in the browser.
-- NEVER put the service_role key in frontend code or GitHub.
