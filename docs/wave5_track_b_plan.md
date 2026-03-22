# Wave 5 Track B plan - Push notifications (Android delivery, iOS-ready)

**Track goal:** Ship production-safe push notifications for **Android in Wave 5** using **Supabase-first infrastructure**, while keeping code paths **iOS-ready** for a later wave:

- `device_tokens` in Supabase for token ownership and lifecycle
- `notification_events` as the event contract (fed by messaging and other producers)
- Edge Function pipeline to fan out and send pushes
- Delivery logging for retries, debugging, and operations

**Scope lock (Wave 5 Track B):**

- Delivery platform in scope: **Android only**
- Deferred platform (not removed): **iOS push**, pending Apple Developer account
- Platform out of scope: **Web push** (service worker/VAPID) for this wave
- Provider lock: **No Firebase, no FCM, no FlutterFire client integration**
- Engineering constraint: Flutter and Edge Function code must include clear iOS hooks/stubs that are disabled in Wave 5

---

## 1) Database migration plan

Use three migrations so ownership and rollback are clear.

## 1.1 Migration `017_device_tokens.sql`

Create table:

- `device_tokens`
  - `id uuid primary key default gen_random_uuid()`
  - `user_id uuid not null` -> `auth.users(id)` (cascade delete)
  - `school_id uuid not null` -> `schools(id)` (cascade delete)
  - `platform text not null check (platform in ('ios','android'))`
  - `token text not null`
  - `device_label text null` (optional debugging label)
  - `app_version text null`
  - `last_seen_at timestamptz not null default now()`
  - `created_at timestamptz not null default now()`
  - `updated_at timestamptz not null default now()`

Constraints/indexes:

- Unique active token: `unique(token)`
- Lookup index: `(user_id, school_id)`
- Freshness index: `(last_seen_at desc)`

RLS policies:

- `select`: user can read only their own rows (`auth.uid() = user_id`)
- `insert`: user can insert only rows where `user_id = auth.uid()`
- `update`: user can update only their own rows
- `delete`: user can delete only their own rows

RPC helper (recommended):

- `upsert_device_token(p_school_id uuid, p_platform text, p_token text, p_device_label text default null, p_app_version text default null)`
  - Enforces membership in `p_school_id`
  - Upserts by `token` and updates `last_seen_at`
  - Prevents client from writing arbitrary `user_id`

## 1.2 Migration `018_notification_events.sql`

Create table:

- `notification_events`
  - `id uuid primary key default gen_random_uuid()`
  - `school_id uuid not null` -> `schools(id)`
  - `target_user_id uuid not null` -> `auth.users(id)`
  - `event_type text not null` (examples: `message_created`, `announcement_posted`, `attendance_marked`)
  - `entity_table text null` (optional)
  - `entity_id uuid null`
  - `title text not null`
  - `body text not null`
  - `payload jsonb not null default '{}'::jsonb`
  - `status text not null default 'pending' check (status in ('pending','processing','sent','failed','discarded'))`
  - `scheduled_for timestamptz not null default now()`
  - `attempt_count int not null default 0`
  - `last_error text null`
  - `dedupe_key text null`
  - `created_at timestamptz not null default now()`
  - `updated_at timestamptz not null default now()`
  - `processed_at timestamptz null`

Constraints/indexes:

- Optional dedupe guard: unique on `dedupe_key` where not null
- Worker pickup index: `(status, scheduled_for, created_at)`
- Target lookup index: `(target_user_id, created_at desc)`

RLS and write boundary:

- App users: no direct writes/updates/deletes
- Only trusted paths create events:
  - security-definer RPCs used by product features, or
  - Edge Function/service role path

## 1.3 Migration `019_notification_deliveries.sql`

Create table:

- `notification_deliveries`
  - `id uuid primary key default gen_random_uuid()`
  - `event_id uuid not null` -> `notification_events(id)` (cascade delete)
  - `token_id uuid not null` -> `device_tokens(id)` (cascade delete)
  - `status text not null check (status in ('sent','failed','invalid_token','skipped'))`
  - `provider_message_id text null`
  - `provider_response jsonb not null default '{}'::jsonb`
  - `error_code text null`
  - `error_message text null`
  - `attempted_at timestamptz not null default now()`

Constraints/indexes:

- Event and token history indexes: `(event_id)`, `(token_id)`, `(attempted_at desc)`

RLS:

- No app-user read/write
- Service role / Edge Function only

Retention:

- Keep deliveries for operational window (for example 30-90 days), then cleanup via scheduled SQL task.

---

## 2) Edge Function implementation plan

Function name:

- `send_push_notifications`

Execution model:

- Triggered by scheduler (every 1 minute) and callable manually for smoke tests
- Pulls `pending` events with `scheduled_for <= now()`
- Claims a small batch (`limit 50-200`) by atomically flipping to `processing`

Recommended claim query pattern:

- `update ... set status = 'processing' ... where id in (select id ... for update skip locked limit N) returning *`

Per-event pipeline:

1. Load recipient tokens from `device_tokens` where `target_user_id` and recent freshness.
2. If no tokens:
   - Mark event `discarded` (or `failed` with no-recipient reason by policy)
   - Write one `notification_deliveries` row with `status='skipped'`.
3. For each token:
   - Build platform payload (`title`, `body`, `payload`, deep link metadata).
   - Send through chosen push transport adapter.
   - Android path is active in Wave 5.
   - iOS path exists as a disabled stub (`enabled=false` / feature flag guard) for future activation with credentials only.
   - Insert `notification_deliveries` result row.
4. Finalize event:
   - `sent` if at least one token succeeded
   - otherwise `failed`, increment `attempt_count`, set `last_error`
5. Retry policy:
   - Exponential backoff on transient errors
   - Mark `invalid_token` delivery rows and deactivate/remove bad tokens
   - Stop after max attempts (for example 5), then keep `failed`.

Operational requirements:

- Idempotent processing (safe if function retried)
- Structured logs with `event_id`, `target_user_id`, result counts
- Metrics endpoint/log summary for success/failure rates
- No secrets in logs

Scheduling:

- Use Supabase scheduled execution to run worker frequently
- Keep a manual invoke endpoint/script for incident recovery

---

## 3) Flutter implementation plan (mobile, Android-active)

## 3.1 New modules

Create:

- `schoolify_app/lib/core/notifications/push_token_repository.dart`
- `schoolify_app/lib/core/notifications/push_notification_service.dart`
- `schoolify_app/lib/core/notifications/push_notification_providers.dart`
- `schoolify_app/lib/core/notifications/push_navigation.dart` (optional deep-link router helper)

Repository contract:

- `Future<void> registerOrRefreshToken({required String schoolId, required String platform, required String token, String? deviceLabel, String? appVersion})`
- `Future<void> unregisterToken({required String token})`

Supabase implementation:

- Calls `upsert_device_token` RPC
- Unregisters on logout/token invalidation

## 3.2 App lifecycle integration

Wire in app bootstrap:

- On authenticated session start:
  - request notification permission
  - obtain current device token from native push SDK bridge
  - call repository registration
- On token refresh event:
  - upsert latest token
- On logout:
  - unregister token or mark inactive

Foreground/background behavior:

- Foreground: show local in-app notification UI or banner
- Background/terminated: OS notification opens app -> route to target thread/screen using payload metadata

iOS-ready requirement (Wave 5):

- Keep iOS token/provider integration points as explicit placeholders in service/repository interfaces.
- Guard iOS runtime registration with a disabled feature toggle until Apple credentials are available.
- Do not require iOS credentials or iOS-specific setup to ship this wave.

Guardrails:

- Register token only when `school_id` is resolved
- Debounce token updates to avoid excessive writes
- Never store push credentials in Flutter app

## 3.3 QA scenarios (must pass)

- Admin/teacher/parent each receives expected pushes for allowed events
- User in different school never receives cross-tenant event
- Token rotation updates row correctly
- Revoked/invalid token is cleaned up after send failure
- Cold-start deep link opens correct screen
- iOS code path compiles and remains disabled without credentials

---

## 4) Agent ownership and sequencing

| Work item | Primary owner | Supporting owners | Dependency |
|---|---|---|---|
| `017_device_tokens.sql` | Supabase/DB agent | Auth & tenancy | none |
| `018_notification_events.sql` | Supabase/DB agent | Messaging + Platform | Track C event contract |
| `019_notification_deliveries.sql` | Supabase/DB agent | Platform | `018` |
| Push worker Edge Function | Platform/Mobile infra agent | Supabase/DB | 017-019 |
| Event producer wiring (message/announcement/attendance) | Feature agents | Supabase/DB | `018` |
| Flutter token registration + handlers | Platform/Mobile infra agent | Auth & tenancy, Design system | `017` |
| Tenant and role validation pass | Auth & tenancy agent | Platform | all above |
| End-to-end test pass and rollout checklist | Platform + Lead | all agents | all above |

Recommended merge order:

1. DB migrations (017 -> 018 -> 019)
2. Edge Function worker with dry-run logging
3. Feature event producers
4. Flutter registration/handlers
5. End-to-end QA and hardening

---

## 5) Manual setup required before agents start

Complete these once to avoid blockers mid-implementation.

## 5.1 Apple (iOS push) - deferred

No Apple setup is required for Wave 5 Track B delivery.

Prepare later (future wave):

- Apple Developer account access with push capability permissions
- APNs Auth Key (`.p8`), `Key ID`, `Team ID`
- iOS bundle push capability + deployment secrets for the iOS send path

## 5.2 Android push provider credentials

- Create production push credentials for Android in the selected provider path used by Edge Function transport
- Add required server credentials as Supabase Edge Function secrets
- Define Android notification channel IDs/names used by app

## 5.3 Supabase environment and secrets

- Ensure Edge Functions are enabled in the target project
- Set push provider secrets in Supabase (`supabase secrets set ...`)
- Keep iOS secrets unset for this wave; iOS send path remains inactive
- Set optional limits/config:
  - `PUSH_BATCH_SIZE`
  - `PUSH_MAX_ATTEMPTS`
  - `PUSH_RETRY_BASE_SECONDS`

## 5.4 Operational setup

- Configure scheduled invocation for `send_push_notifications`
- Add log review checklist for failed deliveries and invalid tokens
- Prepare runbook for replay/retry of failed `notification_events`

---

## 6) Definition of done (Track B)

- Migrations `017`-`019` applied and reviewed
- Edge Function sends push for pending events and writes delivery logs
- Flutter app registers/unregisters tokens reliably on Android
- Message-created events produce push notifications end-to-end
- At least one announcement and one attendance event path verified
- Cross-tenant isolation validated with real role accounts
- Web push remains out of scope and not implemented in this wave
- iOS is explicitly deferred (not dropped); iOS hooks/stubs are present and disabled so later enablement requires credentials/config only
