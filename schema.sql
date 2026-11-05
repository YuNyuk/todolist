-- Supabase 대시보드 → SQL Editor → New query 에 전체 붙여넣고 Run

-- 프로젝트
create table if not exists public.projects (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name       text not null,
  color      text not null default '#2f5bea',
  created_at timestamptz not null default now()
);

-- 할 일
create table if not exists public.todos (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  project_id uuid references public.projects(id) on delete set null,
  title      text not null,
  memo       text not null default '',
  due_date   date,
  done       boolean not null default false,
  done_at    timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists todos_user_due_idx  on public.todos (user_id, due_date);
create index if not exists todos_user_done_idx on public.todos (user_id, done, done_at desc);

-- 행 단위 보안(RLS): 로그인한 본인 데이터만 읽고 쓰기
alter table public.projects enable row level security;
alter table public.todos    enable row level security;

drop policy if exists "own projects" on public.projects;
create policy "own projects" on public.projects
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists "own todos" on public.todos;
create policy "own todos" on public.todos
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
