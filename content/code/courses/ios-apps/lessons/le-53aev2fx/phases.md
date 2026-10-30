---
title: Phases, and the failure AsyncImage does not report
version: 1
---

**The short form has a placeholder and a picture, and nothing for the third case.** If the download
fails, the placeholder stays, and Apple's documentation adds a detail worth knowing: when the
placeholder is itself an `Image` that does not load, SwiftUI shows nothing and reports no error. A
cover that never arrives is then indistinguishable from one that is still on its way.

The fuller form hands the closure an `AsyncImagePhase`, an enum with three cases: `empty` while
loading, `success` with an `Image`, and `failure` with an `Error`. It is lesson 12's `Loadable` in
another costume, and it is drawn the same way, with a `switch` that the compiler holds to every case.
**Not run**:

```swift
// CourseCover.swift
import SwiftUI

struct CourseCover: View {
    let url: URL

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Cover not available")
            @unknown default:
                Color.clear
            }
        }
        .frame(width: 80, height: 80)
        .clipped()
    }
}
```

`@unknown default` is there because `AsyncImagePhase` is an enum Apple may add a case to in a later
iOS. **A `switch` over somebody else's enum needs it, and a `switch` over your own should not**, which
is why lesson 12's `Loadable` had none: there, a new case is supposed to break the build.

The failure draws a symbol and a label for VoiceOver. A cover is decoration beside a course's title,
so its failure is quiet; a picture that is the content, a receipt or a diagram, would deserve a
message and a retry, as lesson 12's error state had.

## A transaction, for the moment it appears

The same initializer takes a `Transaction`, which is how a loaded picture fades in instead of
appearing at once:

```swift
// CourseCover.swift, the fading version
AsyncImage(url: url, transaction: Transaction(animation: .easeIn(duration: 0.2))) { phase in
    // the same switch as above
}
```

Lesson 11 is about animation; the point here is only that the change from `empty` to `success` is a
change of state like any other, and can be animated like one.
