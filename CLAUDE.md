# OneTrack

A personal all-in-one fitness and health tracking iOS app built with Swift/SwiftUI. Replaces Cal AI, Apple Health, Excel sheets, and iPhone Notes with a single unified app.

## Features

### 1. Workout Tracking
- User-created workout plans with custom exercises, sets, and reps
- Exercise picker with built-in database (36 exercises across 6 categories)
- Log workout sessions: record actual sets, reps, and weight per exercise
- Stepper-based input (no keyboard) — designed for gym use with sweaty hands
- Track progressive overload — compare current session to previous sessions
- Rest timer with configurable duration (auto-starts on set completion)
- Resume interrupted workouts
- History of all completed workouts

### 2. Calorie & Meal Tracking
- **Primary input:** text-based ingredient entry (e.g. "3 eggs, 4 tomatoes, 1 onion")
- **Nutrition lookup:** embedded USDA Foundation Foods + SR Legacy database (~8,100 foods, ~1.1 MB JSON) for instant offline calorie/macro resolution
- **API fallback:** USDA FoodData Central API (free, 1,000 req/hr) for foods not in the local DB
- **Barcode scanning (future):** Open Food Facts API (free, no key) for packaged/branded foods
- Daily calorie budget with remaining calories display
- Macros per meal: calories, protein, carbs, fat

### 3. Weight & Body Measurements
- Log weight, waist width, muscle measurements (biceps, chest, etc.)
- Read weight from HealthKit if available (Cal AI and other apps sync weight there)
- Historical trends: weekly, monthly, yearly

### 4. Activity
- Pull from Apple HealthKit: steps, active calories, workouts
- No manual entry needed — reads from iPhone Fitness / Apple Watch data

### 5. Dashboard
- Stat cards: weekly workout count, volume, total workouts, streak
- Recent workout history
- At-a-glance daily summary

## Tech Stack

- **Language:** Swift 6
- **UI:** SwiftUI (iOS 18+, NavigationStack, @Observable)
- **Storage:** SwiftData with iCloud CloudKit sync (automatic backup + multi-device)
- **Health data:** HealthKit (read: steps, weight, active calories, workouts)
- **Nutrition data:** USDA Foundation Foods + SR Legacy JSON (bundled), USDA FoodData Central API (fallback)
- **Charts:** Swift Charts
- **Target:** iPhone only

## Architecture

- **No custom backend** — SwiftData on-device + iCloud CloudKit for sync/backup
- **No authentication** — single user, personal tool (iCloud identity via Apple ID)
- **No network required** for core features (workout logging, local food lookup, measurements)
- **Network used for** iCloud sync, USDA API fallback, HealthKit sync

## Data Storage

- **SwiftData** stores all data locally on-device in SQLite
- **CloudKit** automatically syncs data to iCloud (requires paid Apple Developer account, $99/year)
- **Offline-first** — app works fully offline, syncs when connectivity is available
- Data persists across app re-deploys and survives device resets (via iCloud backup)

## Deployment

- Xcode 16.4 + Apple Developer account + USB-C cable (or Wi-Fi debugging)
- Deploy directly to personal iPhone — no App Store
- Free account: re-deploy every 7 days (no CloudKit sync)
- Paid account ($99/year): 1-year signing + CloudKit sync enabled

## Design Principles

- **Minimal friction:** fewest possible taps to log data
- **Offline-first:** core features work without internet
- **Gym-friendly:** stepper inputs, large tap targets, rest timer — no keyboard needed
- **Clean UI:** inspired by Strong/Hevy — simple cards, no flashy colors

## Source Control

- **Repository:** https://github.com/amitwitk/OneTrack (public)
- **Branch protection:** PRs required to merge to `main`, CI must pass
- **CI:** GitHub Actions (`.github/workflows/ci.yml`) — build + test on macOS 15 / Xcode 16.4 / iOS Simulator

## Development Workflow

For each feature or bug fix:

1. **Pick an issue** from the [project board](https://github.com/users/amitwitk/projects/6) or [GitHub Issues](https://github.com/amitwitk/OneTrack/issues) — labeled by domain (`workout`, `nutrition`, `body`, `activity`, `dashboard`)
2. **Move to In Progress** — assign yourself and move the issue to "In Progress" on the [project board](https://github.com/users/amitwitk/projects/6)
3. **Pull latest main** — `git checkout main && git pull origin main`
4. **Create a branch** from `main` — `feat/<name>` or `fix/<name>`
5. **Plan** the implementation (identify models, views, and dependencies)
6. **Implement** with clean, testable code — extract logic into standalone functions/structs for testability
7. **Add tests** — unit tests using Swift Testing framework, in-memory SwiftData containers, aim for coverage on all new logic
8. **Build and test locally** — `xcodebuild test -scheme OneTrack -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO`
9. **Commit and push** — conventional commit messages (`feat:`, `fix:`, `test:`, `refactor:`)
10. **Create PR** — with summary, test plan, and `Closes #N` (ensures issues auto-close on merge)
11. **CI must pass** — GitHub Actions runs build + test automatically
12. **Squash merge** to `main` — keeps history clean
13. **Verify issues closed** — after merge, confirm referenced issues are closed and moved to "Done" on the project board. If not, close and move them manually

## Bug Fix Workflow

When a bug is identified (runtime crash, incorrect behavior, etc.):

1. **Open a GitHub issue** — label with `bug` + domain label, describe the symptom and root cause
2. **Move to In Progress** on the [project board](https://github.com/users/amitwitk/projects/6)
3. **Identify** — read logs/crash traces, locate the root cause in code
4. **Plan** — determine the fix and what test would have caught this
5. **Write a regression test first** — the test must fail without the fix (proves it catches the bug)
6. **Fix the bug** — minimal change to resolve the root cause
7. **Verify test passes** — the regression test now passes with the fix applied
8. **PR must include test coverage** — PRs for bugs are not merged without a test that prevents recurrence
