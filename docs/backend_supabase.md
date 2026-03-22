# Supabase backend — MVP schema, RLS, and Flutter contracts

**Audience:** backend implementers, Flutter repository authors, security review.  
**Aligned with:** `product.md`, `rules.md`, `system_design.md`, `INTEGRATIONS_AND_SETUP.md`.

---

## 1. Protected foundational decisions (do not change without explicit approval)

| Decision | Rationale |
|----------|-----------|
| **Supabase** as Auth + Postgres + Storage + Realtime + Edge Functions | Locked in `system_design.md`. |
| **Multi-tenant isolation via `school_id`** on tenant-scoped rows | Product requirement; all app queries must be tenant-scoped. |
| **RLS as the isolation mechanism** for client access (anon key + user JWT) | Service role bypasses RLS — use only in Edge Functions / trusted jobs. |
| **Data flow:** UI → Provider → Repository → Supabase | Flutter agents must not bypass repositories for cross-cutting concerns. |

**JWT rule:** The client never proves tenancy by sending a bare `school_id` alone. Membership and role are enforced in Postgres (policies + FKs), optionally mirrored in JWT claims for convenience, not as the sole source of truth.

---

## 2. Multi-tenant model

**Tenant = one school row** (`schools`). All pupil/staff/parent operational data references `school_id` (UUID).

**User can belong to multiple schools** (e.g. parent with children in two schools, or consultant). MVP still uses a **single active school context** in the app: `current_school_id` chosen after login (stored client-side, validated server-side on every request via RLS).

**Isolation checklist (every tenant table):**

- Column `school_id uuid not null references schools(id) on delete restrict`
- Index on `(school_id)` or `(school_id, <common filter>)` for list queries
- RLS: `USING` / `WITH CHECK` predicates that tie the row to **membership** in that school

---

## 3. Auth → profile → membership → role

### 3.1 Identity

- **Supabase Auth** (`auth.users`) is the only identity store for login.
- **`profiles`** (or extend `auth.users` via trigger): `id uuid primary key references auth.users(id)`, `full_name`, `avatar_url`, `created_at`, `updated_at`. No `school_id` on profile alone — tenancy lives in membership.

### 3.2 Membership and roles

**`school_users`** (authoritative for “who can access this school”):

| Column | Type | Notes |
|--------|------|--------|
| `id` | uuid PK | |
| `school_id` | uuid FK → schools | |
| `user_id` | uuid FK → profiles / auth.users | |
| `role` | text or enum | `admin`, `teacher`, `parent` |
| `created_at` | timestamptz | |
| **Unique** | `(school_id, user_id)` | One role per school per user for MVP |

**MVP rule:** If product later needs “teacher + parent” in the same school, model as **two rows** with different `role` values or add a `roles[]` column in a later migration — avoid premature complexity; start with **one role per (school, user)**.

### 3.3 Optional JWT helper

For fewer joins in RLS, an **Auth Hook** or login trigger can set `app_metadata` / custom JWT claims, e.g.:

- `school_ids`: uuid[] (optional)
- `active_school_id`: uuid (optional; must still match `school_users`)

**Postgres remains authoritative:** policies must still resolve access from `school_users` (or a `SECURITY DEFINER` helper that reads it) so token tampering does not grant cross-tenant access.

---

## 4. Core tables (MVP-oriented)

Order reflects **dependencies**, not final naming — keep names stable once Flutter models exist.

### 4.1 Platform / billing (minimal)

- **`schools`**: `id`, `name`, `slug` (unique), `created_at`, billing fields as needed later (`stripe_customer_id`, subscription status) — align with Stripe Edge Function updates per `INTEGRATIONS_AND_SETUP.md`.

### 4.2 People (within a school)

- **`students`**: `id`, `school_id`, `first_name`, `last_name`, `external_ref` (optional), `created_at`, …
- **`classes`** (or `sections`): `id`, `school_id`, `name`, `grade_level` (optional), …
- **`enrollments`**: `student_id`, `class_id`, `school_id` (denormalized for RLS simplicity), `academic_year` or date range — **enforce** `student.school_id = class.school_id` via trigger or composite FK pattern.

**Parent ↔ student linkage:**

- **`student_guardians`**: `school_id`, `student_id`, `guardian_user_id` (FK to user), `relationship` (optional), unique `(school_id, student_id, guardian_user_id)`.

Teachers:

- **`class_teachers`** (or role on `school_users` only): if teachers are assigned per class, `class_id`, `teacher_user_id`, `school_id`.

### 4.3 Features

- **Attendance:** `attendance_records` — `school_id`, `student_id`, `class_id` (or session), `date`, `status` (enum), `recorded_by_user_id`, `created_at`. Indexes for “by class + date”.
- **Grades:** `grade_items` / `assessments` + `grades` or a single denormalized table for MVP — always `school_id`; tie to `student_id` and optionally `class_id`.
- **Fees:** `fee_definitions`, `fee_charges` / `invoices` with `school_id`, `student_id`, `amount`, `status`, Stripe ids if parent payment — **writes** for payment status may be Edge Function + service role only.
- **Messaging:** `message_threads` (`school_id`, subject, `created_at`), `thread_participants` (`thread_id`, `user_id`, `school_id`), `messages` (`thread_id`, `school_id`, `sender_id`, `body`, `created_at`). Enable Realtime on these tables after RLS is correct.

### 4.4 Device / push

- **`device_tokens`**: `user_id`, `school_id` (optional if token is global), `token`, `platform`, `updated_at` — RLS so users only upsert their own rows.

---

## 5. Row Level Security (RLS) strategy

### 5.1 Enable RLS on all tenant tables

Default **deny**; then explicit policies per operation.

### 5.2 Helper functions (recommended)

Define **STABLE** functions marked `SECURITY DEFINER` that read `school_users` using `auth.uid()`:

- `current_user_school_ids()` → set of school ids the user belongs to
- `user_role_in_school(_school_id uuid)` → role or null
- Optionally `user_can_access_school(_school_id uuid)` → boolean

Implement once; reference in policies to avoid copy-paste bugs.

### 5.3 Policy patterns (sketch)

**SELECT:** row is visible if `school_id` is in `current_user_school_ids()` **and** role-specific rules hold (e.g. parent only sees students linked in `student_guardians`).

**INSERT / UPDATE / DELETE:**

- **Admin:** full CRUD within `school_id` (or scoped to non-billing tables per product).
- **Teacher:** CRUD on attendance/grades for **their** classes (join `class_teachers`); read students in those classes.
- **Parent:** read-only on their children’s attendance/grades/messages; insert messages only in threads they participate in.

**WITH CHECK** on insert/update must mirror **USING** so users cannot move rows across schools.

### 5.4 Testing requirement

Test policies with **three real users** (admin, teacher, parent) and JWT from Supabase — never rely on service role for app behavior.

---

## 6. Storage buckets and boundaries

| Bucket (example) | Path convention | RLS / policy idea |
|--------------------|-----------------|-------------------|
| `school-assets` | `{school_id}/...` | Read/write only if user is member of `school_id`; admin may upload school logo |
| `message-attachments` | `{school_id}/{thread_id}/...` | Participant-only |

**Rules:**

- **No service role in Flutter.** Uploads use user JWT; policies validate path prefix matches allowed `school_id`.
- Virus scanning / MIME checks: defer to post-MVP unless required; at minimum restrict extensions and size in app + bucket policy.

---

## 7. Edge Functions — when to use

| Responsibility | Why not client-only |
|----------------|---------------------|
| Stripe webhooks, subscription sync | Secret keys, signature verification |
| Creating Stripe Checkout / Portal sessions | Secret key |
| Fee payment confirmation webhooks | Same |
| Optional: invite emails, heavy PDF generation | Secrets + rate limits |

**Idempotency:** Stripe handlers must be safe to retry (unique constraints on event ids).

---

## 8. Flutter repository contracts

### 8.1 Conventions

- **Every query** that touches tenant data: filter by `school_id` **and** rely on RLS (defense in depth).
- **Models:** one Dart model per table (per `rules.md`); map snake_case columns ↔ Dart fields consistently.
- **Inserts:** include `school_id` from **app state** (current school), not from user-typed input without validation.

### 8.2 Repository method shapes (illustrative)

```dart
// Pseudocode — actual types from generated models
Future<List<Student>> listStudents({required String schoolId});
Future<void> recordAttendance({required String schoolId, required AttendanceDto dto});
Stream<List<Message>> watchThreadMessages({required String schoolId, required String threadId});
```

**Realtime:** subscribe after auth; handle reconnection; scope channels by `school_id` + resource id.

### 8.3 Errors

Map Postgres / PostgREST errors to user-safe messages; never expose raw SQL or internal ids unnecessarily in logs sent to clients.

---

## 9. Migration order (recommended)

1. Extensions if needed (`uuid-ossp` or `pgcrypto` — Supabase defaults often suffice).
2. `schools`
3. `profiles` + trigger from `auth.users` → profile row
4. `school_users` + RLS + helper functions
5. People: `students`, `classes`, `enrollments`, `student_guardians`, `class_teachers`
6. Feature tables: attendance → grades → fees (minimal) → messaging
7. `device_tokens`
8. Storage buckets + policies
9. Realtime publication for messaging (and others as needed)
10. Stripe-related columns on `schools` / `subscriptions` + Edge Functions (can be parallel track)

**Rule:** add new tenant tables only **after** `school_users` and helpers exist so policies stay consistent.

---

## 10. Cross-agent impact flags

| Change | Who is affected |
|--------|-------------------|
| Renaming `school_users` or `role` enum values | Flutter auth routing, all repositories, seed data |
| Adding a second role dimension (e.g. staff vs teacher) | RLS policies, UI role checks |
| Splitting “current school” vs multi-school UX | Session provider, all list queries |
| Fee payment moving in-app | Stripe + Edge Functions + possibly PCI scope |
| Messaging schema (thread vs channel) | Realtime subscriptions, notifications |

---

## 11. Out of scope for MVP (avoid)

- Per-tenant Postgres schemas or separate databases per school
- Complex ABAC beyond admin/teacher/parent
- Full audit log tables (add later if compliance requires)
- Soft-delete everywhere (add only where product needs undo)

---

## 12. Document maintenance

Update this file when schema or RLS patterns change; keep `INTEGRATIONS_AND_SETUP.md` in sync for third-party steps (Stripe, Supabase push).
