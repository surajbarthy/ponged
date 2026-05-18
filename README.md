# Ponged

Playful async sound hits between close friends — throw, hear spatially, catch, throw back.

## Docs

| Document | Purpose |
|----------|---------|
| [V1_PLAN.md](V1_PLAN.md) | **Active** — iOS V1 core mechanic spec and tunable parameters |
| [NORTHSTAR_PLAN.md](NORTHSTAR_PLAN.md) | **Frozen** — long-term product and systems vision (do not edit) |
| [docs/CONTEXT.md](docs/CONTEXT.md) | Session context for resuming work in a new chat |

## Status

**iOS V1** implemented under `ios/Ponged/` (SwiftUI + AVAudioEngine + CoreMotion).

## Run

1. Open [`ios/Ponged/Ponged.xcodeproj`](ios/Ponged/Ponged.xcodeproj) in **Xcode** (full app required).
2. Set your signing **Team**, then run on a **physical iPhone** for gyro catch.

See [`ios/Ponged/README.md`](ios/Ponged/README.md) for details.

## Legacy

`index.html` is an unrelated early web canvas demo; not part of V1.
