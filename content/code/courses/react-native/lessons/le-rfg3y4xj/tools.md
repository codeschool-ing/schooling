---
title: Logs and React Native DevTools
version: 1
---

The rest of debugging is looking at a running app, and three tools do most of it.

## Logs

- **`console.log` in development goes to Metro's terminal**, and also to DevTools' console. In release it
  goes to the platform's log, where nobody reads it unless they go looking.
- **On Android, that log is `logcat`**, read with `adb logcat` from the platform tools of lesson 3, with a
  phone or an emulator attached. React Native's JavaScript messages carry the tag `ReactNativeJS`, so
  `adb logcat ReactNativeJS:V *:S` shows those and silences the rest. A native crash, Kotlin's own, appears
  there as an `AndroidRuntime` stack trace.
- **On iOS, the Console app** on a Mac shows a connected phone's log, and Xcode shows a simulator's.

*None of the three was run for this course: each needs a phone, an emulator or a Mac.*

## React Native DevTools

**Press `j` in the terminal where Metro runs**, with a development build connected, and React Native
DevTools opens: Chrome's developer tools, connected to Hermes on the phone. It has a console, breakpoints and
a step-through debugger for your TypeScript, mapped through the same source maps as the last section, a
**Components** panel that shows the tree and each component's props and state, and a **Profiler** that
records which components rendered and why, which lesson 19 uses. *This course did not open it, for the same
reason: there was no development build running on a device.*

**What you can open is the web build in a browser**, whose developer tools do the same for everything that
is not native: breakpoints in your code, the network panel showing every request the planner makes, and
React's own DevTools extension for the component tree.

## Crash reporting

A released app needs to tell its team when it fails, because the people it fails for will not. Services
such as Sentry and Bugsnag have React Native libraries that catch JavaScript errors, native crashes and
error boundaries' reports, and upload the source maps at build time, so each report arrives already
mapped to a file and a line. The planner's boundary has the place for that call, in `componentDidCatch`.
