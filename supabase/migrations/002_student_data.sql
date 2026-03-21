-- Student data: students, attendance, grade_items, announcements, classes + RLS
-- SELECT policies: school_id in (select public.user_school_ids()) — same pattern as 001_baseline.sql

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  display_name text,
  homeroom_label text,
  created_at timestamptz not null default now()
);

create index if not exists students_school_id_idx on public.students (school_id);

create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  student_id uuid not null references public.students (id) on delete cascade,
  date date not null,
  status text not null check (status in ('present', 'absent', 'excused')),
  created_at timestamptz not null default now()
);

create index if not exists attendance_school_id_idx on public.attendance (school_id);
create index if not exists attendance_student_id_idx on public.attendance (student_id);

create table if not exists public.grade_items (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  student_id uuid not null references public.students (id) on delete cascade,
  teacher_id uuid not null references public.profiles (id) on delete restrict,
  course_label text,
  assignment_label text,
  score_label text,
  created_at timestamptz not null default now()
);

create index if not exists grade_items_school_id_idx on public.grade_items (school_id);
create index if not exists grade_items_student_id_idx on public.grade_items (student_id);
create index if not exists grade_items_teacher_id_idx on public.grade_items (teacher_id);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  title text,
  body text,
  posted_at timestamptz not null default now()
);

create index if not exists announcements_school_id_idx on public.announcements (school_id);

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  label text,
  teacher_id uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default now()
);

create index if not exists classes_school_id_idx on public.classes (school_id);
create index if not exists classes_teacher_id_idx on public.classes (teacher_id);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.students enable row level security;
alter table public.attendance enable row level security;
alter table public.grade_items enable row level security;
alter table public.announcements enable row level security;
alter table public.classes enable row level security;

-- ---------------------------------------------------------------------------
-- Policies — tenant isolation via user_school_ids()
-- ---------------------------------------------------------------------------

create policy students_select_same_tenant
  on public.students
  for select
  to authenticated
  using (school_id in (select public.user_school_ids ()));

create policy attendance_select_same_tenant
  on public.attendance
  for select
  to authenticated
  using (school_id in (select public.user_school_ids ()));

create policy grade_items_select_same_tenant
  on public.grade_items
  for select
  to authenticated
  using (school_id in (select public.user_school_ids ()));

create policy announcements_select_same_tenant
  on public.announcements
  for select
  to authenticated
  using (school_id in (select public.user_school_ids ()));

create policy classes_select_same_tenant
  on public.classes
  for select
  to authenticated
  using (school_id in (select public.user_school_ids ()));
