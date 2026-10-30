---
title: Two design systems, and what each one is for
version: 1
---

**A design system is a set of decisions somebody made once so that nobody has to make them again on
every screen.** It names the parts a screen is built from, says where each part goes and what it is
for, and fixes the colours, the type and the spacing they share. The common picture is a style guide,
a page of colours and a logo. That is the smallest part of it. The useful part is the agreement
about behaviour: which bar switches sections, where the main action sits, what a sheet sliding up
from the bottom means.

**Each platform publishes one, because each platform wants its apps to feel like one place.** A
person who has used ten Android apps expects the eleventh to put its sections in the same bar and
its back action in the same gesture, and an iPhone user expects the same of the next iPhone app. An
app that follows the system's design inherits ten apps' worth of teaching for free. Google's is
**Material Design**, now in its third version, Material 3, published in full at `m3.material.io`.
Apple's is the **Human Interface Guidelines**, the HIG, at
`developer.apple.com/design/human-interface-guidelines`. Everything this lesson says about either
was read on 30 October 2026: Material in Android's documentation on Material 3 in Compose and its
component pages, the HIG in its own pages. Those pages carry dates and change. The HIG's page on
toolbars says it took in the old navigation bar guidance in June 2025.

## The parts each one names

Both systems name the same jobs, and give them different shapes and places. This is the vocabulary
the rest of the lesson uses:

| the job | Material 3 | the HIG, on iPhone |
|---|---|---|
| the title of the screen | a **top app bar** | a navigation bar, with a **large title** that shrinks as the list scrolls |
| the one most common action | a **floating action button**, a FAB, "typically anchored to the bottom right" | a button in the **toolbar** at the top |
| switching between sections | a **navigation bar** at the bottom, for three to five destinations | a **tab bar** at the bottom |
| more sections, a bigger screen | a **navigation rail** at the side, or a **navigation drawer** that slides in | a sidebar, on iPad |
| a short task on top of the screen | a bottom sheet or a dialog | a **sheet** |
| icons | Material's icon set, `Icons` in Compose | **SF Symbols**, drawn to match the system font |
| depth | **elevation**, shown as a tone of colour as well as a shadow | **materials**: Liquid Glass for bars and controls, standard materials inside the content |

Two rows carry more than their names. Android's documentation describes the navigation bar as the
place for "three to five destinations of equal importance", and the rail for three to seven, on
tablet or desktop layouts: the choice between them is the screen's width, which is lesson 8's subject.
The HIG says a tab bar is "for navigation, not to provide actions": an action belongs in a toolbar.
Both rules say the same thing in two spellings. **The bar at the bottom moves between places; it
does not do things.**

## What each one insists on

**Material is built to be themed.** Its guide is a set of roles, *primary*, *on primary*, *surface*,
and a type scale of fifteen named styles, and an app fills them with its own values. On Android 12
and later it goes one step further with **dynamic colour**: Android's documentation describes an
algorithm that "derives custom colors from a user's wallpaper" and offers them to the app, so the
same app can look different on two phones.

**The HIG is built to defer to the system.** It asks for the system's font, the system's colours,
the system's symbols and the system's bars, so that a setting the user changes, a larger text size
or a darker appearance, reaches every app at once. Its page on dark mode puts that plainly: avoid an
appearance setting of your own, because people "may think your app is broken because it doesn't
respond to their systemwide" choice.

Neither is a law. **An app that ignores either guide still installs and runs**, as lesson 1 put
it. What it loses is the user's head start, and the next section shows what that looks
like on one screen of the planner.
