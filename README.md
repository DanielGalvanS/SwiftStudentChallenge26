# Musiora
### Swift Student Challenge 2026

> *Your brain is wired to sync your movements together. Musicians spend years learning to break that.*

---

## What is it?

Musiora is an interactive rhythm game that teaches **motor independence** — the ability to move different parts of your body to different rhythms simultaneously.

It's the core skill that separates a beginner from a professional musician. Drummers train it for years. Pianists too. Musiora lets you experience it in minutes, using only your body and the front camera.

---

## How it works

The app uses the camera to detect your body in real time. No controllers, no accessories — just you.

You progress through four acts, each adding a new body part to the rhythm:

| Act | Body part | Role |
|-----|-----------|------|
| 1 — The Pulse | Knees | Bass drum |
| 2 — The Snare | Left hand | Snare drum |
| 3 — The Cymbal | Right hand | Cymbal |
| 4 — The Accent | Head | Accent on beat 1 |

Each act introduces the new movement on top of what you already learned. By the end, all four parts are playing at the same time — each to its own rhythm.

A rhythm guide at the bottom shows the beat in real time. Hit the right part at the right moment to advance.

---

## Results

After finishing, you get a breakdown of your accuracy per body part.

Two scoring modes:
- **Normal** — measures precision: of all the times you moved, how many were on beat
- **Strict** — also penalizes missed beats

---

## Technologies

- **SwiftUI** — UI and animations
- **Vision** — real-time human body pose detection (`VNHumanBodyPoseObservation`)
- **AVFoundation** — multi-track audio engine with synchronized looping
- **Swift Concurrency** — async camera stream, beat clock, phase transitions
- **GarageBand** — all music tracks composed and exported as audio loops

---

## Requirements

- iOS 18.0+
- iPad or iPhone with front camera
- Camera permission required

---

## Running the project

Open `Musiora.swiftpm` in Swift Playgrounds 4 or Xcode 16+.

---

## License

MIT — see [LICENSE](LICENSE)
