---
title: Design for a range of windows, not for a phone
version: 1
---

**An app does not know what shape it will be drawn in, so a layout is designed for a range of
sizes rather than for one device.** The common picture is two layouts, one for a phone and one for
a tablet, chosen when the app starts by asking what kind of device it is. That picture fails on
the first foldable, and Android's documentation on window size classes says so in plain terms: the
classes are not determined by the size of the device's screen, and they are not meant for
"is this a tablet" logic.

## The window, not the screen

The space an app gets is its **window**, and on a modern phone the window and the screen are
often different sizes. These are the ordinary ways they come apart:

| what happens | what the app sees |
|---|---|
| the user turns the phone | width and height swap; a tall window becomes a short, wide one |
| a foldable opens or closes | the window jumps from phone-sized to nearly tablet-sized, or back |
| split screen, on Android or iPad | the app gets half of the screen, or a third, and the user can drag the line |
| a window on a desktop, a Chromebook or an iPad in windowed mode | any size the user drags it to |
| a second display is connected | the window moves to a screen with a different size and density |

Android's documentation on multi-window mode lists the forms it takes: two apps side by side or
one above the other in split screen, one app in a small picture-in-picture window, and apps in
separate movable, resizable windows. Apple's Human Interface Guidelines list the same family for
iOS and iPadOS: different screen sizes, orientations, resizable windows on iPad and Mac, and
external displays, all as things a layout has to handle.

**So "the screen is 360 dp wide" is never a fact an app can keep.** It is the size now. The right
question is asked again whenever the window changes, and on Android each of the changes in the
table is a configuration change, the event lesson 4 described as the system rebuilding the
screen.

## A range has two ends and a middle

Designing for a range means deciding three things, and they are worth separating because they
fail differently:

- What stretches. A list fills the width it is given; a text field grows; a picture scales.
  The next section but one is about that.
- What stays fixed. A touch target is 48 dp on any window, and the size classes do not
  change it. Lesson 7 is why.
- Where the layout changes shape. At some width, one column of content becomes two, or a tab
  bar becomes a rail down the side. Those points are the size classes of the next section.

The first two are about one layout that bends. The third is about switching to a different
layout, and it is the one that needs a rule, because without one every screen of an app ends up
choosing its own breakpoints and the app changes shape at five different widths.

**Locking the orientation is not a way out.** An app can ask to be portrait only, and Apple's
guidelines point out that even an app locked to one orientation still has to resize well,
because windows change for reasons that have nothing to do with turning the phone. Split screen
gives a portrait-locked app a window that is wider than it is tall, or barely wider than a
button.
