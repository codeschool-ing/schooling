---
title: Navigation is a library, and why
version: 1
---

**React Native has no navigation built in.** On the web the browser keeps a history and the address bar
says where you are; a phone app has neither, so moving between screens, remembering the way back and
animating the change are an app's own job. The library nearly every React Native app uses for it is
**React Navigation**, and Expo's own file-based router, Expo Router, is built on top of it.

## The three shapes

| navigator | what the person sees | in the planner |
|---|---|---|
| **stack** | screens slide in on top of each other; back removes the top one | a course's screen, over the list |
| **tabs** | a bar of tabs, each a screen that keeps its place | *Courses* and *This week* |
| **drawer** | a panel that slides in from the side | not needed |

Navigators **nest**. The planner's root is a stack whose first screen is the tabs; a course's screen sits
in the stack, above the tabs, so it covers the tab bar while it is open and back returns to whichever tab
the person was on.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l08-nesting\" aria-label=\"The planner's navigators. The root is a native stack. Its first screen is Tabs, a bottom-tab navigator holding Courses and This week. Above the tabs, the stack can push Course, with an id. Pushing Course covers the tab bar; going back returns to the tab the person was on.\"><defs><marker id=\"l08-nesting-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-nesting-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">root: native stack</text><rect x=\"20\" y=\"34\" width=\"380\" height=\"170\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"130\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">Tabs: bottom tabs</text><rect x=\"40\" y=\"70\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Courses</text><rect x=\"40\" y=\"130\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">This week</text><rect x=\"230\" y=\"100\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"305.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Course { id }</text><path d=\"M190 90 L230 112\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-nesting-ah-amber)\"></path><text x=\"214\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">push</text><path d=\"M230 128 L190 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l08-nesting-ah-paper-dim)\"></path><text x=\"212\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">back</text></svg>", "caption": "Navigators nest: a course's screen sits in the stack above the tabs, so back returns to whichever tab was open."}
```

## Installing it

React Navigation is four packages here: the core, the two navigators, and `react-native-screens`, which
turns each screen into a real native screen, a `UIViewController` on iOS and a `Fragment` on Android. The
safe-area library of lesson 6 is the fifth, already installed:

```
ana@dev:~/planner$ npm install -E @react-navigation/native@7.5.1 @react-navigation/native-stack@7.21.0 @react-navigation/bottom-tabs@7.21.0 react-native-screens@4.30.1

added 21 packages, and audited 1090 packages in 9s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

`native-stack` uses the platforms' own navigation controllers, so the push animation, the back swipe on
iOS and the header are the system's. A JavaScript stack, `@react-navigation/stack`, exists too and is
easier to customise; the native one is the default choice because it behaves exactly as a native app
does.

## Expo Router, in one paragraph

Expo Router builds the same navigators from the **files** in an `app/` folder: `app/course/[id].tsx` is
the course screen and its address at once. It is a good choice for a new app and it is React Navigation
underneath, so everything in this lesson applies to it. This course writes the navigators by hand because
that is what Expo Router writes for you, and seeing it once makes the generated version readable.
