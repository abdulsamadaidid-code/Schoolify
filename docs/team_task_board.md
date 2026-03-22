# Team task board (School Management SaaS)

**Role:** Lead Engineer orchestration artifact.  
**Quick handover (LLMs / new contributors):** [Project_Overview.md](Project_Overview.md).  
**Authoritative context:** [system_design.md](system_design.md), [product.md](product.md), [branding.md](branding.md), [rules.md](rules.md), [INTEGRATIONS_AND_SETUP.md](INTEGRATIONS_AND_SETUP.md).  
**Stitch UI:** Reference only under `Stitch UI/` — layout/UX guidance; do not copy export code.

**Canonical Flutter root:** **`schoolify_app/`** — one `pubspec.yaml` / package name `schoolify_app`. Do not reintroduce a parallel `app/` tree.

### Program status (waves)

| Wave | Scope (product) | Status |
|------|-----------------|--------|
| **Wave 1** | Foundations (platform, baseline DB, design system, auth/tenancy) | **Done** |
| **Wave 2** | Phase 1 — dashboard shell + KPI/schedule (mock or minimal real read) | **Done** |
| **Wave 3** | Phase 2–4 — students → attendance → parent mobile | **Done** |
| **Wave 4** | Grades writes, announcements E2E, admin user management | **Done** |
| **Wave 5** | Messaging + OneSignal push notifications via Edge Functions; fees deferred | **In progress** |

**Wave 2 orchestration (archived):** [wave2_delegation.md](wave2_delegation.md) — **completed.**  
**Wave 3 orchestration (archived):** [wave3_delegation.md](wave3_delegation.md).  
**Wave 5 plan (active):** [wave5_plan.md](wave5_plan.md).

---

## Protected foundations (single owner per area; merge carefully)

| Foundation | Owner agent | Notes |
|------------|-------------|--------|
| App shell, routing, `ProviderScope` | Platform / App | `lib/app/` — one PR at a time for router + global providers. |
| Design tokens + theme + shared UI primitives | Design system | [branding.md](branding.md) → `lib/core/design_system`, `lib/core/theme`, `lib/core/ui`. |
| Supabase client init + env (anon key only in app) | Platform + Auth | Never ship `service_role` in Flutter per integrations doc. |
| Schema + RLS baseline | Supabase / DB | `schools`, `profiles`, `school_members` first; every tenant table has `school_id`. |
| Auth + tenant context (`school_id`, `role`) | Auth & tenancy | Single source of truth for repositories; no duplicate “current school” logic. |

**Rule:** Downstream features consume these contracts; they do not redefine architecture ([system_design.md](system_design.md)).

---

## Agent roster

| Agent | Responsibility |
|-------|----------------|
| **Platform / Flutter** | `pubspec`, `main.dart`, analysis_options, folder skeleton, CI smoke. |
| **Design system** | Tokens, `ThemeData`, shared buttons/cards/inputs/shells. |
| **Supabase / DB** | `supabase/migrations`, RLS, indexes, dev seed SQL. |
| **Auth & tenancy** | Sign-in/out, profile, membership → `school_id` + role, route guards. |
| **Feature: Dashboard** | Phase 1 dashboard (mock or minimal real read). |
| **Feature: Students** | Phase 2 — list, CRUD, enrollment (after foundation). |
| **Feature: Attendance** | Phase 3 — date-only sessions, P/A/L, counts + history. |
| **Feature: Parent** | Phase 4 — mobile shell, summary/history, tenant isolation. |
| **Stitch / UX** | Optional alignment pass vs branding; no production code from exports. |

---

## Parallel-safe workstreams

**Safe in parallel** once naming/contracts are agreed (short written note in PR):

- Platform: Flutter scaffold + feature folders.
- Supabase: Migration v1 for identity/tenant tables + RLS.
- Design system: theme + tokens (after `lib/` exists, or immediately after Platform lands).

**Avoid parallel edits** on the same file: `pubspec.yaml`, `main.dart`, single migration file — serialize or split ownership.

---

## Blocked workstreams

| Workstream | Blocked until |
|------------|----------------|
| Student CRUD / enrollment | Auth + tenant context + student/class tables + RLS |
| Attendance | Enrollments + attendance tables + RLS |
| Parent mobile | Guardian linkage + parent read policies |
| Payments (Stripe + local method) | Product and integration decision before implementation |

---

## Recommended execution order (waves)

### Wave 0 — Lead / orchestrator

- Confirm MVP tenant bootstrap (e.g. admin creates school + adds members; invites later).
- File ownership: who merges `lib/app/router`, `supabase/migrations`, `lib/core/theme`.

### Wave 1 — Foundations (sequential priority)

1. **Platform:** Flutter app + feature-based `lib/` per [rules.md](rules.md).  
   **Acceptance:** `flutter analyze` clean; runs on web + one mobile target.

2. **Supabase:** Baseline migration — `schools`, `profiles`, `school_members` + RLS.  
   **Acceptance:** Authenticated user sees only tenant-scoped rows per policy.

3. **Design system:** Wire `ThemeData` to [branding.md](branding.md).  
   **Acceptance:** Demo route shows tokens (light/dark if in scope).

4. **Auth & tenancy:** Session + profile + `school_id` / `role` + guarded routes.  
   **Acceptance:** Stub routes differ by role; no queries without tenant context.

### Wave 2 — Phase 1 dashboard (MVP) — **done**

5. **Dashboard feature:** Shell + KPI/schedule placeholders; Stitch for layout only.  
   **Acceptance:** Responsive shell matches plan; mock or one real read.

### Wave 3 — Locked implementation plan (**done**)

Delivered in **product phases** (sequential order):

- **Phase 2** — Students: CRUD, directory, minimal enrollment.
- **Phase 3** — Attendance: date-only sessions, idempotent marks, monthly counts + history.
- **Phase 4** — Parent mobile: summary + history; calendar optional.

### Wave 4 — Post-parent product delivery (**done**)

- Grades write flow.
- Announcements end-to-end (create/edit/delete with role-safe access).
- Admin user management (list/add/remove/update role + parent link tooling).

### Wave 5 — Current execution scope (**active**)

- Messaging between staff and parents (**Track C shipped**).
- OneSignal push notifications via Edge Functions (**Track B active**).
- Fees/payments deferred until payment strategy is finalized.

**Wave 5 decision lock (do not reopen without Lead approval):**

- Teacher participant-source fix in messaging is required before Track C sign-off (**completed in Track C**).
- Message -> `notification_events` persistence is deferred to Track B (push), not a Track C blocker.
- Strict staff↔parent participant enforcement remains open product policy and is intentionally not blocking current Track C delivery.

---

## Kanban columns (operational)

| Column | Typical items |
|--------|----------------|
| **Now** | Wave 5 — OneSignal push integration (Track B) after Track C messaging ship |
| **Next** | Fees/payments after provider decision (Stripe + local method) |
| **Blocked** | Work requiring payment-method decision or explicit product scope changes |
| **Done** | Waves 1–4 shipped; `analyze` green in CI/manual and no architecture drift |

---

## Delegation template (use for every task)

1. **Current priority**  
2. **Agent**  
3. **Exact scope** (files/modules)  
4. **Dependencies**  
5. **Acceptance criteria**

---

## Review checklist (sub-agent output)

- [ ] Matches [system_design.md](system_design.md) (layers, Riverpod, Supabase, `school_id`).
- [ ] [rules.md](rules.md): feature structure, file size, models, forms.
- [ ] [branding.md](branding.md): colors, type, no ad-hoc dividers.
- [ ] MVP-focused; no scope creep.
- [ ] No duplicated tenant or auth logic.
- [ ] Stitch: reference only — no pasted export code.

---

*Last updated: Waves 1-4 marked complete; Wave 5 active (messaging + push, fees deferred).*
