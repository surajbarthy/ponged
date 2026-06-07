# Ponged iOS (V1)

Native SwiftUI build for the V1 core mechanic test.

## Open & run

1. Install **Xcode** from the Mac App Store (Command Line Tools alone are not enough).
2. Open `Ponged.xcodeproj` in this folder.
3. Select your **iPhone** as the run destination (recommended for gyro + spatial audio).
4. Set **Signing & Capabilities** → Team to your Apple ID.
5. Press **Run** (⌘R).

## Simulator

Works for UI flow; **gyro throw/catch** and **HRTF spatial audio** need a physical device + **headphones**.

## Config

All tunables live in `Ponged/Models/MechanicConfig.swift` (see repo `V1_PLAN.md`).

## Audio

- Presets: `Resources/Sounds/hee_hee.mp3`, `aaow.mp3` (stereo → mono at load for HRTF).
- Shared `SpatialAudioEngine` in `ContentView` (`.environmentObject`).
- **HRTF Spatial Test** on Home screen: 3×3 grid, mode picker (HRTF vs Stereo Pan), live position debug.

## Grid

- **Game:** 2×3 (display x: −1,0,1 · rows 0 = ear, 1 = elevated).
- **Debug test:** 3×3 (display x,y: −1…1).

## Default input mode

- **V1a (default):** Tap start cell → tap end cell → Send ping.
- **V1b:** Enable “Gyro throw” toggle on Throw screen.

## Pass-and-play

No network. Hand off phone between sender and receiver.
