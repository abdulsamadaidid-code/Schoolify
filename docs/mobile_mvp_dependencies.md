# Mobile MVP (Parent / Teacher) — dependencies & blockers

**Scope:** Parent and teacher mobile MVP flows implemented under `schoolify_app/lib/` with **stub repositories** until Supabase tables, RLS, and Auth & tenancy are wired.

## Upstream dependencies (must stay stable)

| Dependency | Owner / area | Why it blocks “real” data |
|------------|----------------|---------------------------|
| `AuthSession.role` + `schoolId` from membership | Auth & tenancy | Repositories need a single tenant scope (`school_id`) for every query. |
| Supabase schema for students, attendance, grades, fees, announcements | Supabase / DB | Stub models map to future tables; RLS must enforce `school_id`. |
| Guardian / parent ↔ student linkage | Supabase / DB + policies | Parent views must only return linked children. |
| App shell + `go_router` ownership | Platform / App | This PR adds a minimal router + shells; merge conflicts possible if shell changes in parallel. |

## What is implemented

- **Auth wiring:** `authStateProvider` ([`core/auth/providers/auth_providers.dart`](../schoolify_app/lib/core/auth/providers/auth_providers.dart)) is the routing source of truth: Supabase session stream when configured, else demo `authProvider`. `GoRouter` refreshes via [`app/router/go_router_refresh.dart`](../schoolify_app/lib/app/router/go_router_refresh.dart).
- **Role entry:** without Supabase, `/` and `/login` show `RoleSelectScreen` (Parent / Teacher demo). With Supabase, `/login` is `LoginPage`; unresolved role → `/pending-role`.
- **Navigation:** `StatefulShellRoute.indexedStack` + Material 3 `NavigationBar` — parent vs teacher destinations are disjoint (`/parent/*` vs `/teacher/*`).
- **Contracts:** `abstract` repositories + `Stub*` implementations + Riverpod `FutureProvider`s per screen.
- **Design:** `docs/branding.md` tokens via `lib/core/theme/` and shared cards / buttons / headers.

## Blocked or deferred (no backend redesign here)

| Item | Notes |
|------|--------|
| Live Supabase reads/writes | Swap stub repository providers for implementations calling `Supabase.instance.client` + tenant filters. |
| Fee payments (Stripe) | MVP shows **fees summary** only; charging flows per `docs/INTEGRATIONS_AND_SETUP.md`. |
| Teacher “mark attendance” detail flow | MVP lists **today’s classes**; drill-down to mark P/A/L needs attendance schema + UX slice. |
| Push / FCM | Not in this MVP slice. |

## Stitch references

`Stitch UI/` HTML/DESIGN files are **layout/UX reference only** ([`docs/team_task_board.md`](team_task_board.md)); implementation follows `branding.md` and shared Flutter widgets.
