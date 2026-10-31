---
title: Taking one, and the three answers
version: 1
---

**`take` is the permission model of the first section, written out.** It asks, and reads the answer
before anything else:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l13-ask\" aria-label=\"A flow chart. The person presses Take a photo, and the app asks for the camera. If it is granted, the system camera opens. If it is refused and canAskAgain is true, the app explains what is lost and offers to choose a photo instead; it may ask again next time. If it is refused and canAskAgain is false, the app explains and offers a button that opens Settings.\"><defs><marker id=\"l13-ask-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Take a photo</text><rect x=\"200\" y=\"30\" width=\"230\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"315.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">requestCameraPermissionsAsync()</text><path d=\"M150 48 L200 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-ask-ah-paper-dim)\"></path><rect x=\"500\" y=\"30\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the system camera opens</text><path d=\"M430 48 L500 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-ask-ah-paper-dim)\"></path><text x=\"465\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--phosphor)\">granted</text><rect x=\"240\" y=\"120\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"315.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">canAskAgain</text><path d=\"M315 66 L315 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-ask-ah-paper-dim)\"></path><text x=\"335\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">refused</text><rect x=\"60\" y=\"200\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"165.0\" y=\"215.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">explain what is lost,</text><text x=\"165.0\" y=\"228.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">offer the library</text><rect x=\"400\" y=\"200\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"505.0\" y=\"215.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">explain, and offer</text><text x=\"505.0\" y=\"228.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Open Settings</text><path d=\"M270 156 L165 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-ask-ah-paper-dim)\"></path><path d=\"M360 156 L505 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-ask-ah-paper-dim)\"></path><text x=\"196\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">true</text><text x=\"452\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">false</text></svg>", "caption": "One request, three outcomes. Only the person can undo a final refusal, so the app's last move is to show them where."}
```

- **Allowed**, the system camera opens. The person takes the photo in the system's own camera screen and returns
  with it, and `launchCameraAsync` answers exactly as the library picker does.
- **Refused this time**, the planner says what is missing and points at the button beside it: a photo
  from the library works just as well. It does not ask again straight away. The next press asks, and on
  Android that shows the dialog once more.
- **Refused for good**, asking is useless, so the planner says where the setting is and offers a button
  that opens it. `Linking.openSettings()` opens the app's own page in Settings, where the camera switch
  is.

**None of the sentences blames the person.** They refused for a reason, perhaps a good one, and the
planner works without the camera. What the screen owes them is the consequence and the way round it.

## A camera inside the app

`launchCameraAsync` borrows the system's own camera screen, which is right for a photo of a page: it is the
camera the person already knows, with its focus, flash and zoom. An app that needs the camera inside its
own screen, to scan a code or to draw over the picture, uses `expo-camera` instead. Its `CameraView` is a
component that shows the live picture, and it asks for the same permission, with the same three answers.
*The planner does not need it, and this course did not install it.*
