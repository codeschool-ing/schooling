---
title: iOS points, scale factors, and React Native's PixelRatio
version: 1
---

**iOS measures in points, and a point becomes one, two or three pixels depending on the screen's
scale factor.** Apple's Human Interface Guidelines, on images, define it the same way Android
defines a dp: a point is an abstract unit that keeps visual content the same size whatever the
display, and the *scale factor* says how many pixels a point covers. A scale factor of 1, written
@1x, is one pixel per point; @2x is two by two pixels per point, and @3x three by three.

The difference from Android is the number of steps. **The guidelines list @2x and @3x for iPhone
and @2x for iPad**, because Apple makes every screen these run on and chose the densities
accordingly. Android has five buckets in use because hundreds of manufacturers chose theirs. The
idea is the same; iOS has fewer cases.

## React Native: the platform's unit, and PixelRatio

**A size in React Native is a plain number, and it means the platform's own unit**: a dp on
Android and a point on iOS. `width: 48` is a 48 dp box on one platform and a 48 pt box on the
other, and both are about the same size under the finger. React Native's documentation for
`PixelRatio` gives the pixels behind the number when an app needs them: `PixelRatio.get()`
returns the density, and its examples put an xhdpi Android phone and an iPhone 11 at 2, and an
xxhdpi phone at 3. `PixelRatio.getPixelSizeForLayoutSize(48)` turns a layout size into the
pixels it covers, which is what an app asks for when it downloads an image of the right size.

## The same square in three spellings

The fragments below draw a 48-unit square with a 24-unit icon in it, and a title whose size
follows the user's text setting. They are adapted from each platform's documentation, and **they
were not compiled or run for this course**.

```kotlin
// Compose: sizes in dp, text in sp
Box(Modifier.size(48.dp)) {
    Icon(Icons.Filled.Add, contentDescription = "Add session", modifier = Modifier.size(24.dp))
}
Text("Mobile Fundamentals", fontSize = 16.sp)
```

```swift
// SwiftUI: sizes in points, text in a style that follows Dynamic Type
Image(systemName: "plus")
    .frame(width: 24, height: 24)
    .frame(width: 48, height: 48)
Text("Mobile Fundamentals")
    .font(.body)
```

```tsx
// React Native: plain numbers are dp on Android and points on iOS
<Pressable style={{ width: 48, height: 48, alignItems: "center", justifyContent: "center" }}>
  <Image source={require("./ic_session.png")} style={{ width: 24, height: 24 }} />
</Pressable>
<Text style={{ fontSize: 16 }}>Mobile Fundamentals</Text>
```

**Not one of the three mentions a pixel**, and that is the point of all of them. Text is where
they differ most. Compose writes the text size in `sp`. SwiftUI's usual way is a text style,
`.body`, which the system sizes from the user's Dynamic Type setting rather than a number. React
Native's `Text` scales its `fontSize` with the user's setting, because its `allowFontScaling` is
`true` by default, and `PixelRatio.getFontScale()`
reports the factor the documentation says comes from the text size in each platform's settings.
How far text may grow, and what a layout has to do when it does, is lesson 19.

## Where pixels come back

Two things make a developer think in pixels again, on both platforms. The first is a **raster
image**, a PNG or a photo, which is made of pixels and looks soft when it is stretched, so it has
to be supplied at the scale the screen uses. The second is a **hairline**: a border of one
pixel, rather than one point, is half a point at @2x and a third at @3x, and React Native's
`PixelRatio` page explains that it rounds layout to whole pixels so that such a line neither
vanishes nor doubles. The next section computes the first of these for the planner.
