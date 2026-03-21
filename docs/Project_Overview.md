# Project overview (LLM handover)

**Purpose:** Quick orientation for anyone (including LLM agents) picking up work on this codebase. For depth, follow the linked docs—this file does not replace them.

**Program status:** **Wave 1–2 complete** (foundations + Phase 1 dashboard). **Wave 3 in progress** — students → attendance → parent ([team_task_board.md](team_task_board.md), [wave3_delegation.md](wave3_delegation.md)).

---

## What this is

**Schoolify** is a **multi-tenant School Management SaaS**: one backend serves many schools; each school’s data is isolated. **Flutter** (web + mobile) talks to **Supabase** (Postgres, Auth, RLS). Business goal: sell to schools as a **monthly subscription**.

**Target users:** Admin, Teachers, Parents (see [product.md](product.md)).

**Core product areas (full vision):** students, attendance, grades, fees, messaging—delivered in **phased MVP** waves, not all at once (see [team_task_board.md](team_task_board.md)).

---

## Locked architecture (do not change without explicit approval)

| Layer | Choice |
|--------|--------|
| **UI** | Flutter, feature-based folders |
| **State** | Riverpod |
| **Backend** | Supabase |
| **Tenancy** | Every tenant-scoped row includes **`school_id`**; RLS enforces isolation |
| **Data flow** | `UI → Provider → Repository → Supabase` |

**Roles in the product:** Admin, Teacher, Parent ([system_design.md](system_design.md)).

**Engineering rules:** [rules.md](rules.md) — e.g. clean/feature structure, no huge files (~300 lines max), models for tables, validated forms.

---

## Repository map

| Path | Role |
|------|------|
| **[`schoolify_app/`](../schoolify_app/)** | **Canonical Flutter app** — single `pubspec.yaml`, package name `schoolify_app`. **Do not add a parallel `app/` tree.** |
| `schoolify_app/lib/app/` | Bootstrap, `MaterialApp.router`, `go_router`, shells |
| `schoolify_app/lib/core/` | Theme, design tokens, shared UI, auth/tenancy helpers, config |
| `schoolify_app/lib/features/` | Feature modules (dashboard, students, etc.) |
| `docs/` | Product, architecture, branding, integrations, orchestration |
| `Stitch UI/` | **Visual reference only** — layout/UX; **do not paste export code** into the app |

---

## Authoritative docs (read order for new agents)

1. [system_design.md](system_design.md) — architecture contract  
2. [product.md](product.md) — who it’s for and what we’re building  
3. [rules.md](rules.md) — code structure and quality bar  
4. [branding.md](branding.md) — colors, typography (source of truth for UI tokens)  
5. [INTEGRATIONS_AND_SETUP.md](INTEGRATIONS_AND_SETUP.md) — Supabase, secrets (**anon key in client only**; never `service_role` in Flutter)  
6. [team_task_board.md](team_task_board.md) — waves, agent roles, what blocks what, review checklist  
7. [design_system.md](design_system.md) — where Flutter theme/widgets live under `schoolify_app/lib/core/`  

**Onboarding / tooling:** [DEV_TOOLING_AND_ONBOARDING.md](DEV_TOOLING_AND_ONBOARDING.md).

---

## How to run the app

From **`schoolify_app/`**:

```bash
flutter pub get
flutter analyze
flutter run -d chrome   # or ios / android
```

Optional Supabase (compile-time defines — see [INTEGRATIONS_AND_SETUP.md](INTEGRATIONS_AND_SETUP.md)):

```bash
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

Without credentials, the app can run in a **demo / offline** mode (see [`schoolify_app/README.md`](../schoolify_app/README.md)).

---

## MVP delivery order (high level)

Aligned with [team_task_board.md](team_task_board.md):

1. **Foundations** — tenant schema + RLS baseline, auth + `school_id` / role context, theme aligned with branding, router guards  
2. **Phase 1** — dashboard shell + mock or minimal real reads  
3. **Phase 2** — students (directory, CRUD, enrollment)  
4. **Phase 3** — attendance (date-only sessions, consistent marking rules, history/summary)  
5. **Phase 4** — parent mobile flows with tenant isolation  

Later: grades, fees, messaging per product scope, with role-scoped policies.

---

## Non-negotiables for contributors

- **Multi-tenant safety:** No feature queries without tenant context; align with RLS.  
- **No duplicate architecture:** One routing stack, one theme system, one place for “current school” / role.  
- **Stitch:** Reference under `Stitch UI/` only; **branding.md** wins over screenshots for tokens.  
- **Serialize risky edits:** Avoid parallel edits to `pubspec.yaml`, `main.dart`, or a single migration file without ownership ([team_task_board.md](team_task_board.md)).

---

## Cursor / IDE hints

Project rules may live under [`.cursor/rules/`](../.cursor/rules/) (e.g. Stitch reference, architecture reminders). Treat **`docs/`** as the contract; rules summarize and point there.

---

*Use this file for orientation; keep [team_task_board.md](team_task_board.md) updated for current wave status and delegation.*
