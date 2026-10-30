---
title: The camera, and the photos you do not need permission for
version: 1
---

**There are two ways for the planner to get a picture of somebody's notes, and only one of them
needs a permission.** The camera does: the app takes the picture itself, so it has to be allowed to
use the camera. Choosing a photo already in the library does not, if the app lets the system do the
choosing. Nothing in this section was run for the course; it is written from Apple's documentation
for `AVCaptureDevice` and for SwiftUI's `PhotosPicker`, read on 30 October 2026.

## The camera: ask at the moment of use

The camera's state is one of four, and the app reads it before deciding anything:

```swift
// CameraAccess.swift
import AVFoundation

func cameraAllowed() async -> Bool {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
        return true
    case .notDetermined:
        return await AVCaptureDevice.requestAccess(for: .video)
    case .denied, .restricted:
        return false
    @unknown default:
        return false
    }
}
```

**Only `.notDetermined` leads to the alert.** `requestAccess` is the call that makes iOS show the
usage string from section 02, and it is answered once; afterwards the status is `.authorized` or
`.denied` and the call returns that answer without asking. `.restricted` means somebody other than
the person holding the phone decided, a parent's Screen Time setting or a company's device
management, and the person cannot change it either. `@unknown default` is there because Apple may
add a case to this enumeration in a later iOS, and the compiler asks you to say now what an unknown
case means. Here it means no.

Call it **when the person taps the button that takes the photo**, not when the app starts. Apple's
guidance for location, quoted in section 04, gives the reason, and it holds for every permission:
asked out of context, people say no, and section 02 showed that no is permanent.

## Photos: let the system choose

A person attaching a photo of their notes wants one picture, not to hand over a library of ten
thousand. SwiftUI's `PhotosPicker` shows the system's photo picker in a separate process: the app
sees only what the person picks, and so **it needs no permission and no usage string**. Apple's
documentation for `PHPickerViewController`, which `PhotosPicker` wraps, says the same thing, and
guideline 5.1.1(iii) asks for exactly this: "use the out-of-process picker or a share sheet rather
than requesting full access to protected resources like Photos".

```swift
// NotesPhotoButton.swift
import SwiftUI
import PhotosUI

struct NotesPhotoButton: View {
    @State private var item: PhotosPickerItem?
    @State private var image: Image?

    var body: some View {
        PhotosPicker("Attach a photo of your notes", selection: $item, matching: .images)
            .task(id: item) {
                image = try? await item?.loadTransferable(type: Image.self)
            }
    }
}
```

`PhotosPickerItem` is a placeholder for what the person chose, and `loadTransferable` loads the
picture itself, which may take a moment for a photo stored in iCloud. **The `try?` throws the error
away, and here that is a choice with a reason**: the documentation's example of a failure is a
picture that cannot be downloaded, and the button stays usable for another try. A real app would
show a line saying the photo could not be loaded, and lesson 12's error state is the shape for it.

`NSPhotoLibraryUsageDescription`, full access to the library, is what an app that browses or edits
the whole library needs: a photo editor, a backup tool. The planner is neither.
