---
title: What each system lets an app do in the background
version: 1
---

**An app off the screen does not get to decide when it runs.** On a laptop a program in the
background carries on until it finishes. On a phone the system stops it, freezes it or lets it run
at moments it picks, and both platforms tighten these rules in almost every release. The details
differ and the principle does not. **Work that is not for the person looking at the screen runs
when the system says, in a batch with everybody else's.**

Everything below was read in each platform's documentation on 30 October 2026. It changes, so the
courses after the fork read it again for their own release.

## Android: Doze, standby buckets and the work that waits

**Doze is what a phone does when nobody is touching it.** Android's page on Doze and App Standby
describes it: when the device is unplugged, stationary and has its screen off for a while, apps
lose network access, their wake locks are ignored, and their jobs, syncs and ordinary alarms are
put off. Now and then the system opens a short *maintenance window* in which all of that deferred
work runs and the network is available, then closes it again, and the windows grow further apart
the longer the phone lies still. Moving the phone, turning on the screen or plugging in a charger
ends Doze.

**App Standby Buckets rank every app by how recently and how often it is used**, from Android 9.
The bucket decides how often an app's jobs may run and alarms may fire, and the documentation names
five, plus a special bucket for apps installed and never opened:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l15-buckets\" aria-label=\"Android's App Standby Buckets as a ladder, from fewest restrictions to most. Active: the app is in use or was used very recently; minimal restrictions. Working set: in regular use; mild restrictions. Frequent: used often, not daily; stronger restrictions. Rare: not used often; strict restrictions on jobs, alarms and the network. Restricted: uses a lot of resources, or, from Android 13, not opened for 8 days; jobs once a day in a ten-minute batched session. Apart from the ladder, a never bucket for apps installed and never opened.\"><text x=\"30\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">bucket</text><text x=\"180\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">the app is</text><text x=\"470\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">restrictions</text><rect x=\"20\" y=\"34\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">active</text><rect x=\"170\" y=\"34\" width=\"280\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">in use, or used very recently</text><rect x=\"460\" y=\"34\" width=\"240\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">minimal</text><rect x=\"20\" y=\"74\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">working set</text><rect x=\"170\" y=\"74\" width=\"280\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">in regular use</text><rect x=\"460\" y=\"74\" width=\"240\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mild</text><rect x=\"20\" y=\"114\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">frequent</text><rect x=\"170\" y=\"114\" width=\"280\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">used often, not daily</text><rect x=\"460\" y=\"114\" width=\"240\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">stronger</text><rect x=\"20\" y=\"154\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">rare</text><rect x=\"170\" y=\"154\" width=\"280\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">not used often</text><rect x=\"460\" y=\"154\" width=\"240\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">strict: jobs, alarms, network</text><rect x=\"20\" y=\"194\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">restricted</text><rect x=\"170\" y=\"194\" width=\"280\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">heavy on resources, or unopened 8 days</text><rect x=\"460\" y=\"194\" width=\"240\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">jobs once a day, 10 minutes</text><text x=\"710\" y=\"20\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">more restricted ↓</text><text x=\"20\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">and a never bucket, for apps installed and never opened: severe</text></svg>", "caption": "The system moves an app between buckets as it is used, and each manufacturer may set its own criteria. An app cannot choose its bucket; it can only behave well in all of them."}
```

Two lines on that page are worth reading twice. **Every manufacturer may set its own rules for
which bucket an app lands in**, and the advice is not to try to influence it but to behave well in
any of them. And from Android 13, an app the user has not opened for 8 days goes into *restricted*,
where its jobs run once a day in a ten-minute batched session alongside other apps' jobs.

**A foreground service is the one way to keep running in plain view, and it carries a
notification the user can see.** Music, a tracked run, navigation: work the user started
and knows about. From Android 14, an app must declare a *type* for each foreground service,
such as location, media playback, data sync or health, and request the permission that goes with
it. Without them, the system throws an exception when the service starts.

**Everything else goes through WorkManager**, which runs work that has to survive the app closing.
It takes *constraints*: run only on an unmetered network, only while charging, only when the
battery is not low, only when the device is idle. Periodic work exists, and the shortest interval
it accepts is **15 minutes**. Even then, the documentation is careful: the interval is the minimum
time between runs, and the exact moment depends on the constraints and on the system.

## iOS: a few named modes, and tasks at a time the system chooses

**iOS gives an app in the background a short list of things it may do, and suspends it otherwise.**
An app declares the *background modes* it needs in its project, and each one is a specific job:
playing audio, receiving location updates, a voice call, background fetch, background processing.
An app with none of them is suspended shortly after it leaves the screen.

**Deferred work goes through `BGTaskScheduler`, in two kinds.** A `BGAppRefreshTaskRequest` asks
for a short refresh, such as fetching the latest week. A `BGProcessingTaskRequest` asks for a
longer task, minutes rather than seconds, and can require external power and a network connection,
which is what database maintenance or a large upload should ask for. Each task identifier must be
listed in the app's `Info.plist`, and the app registers its handler as it launches.

**And iOS promises nothing about when.** A request carries an `earliestBeginDate`, and Apple's
documentation for it says that the system does not guarantee to launch the task at that date, only
that it will not begin sooner. The system weighs the battery, the network and how the user uses the
app. A task that must run at 08:00 exactly is not a background task on iOS; lesson 17 shows what is.

## React Native borrows both

**A React Native app runs in the same two systems, under the same rules.** It has no background
mechanism of its own: libraries wrap the native ones. Expo's `expo-background-task`, read in its
documentation on the same day, uses WorkManager on Android and `BGTaskScheduler` on iOS. Its tasks
share a single worker, wait at least 15 minutes between runs on Android, and run only when the
battery has enough charge and a network is available. React Native also has *headless JS*, a way
for Android to run JavaScript with no screen, and it obeys the same limits.

| | Android | iOS | React Native |
|---|---|---|---|
| deferred, batched work | WorkManager, with constraints | `BGTaskScheduler`: app refresh or processing | `expo-background-task`, over both |
| shortest repeat | 15 minutes | none promised: the system decides | 15 minutes on Android, the system's choice on iOS |
| running in plain view | a foreground service, with a notification and a declared type | a background mode, such as audio or location | the platform's own, through a library |
| when the user leaves the phone alone | Doze, and the standby bucket | the app is suspended | whichever system it runs on |
