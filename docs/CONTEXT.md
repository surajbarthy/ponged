# Ponged — Project Context (session snapshot)

**Last updated:** 2026-05-17  
**Repo:** https://github.com/surajbarthy/ponged  
**Local path:** `/Users/surajbarthy/ponged`

Use this file to resume after a fresh chat or machine. **Do not edit `NORTHSTAR_PLAN.md`** — it is frozen.

---

## What we're building

**Ponged** is a mobile-first social toy: send a short comic sound “hit” to a close friend; they experience it spatially and catch it by moving their phone; they throw back. Lower pressure than texting; more embodied than reactions.

**Current phase:** **V1 — core mechanic test** (not full product).  
**Next implementation:** **Native iOS** — SwiftUI + AVAudioEngine + CoreMotion.

---

## Plan documents

| File | Role |
|------|------|
| `NORTHSTAR_PLAN.md` | **Frozen** — full storyboard (12 panels), architecture options, production MVP, data model. Do not overwrite. |
| `V1_PLAN.md` | **Active** — what to build now. Includes **tunable parameters table**. |
| `docs/CONTEXT.md` | This file — session history and decisions. |

Cursor plan copies may live under `~/.cursor/plans/` (`ponged_northstar_plan.md`, `ponged_v1_plan.md`, `ponged_mvp_system_plan_f6b9c389.plan.md`).

---

## V1 core mechanic (latest)

1. **3×3 vertical grid** on sender and receiver.
2. **No bounce.** Path is **`start_cell` → `end_cell` on the sender’s grid only** (receiver uses same cell indices to catch).
3. **Looping audio:** preset repeats with **`loop_gap` = 0.5 s** between plays.
4. **Travel:** When receiver opens receive screen, sound moves slowly sender → receiver over **`travel_duration` = 10 s** across fictional **`imaginary_distance` = 50 ft** (`travel_speed` = 5 ft/s).
5. **Catch:** Receiver **orients phone** (gyro) to align with **`end_cell`** (tap is debug fallback only).
6. **Pass-and-play** for V1 (no auth/push/backend initially).

### Tunable parameters (edit in `V1_PLAN.md` → implement in `MechanicConfig.swift`)

| Key | Default |
|-----|---------|
| `loop_gap` | 0.5 s |
| `travel_duration` | 10 s |
| `imaginary_distance` | 50 ft |
| `travel_speed` | 5 ft/s (derived) |
| `grid_columns` / `grid_rows` | 3 |
| `catch_hold_duration` | 0.3 s |
| `catch_angle_tolerance` | 15° |
| `sender_preview_loops` | 3 |
| `travel_curve` | linear |
| `min_receiver_open_delay` | 0 s |

### V1 screens

Home → Pick sound (POW/ZAP/CRASH) → Throw → Handoff → Receive → Success → return loop.

### Throw input tiers

- **V1a:** Tap start cell, tap end cell (build first).
- **V1b:** Gyro throw maps start/end.

### Explicitly OUT of V1

Auth, friends, push, record-your-own, bounces, full 12-panel polish, Firestore until pass-and-play validates, true binaural/AR.

### V1 success criteria

- Smile test ≥4/5
- ≥50% unprompted return throw (round 2+)
- ≥60% catch within 3 tries
- Travel feels slow / tense (qualitative)

---

## Storyboard (northstar UX reference)

12-panel flow: Splash → Friends → Select friend → Comic presets → Record (later) → Select sound → Throw onboarding → Throw in space → “A HAS PINGED YOU” → Receive spatial + hit → SUCCESSFUL HIT → Return prompts.

Northstar uses **“ping”** (notify) and **“throw”** (send). V1 simplifies visuals but keeps grid + spatial + catch.

**Northstar architecture note:** MVP does **not** need a live shared 3D room — sender encodes path; receiver **replays** locally.

---

## Architecture decisions (northstar, for later)

- **V1:** No backend; optional Firestore single `pings` collection after mechanic validates.
- **Production (northstar):** BaaS first → API + queue at scale.
- **Entities (northstar):** User, Friendship, SoundPayload, Interaction, Thread, Device.

---

## Stack decision for implementation

**Chosen for V1:** **Swift / SwiftUI**

| Layer | Technology |
|-------|------------|
| UI | SwiftUI, NavigationStack |
| Audio | AVAudioEngine, per-cell pan, ~60fps interpolation during travel |
| Motion | CoreMotion (gyro catch + throw V1b) |
| State | Observable `GameSession`, pass-and-play `Ping` in memory |
| App path | `ios/Ponged/` (to be created by agent) |

**Not V1:** Expo, old web `index.html` canvas pong (legacy, ignore for V1).

---

## Agent execution (next step)

User runs **single-shot Agent prompt** to build full iOS V1 without stopping. Requirements:

- `MechanicConfig.swift`, `SpatialAudioEngine`, `Grid3x3View`, 5 screens, pass-and-play
- `xcodebuild` must pass
- Do not edit `NORTHSTAR_PLAN.md`

If agent stops: `Continue. Assume yes to all permissions. Finish remaining items from V1_PLAN.`

**Gyro:** Test on a **physical iPhone**; simulator is limited for catch.

---

## Repo history (planning session)

1. Empty GitHub repo `surajbarthy/ponged`; planning at `/Users/surajbarthy/ponged`.
2. Northstar system plan → `NORTHSTAR_PLAN.md` (frozen).
3. V1 split as minimal mechanic test; iterations:
   - Storyboard 12-panel alignment
   - 3×3 grid, bounce → **no bounce**, sender start/end, loop 0.5s, 10s/50ft travel, gyro catch
   - Tunable parameters table in `V1_PLAN.md`
4. Stack: **Swift** (not Expo).
5. This commit: docs + git push before iOS one-shot build.

---

## Chat arc (summary)

1. Northstar product/system plan from founding-engineer prompt.
2. Storyboard integrated as canonical UX.
3. Northstar preserved separately; V1 scoped for mechanic-only test.
4. Core mechanic refined: grid, no bounce, looping sound, slow travel, phone-orientation catch.
5. Build advice: Swift + phased or one-shot agent prompts.
6. User requested CONTEXT.md + git push before iOS build → this commit.

---

## Files to read first in a new session

1. `V1_PLAN.md`
2. `docs/CONTEXT.md` (this file)
3. `NORTHSTAR_PLAN.md` (reference only — do not edit)
4. After iOS build: `ios/Ponged/` and root `README.md`
