---
title: When the answer is no
version: 1
---

**A person who says no has not broken the app, and the app has to keep working for them.** Guideline
5.1.1(iv) of the App Review Guidelines, read on 30 October 2026, says apps "must respect the user's
permission settings" and, "where possible, provide alternative solutions for users who don't grant
consent". For the planner that is easy to state: a session without a photo is still a session. The
camera button changes; nothing else does.

iOS never shows the alert a second time, so the app cannot ask again. What it can do is say what is
off and offer the one place where the person can change it: the app's page in the Settings app,
which `UIApplication.openSettingsURLString` opens. **Do it as a sentence and a button, at the
place where the camera would have been**, not as an alert that blocks the screen.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l18-states\" aria-label=\"The four states of a permission. It starts as notDetermined. The app&#x27;s request shows the system alert, once; Allow leads to authorized and Don&#x27;t Allow to denied. From denied, only the person can go back, by turning the switch on in the Settings app. A fourth state, restricted, is set by someone else, a parent&#x27;s Screen Time or a device manager, and the app cannot lead the person out of it.\"><defs><marker id=\"l18-states-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l18-states-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-states-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l18-states-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"110\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">notDetermined</text><text x=\"95\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nobody has asked</text><rect x=\"250\" y=\"95\" width=\"170\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"335\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the system alert</text><text x=\"335\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">your usage string</text><text x=\"335\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">shown once</text><path d=\"M170 135 L248 135\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-states-ah-amber)\"></path><text x=\"209\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">request</text><rect x=\"510\" y=\"30\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">authorized</text><text x=\"600\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the camera opens</text><rect x=\"510\" y=\"190\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">denied</text><text x=\"600\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a sentence and Settings</text><path d=\"M420 115 L508 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-states-ah-phosphor)\"></path><text x=\"455\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">Allow</text><path d=\"M420 155 L508 210\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-states-ah-wire)\"></path><text x=\"448\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Don't Allow</text><path d=\"M690 205 C 715 160, 715 110, 692 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l18-states-ah-paper-dim)\"></path><text x=\"640\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the person, in Settings</text><rect x=\"20\" y=\"220\" width=\"300\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"170\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">restricted</text><text x=\"170\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">set by somebody else; no way out from the app</text></svg>", "caption": "The app can move a permission out of notDetermined once. After that, only the person can change it, and only in Settings."}
```

## The decision, as plain Swift

What the button shows depends on the state and on nothing else, so the decision can be a function
of the state, and a function of plain values runs anywhere. The four states are the ones
`AVCaptureDevice` reports, written out as an enumeration of the planner's own so that this file
needs no Apple framework. Save it as `denied.swift` in `~/privacy`:

```schooling-example
{"language": "swift", "file": "denied.swift", "parts": [{"code": "// denied.swift: what the camera button shows, for each answer the person may have given\nenum CameraAccess: CaseIterable {\n    case notDetermined, authorized, denied, restricted\n}\n\nenum CameraButton: Equatable {\n    case ask(String)\n    case takePhoto\n    case openSettings(String)\n    case unavailable(String)\n}\n", "note": "The planner's own copy of the four states, and the four things the button can be. `CaseIterable` lets the loop below walk every state, so a fifth one added later is printed too."}, {"code": "func button(for access: CameraAccess) -> CameraButton {\n    switch access {\n    case .notDetermined: .ask(\"Take a photo of your notes\")\n    case .authorized: .takePhoto\n    case .denied: .openSettings(\"Camera is off for Planner. You can turn it on in Settings.\")\n    case .restricted: .unavailable(\"The camera is not available on this device.\")\n    }\n}\n", "note": "No `default`: the compiler checks that every state has an answer. `.restricted` gets no Settings button, because the person holding the phone cannot change a restriction somebody else set."}, {"code": "for access in CameraAccess.allCases {\n    print(access, \"->\", button(for: access))\n}\n", "note": "One line per state. Each sentence says what is off and what can be done, without blaming the person for the answer they gave."}]}
```

```
ana@vm:~/privacy$ swift denied.swift
notDetermined -> ask("Take a photo of your notes")
authorized -> takePhoto
denied -> openSettings("Camera is off for Planner. You can turn it on in Settings.")
restricted -> unavailable("The camera is not available on this device.")
```

**`.denied` and `.restricted` look alike and are not.** Both mean no camera, and a screen that
showed one message for both would send somebody whose phone is managed by their school to a Settings
page where the switch is greyed out. The SwiftUI half, which was not run, turns each value into a
control:

```swift
// CameraButtonView.swift
import SwiftUI
import UIKit

struct CameraButtonView: View {
    let state: CameraButton
    var takePhoto: () -> Void

    var body: some View {
        switch state {
        case .ask(let title):
            Button(title, action: takePhoto)
        case .takePhoto:
            Button("Take a photo of your notes", action: takePhoto)
        case .openSettings(let text):
            VStack(alignment: .leading) {
                Text(text)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        case .unavailable(let text):
            Text(text)
        }
    }
}
```

The two `Take a photo` buttons call the same action: the first time it runs, the action's call to
`requestAccess` from section 03 shows the alert, and every time after it opens the camera.
