-- 9jaGrade CBT database
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default 'Student',
  role text not null default 'student' check (role in ('student','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.cbts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  duration_minutes integer not null default 30 check (duration_minutes > 0),
  pass_mark integer not null default 50 check (pass_mark between 0 and 100),
  access_code text not null unique,
  published boolean not null default false,
  shuffle_questions boolean not null default false,
  shuffle_options boolean not null default false,
  show_result boolean not null default true,
  show_leaderboard boolean not null default true,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.questions (
  id uuid primary key default gen_random_uuid(),
  cbt_id uuid not null references public.cbts(id) on delete cascade,
  position integer not null default 1,
  question text not null,
  option_a text not null,
  option_b text not null,
  option_c text not null,
  option_d text not null,
  correct_answer text not null check (correct_answer in ('A','B','C','D')),
  created_at timestamptz not null default now()
);

create table if not exists public.attempts (
  id uuid primary key default gen_random_uuid(),
  cbt_id uuid not null references public.cbts(id) on delete cascade,
  student_id uuid not null references auth.users(id) on delete cascade,
  score integer not null,
  total_questions integer not null,
  percentage integer not null,
  time_used_seconds integer not null default 0,
  submitted_at timestamptz not null default now()
);

create table if not exists public.answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.attempts(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  selected_answer text check (selected_answer in ('A','B','C','D') or selected_answer is null),
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id,full_name) values (new.id, coalesce(new.raw_user_meta_data->>'full_name','Student'));
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.is_admin()
returns boolean language sql security definer set search_path=public stable as $$
  select exists(select 1 from public.profiles where id=auth.uid() and role='admin');
$$;

alter table public.profiles enable row level security;
alter table public.cbts enable row level security;
alter table public.questions enable row level security;
alter table public.attempts enable row level security;
alter table public.answers enable row level security;

drop policy if exists "profiles own read" on public.profiles;
create policy "profiles own read" on public.profiles for select using (id=auth.uid() or public.is_admin());

drop policy if exists "admin all cbts" on public.cbts;
create policy "admin all cbts" on public.cbts for all using (public.is_admin()) with check (public.is_admin());
drop policy if exists "students read published cbts" on public.cbts;
create policy "students read published cbts" on public.cbts for select using (published=true or public.is_admin());

drop policy if exists "admin all questions" on public.questions;
create policy "admin all questions" on public.questions for all using (public.is_admin()) with check (public.is_admin());
drop policy if exists "students read published questions" on public.questions;
create policy "students read published questions" on public.questions for select using (
  exists(select 1 from public.cbts c where c.id=cbt_id and c.published=true)
);

drop policy if exists "students own attempts" on public.attempts;
create policy "students own attempts" on public.attempts for select using (student_id=auth.uid() or public.is_admin());
drop policy if exists "students create own attempts" on public.attempts;
create policy "students create own attempts" on public.attempts for insert with check (student_id=auth.uid());
drop policy if exists "admin attempts" on public.attempts;
create policy "admin attempts" on public.attempts for all using (public.is_admin()) with check (public.is_admin());

drop policy if exists "students own answers" on public.answers;
create policy "students own answers" on public.answers for select using (
  exists(select 1 from public.attempts a where a.id=attempt_id and (a.student_id=auth.uid() or public.is_admin()))
);
drop policy if exists "students create answers" on public.answers;
create policy "students create answers" on public.answers for insert with check (
  exists(select 1 from public.attempts a where a.id=attempt_id and a.student_id=auth.uid())
);
drop policy if exists "admin answers" on public.answers;
create policy "admin answers" on public.answers for all using (public.is_admin()) with check (public.is_admin());

create or replace view public.leaderboard as
select a.id as attempt_id,a.cbt_id,a.student_id,p.full_name,a.score,a.total_questions,a.percentage,a.time_used_seconds,a.submitted_at
from public.attempts a join public.profiles p on p.id=a.student_id;

grant select on public.leaderboard to authenticated;

-- After creating your first account, promote yourself:
-- update public.profiles set role='admin' where id='YOUR_AUTH_USER_UUID';
