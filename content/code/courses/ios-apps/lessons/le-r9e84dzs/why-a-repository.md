---
title: Why a repository sits between the screens and the network
version: 1
---

**A screen that talks to the network directly can show nothing when the network is gone.** Lesson
12's `CourseListView` asked `APIClient` for the courses every time it appeared, so on a train with no
signal it drew the offline message, over a planner whose courses had not changed since the morning.
The phone had seen them. Nothing had kept them.

The fix is one object that every screen asks instead, and that decides where the answer comes from.
That object is called a **repository**, and the word is old: it means the one place that knows how
the app's data is stored and fetched, so that nothing else has to. `mobile-offline` takes the idea
further for all three platforms, in lesson 7 (writing locally first) and lesson 8 (the queue of
writes waiting for the network); this lesson builds the first working version of it in Swift.

## What it promises the screens

Three things, and each one is a test in section 06:

- **a read never waits for the network.** The repository answers with what the device has, at once,
  and a refresh from the server updates it when it can;
- **a write lands on the device first.** A session added on the train is in the plan immediately,
  marked as waiting, and is sent when the network comes back;
- **every failure is reported, and none of them loses data.** The screen is told the server could not
  be reached, or that it refused something; the device's plan is never emptied because a request
  failed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l14-layers\" aria-label=\"Layers from top to bottom. At the top, the screens: CourseListView, CourseDetailView and WeekView, which need a Mac. They read PlannerModel, also on a Mac. Below, inside a region marked runs anywhere, the PlannerRepository actor. It answers the model with the plan at once, and talks to two protocols below it: PlanSource, on the left, implemented by APIClient and by the tests&#x27; FakeSource, which it calls to refresh and sync; and PlanStore, on the right, implemented by FileStore, which it calls to load and save.\"><defs><marker id=\"l14-layers-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l14-layers-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-layers-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l14-layers-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"120\" y=\"14\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"195\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CourseListView</text><rect x=\"290\" y=\"14\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"365\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CourseDetailView</text><rect x=\"460\" y=\"14\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"535\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">WeekView</text><text x=\"60\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a Mac</text><rect x=\"260\" y=\"78\" width=\"200\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PlannerModel</text><path d=\"M195 50 L300 76\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M365 50 L360 76\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M535 50 L420 76\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><rect x=\"16\" y=\"128\" width=\"688\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"80\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">runs anywhere</text><rect x=\"240\" y=\"150\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">PlannerRepository</text><text x=\"360\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">an actor</text><path d=\"M360 148 L360 114\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l14-layers-ah-phosphor)\"></path><text x=\"372\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">plan, at once</text><rect x=\"60\" y=\"240\" width=\"230\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"175\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">PlanSource</text><text x=\"175\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">APIClient</text><text x=\"175\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">FakeSource, in the tests</text><rect x=\"430\" y=\"240\" width=\"230\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">PlanStore</text><text x=\"545\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">FileStore</text><text x=\"545\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one JSON file</text><path d=\"M300 196 L200 238\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l14-layers-ah-amber)\"></path><text x=\"206\" y=\"214\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">refresh, sync</text><path d=\"M420 196 L520 238\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l14-layers-ah-amber)\"></path><text x=\"514\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">load, save</text></svg>", "caption": "The screens see one object. The repository sees two protocols, and everything inside the dashed line runs, and is tested, without a Mac."}
```

## What it is made of

The repository holds two things and knows them only by what they can do:

- a **source**, where data comes from when the app is online. In this course it is lesson 12's
  `APIClient`; in a test, section 06's fake;
- a **store**, where data stays on the device. In this lesson it is one JSON file, which runs on Linux
  and is enough to make every promise above true. On a Mac, lesson 13's SwiftData model is the other
  store that could stand behind the same protocol, and the screens would not notice the change.

**Both are protocols, and that is the point of the arrangement.** The repository is written against
`PlanSource` and `PlanStore`, so it can be tested with a server that goes offline on command and a
store that lives in a temporary file. None of this lesson's tests needs a network.
