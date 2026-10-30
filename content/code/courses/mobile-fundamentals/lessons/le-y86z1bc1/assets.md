---
title: One vector, or the same image in every size
version: 1
---

**An image in an app is either a vector, drawn from shapes and sharp at any size, or a raster,
made of pixels and sharp only at the size it was saved at.** Most of the confusion about "assets
in three sizes" comes from treating every image as a raster. Icons, the planner's plus sign and
its tab symbols, are shapes, and shapes can be described once. A photo of a course's cover is
pixels, and it cannot.

## The vector, on each platform

| platform | the vector format | where it lives |
|---|---|---|
| Android | a *vector drawable*, an XML file of paths and colours | one file in `res/drawable/`, no density folder |
| iOS | SF Symbols, Apple's own symbols, or a PDF or SVG of your own | the asset catalog, one entry |
| React Native | an SVG, through a library, or the platform's own symbols | one file |

**Android's documentation on densities says to prefer vector graphics**, and says why in one
line: a vector drawable is one file that serves every density. It also says that Android does not
read SVG itself, so an SVG from a designer is converted to a vector drawable first, with Android
Studio's Vector Asset Studio. Apple's guidelines name PDF or SVG for flat icons that need to scale,
and SF Symbols is a library of thousands of symbols that the guidelines describe as aligning with
the system font at every weight and size.

A vector is not free. It is drawn from its paths, which costs processor time on the main thread
of lesson 6, and the same documentation calls vectors best for illustrations such as icons, not
for photographs. For a 24 dp plus sign, the cost is nothing worth measuring.

## The raster, in every size

**A photo, a texture or a complicated illustration stays a raster, and then it is supplied once per
density.** The file names come straight from the end of the previous section's output:

| platform | where each size goes | how the right one is chosen |
|---|---|---|
| Android | `res/drawable-mdpi/`, `drawable-hdpi/` … `drawable-xxxhdpi/`, the same file name in each | the system picks the folder for the screen's bucket |
| iOS | one asset catalog entry with an @2x and an @3x image | the system picks by the screen's scale factor |
| React Native | `ic_session.png`, `ic_session@2x.png`, `ic_session@3x.png` side by side | the bundler serves the one for the screen's density |

React Native's documentation on images uses the same @2x and @3x suffixes as iOS, on both
platforms, and says that when no file matches the density, the closest one is used. Android's
documentation describes the same fallback: with no file for the screen's bucket, the system takes
the best match and scales it, so a 48x48 file meant for mdpi is stretched to 72x72 on an hdpi
screen. **Scaled up, a raster goes soft; scaled down, it wastes memory.** Neither is a crash,
which is why a missing size is found by looking at the app rather than by an error.

## The app's own icon is a special case

The icon on the home screen is not drawn by the app. A launcher draws it, and Android's
documentation warns that some launchers show it as much as 25% larger than the screen's bucket
calls for. So Android keeps app icons in `mipmap-` folders, one per bucket, which are all kept in
the app, and the launcher can take the sharper one from the bucket above. iOS keeps the app icon
as an entry of its own in the asset catalog. The images a store asks for are
`mobile-delivery` lesson 4, on the store listing; here it is enough to know that it is
the one image the app hands to something else to draw.

## For the planner

**Every icon in the planner is a vector**: the plus sign for a new session, the check mark for a
done one, the tab symbols. One file each, sharp at every density, on every screen. The only
raster would be a photo a student attaches to a course, and that comes from the camera at
whatever size the camera chose, so the app scales it to the size it shows, in pixels it works
out with exactly the sum `density.ts` runs.
