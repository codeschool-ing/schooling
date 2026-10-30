---
title: Downsampling, decoding only what the screen needs
version: 1
---

**The fix for section 04's numbers is not a smaller download. It is a smaller decode.** A 4032 by 3024
photograph shown in an 80-point square needs 240 by 240 pixels on a 3x screen, and an app that
decodes those pixels and no others spends 230,400 bytes instead of 48,771,072. The file is the same
file; only the decode is different.

`AsyncImage` cannot do that. It decodes at the file's size and lets the frame scale the result down
for drawing, which is cheap to draw and expensive to hold. **The work has to happen before the
`Image` exists**, with the framework that decodes images on Apple systems, ImageIO. Nothing in this
section was run: ImageIO is part of Apple's SDKs and not of the open-source toolchain. It is written
from Apple's documentation for `CGImageSourceCreateThumbnailAtIndex` and its options, read on
30 October 2026.

## The function

```swift
// Downsample.swift
import ImageIO
import UIKit

/// Decode `data` at no more than `maxPixels` on its longer side.
func downsample(_ data: Data, maxPixels: Int) -> UIImage? {
    let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
    let options = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxPixels,
    ] as CFDictionary
    guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
    return UIImage(cgImage: thumbnail)
}
```

Each option says something specific. `ShouldCache: false` on the source tells ImageIO not to decode
the whole image when it opens it. `ThumbnailMaxPixelSize` is the longer side of the result, in pixels.
`CacheImmediately` decodes the small image now, on whatever thread called this, rather than later on
the main thread when it is first drawn. `WithTransform` applies the photograph's orientation, so a
picture taken in portrait does not arrive on its side.

**The number to pass is the one section 04 computed**, the points the view occupies times the screen's
scale: `pixels(points: 80, scale: 3)`, 240. On a Mac the scale of the current display is in the
environment as `displayScale`, and the function belongs in the code that loads the cover, before
anything reaches a view.

## Where it goes in the planner

Downsampling is CPU work, and decoding a 12-megapixel photograph takes long enough to drop frames if
it happens on the main actor while a list is scrolling. So it runs where the download ran, off the
main actor, and only the small result crosses to the view. In section 06's `ImageCache`, that means
the cache keeps the downsampled picture rather than the bytes, and its cost is the 230,400 of the
thumbnail rather than the 48,771,072 of the photograph. **The cache then holds two hundred covers in
the memory one photograph took.**
