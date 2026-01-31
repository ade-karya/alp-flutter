# ALP Flutter - Copilot Instructions

## Project Overview

**ALP (Adaptive Learning Platform)** is a multi-role educational app supporting Windows/Android with offline P2P sync, AI tutoring (Gemini/OpenAI), and role-based dashboards (Student/Teacher).

### Architecture

- **Pattern**: Clean Architecture + BLoC/Cubit state management
- **Key Structure**: `lib/core` (shared services/state), `lib/features` (feature modules)
- **DB**: SQLite (local) + Firebase (optional sync), multi-platform support (FFI for desktop)
- **AI**: Pluggable providers (Gemini, OpenAI, Ollama) via `SettingsCubit`

## Critical Patterns & Conventions

### 1. State Management (BLoC/Cubit)

- **Global Cubits**: `AuthCubit`, `ThemeCubit`, `SettingsCubit`, `NetworkCubitV2` instantiated in `main.dart`
- **Feature-level**: Cubits scoped to feature modules (e.g., `AIAgentCubit`)
- **Usage pattern**: `BlocBuilder<MyCubit, MyState>` for UI, `context.read()` for imperative calls
- **Multi-tenant settings**: `SettingsCubit(userId: userId)` scoped per user (see [main.dart](lib/main.dart))

### 2. Database Access

- **Singleton**: `DatabaseHelper.instance` everywhere
- **Cross-module queries**: Use `DatabaseHelper` directly from features—no repository layer
- **Key tables**: `users`, `classes`, `members`, `assignments`, `questions`, `submissions`
- **Stream updates**: `DatabaseHelper.onClassUpdate` notifies about class data changes
- **Platform handling**: Avoid SQLite on Web; conditional imports in [db_initializer.dart](lib/core/services/db_initializer.dart)

### 3. Networking & Sync

- **Three modes**: `ConnectionMode.local` (mDNS), `internet` (Firebase), `hybrid` (both)
- **NetworkCubitV2** [network_cubit_v2.dart](lib/core/network/network_cubit_v2.dart):
  - Teacher: starts server via `SyncServer` on local port 9090
  - Student: joins via `SyncClient` (local IP or Firebase session code)
  - Interface deduplication required (see [manage_class_screen.dart](lib/features/teacher/screens/manage_class_screen.dart) for interface deduplication pattern)
- **Firebase sync**: `FirebaseSyncService` auto-syncs when no local network available
- **Sync flow**: Data written to SQLite → broadcast to connected clients

### 4. Routing

- **GoRouter-based** with auth-driven redirects in [app_router.dart](lib/core/routes/app_router.dart)
- **Key routes**: `/splash` → `/user-selection` → role dashboard (`/student/dashboard`, `/teacher/dashboard`)
- **Navigation**: Use `context.go('/path')` or `context.push('/path')` for screen stacking
- **Error handling**: Global error redirect to `/user-selection` in [main.dart](lib/main.dart)

### 5. Theme & Localization

- **Themes**: `AppThemeMode.wizard` (magical) vs `AppThemeMode.forest` (nature) toggled via `ThemeCubit`
- **Locales**: Indonesian (id), English (en), Arabic (ar) via `AppLocalizations` (generated from `.arb`)
- **Theme persistence**: No persistence; reset on app start. Change if needed in [theme_cubit.dart](lib/core/theme/theme_cubit.dart)
- **UI components**: `ScaffoldWithNavBar` wraps role-based navigation; `FeatureTutorial` provides spotlight tutorials

### 6. AI Integration

- **Multi-provider support**: `AIProviderType` enum (gemini, openai, ollama)
- **Active provider**: Selected in `SettingsCubit.activeProviderType`, persisted per-user
- **Service**: `GeminiOpenAIService` handles all provider calls with dynamic model/API key switching
- **Live streaming**: `GeminiLiveService` for real-time Gemini Live API conversation (expensive)
- **Screen locations**: `AIAssistantScreen` (config UI), `AITutorScreen` (student chat), `AIAgentScreen` (agent mode)

## Developer Workflows

### Local Development

```bash
flutter pub get                    # Install deps
flutter run -d windows             # Windows
flutter run -d android-emulator    # Android
flutter pub upgrade --major-versions # Update deps
```

### Database Schema Changes

1. Increment version in [database_helper.dart](lib/core/database/database_helper.dart) (`openDatabase` → `version: X`)
2. Implement `_upgradeDB()` migration logic
3. Test on both new installs and upgraded databases

### Adding a New Feature

1. Create `lib/features/my_feature/` with: `screens/`, `cubit/`, `models/`
2. Implement Cubit extending `Cubit<MyState>` with equatable states
3. Add routes in [app_router.dart](lib/core/routes/app_router.dart)
4. Use `BlocBuilder<MyCubit, MyState>` in screens
5. Inject dependencies via `BlocProvider.value()` or `RepositoryProvider`

### Network Testing

- **Local (P2P)**: Both devices on same WiFi, mDNS discovery auto-finds teacher
- **Internet mode**: Requires Firebase config + session code sharing
- **Hybrid**: Falls back to Firebase if local unavailable

### AI Provider Configuration

1. User enters API key in `AIAssistantScreen`
2. Saved per-provider in `SettingsCubit` (SharedPreferences)
3. `GeminiOpenAIService` uses `activeProvider` config when generating content
4. Test with small prompts first (expensive APIs)

## File Organization Reference

- [lib/main.dart](lib/main.dart): App initialization, BLoC setup, global error handling
- [lib/core/routes/app_router.dart](lib/core/routes/app_router.dart): Navigation routing
- [lib/core/auth/auth_cubit.dart](lib/core/auth/auth_cubit.dart): Auth state (Firebase + local DB)
- [lib/core/database/database_helper.dart](lib/core/database/database_helper.dart): SQLite schema & queries
- [lib/core/network/network_cubit_v2.dart](lib/core/network/network_cubit_v2.dart): P2P & Firebase sync
- [lib/features/teacher/screens/manage_class_screen.dart](lib/features/teacher/screens/manage_class_screen.dart): Network UI + class management
- [lib/core/settings/settings_cubit.dart](lib/core/settings/settings_cubit.dart): User prefs (locale, AI config)

## Common Pitfalls

1. **Duplicate mDNS interfaces**: Always deduplicate by IP before Dropdown items (see [manage_class_screen.dart](lib/features/teacher/screens/manage_class_screen.dart))
2. **SQLite on Web**: Will throw—use conditional imports to skip DB init
3. **Unmounted contexts**: Always check `if (mounted)` before `setState()` or `context.read()`
4. **Async locks**: Network operations can be slow; show loading states with `_isLoading` flag
5. **User-scoped settings**: Remember `SettingsCubit(userId)` differs per user—create new instance on login

## Platform-Specific Notes

- **Windows**: Requires Visual Studio C++ build tools; window manager initialized in [main.dart](lib/main.dart)
- **Android**: Permissions handled by `NetworkPermissionService` (WiFi, Bluetooth, location)
- **Shared Preferences**: Used for persisting locale, AI config; auto-migrated on version bump

---

For architecture diagrams and networking deep-dives, see `README.md`, `INTERNET_CONNECTIVITY_GUIDE.md`, and `QUICK_START_INTERNET.md`.
