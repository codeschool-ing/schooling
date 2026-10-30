---
title: The parts of the screen the app does not get
version: 1
---

**A phone's window reaches the edges of the glass, but parts of it are covered by the system or
cut away by the hardware, and the app is told how far in from each edge those parts reach.** Each
of those distances is an *inset*. The common picture is a clean rectangle under a status bar,
which is how phones looked when the status bar was an opaque strip and the app was drawn below it.
On a current phone the app is drawn behind the status bar, around the camera and under the bar
for gestures, and it is the app's job to keep what matters out of the way.

## What covers the edges

| region | where | on Android | on iOS |
|---|---|---|---|
| status bar | top | clock, signal, battery, notifications | clock, signal, battery |
| display cutout | top, or the side in landscape | a notch or a hole for the camera | the notch, or the Dynamic Island |
| navigation | bottom, or a side | a gesture handle, or three buttons | the home indicator |
| rounded corners | the corners | where the glass is rounded | where the glass is rounded |
| keyboard | bottom, when a field has focus | the IME, the input method | the software keyboard |

Android's documentation on insets names the system's own kinds: status bars, navigation bars, the
display cutout, the curved edges of a *waterfall* display, the keyboard as `ime`, and the areas
where the system takes gestures. It sums them up in safe kinds an app reads instead of adding them
by hand: `safeDrawing` for content that must not be drawn under any system interface,
`safeGestures` for the parts of the screen where an app's own swipes would fight the system's, and
`safeContent` for both. Apple's Human Interface Guidelines define the iOS version in one sentence: a
**safe area** is the part of a window not covered by a hardware feature or by another view, such as
a toolbar, a tab bar or the status bar. Respecting it keeps features like the Dynamic Island
from hiding content and controls.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l09-regions\" aria-label=\"A diagram of a phone screen, not a screenshot. In portrait, a band across the top holds the status bar, with a camera cutout in the middle of it, and a band across the bottom holds the gesture area; the safe area is the dashed rectangle between them. In landscape the cutout is on the left side, the bands are on the left and the right, a thinner band runs along the bottom, and the safe area is the dashed rectangle inside them.\"><defs><marker id=\"l09-regions-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"155\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">portrait</text><rect x=\"60\" y=\"26\" width=\"190\" height=\"290\" rx=\"24\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></rect><rect x=\"60\" y=\"26\" width=\"190\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"122\" y=\"31\" width=\"66\" height=\"16\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"155.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--amber)\">cutout</text><rect x=\"60\" y=\"290\" width=\"190\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"125\" y=\"301\" width=\"60\" height=\"4\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"70\" y=\"60\" width=\"170\" height=\"222\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"155.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">safe area</text><path d=\"M272 39 L252 39\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-regions-ah-paper-dim)\"></path><text x=\"276\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">status bar</text><path d=\"M272 303 L252 303\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-regions-ah-paper-dim)\"></path><text x=\"276\" y=\"303\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">gesture area</text><text x=\"565\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">landscape: the cutout moves to a side</text><rect x=\"420\" y=\"98\" width=\"290\" height=\"170\" rx=\"24\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></rect><rect x=\"420\" y=\"98\" width=\"28\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"426\" y=\"158\" width=\"16\" height=\"50\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"682\" y=\"98\" width=\"28\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"452\" y=\"250\" width=\"226\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"535\" y=\"258\" width=\"60\" height=\"4\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"454\" y=\"104\" width=\"222\" height=\"140\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"565.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">safe area</text></svg>", "caption": "A diagram of the regions, not a picture of any phone. The app draws its background into all of them and keeps what the student reads or taps inside the dashed rectangle, which moves when the phone turns."}
```

## Behind, but not under

**An inset is a rule about what goes where, not a hole in the window.** The app is expected to
draw its background colour or a photo all the way to the edges, behind the status bar and the
gesture handle, so the screen looks whole. What it keeps inside the safe area is anything a user
reads or taps: text, the session list, the add-session button. A background under the notch looks
deliberate; the first line of a list under the notch is a line nobody can read.

**The insets change while the app runs.** They are different in landscape, where the cutout moves
to a side and the top inset often disappears. They change when the keyboard opens and closes, by
hundreds of units at once. On Android they change when the user switches from three buttons to
gestures. An app that reads the insets once at launch and keeps the numbers has the problem lesson
8 described for window sizes, in a smaller place.

**And they are reported in the units of lesson 7**: dp on Android, points on iOS, and the
platform's unit in React Native. An inset is a layout size like any other, and it is never a count
of physical pixels.

## The two mistakes

Every inset bug is one of two, and they look opposite:

- Ignoring the insets. The content starts at the top edge and the title sits under the clock;
  the add-session button sits on the bottom edge and the gesture handle covers it, or a swipe to go
  home starts when the student meant to press it.
- Applying them twice. A toolkit that already pads for the safe area, and a developer who adds
  the same padding again by hand, produce a band of empty space above the content and a list that
  starts a status bar's height too low.

Both come from not knowing which part of the code is responsible for the insets. The next section
is about that responsibility on each platform, which is where the two differ most.
