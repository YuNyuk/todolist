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
  daily      boolean not null default false,   -- 매일 하는 일: due_date = 시작일, done = 종결
  created_at timestamptz not null default now()
);
-- 기존 DB에 컬럼 추가 (이미 있으면 무시)
alter table public.todos add column if not exists daily boolean not null default false;

-- 매일 하는 일의 날짜별 체크 기록
create table if not exists public.todo_checks (
  todo_id    uuid not null references public.todos(id) on delete cascade,
  day        date not null,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (todo_id, day)
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

-- 꿀팁 메모장
create table if not exists public.notes (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title      text not null default '',
  body       text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.notes enable row level security;
drop policy if exists "own notes" on public.notes;
create policy "own notes" on public.notes
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

alter table public.todo_checks enable row level security;
drop policy if exists "own checks" on public.todo_checks;
create policy "own checks" on public.todo_checks
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and exists (select 1 from public.todos t where t.id = todo_id and t.user_id = (select auth.uid()))
  );
