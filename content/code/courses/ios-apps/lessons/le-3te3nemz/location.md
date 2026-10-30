---
title: Location, and the planner that does not need it
version: 1
---

**Location has two levels, and the planner needs neither.** It is in this lesson because "would
location make this nicer?" is a question every app meets, and the answer here shows how to decide.
Nothing in this section was run; it is written from Apple's article *Requesting authorization to
use location services*, read on 30 October 2026.

The two levels, in the article's words:

- **When In Use** "makes location updates available only when someone uses your app", and the
  article calls it "the preferred choice, because it has better privacy and battery life
  implications". The key is `NSLocationWhenInUseUsageDescription`.
- **Always** "makes location updates available at any time, and lets the system launch your app
  quietly to handle some updates". It needs `NSLocationAlwaysAndWhenInUseUsageDescription` as well
  as the first key, and iOS reminds the person later that the app has been using it.

The article is also where the rule about timing comes from: "make authorization requests only when
someone engages a part of your app that requires that data", because a request "immediately at app
launch, or in a part of your app that doesn't clearly use location data" is one the person "might
misinterpret" and deny.

```swift
// Nearby.swift: what asking would look like, if the planner needed it
import CoreLocation

final class Nearby: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    func start() {
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }
}
```

The request returns at once and the answer arrives later, in the delegate, because the person may
take their time with the alert.

## Deciding, for the planner

An idea that comes up: remind people to study when they arrive at the library. It needs **Always**,
the strongest level iOS has, to save somebody setting a time. Lesson 17 already schedules a reminder
at a time the person chose, with no location at all. **A feature that needs a stronger permission
than the problem it solves has to earn it**, and guideline 5.1.1(iii) says the same in Apple's
words: request "access to data relevant to the core functionality of the app". A study planner's
core is the plan, so the planner asks for no location, writes no location key, and has one fewer
alert to explain.
