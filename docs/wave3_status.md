# Wave 3 — status checklist

**Wave:** [wave3_delegation.md](wave3_delegation.md) (product Phases 2–4).  
**Last reviewed:** 2026-03-20 (code + migrations vs this doc).

Use this as a **living** tracker; owners are typical agent roles from [team_task_board.md](team_task_board.md).

---

## Phase 2 — Students (directory, CRUD, minimal enrollment)

| Item | Status | Notes |
|------|--------|--------|
| Baseline + tenant tables (`001`) | [x] | `schools`, `profiles`, `school_members`, RLS, `get_my_school_id`, bootstrap RPC |
| Student table + read RLS (`002`) | [x] | `students` + SELECT by tenant |
| Admin student writes + `add_student` RPC (`003`) | [x] | Admin INSERT/UPDATE/DELETE + RPC |
| Flutter: admin list / add / delete | [x] | [`students_repository`](../schoolify_app/lib/features/students/data/students_repository.dart), [`StudentsListScreen`](../schoolify_app/lib/features/students/presentation/students_list_screen.dart) |
| Flutter: teacher read-only roster | [x] | [`teacher_students_repository`](../schoolify_app/lib/features/teacher/data/teacher_students_repository.dart) |
| Student **edit** (update display/homeroom) | [ ] | Not in [`StudentsRepository`](../schoolify_app/lib/features/students/data/students_repository.dart) API — optional MVP gap |
| **Enrollment** (class ↔ student) | [ ] | No enrollment table; `classes` in `002` without student↔class link |
| Auth: `schoolId` + role for repositories | [x] | [`auth_repository`](../schoolify_app/lib/core/auth/data/auth_repository.dart) |

---

## Phase 3 — Attendance (date-only, idempotent marks, history/summary)

| Item | Status | Notes |
|------|--------|--------|
| Schema: `attendance` (`002`) | [x] | Base table; status constraint superseded by `005` |
| RLS: **SELECT** on `attendance` | [x] | Tenant-scoped (`002`) |
| Unique + `upsert_attendance_mark` RPC (`004`) | [x] | [`004_attendance_writes.sql`](../supabase/migrations/004_attendance_writes.sql) — unique `(school_id, student_id, date)`, RPC (present/absent/excused initially) |
| Status `present` / `absent` / `late` (`005`) | [x] | [`005_attendance_late_status.sql`](../supabase/migrations/005_attendance_late_status.sql) — migrates `excused`→`late`, updates RPC |
| Flutter: `upsertMark` + RPC params | [x] | [`teacher_attendance_repository`](../schoolify_app/lib/features/teacher/data/teacher_attendance_repository.dart) → `upsert_attendance_mark` |
| Flutter: mark flow (teacher) | [x] | [`MarkAttendanceScreen`](../schoolify_app/lib/features/teacher/presentation/mark_attendance_screen.dart), route under `/teacher/attendance/mark/:classId` in [`router.dart`](../schoolify_app/lib/app/router.dart) |
| List refresh after save | [x] | Invalidate `teacherAttendanceProvider` on save (verify in mark screen) |
| Parent attendance labels vs DB | [x] | `late` mapped in [`parent_attendance_repository`](../schoolify_app/lib/features/parent/data/parent_attendance_repository.dart) |
| Monthly summary / calendar UX | [ ] | Partial: dashboards use reads; no dedicated “month view” product slice |

**Phase 3 delegation doc:** [wave3_phase3_attendance_delegation.md](wave3_phase3_attendance_delegation.md) — **implementation matches intent** (update that doc’s header to “Completed” when auditing docs only).

---

## Phase 4 — Parent (shell, summary/history, isolation)

| Item | Status | Notes |
|------|--------|--------|
| Parent shell + routes + bottom nav | [x] | [`router.dart`](../schoolify_app/lib/app/router.dart), `ParentShell` |
| Read attendance / dashboard (stub path) | [x] | Repos + screens; **see gap below** |
| **Parent↔student linkage** (RLS + schema) | [ ] | **Not implemented** — repos use **first student in school** (`.limit(1)`), insecure for multi-child & wrong semantically |
| **RLS: parent-scoped reads** | [ ] | Blocked until linkage table + policies — see [wave3_phase4_parent_delegation.md](wave3_phase4_parent_delegation.md) |
| Child switcher + selected `student_id` | [ ] | Depends on linkage + providers |

**Phase 4 delegation:** [wave3_phase4_parent_delegation.md](wave3_phase4_parent_delegation.md).

---

## Cross-cutting

| Item | Status |
|------|--------|
| `flutter analyze` clean on [`schoolify_app/`](../schoolify_app/) | [ ] | Run locally in CI; not verified in this review |
| Supabase migrations `001` → `005` in order | [ ] | Confirm on target project |
| No `service_role` in Flutter ([INTEGRATIONS_AND_SETUP.md](INTEGRATIONS_AND_SETUP.md)) | [x] | By design |

---

## Gaps / risks before Phase 4 execution

1. **Linkage** — Must replace “first student in tenant” with **explicit parent↔student** rows and RLS; highest priority for Phase 4.  
2. **Product** — Confirm whether one parent account can have children in **multiple schools** (affects `get_my_school_id` + UX).  
3. **Monthly attendance report** — Still optional / partial; can ship Phase 4 without full calendar if product agrees.

---

## Next priority (Lead)

1. **Phase 4** — [wave3_phase4_parent_delegation.md](wave3_phase4_parent_delegation.md) (linkage migration → auth → parent UI).  
2. Optional: student **edit** API + UI; **enrollment** table when requirements lock.  
3. Close **monthly summary** slice when Phase 3 polish is scheduled.
