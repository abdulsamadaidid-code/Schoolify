# Agent note — Attendance status: `excused` → `late`

**Date:** 2026-03-21
**Affects:** DB Agent, Teacher/Attendance Agent, Parent Agent

---

## What changed

The attendance `status` field no longer uses `'excused'`. It now uses `'late'` to record late arrivals.

| Before | After |
|--------|-------|
| `present` / `absent` / `excused` | `present` / `absent` / `late` |

---

## DB Agent

- `005_attendance_writes.sql` applied — drops old `attendance_status_check` and adds new one with `'late'`
- `upsert_attendance_mark` RPC updated to validate `'late'` instead of `'excused'`
- Any existing `'excused'` rows in dev were migrated to `'late'`
- **If you add any future migrations referencing attendance status, use `present/absent/late`**

---

## Teacher/Attendance Agent

- `mark_attendance_screen.dart` — chip label changed from `E` → `L`, value from `'excused'` → `'late'`
- `teacher_attendance_repository.dart` — doc comment updated
- `teacherAttendanceProvider` is now invalidated after save so the class list refreshes to "Marked"
- **If you add any attendance filtering or display logic, map `'late'` not `'excused'`**

---

## Parent Agent

- `parent_attendance_repository.dart` reads `status` from the DB — if you display status labels to parents, map `'late'` → `'Late'` (not `'Excused'`)
- The `AttendanceDay.statusLabel` in `core/models/attendance_day.dart` may need updating if it hardcodes `'Excused'`
