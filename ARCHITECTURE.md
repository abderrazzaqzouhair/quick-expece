# Control One — Architecture Reference

This document describes the architecture of the **Control One** Flutter monorepo. It is written to be reused as a
blueprint when bootstrapping a new project with a similar structure.

---

## 1. Project Type & Tech Stack

- **Type**: Flutter/Dart **monorepo** (client app only — consumes a remote REST API, no backend code here).
- **Language**: Dart, SDK `>=3.9.0 <4.0.0`.
- **Framework**: Flutter — mobile (iOS/Android) via `control_one_mobile`, web via `control_one_web`.
- **Monorepo tool**: **Melos 7.3.0**. Config is inline in the root `pubspec.yaml` under a `melos:` block (not a
  separate `melos.yaml` — a Melos-7-specific style), using `workspace:` resolution mode with
  `usePubspecOverrides: true`.
- **Package manager**: `flutter pub` / `dart pub` per package, orchestrated by Melos.
- **Scaffolding tool**: **Mason** (`mason.yaml`, `mason-lock.json`, `.mason/`) with a custom local brick
  (`bricks/feature`) that generates new feature packages with the Clean Architecture skeleton described below.

---

## 2. Top-Level Directory Structure

```
project-root/
├── pubspec.yaml           # Root workspace manifest + Melos config (scripts, workspace member list)
├── pubspec.lock           # Root lockfile (workspace-resolved)
├── mason.yaml             # Registers local bricks (feature)
├── mason-lock.json        # Mason brick lock file
├── .mason/                # Mason cache
├── README.md              # Monorepo usage guide
├── apps/                  # Deployable applications
│   ├── <app>_mobile/         # Flutter mobile app (iOS + Android) — main entry point
│   └── <app>_web/            # Flutter web app
├── packages/              # Shared workspace packages
│   ├── core/                 # Cross-cutting utilities, services, config
│   ├── networking/            # Dio HTTP client, interceptors, endpoints, exceptions
│   ├── localization/           # flutter_localizations / l10n (ARB files, generated classes)
│   ├── ui_kit/                 # Design system (atoms/molecules/organisms, theme, assets, fonts)
│   ├── maps_kit/                # Maps/geolocation wrapper
│   └── features/               # One package per business domain (Clean Architecture, see §3)
│       ├── auth/
│       ├── profile/
│       ├── <domain-a>/
│       ├── <domain-b>/
│       └── ...
└── bricks/feature/          # Mason brick: generates a new feature package skeleton
```

Notes / pitfalls observed worth avoiding in a new project:
- Some simple features lived only inside the app's `lib/features/` (UI-only, no package), while others were
  promoted to full `packages/features/*` packages — this was inconsistent. Decide up front which features get a
  dedicated package (state/business logic) vs. which stay purely presentational inside the app.

---

## 3. Layered / Module Architecture — Clean Architecture per Feature

Each feature package under `packages/features/<name>` follows **Clean Architecture** with three layers:
`data` → `domain` → `presentation`. This is the canonical, reusable pattern.

```
packages/features/<feature>/lib/
├── <feature>.dart                       # Barrel file (public API export)
├── data/
│   ├── datasources/
│   │   └── <feature>_remote_datasource.dart   # Talks to ApiClient/endpoints, returns raw DTOs
│   ├── mappers/
│   │   └── <feature>_mappers.dart              # DTO -> domain Entity mapping
│   ├── models/                                  # Freezed + json_serializable DTOs (Request/Response models)
│   │   ├── <x>_request.dart / .g.dart
│   │   └── <x>_response.dart / .freezed.dart / .g.dart
│   └── repositories/
│       └── <feature>_repository_impl.dart       # Implements the domain repository interface
├── domain/
│   ├── entities/              # Plain entities — no JSON/Freezed coupling
│   ├── repositories/          # Abstract repository interfaces (contracts consumed by usecases)
│   ├── services/              # Domain-level singleton services (e.g. TokenService)
│   └── usecases/              # Single-purpose callables (e.g. SignInUseCase, SignOutUseCase)
└── presentation/
    ├── providers/              # Riverpod provider wiring: datasource -> repository -> usecase -> controller
    └── states/                 # Freezed sealed state classes (Initial / Loading / Success / Failure)
```

The **app** (`apps/<app>_mobile/lib/`) stays a thin shell:

```
lib/
├── main.dart                  # Bootstraps DioClient, Stripe, ProviderScope, MaterialApp.router
├── config/
│   ├── router/                 # GoRouter configuration + path constants
│   └── navigation/              # Bottom-nav shell widget
└── features/                   # App-local, UI-ONLY: screens / components / widgets
    ├── auth/ (screens, components — consumes the `auth` package for logic)
    ├── <domain-a>/, <domain-b>/, ...
    ├── onboarding/, splash/, notifications/   # App-local-only features (no dedicated package)
```

**Rule of thumb**: business logic (data/domain/state) lives in `packages/features/*`; the app only assembles
screens/widgets and wires them to that package's Riverpod providers.

---

## 4. State Management

**Riverpod** (`flutter_riverpod ^3.0.0`) across the app and all feature packages.

- `ProviderScope` wraps the app root in `main.dart`.
- Controllers use Riverpod 3.x `Notifier<State>` classes (not legacy `StateNotifier`).
- State classes are **Freezed sealed unions** with factory constructors, e.g.:
  `AuthState` = `.initial()` / `.loading()` / `.success(...)` / `.failure(...)`.
- `riverpod_annotation` + `riverpod_generator` are available as dev-dependencies for annotation-based
  (`@riverpod`) provider generation, used selectively alongside hand-written `Notifier` classes.
- No Bloc, GetX, or legacy Provider — **pick one state management approach and standardize** on it project-wide.

---

## 5. Networking / API Layer

A dedicated shared package, e.g. `packages/networking`, exporting a single barrel file:

```
packages/networking/lib/
├── client/
│   ├── dio_client.dart      # Singleton (DioClient.instance): BaseOptions, timeouts, interceptor registration
│   └── api_client.dart      # Wrapper: get/post/put/patch/delete/multipart/upload/download -> ApiResponse<T>
├── endpoints/
│   └── api_endpoints.dart   # Static endpoint paths grouped by domain, built on a baseUrl
├── interceptors/
│   ├── auth_interceptor.dart   # Injects Bearer token; 401 -> refresh-token flow with request queueing
│   └── error_interceptor.dart  # Central error logging + callback hooks (401/403/500/network errors)
├── exceptions/
│   └── api_exception.dart   # Typed ApiException (network/timeout/unauthorized/forbidden/notFound/
│                             #   validation/server/cancelled/unknown) via named factory constructors
└── models/
    └── api_response.dart    # Generic ApiResponse<T>{success,data,statusCode,message,meta}, PaginatedResponse<T>
```

- **Dio** as the HTTP client, `pretty_dio_logger` for debug logging, `connectivity_plus` for connectivity checks.
- Data flow: `RemoteDataSource` (raw ApiClient calls + JSON parsing) → `RepositoryImpl` (implements the domain
  interface, maps DTOs to entities) → `UseCase` (one business operation) → Riverpod controller/provider.
- `DioClient.instance.init()` is called once at startup, before `runApp`.

---

## 6. Authentication, Permissions, Subscriptions & Payments

- **Auth**: sign-in / sign-up / verify-code / register / check-auth / logout usecases behind an `AuthRepository`
  interface + impl. A domain-level `TokenService` singleton coordinates the in-memory token used by `DioClient`
  with the persisted token in secure storage, wires the `AuthInterceptor`'s refresh callback, and handles
  session-expiry redirects. Multi-step sign-up wizards are modeled as a sequence of step components/screens.
- **Permissions** (in this project's domain: vehicle-sharing co-manager permissions, not RBAC) are modeled as a
  Freezed class of boolean capability flags (e.g. `canView`, `canUploadDocs`, `canManageAppointments`) with
  `@JsonKey(name: 'snake_case')` mapping, mutated via a dedicated `PATCH .../permissions` endpoint.
- **Subscriptions**: modeled per business entity (e.g. per-vehicle), with a subscription model, a
  `SubscribeVehicleUseCase`/provider/state, and endpoints for listing plans, subscribing, toggling, cancelling,
  and updating the subscription's payment method.
- **Payments**: **Stripe** (`flutter_stripe`), initialized in `main.dart` via `Stripe.publishableKey` +
  `Stripe.instance.applySettings()`. A booking/checkout feature owns the payment-intent flow (payment intent,
  payment status, payment details models; a `PaymentController` Notifier that loads saved cards, selects one, and
  submits `paymentMethodId` with the booking). A profile-like feature manages saved cards/payment methods and
  payment history separately.

---

## 7. Database / Local Storage

- No embedded database by default (no Hive/Isar; `sqflite`, if present, is only a transitive dependency pulled in
  by a plugin — not used directly).
- Local persistence limited to **`flutter_secure_storage`** via a singleton service (e.g.
  `SecureStorageService`) storing `access_token`, `refresh_token`, `user_id` (Keychain on iOS, encrypted
  SharedPreferences on Android).
- All other state lives in-memory in Riverpod providers for the session lifetime.
- **Consider for a new project**: add `shared_preferences` for lightweight non-sensitive persisted settings if
  needed, and/or a local cache (Hive/Isar) for offline support if that's a requirement.

---

## 8. Navigation / Routing

**go_router**, configured in `apps/<app>_mobile/lib/config/router/app_router.dart`:

- `GoRouter` with a `_rootNavigatorKey` and a `_shellNavigatorKey`.
- `initialLocation` points to a splash route; path constants centralized in a separate `app_routes.dart`.
- Nested/child `GoRoute`s use path params (`:id`) and `state.extra` for passing complex objects.
- A `ShellRoute` wraps the main bottom-nav section (tabs: Home / Feature A / Feature B / ... / Profile).
- `parentNavigatorKey: _rootNavigatorKey` is used to push full-screen routes outside the tab shell (e.g.
  add/edit flows, subscription/payment screens).
- Custom 404 `errorBuilder`.
- **Gap to fix in a new project**: define a `_redirect` hook that actually enforces auth-gating using a
  `_publicRoutes` allowlist (in the reference project this was defined but not wired in — don't repeat that).

---

## 9. Dependency Injection

No DI container (no `get_it`/`injectable`). **DI is done entirely via Riverpod provider composition**: each
feature package builds its own provider chain in `presentation/providers/*.dart`, e.g.:

```
apiClientProvider → xRemoteDataSourceProvider → xRepositoryProvider → xUseCaseProvider → xControllerProvider
```

composed via `ref.watch()` / `ref.read()`.

Outside Riverpod, a few classic singletons exist (`DioClient.instance`, `SecureStorageService.instance`,
`TokenService.instance`).

**Improvement for a new project**: centralize the `ApiClient`/`apiClientProvider` in the shared `networking` (or
`core`) package and have every feature package depend on that single instance, instead of each feature
re-declaring its own — avoids duplication and inconsistent Dio configuration.

---

## 10. Key Dependencies (by package layer)

| Layer | Notable packages |
|---|---|
| Workspace root | `melos` |
| App | `go_router`, `flutter_riverpod`, `dio`, `flutter_stripe`, `flutter_svg`, `cached_network_image`, `image_picker`, `path_provider`, `open_filex` |
| `networking` | `dio`, `pretty_dio_logger`, `connectivity_plus` |
| `core` | `flutter_secure_storage`, `image_picker`, `file_picker`, `url_launcher` |
| Feature packages | `flutter_riverpod`, `riverpod_annotation`/`riverpod_generator`, `freezed_annotation`/`freezed`, `json_annotation`/`json_serializable`, `build_runner`, `flutter_stripe` (payment-related features), `equatable` |
| `ui_kit` | video player, country picker, cached network image, skeleton loaders, card-swiper, shimmer |
| `maps_kit` | `google_maps_flutter`, `geolocator`, `geocoding` |
| All packages (dev) | `flutter_lints` |

---

## 11. Testing Structure

Each package has a `test/` folder. Melos exposes `melos run test` / `test:coverage`, filtered to packages that
contain a `test/` directory, plus a `build:runner` filter for packages depending on `build_runner`.

**Improvement for a new project**: don't stop at scaffold smoke tests — add real unit tests for usecases/
repositories (mock the datasource), and widget tests for key screens, from day one.

---

## 12. CI/CD

None in the reference project. **For a new project, add from the start**: a CI workflow that runs
`melos run analyze`, `melos run format`, `melos run build:runner`, and `melos run test` on every PR.

---

## 13. Code Generation

Driven by `build_runner`, orchestrated via a Melos script (`dart run build_runner build
--delete-conflicting-outputs`, filtered to packages that depend on `build_runner`):

- **Freezed** — immutable data classes and sealed-union state (`.freezed.dart`), used in both
  `data/models` and `presentation/states`.
- **json_serializable** — `fromJson`/`toJson` (`.g.dart`), typically paired with Freezed
  (`@freezed` + `part '*.g.dart'`).
- **riverpod_generator** — annotation-based (`@riverpod`) provider generation, available alongside
  hand-written `Notifier` classes.
- **Mason** — the `bricks/feature` brick takes a `feature_name` variable and scaffolds a full feature package:
  barrel file, state, provider, entity, repository (interface + impl), usecase, model, datasource, and a starter
  `pubspec.yaml` declaring `flutter_riverpod` + `freezed_annotation`. Run it whenever adding a new business
  domain to keep the Clean Architecture layout consistent.

---

## 14. Naming / Coding Conventions

- Every package has its own `analysis_options.yaml` (typically just `include: package:flutter_lints/flutter.yaml`).
  A root Melos `analyze` script runs `dart analyze --fatal-infos` across all packages.
- `dart format --set-exit-if-changed` enforced via a Melos `format` script (with a `format:fix` variant).
- File naming: `snake_case.dart`; class naming: `PascalCase`.
- Freezed abstract classes named `XxxModel` / `XxxResponse` / `XxxRequest`, with generated private impl `_Xxx`.
- JSON field mapping uses `@JsonKey(name: 'snake_case_field')` to bridge an API's snake_case with Dart's
  camelCase.
- Barrel files (`<package_name>.dart`) at each package root re-export its public API surface — internal
  `data`/`domain` details stay unexported.
- Pick one language for comments/docs and apply it consistently across the codebase (the reference project mixed
  French comments with English identifiers — fine if intentional, but decide explicitly for a new project).

---

## 15. Environment / Config Management

Immature in the reference project — **treat these as required improvements for a new project**, not optional:

- Don't hardcode the API base URL or Stripe publishable key directly in source. Use `--dart-define` /
  `--dart-define-from-file` or Flutter flavors, with a config object (e.g. `AppConfig`) that reads them at
  startup.
- Set up Flutter **flavors** (dev/staging/prod) from the start if multiple environments are expected.
- Keep secrets out of the repo; only commit `.env.example`/placeholders.
- Localization: use the `flutter gen-l10n` pipeline (ARB files + `l10n.yaml`) from day one, and decide the
  supported-locale list explicitly rather than hardcoding a single `Locale`.

---

## 16. Recommendations Checklist for a New Project

- [ ] Keep the `apps/` (deployable) + `packages/` (shared) + `packages/features/*` (Clean Architecture per
      domain) monorepo layout — it scales well and keeps the app shell thin.
- [ ] Use the Mason `feature` brick pattern to scaffold new features consistently (`data/domain/presentation`).
- [ ] Standardize state management on Riverpod + Freezed sealed states from the start.
- [ ] Centralize the API client/provider in `networking`/`core` — don't let each feature redeclare its own.
- [ ] Wire up real auth-gating in the router's `redirect` hook, don't just define an unused allowlist.
- [ ] Add environment/flavor-based config management before hardcoding any base URL or API key.
- [ ] Set up CI (analyze, format, build_runner, test) before the codebase grows.
- [ ] Write real unit/widget tests per feature package, not just scaffold smoke tests.
- [ ] Decide upfront which small features get a full package vs. stay app-local, and apply it consistently.
