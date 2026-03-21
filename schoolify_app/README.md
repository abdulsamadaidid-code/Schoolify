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

## Running with Supabase

1. **Apply the schema.** In the [Supabase Dashboard](https://supabase.com/dashboard) → **SQL Editor**, paste and execute the contents of [`../supabase/migrations/001_baseline.sql`](../supabase/migrations/001_baseline.sql) (repository root).

2. **Run the app** with your project URL and **anon** key:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://vmkibeakzshjchhsqokz.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZta2liZWFrenNoamNoaHNxb2t6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwOTg4MDksImV4cCI6MjA4OTY3NDgwOX0.ud8d4HjQTSLTebtiuw_iWkB1WmmF0qHAHRI7nswhWHA
```

3. **First-time setup:** Create a user via Supabase Auth (Dashboard → **Authentication**, or the app’s sign-up). Then in **SQL Editor**, bootstrap the first school and admin membership:

```sql
select create_school_with_admin('School Name');
```

Replace `'School Name'` with your school’s display name.

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
