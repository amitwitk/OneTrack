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
