---
title: Background URL sessions, transfers the system finishes
version: 1
---

**A background `URLSession` hands the transfer to the system, which carries on with it while the app is
suspended or even after it has been removed from memory.** It is the one way an app can move a large
file without being awake for the whole of it, and it works differently from everything in lesson 12.
This section was written from Apple's documentation for `URLSessionConfiguration.background(withIdentifier:)`
and *Downloading files in the background*, and **was not run**: background sessions belong to Apple's
own implementation, not to the Foundation on Linux.

## What changes

A background session is made from a configuration with an identifier of its own, and its transfers
are **tasks with a delegate**, not `await`ed calls:

```swift
// Exporter.swift
import Foundation

final class Exporter: NSObject, URLSessionDownloadDelegate {
    static let sessionID = "com.example.planner.export"

    lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: Self.sessionID)
        config.isDiscretionary = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    func download(_ url: URL) {
        session.downloadTask(with: url).resume()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        // Move the file out of `location` now: the system deletes it when this returns.
    }
}
```

**The `async` methods of lesson 12 are not the interface here.** An `await` keeps a function waiting
in the app's memory, and a background session exists precisely for the case where the app is not in
memory any more. So the system finishes the transfer, launches the app in the background if it has to,
and calls the delegate. `isDiscretionary` lets the system pick a good moment, Wi-Fi and power, for a
transfer that is not urgent.

SwiftUI has a task type for the relaunch, `.backgroundTask(.urlSession(Exporter.sessionID))`, where the
app recreates the session with the same identifier so the system can deliver the events it kept.

## Whether the planner needs one

**Not for its sessions.** Each is a few dozen bytes, a background session is built for files, and
section 07's ordinary requests inside an app refresh task are the right size for the job. The export
from section 04 is where a planner would use one: the app asks the server for a year of study as a
file, the person closes the app, and the file is there when they come back.
