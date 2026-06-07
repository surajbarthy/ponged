# Ponged — Project Context (session snapshot)

**Last updated:** 2026-05-21  
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

1. **2×3 grid** on sender and receiver (3 columns × 2 rows). Display coords: **x = −1, 0, 1**; **row 0 = ear level**, **row 1 = elevated**.
2. **No bounce.** Path is **`start_cell` → `end_cell` on the sender’s grid only** (receiver uses same cell indices to catch).
3. **Looping audio:** preset repeats with **`loop_gap` = 0.5 s** between plays (discrete waypoint plays during travel, not continuous pan).
4. **Travel:** Receiver hears **5–7 discrete plays** at interpolated 3D waypoints from start → end (extra loops when row changes).
5. **Catch:** Receiver **orients phone** (gyro) to align with **`end_cell`**; tap any cell to preview position after arrival; tap green end cell also catches (debug).
6. **Pass-and-play** for V1 (no auth/push/backend initially).

### Tunable parameters (`MechanicConfig.swift`)

| Key | Default |
|-----|---------|
| `loop_gap` | 0.5 s |
| `travel_duration` | 10 s (fiction; travel is waypoint-based) |
| `imaginary_distance` | 50 ft |
| `grid_columns` / `grid_rows` | 3 / **2** |
| `catch_hold_duration` | 0.3 s |
| `catch_angle_tolerance` | 15° |
| `sender_preview_loops` | **1** |
| `receiver_min_loops` | **5** |
| `vertical_travel_min_loops` | **7** |
| `spatial_radius` | **1.0 m** (fixed — direction only, no volume falloff) |
| `max_azimuth_radians` / `max_elevation_radians` | **π/2** each |
| `travel_curve` | linear |
| `min_receiver_open_delay` | 0 s |

### V1 screens

Home → Pick sound (**Hee Hee!** / **Aaow!**) → Throw → Handoff → Receive → Success → return loop.

**Debug:** Home → **HRTF Spatial Test** (3×3 grid, display −1…1 on both axes; not used in game flow).

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
| Audio | `AVAudioEngine` + `AVAudioEnvironmentNode` (HRTF) or stereo-pan fallback; bundled **MP3** presets |
| Motion | CoreMotion (gyro catch + throw V1b) |
| State | `@StateObject` shared `SpatialAudioEngine` in `ContentView`; `GameSession` for pass-and-play |
| App path | `ios/Ponged/` |

**Not V1:** Expo, old web `index.html` canvas pong (legacy, ignore for V1).

---

## Spatial audio (2026-05-21 session)

### Architecture

- **Single shared** `SpatialAudioEngine` via `.environmentObject` (avoids multiple engines fighting).
- **HRTF mode (default):** `player → AVAudioEnvironmentNode → mainMixer`
  - `player.sourceMode = .pointSource`
  - `player.renderingAlgorithm = .HRTFHQ`
  - Stereo MP3s **downmixed to mono** at load (environment only spatializes mono).
- **Stereo Pan fallback:** `player → mixer → mainMixer` (L/R only; no height).
- **Playback:** `scheduleBuffer` on mono PCM buffers; do **not** call `player.stop()` before schedule (HRTF crash).
- **Travel:** discrete waypoint plays; position set before each buffer.

### Position mapping (`SpatialTable`)

- Display grid coords → **direction on a 1 m sphere** (constant loudness, no distance attenuation tricks).
- `(0,0)` → 1 m in front; `y ±1` → ±90° elevation (below / overhead).
- Game uses **2 rows**; debug test uses **3 rows** (−1, 0, 1 on y).

### Key files

| File | Role |
|------|------|
| `Audio/SpatialAudioEngine.swift` | Engine, HRTF graph, mono preload, travel |
| `Models/CellPanPosition.swift` | `SpatialTable` 3D mapping |
| `Models/MechanicConfig.swift` | Tunables |
| `Views/SpatialDebugView.swift` | 3×3 HRTF test grid |
| `Resources/Sounds/` | `hee_hee.mp3`, `aaow.mp3` |

### Open / next session

- **Validate HRTF height on physical iPhone + headphones** (speaker won’t work).
- User still struggled to **differentiate position** — volume falloff from `y=20` meters was fixed via sphere mapping; retest needed.
- Consider `.automatic` rendering algorithm or **PHASE** if AVAudio HRTF remains weak.
- Paired playtesting per `V1_PLAN.md` validation table not started.

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
5. iOS V1 scaffolded: SwiftUI screens, synthesized SFX, pass-and-play loop.
6. **2026-05-21:** Real MP3s, HRTF spatial engine, 2×3 game grid, 3×3 debug grid, mono downmix, fixed-radius sphere positioning, receiver cell-tap preview. Paused before HRTF height validation on device.

---

## Files to read first in a new session

1. `V1_PLAN.md`
2. `docs/CONTEXT.md` (this file)
3. `NORTHSTAR_PLAN.md` (reference only — do not edit)
4. After iOS build: `ios/Ponged/` and root `README.md`
