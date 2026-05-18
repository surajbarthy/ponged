# Ponged iOS (V1)

Native SwiftUI build for the V1 core mechanic test.

## Open & run

1. Install **Xcode** from the Mac App Store (Command Line Tools alone are not enough).
2. Open `Ponged.xcodeproj` in this folder.
3. Select your **iPhone** as the run destination (recommended for gyro catch).
4. Set **Signing & Capabilities** → Team to your Apple ID.
5. Press **Run** (⌘R).

## Simulator

Works for UI flow; **gyro throw/catch** needs a physical device.

## Config

All tunables live in `Ponged/Models/MechanicConfig.swift` (see repo `V1_PLAN.md`).

## Default input mode

- **V1a (default):** Tap start cell → tap end cell → Send ping.
- **V1b:** Enable “Gyro throw” toggle on Throw screen.

## Stubbed

- SFX are **synthesized tones** (not final comic assets).
- Pass-and-play only (no network).
