# Supabase Migration Guide — Efatha App

## What was done (foundation)
- Added `supabase_flutter: ^2.8.0` to `pubspec.yaml`
- New: `lib/core/config/supabase_config.dart` (URL + anon key via `--dart-define`, table/bucket names)
- New: `lib/core/services/supabase_client_service.dart` (init/singleton)
- New: `lib/core/services/supabase_auth_service.dart` (signUp/signIn/passwordless OTP/profile)
- New: `lib/core/services/supabase_database_service.dart` (sermons/events/prayers/testimonies/giving/live/bible/hymns)
- New: `lib/core/services/supabase_storage_service.dart` (profiles/sermons/events/testimonies/prayers/announcements buckets)
- New: `supabase/schema.sql` — full Postgres schema + RLS + storage buckets (run once in Supabase SQL Editor)
- Updated: `lib/main.dart` (initializes Supabase if configured, else Django fallback)
- Updated: `screens/splash_screen.dart` + `core/services/auth_manager.dart` (Supabase session first, Django JWT fallback)

Django backend is **not deleted** — app runs in hybrid mode until you finish migrating screens.

## 1. Create Supabase project
1. https://supabase.com → New project (region closest to TZ, e.g. EU Central)
2. Settings → API → copy `Project URL` + `anon public` key
3. SQL Editor → paste `supabase/schema.sql` → Run
4. Authentication → Providers → Email → enable; set redirect / OTP expiry
5. Storage → confirm 6 public buckets exist

## 2. Run the app with Supabase
```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGci...
```
Without flags the app still works on Django (you'll see "Supabase not configured" in logs).

For production, bake keys into CI or use `--dart-define` in your build:
```bash
flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

## 3. Migrate screens (pattern per feature)
Replace per-screen `http + ApiConfig + SharedPreferences token` with the new services:

```dart
// OLD (Django)
final res = await http.get(Uri.parse(ApiConfig.sermons), headers: {...});

// NEW (Supabase)
final db = SupabaseDatabaseService();
final sermons = await db.getSermons(category: 'Sunday Service', search: q);
```

Auth:
```dart
// OLD
await ApiService().login(username: u, password: p);
// NEW
await SupabaseAuthService().signInWithPassword(email: e, password: p);
// or passwordless:
await SupabaseAuthService().sendOtp(email: e);
await SupabaseAuthService().verifyOtp(email: e, token: code);
```

Uploads:
```dart
// OLD: multipart POST to Django MEDIA
// NEW:
final url = await SupabaseStorageService().uploadSermonFile(sermonId: id, kind: 'video', file: f);
await SupabaseDatabaseService().update('sermons', id, {'video_url': url});
```

Priority order (biggest wins first):
1. Auth screens (login/returning/email_verification/onboarding) → `SupabaseAuthService`
2. Sermons list/detail/upload → `getSermons/incrementSermonViews` + storage
3. Home/More profile load (`getCurrentUser` → `getCurrentProfile`)
4. Events/Prayers/Testimonies → generic `list/insert/update/delete` + toggles
5. Giving → `createGiving` (keep PesapalService for payment, store record in Supabase)
6. Live streams/chat → `getCurrentLiveStream` + realtime channel
7. Delete `ApiService/ApiConfig/Django` only when no `ApiConfig.` references remain:
   `rg "ApiConfig\." lib`

## 4. Data migration (Django → Supabase)
- Export Postgres: `pg_dump efatha_db > dump.sql`, or per-table CSV via Django admin
- Rewrite IDs: Django ints → Supabase uuids (keep old id in a `legacy_id` column if you need mapping)
- Media: copy `backend/media/*` → upload to matching buckets, update `*_url` columns
- Users: **don't import passwords** — create users via Supabase Auth (invite email), then update `profiles` rows

## 5. Security checklist
- [ ] RLS enabled (schema does it) — test anon can't write
- [ ] Tighten `auth write ...` policies by role (editor/admin) before launch
- [ ] Remove hardcoded Pesapal live keys from `pesapal_service.dart` → Edge Function or backend secret
- [ ] Fix `DonationsService` token key bug (`auth_token` vs `access_token`) — goes away once on Supabase
- [ ] Change `FlutterDownloader ignoreSsl:true` + `debug:true` for release

## 6. Rollback
Hybrid mode = safe. If Supabase fails, splash/AuthManager fall back to Django automatically.
Remove Django only after all screens migrated + data verified.
