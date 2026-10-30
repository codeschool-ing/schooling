---
title: Before you write one
version: 1
---

**A plugin of your own is native code you now maintain on two platforms**, through every Capacitor
release and every Android and iOS version after it. That is a real cost, and most of the time it can
be avoided. The planner needs one thing the official plugins do not give it: during a study session,
**the screen should stay on**, the way a recipe app or a navigation app keeps it on. Before writing
that, the questions come in this order:

1. **Does the web already do it?** Many things a phone does are a web API now, and some work in the
   WebView with no plugin, the clipboard for one. Check that the WebView supports it, on both systems,
   and not only your desktop browser: a WebView is not the browser it is built from, and an API a
   browser has can be missing or limited in the WebView. The Screen Wake Lock API is the example this
   lesson meets: Chromium has it, Safari gained it years later, and in an app it has conditions of its
   own.
2. **Is there an official plugin?** Capacitor's own plugins, `@capacitor/…`, are maintained with
   Capacitor and move to each new major version with it.
3. **Is there a community one?** The Capacitor Community organisation on GitHub keeps plugins under
   `@capacitor-community/…`, and individuals publish many more. Read the last release date, the open
   issues and the platforms it claims before installing one: a plugin stuck on an old major version of
   Capacitor holds your whole app back with it.
4. **Then write one**, as small as the job allows.

For keeping the screen on, the answer to the third question is yes: community plugins exist. This
lesson writes one anyway, because it is the smallest real case there is, three short methods, and
because every part of a plugin shows in it. **Your own app's reason to write one will be different**:
a device the company makes, a native SDK a partner gives you, a system feature nobody has wrapped.

## What a plugin is, from the outside

From the planner's side, nothing changes from lesson 4: an npm package with an interface, imported and
called. From the inside it is the three implementations of that interface, and a name that joins
them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l05-plugin\" aria-label=\"One plugin from the inside. The planner imports the KeepAwake interface from src/definitions.ts. registerPlugin('KeepAwake') in src/index.ts joins it, by that name, to three implementations: src/web.ts for the browser, which uses the Screen Wake Lock API; KeepAwakePlugin.kt for Android, which sets FLAG_KEEP_SCREEN_ON on the window; and KeepAwakePlugin.swift for iOS, which sets isIdleTimerDisabled. Capacitor calls the one for the platform the app runs on.\"><defs><marker id=\"l05-plugin-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"56.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the planner calls</text><text x=\"105.0\" y=\"69.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">KeepAwake.keepAwake()</text><rect x=\"220\" y=\"40\" width=\"160\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"56.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">src/definitions.ts:</text><text x=\"300.0\" y=\"69.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the interface</text><rect x=\"410\" y=\"40\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"495.0\" y=\"56.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">registerPlugin(\"KeepAwake\")</text><text x=\"495.0\" y=\"69.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">in src/index.ts</text><path d=\"M190 63 L220 63\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-plugin-ah-paper-dim)\"></path><path d=\"M380 63 L410 63\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-plugin-ah-paper-dim)\"></path><rect x=\"60\" y=\"140\" width=\"180\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"156.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">web: src/web.ts</text><text x=\"150.0\" y=\"169.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Screen Wake Lock API</text><rect x=\"270\" y=\"140\" width=\"180\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"156.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Android: Kotlin</text><text x=\"360.0\" y=\"169.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">FLAG_KEEP_SCREEN_ON</text><rect x=\"480\" y=\"140\" width=\"180\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"156.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">iOS: Swift</text><text x=\"570.0\" y=\"169.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">isIdleTimerDisabled</text><path d=\"M495 86 L150 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-plugin-ah-paper-dim)\"></path><path d=\"M495 86 L360 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-plugin-ah-paper-dim)\"></path><path d=\"M495 86 L570 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-plugin-ah-paper-dim)\"></path><text x=\"360\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">the same name, and the same method names, on all three sides</text></svg>", "caption": "The planner sees one interface. Behind it are three programs in three languages, and only the name joins them."}
```

**The name is the join.** `registerPlugin("KeepAwake")` in TypeScript, `@CapacitorPlugin(name =
"KeepAwake")` in Kotlin and `jsName = "KeepAwake"` in Swift must be the same string, and so must the
method names on all three sides. Nothing checks it before the app runs: a method spelt differently on
one side is an error the first time it is called, on that platform only.
