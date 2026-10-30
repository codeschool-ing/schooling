---
title: Frames, slow and frozen
version: 1
---

**Smooth scrolling means a new frame on every refresh of the screen, and a frame that misses its
deadline is visible as a stutter.** At 60 frames per second, each frame has about **16 milliseconds**;
on a 120 Hz screen, about 8. *Read from Android's documentation on slow rendering, October 2026.*

## Two kinds of bad frame

| | definition | what a person feels |
|---|---|---|
| **slow frame** | took longer than 16 ms to render | a stutter in a scroll or an animation |
| **frozen frame** | took longer than **700 ms** to render | the app stopped for a moment, and the touch seemed ignored |

Android's documentation says that **no frame should ever take longer than 700 ms**, and tracks frozen
frames separately from slow ones. A frozen frame is a short hang, the same failure as lesson 14's
ANR at a smaller scale, usually with the same cause: work on the main thread.

## How they are measured

- **Android vitals** reports the share of sessions with too many slow or frozen frames, from
  people's phones.
- **Android's JankStats** library and the **Macrobenchmark** tests measure frames in your own app and
  in your lab.
- On iOS, the **hitch rate** in Xcode's Organizer and in MetricKit, and Instruments on a Mac.
- In React Native, the same native numbers, plus a JavaScript thread that drops frames of its own
  when it is busy, because animations driven from JavaScript wait for it.

## The planner's slow frame

The week view draws one row per session. A row that formats its date by creating a new date
formatter each time spends milliseconds on every row; scroll a list of two hundred sessions and the
frames go slow. The cure is the same on every platform: make the formatter once and reuse it, and
compute the week's total once, when the data changes, not on every frame that draws it. **Work done
per frame is multiplied by the frame rate**; work done per change is not.
