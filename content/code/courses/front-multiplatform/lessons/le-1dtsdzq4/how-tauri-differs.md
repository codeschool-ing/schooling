---
title: The WebView the system already has
version: 1
---

**Tauri makes the same kind of app as Electron, a desktop window with your web app in it, out of two
different parts.** Where Electron carries its own Chromium, Tauri uses the WebView the operating system
already has. Where Electron's main process is Node.js, Tauri's core is a program written in Rust, compiled
for each system.

| | Electron | Tauri |
|---|---|---|
| the engine that draws the page | its own Chromium, in every app | the system's: WebView2 on Windows, WebKit on macOS, WebKitGTK on Linux |
| the part that may touch the computer | the main process, in Node.js | the core, in Rust |
| the door between the two | the preload and IPC | commands, called with `invoke` |
| what the person downloads | the app plus a browser and a runtime | the app, and a small native program |

**What the system's WebView buys is size and memory**: there is no browser in the download, and the
operating system keeps its WebView up to date, security fixes included, which was the last row of
lesson 11's checklist. **What it costs is sameness.** WebView2 is Chromium, WebKit on a Mac is Safari's
engine, and WebKitGTK is another build of WebKit, so the planner runs in three engines, of three ages, as a
website does. A CSS feature or a web API that works in one may not in another, and the app has to be
tried on each system it ships to.

The other cost is Rust. **The planner's own code stays TypeScript**, and most Tauri apps need only a few
lines of Rust, for the commands the page calls. But those lines are Rust, compiled by Rust's toolchain,
which the next section installs, and an error in them is a Rust compiler error. Tauri 2 also builds for
Android and iOS, with the same core; this course uses it only on the desktop, because lessons 2 to 6
already took the planner to the phone with Capacitor.
