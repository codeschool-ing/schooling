---
title: Contrast, measured rather than judged
version: 1
---

**Whether text can be read against its background is arithmetic, and it is the one accessibility
question you can answer on any computer.** The Web Content Accessibility Guidelines define a
contrast ratio between two colours, from 1:1 for the same colour twice to 21:1 for black on white. WCAG 2.2 at level AA asks for **4.5:1 for ordinary text** and **3:1 for large text** and for
the parts of a control a person has to see. Apple's Human Interface Guidelines, read on 30 October
2026, point at the same thresholds. This platform holds its own screens to AA, and an app built in
this course should meet the same bar.

The belief to drop is that a colour that looks fine on your screen is fine. Your screen is bright,
your eyes are yours, and you know what the text says. The ratio knows none of that.

## The formula

Each colour's **relative luminance** is computed from its red, green and blue channels: each
channel is scaled to 0–1, undone from the sRGB curve, and weighted, green most because the eye is
most sensitive to it. The ratio is `(lighter + 0.05) / (darker + 0.05)`. Save this as
`contrast.swift` in `~/contrast`:

```schooling-example
{"language": "swift", "file": "contrast.swift", "parts": [{"code": "// contrast.swift: WCAG contrast ratios for the planner's colours\nimport Foundation\n\nfunc luminance(_ hex: String) -> Double {\n    let v = Int(hex.dropFirst(), radix: 16)!\n    let channels = [(v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF].map { Double($0) / 255 }\n    let linear = channels.map { c in c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }\n    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]\n}\n", "note": "WCAG's relative luminance. The `pow` undoes the sRGB curve, which stores dark tones with more precision than light ones; the three weights are how much red, green and blue each contribute to how bright a colour looks."}, {"code": "func ratio(_ a: String, _ b: String) -> Double {\n    let (x, y) = (luminance(a), luminance(b))\n    return (max(x, y) + 0.05) / (min(x, y) + 0.05)\n}\n", "note": "The order of the two colours does not matter: the lighter one is always on top. The `0.05` stands for the light a real screen reflects, and it is why black on white is 21 and not infinite."}, {"code": "let pairs = [\n    (\"title on white\", \"#1C1C1E\", \"#FFFFFF\"),\n    (\"minutes, grey on white\", \"#6E6E73\", \"#FFFFFF\"),\n    (\"placeholder, light grey\", \"#AEAEB2\", \"#FFFFFF\"),\n    (\"done tick, green on white\", \"#34C759\", \"#FFFFFF\"),\n    (\"done tick, darker green\", \"#248A3D\", \"#FFFFFF\"),\n    (\"minutes, grey on dark\", \"#98989D\", \"#1C1C1E\"),\n]\nfor (name, fg, bg) in pairs {\n    let r = ratio(fg, bg)\n    let verdict = r >= 4.5 ? \"text ok\" : r >= 3 ? \"large text and icons only\" : \"fails\"\n    print(name.padding(toLength: 27, withPad: \" \", startingAt: 0), String(format: \"%5.2f:1\", r), verdict)\n}\n", "note": "The planner's colours, light and dark. Each verdict is AA's: 4.5 for text, 3 for large text and for a control's visible parts, such as a tick that says a session is done."}]}
```

```
ana@vm:~/contrast$ swift contrast.swift
title on white              17.01:1 text ok
minutes, grey on white       5.07:1 text ok
placeholder, light grey      2.21:1 fails
done tick, green on white    2.22:1 fails
done tick, darker green      4.40:1 large text and icons only
minutes, grey on dark        5.93:1 text ok
```

**Two of the six fail, and both looked fine on the screen they were picked on.** The light grey of
a placeholder in a text field is a common one, and it matters more than it seems, because a
placeholder is sometimes the only hint a field has. The bright green tick fails even as an icon, at
2.22:1. The darker green reaches 4.40:1, which is enough for a tick and not for text, so the word
*done* beside it is drawn in the grey that passed. And the grey that works on white is a different grey in
the dark theme: each theme's pair is measured on its own.

## In the app

Two system features change these numbers without the app's help, and an app has to keep working
under both. **Increase Contrast**, in the accessibility settings, makes iOS's own colours darker or
lighter, and SwiftUI exposes it to a view as `@Environment(\.colorSchemeContrast)`. **Dark Mode**
swaps the whole palette. Colours from an asset catalogue can carry a variant for each, and system
colours such as `Color.secondary` adapt already. A colour typed into the code as numbers, like the
six above, adapts to nothing, which is why measuring each one in each theme is the job.
