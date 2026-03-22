# Developer tooling, MCP, and environment (repeatable setup)

This document complements [INTEGRATIONS_AND_SETUP.md](INTEGRATIONS_AND_SETUP.md) with a **tool inventory**, **MVP vs optional** classification, **validation commands**, and **known blockers**. It is aimed at implementation readiness without changing product scope.

**Lead engineer execution order** (foundations) is in [team_task_board.md](team_task_board.md) — Wave 1 expects: Flutter scaffold + Supabase migrations + theme + auth/tenancy.

---

## 1. Document map

| Doc | Purpose |
|-----|---------|
| [INTEGRATIONS_AND_SETUP.md](INTEGRATIONS_AND_SETUP.md) | Services, packages, step-by-step environment (authoritative for integrations) |
| [rules.md](rules.md) | Engineering rules (layers, file size, models, forms) |
| [system_design.md](system_design.md) | Locked architecture |
| [team_task_board.md](team_task_board.md) | Priorities, ownership, blocked workstreams |

> **Note:** There is no `integrations.md` in this repo; use `INTEGRATIONS_AND_SETUP.md`.

---

## 2. Required tools — MVP-essential

These are required to meet **Wave 1** acceptance: `flutter analyze` clean; app runs on **web + one mobile target**; Supabase schema/RLS work proceeds in parallel.

| Tool | Role | Validate | Status (project) |
|------|------|----------|------------------|
| **Git** | Version control | `git --version` | Expected on all dev machines |
| **Flutter SDK (stable)** | Dev and builds | `flutter doctor -v` | App lives in `schoolify_app/` — run commands from that directory |
| **Chrome** | Flutter web debug | `flutter devices` includes Chrome | Required for web target |
| **Supabase account + project** | Backend | Dashboard access | **Secrets:** project URL + **anon** key (never `service_role` in the app) |
| **Supabase CLI** | Migrations, `supabase link`, Edge Functions | `supabase --version` | Not yet committed: no `supabase/` directory in repo at time of writing — add when DB work starts |

**Platform-specific (pick targets your team ships):**

| Tool | When required | Validate |
|------|----------------|----------|
| **Xcode** (macOS) | iOS / Simulator | `xcodebuild -version` |
| **Android Studio + SDK + licenses** | Android / emulator | `flutter doctor`; `flutter doctor --android-licenses` |
| **CocoaPods** | iOS native deps after `flutter create` | `pod --version` |

---

## 3. Tools — MVP-useful but not blocking “hello tenant”

| Tool | Role | When |
|------|------|------|
| **Docker** | Local `supabase start` | Optional; use hosted Supabase if Docker is unavailable |
| **Stripe CLI** | Webhook forwarding to local Edge Functions | When implementing billing slice |
| **Node.js** | Stripe CLI, some JS tooling | Optional unless you use those tools |

---

## 4. Tools — post-MVP or optional (per INTEGRATIONS)

| Tool | Role |
|------|------|
| **OneSignal + Supabase Edge Functions** | Push notifications (Android now, iOS later) |
| **Sentry** | Crash reporting |
| **PostHog** | Product analytics |
| **CI (e.g. GitHub Actions)** | `analyze`, `test`, `build web` — suggested in INTEGRATIONS; **no workflow files in repo yet** |

---

## 5. MCP (Model Context Protocol) — Cursor / agents

**Repository state:** There is **no** checked-in `mcp.json` in this workspace. MCP servers are typically configured **per developer** in Cursor (or global agent config).

| MCP / capability | Purpose | Setup hint |
|------------------|-----------|------------|
| **Stitch MCP** | High-fidelity UI generation/editing aligned with Stitch workflows | Referenced by [.cursor/rules/stitch-ui.mdc](../.cursor/rules/stitch-ui.mdc) and the `stitch-design` skill (`~/.agents/skills/stitch-design`). Install/enable the Stitch MCP server in Cursor and authenticate per vendor docs. |
| **Supabase MCP** (if used) | Schema/admin assistance | Optional; team choice — do not replace migrations/RLS review in code |

**Validation:** In Cursor, confirm MCP servers load without errors (Cursor Settings → MCP). No automated repo-level check.

---

## 6. Secrets and environment (blockers if missing)

| Secret / input | Used by | Never commit |
|----------------|---------|--------------|
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Flutter app (compile-time) | — |
| Supabase **service_role** | Edge Functions / server only | Yes — never in Flutter |
| Stripe **secret** + **webhook signing secret** | Edge Functions | Yes |
| OneSignal App ID + REST API Key | Edge Functions / deployment environment | Store as secrets; never commit |
| Apple Developer / signing | iOS device/release | Certificates in Keychain / CI secrets |

Local run pattern (from `schoolify_app/README.md`):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

---

## 7. Step-by-step — minimal path to “ready to implement Wave 1”

1. **OS:** Use **macOS 14+** if you need the **current** Flutter toolchain (see §8 — Flutter’s Dart VM may refuse macOS 13).
2. **Install Flutter** per [official install](https://docs.flutter.dev/get-started/install); add to `PATH`.
3. **`flutter doctor -v`** — fix all items needed for your targets (Xcode, Android toolchain, Chrome).
4. **Clone repo** → `cd schoolify_app` → `flutter pub get`.
5. If `android/`, `ios/`, or `web/` are missing: `flutter create . --project-name schoolify_app --platforms=android,ios,web` (from README).
6. **`flutter analyze`** — must be clean per task board.
7. **Supabase:** Create project; install CLI; when ready, `supabase init` in repo root and commit `supabase/` migrations (coordinate with single owner per task board).
8. **Optional:** Docker + `supabase start` for local stack.

---

## 8. Risks and validated blockers

### 8.1 macOS version vs Flutter (critical)

On a machine running **macOS 13 (Ventura)**, the **current** Flutter SDK may fail with:

`VM initialization failed: Current Mac OS X version 13.0 is lower than minimum supported version 14.0`

**Mitigation:**

- **Upgrade to macOS 14+** for the supported toolchain, **or**
- Pin an **older Flutter SDK** that still supports macOS 13 (team policy: document the version in this file or use [FVM](https://fvm.app) / `flutter version` file when introduced).

Until resolved, **`flutter doctor`, `flutter analyze`, and `flutter run` cannot be validated** on that host.

### 8.2 Repo gaps (not blockers for coding, blockers for automation)

| Gap | Impact |
|-----|--------|
| No `supabase/` directory | Expected until Supabase agent adds migrations |
| No `.github/workflows/` | No automated analyze/test yet |
| Not a git repo in some sandboxes | No PR/CI until `git init` / remote added |

### 8.3 This workspace snapshot (example)

Tools **not** found on `PATH` during one check: `supabase`, `stripe`, `docker`. Install per INTEGRATIONS as those slices start.

---

## 9. Quick validation checklist

Copy/paste from `schoolify_app/`:

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
# Optional: flutter run -d ios   # macOS + Xcode
# Optional: flutter run -d android
```

**Wave 1 alignment:** [team_task_board.md](team_task_board.md) — Platform → Supabase → Design system → Auth & tenancy.

---

*Last updated: DevOps/tooling pass — environment validation and repo inventory.*
