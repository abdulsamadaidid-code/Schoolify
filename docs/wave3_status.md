# Wave 3 — status checklist

**Wave:** [Wave 3 delegation](wave3_delegation.md) (product Phases 2–4).  
**Last reviewed:** update this line when you change status.

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
| Student **edit** (update display/homeroom) | [ ] | Optional MVP gap |
| **Enrollment** (class ↔ student) | [ ] | Not in schema yet; defer or add migration |
| Auth: `schoolId` + role for repositories | [x] | [`auth_repository`](../schoolify_app/lib/core/auth/data/auth_repository.dart) |

---

## Phase 3 — Attendance (date-only, idempotent marks, history/summary)

| Item | Status | Notes |
|------|--------|--------|
| Schema: `attendance` (`002`) | [x] | `date`, `status` ∈ present/absent/excused, `school_id`, `student_id` |
| RLS: **SELECT** on `attendance` | [x] | Tenant-scoped (`002`) |
| RLS: **INSERT/UPDATE** (or RPC) for marks | [ ] | **Blocking** for real marking — see [wave3_phase3_attendance_delegation.md](wave3_phase3_attendance_delegation.md) |
| DB: idempotency **unique (school_id, student_id, date)** | [ ] | Recommended before/at same time as writes |
| Flutter: mark attendance flow (teacher/admin) | [ ] | Today [`TeacherAttendanceScreen`](../schoolify_app/lib/features/teacher/presentation/teacher_attendance_screen.dart) is **read-only** class list |
| Flutter: repository `upsert` / mark APIs | [ ] | Wire to Supabase after migration |
| Monthly summary / history (product) | [ ] | Partial reads exist; finalize UX + queries |

---

## Phase 4 — Parent (shell, summary/history, isolation)

| Item | Status | Notes |
|------|--------|--------|
| Parent shell + routes | [x] | [`router.dart`](../schoolify_app/lib/app/router.dart), parent screens |
| Read attendance for parent | [x] | [`parent_attendance_repository`](../schoolify_app/lib/features/parent/data/parent_attendance_repository.dart) (depends on data + RLS) |
| Parent ↔ student linkage (if multi-child) | [ ] | Schema/policy TBD |
| RLS: parent-only reads | [ ] | Align policies when linkage exists |

---

## Cross-cutting

| Item | Status |
|------|--------|
| `flutter analyze` clean on [`schoolify_app/`](../schoolify_app/) | [ ] |
| Supabase migrations applied in order (`001` → `002` → `003` → …) | [ ] |
| No `service_role` in Flutter ([INTEGRATIONS_AND_SETUP.md](INTEGRATIONS_AND_SETUP.md)) | [x] |

---

## Next priority (Lead)

1. **Phase 3 — attendance writes + mark flow** — [wave3_phase3_attendance_delegation.md](wave3_phase3_attendance_delegation.md)  
2. Enrollment + parent linkage when product locks requirements  
3. Optional: student edit, grades write path (post-MVP scope)
