-- Supabase 대시보드 → SQL Editor → New query 에 전체 붙여넣고 Run

-- 프로젝트
create table if not exists public.projects (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name       text not null,
  color      text not null default '#2f5bea',
  sort_order integer not null default 0,   -- 왼쪽 메뉴 표시 순서 (드래그&드롭)
  created_at timestamptz not null default now()
);
-- 기존 DB에 컬럼 추가 (이미 있으면 무시)
alter table public.projects add column if not exists sort_order integer not null default 0;

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
alter table public.todos add column if not exists daily boolean not null default false;   -- (예전 '매일' 표시, 이제 repeat_unit 사용)

-- 반복: repeat_unit = day/week/month (null이면 반복 아님), repeat_every = X일/주/개월마다
--       repeat_count = 반복 횟수, repeat_until = 종료 날짜 (둘 다 null이면 계속 반복)
alter table public.todos add column if not exists repeat_unit  text check (repeat_unit in ('day', 'week', 'month'));
alter table public.todos add column if not exists repeat_every integer not null default 1 check (repeat_every between 1 and 365);
alter table public.todos add column if not exists repeat_count integer check (repeat_count between 1 and 999);
alter table public.todos add column if not exists repeat_until date;
-- 놓친 반복(체크 못 하고 지나간 반복 날짜)을 '밀린 일'에 표시할지
alter table public.todos add column if not exists repeat_carry boolean not null default true;
-- 예전 '매일 하는 일'을 '1일마다 반복'으로 옮기기
update public.todos set repeat_unit = 'day', repeat_every = 1, daily = false where daily and repeat_unit is null;

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

-- 반복하는 일의 날짜별 '한 일' 메모
create table if not exists public.todo_day_notes (
  todo_id    uuid not null references public.todos(id) on delete cascade,
  day        date not null,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  note       text not null default '',
  updated_at timestamptz not null default now(),
  primary key (todo_id, day)
);
alter table public.todo_day_notes enable row level security;
drop policy if exists "own day notes" on public.todo_day_notes;
create policy "own day notes" on public.todo_day_notes
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and exists (select 1 from public.todos t where t.id = todo_id and t.user_id = (select auth.uid()))
  );

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
