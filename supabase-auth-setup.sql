-- Project CREATE authentication setup
-- Run in Supabase Dashboard > SQL Editor > New query.
-- Students get the student role automatically. Never let users choose teacher during signup.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role text not null default 'student' check (role in ('student','teacher','admin')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Users can read own profile" on public.profiles;
create policy "Users can read own profile"
on public.profiles for select to authenticated
using (auth.uid() = id);

-- Profile role changes are intentionally not available to end users.
-- Admins grant teacher access from the SQL Editor only.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    'student'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Teacher access is granted only by an administrator in the SQL Editor:
-- update public.profiles set role = 'teacher' where id = 'AUTH_USER_UUID';
-- Find the UUID in Authentication > Users. Do not expose service-role keys in the website.
