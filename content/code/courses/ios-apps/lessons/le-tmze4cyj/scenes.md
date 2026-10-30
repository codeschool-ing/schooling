---
title: Scenes: a window, and the views inside it
version: 1
---

**A scene is a piece of the interface whose life the system manages.** On an iPhone the app usually
has one, and it fills the screen. On an iPad the same declaration can produce several at once: two
planner windows side by side, each showing a different course. Apple's documentation for `Scene`
puts it this way: a scene is a container for a view hierarchy, and the system decides when and how
to present it.

The planner declares one kind of scene, a `WindowGroup`:

```swift
WindowGroup {
    CourseListView()
}
```

**A `WindowGroup` is a template, not a window.** The views in its closure are what each window it
creates will contain. On an iPhone there is one such window. On iPadOS, Apple's documentation says,
a person can open more than one window from the group, provided the app's `Info.plist` sets
`UIApplicationSupportsMultipleScenes` to `true` in its scene manifest. **Every window keeps its own
state**: the documentation is explicit that SwiftUI allocates new storage for the `@State` variables
of each window it creates.

That sentence decides where the planner's data may live. If the plan were `@State` inside
`CourseListView`, two iPad windows would hold two plans, and a session added in one would not appear
in the other. Lesson 7 puts the plan in a model created once, in the `App`, so every window reads the
same one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-scenes\" aria-label=\"The PlannerApp value at the top declares one WindowGroup. On an iPhone the group makes one window; on an iPad it makes two windows side by side. Each window holds its own CourseListView with its own state, so two windows showing @State would hold two separate plans.\"><defs><marker id=\"l02-scenes-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l02-scenes-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-scenes-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l02-scenes-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"260\" y=\"16\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">PlannerApp</text><rect x=\"260\" y=\"84\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">WindowGroup</text><path d=\"M360 56 L360 82\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-scenes-ah-wire)\"></path><text x=\"150\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a template</text><rect x=\"30\" y=\"160\" width=\"180\" height=\"110\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">iPhone: one window</text><rect x=\"50\" y=\"196\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CourseListView</text><text x=\"120\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its own @State</text><rect x=\"290\" y=\"160\" width=\"400\" height=\"110\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"490\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">iPad: two windows from the same group</text><rect x=\"310\" y=\"196\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"395\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CourseListView</text><text x=\"395\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its own @State</text><rect x=\"500\" y=\"196\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"585\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CourseListView</text><text x=\"585\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its own @State</text><path d=\"M330 124 L125 158\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-scenes-ah-amber)\"></path><path d=\"M380 124 L395 158\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-scenes-ah-amber)\"></path><path d=\"M420 124 L580 158\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-scenes-ah-amber)\"></path></svg>", "caption": "One declaration, as many windows as the platform allows, and separate @State in each of them."}
```

## The other kinds of scene

SwiftUI provides more scene types than the planner needs, and knowing they exist explains some of
what you will read in other apps:

- `DocumentGroup` opens and saves documents, one window per file, for an app built around files;
- `Settings` is a macOS scene for the settings window;
- `Window` declares a single, unique window, again mostly on macOS.

None of them changes what this course builds. **One `WindowGroup` is the planner's whole `body`**, and
everything else in the course happens in the views inside it. Nothing in this section was run; it is
written from Apple's documentation for `Scene` and `WindowGroup`, read on 30 October 2026.
