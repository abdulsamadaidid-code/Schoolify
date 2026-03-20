# Schoolify (Flutter app)

Foundation scaffold: feature-based `lib/`, Riverpod, `go_router` (`lib/app/router.dart`), Supabase init from compile-time env (`lib/app/bootstrap.dart`). **Design tokens + shared UI:** `lib/core/theme/`, `lib/core/design_system/`, `lib/core/ui/` (see [docs/design_system.md](../docs/design_system.md)).

**Auth:** `authStateProvider` merges Supabase session (`Env.hasSupabaseConfig`) with demo `authProvider` when running without credentials — one guard for `go_router` and feature screens.

## First-time project generation (platform folders)

If this directory was created without `flutter create` (e.g. CI or partial checkout), generate Android / iOS / web host files from a machine with a supported Flutter SDK:

```bash
cd schoolify_app
flutter create . --project-name schoolify_app --platforms=android,ios,web
```

Then:

```bash
flutter pub get
flutter analyze
flutter run -d chrome   # or ios / android
```

## Tooling checklist

See [docs/DEV_TOOLING_AND_ONBOARDING.md](../docs/DEV_TOOLING_AND_ONBOARDING.md) for MVP vs optional tools, MCP notes, and OS/Flutter constraints.

## Environment (Supabase)

Pass **anon** credentials at compile time (see [docs/INTEGRATIONS_AND_SETUP.md](../docs/INTEGRATIONS_AND_SETUP.md)):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

If omitted, the app runs in **offline / no-backend** mode: auth stream stays signed-out; login shows a clear message.

## Mobile MVP (Parent / Teacher)

- **Entry:** Without Supabase, `/` and `/login` use `RoleSelectScreen` (demo Parent / Teacher). With Supabase, use `LoginPage` and membership/`user_metadata` for role (see `AuthRepository`).
- **Routes:** `/parent/*` (dashboard, attendance, grades, announcements, fees) and `/teacher/*` (dashboard, attendance, students, grades, announcements). See [`docs/mobile_mvp_dependencies.md`](../docs/mobile_mvp_dependencies.md).
- **Data:** Repository **interfaces** + **stub** implementations; swap providers when backend is ready.

## Ownership (see `docs/team_task_board.md`)

| Area | Owner |
|------|--------|
| `lib/app/` router, shell, bootstrap | Platform |
| `lib/core/theme` + design tokens (when added) | Design system |
| Profile, `school_id`, RLS-backed role | Auth & tenancy |
| Feature modules under `lib/features/` | Feature agents |
