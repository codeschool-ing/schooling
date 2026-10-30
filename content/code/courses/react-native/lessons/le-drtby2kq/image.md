---
title: Image, which has to know its size
version: 1
---

**An `Image` draws a picture, and unlike an `<img>` it will not size itself from the file it
downloads.** That one difference explains most of what goes wrong with images in React Native.

## Two kinds of source

| source | written as | size |
|---|---|---|
| a file in the project | `source={require("../assets/icon.png")}` | known when the app is built, from the file |
| a picture on the network | `source={{ uri: "https://example.org/cover.png" }}` | unknown until it arrives, so **you must give one** |

`require` is resolved by Metro at bundle time, like an `import`, so a missing file is an error when the
app is bundled rather than a blank space later. The file goes into the bundle (or, on a phone, into
the app's assets) at every resolution the project provides: `icon.png`, `icon@2x.png` and
`icon@3x.png` beside each other are chosen by the screen's pixel density.

**A network image with no `width` and `height` is drawn at zero by zero**, which is to say not at all,
with no error. It is the single most common "my image does not show" question about React Native.
Give it a size, or a `flex` and an `aspectRatio` that produce one.

## Pixels you see, pixels you pay for

The size in the style is in **density-independent pixels**, the unit of lesson 5: a 40 by 40 icon is 40
by 40 on every phone, and covers 120 by 120 real pixels on a phone whose density is three. The image
file should be roughly that size or one of its `@2x` and `@3x` siblings. A 4000-pixel photo shown in a
40-point square is decoded at full size into memory first; lesson 19 measures what that costs, and why
a list of such photos is how an app runs out of memory.

## What a screen reader says

An image that means something needs words: `alt="Statistics course cover"`, which React Native passes
to the platform as the image's label. An image that only decorates, like the planner's icon next to
its heading, should be skipped, and `aria-hidden` says so. Without either, what a screen reader does
with it is left to the platform, and neither platform's choice is the one you meant.

## How the planner uses one

Its first screen puts the app's own icon, already in `assets/` from the template, to the left of the
heading. A file in the project, so `require`, and decorative, so `aria-hidden`. The last section of this
lesson shows it in place, and its style gives it an explicit 40 by 40, which a local image does not
strictly need and which makes the layout independent of the file's own size.
