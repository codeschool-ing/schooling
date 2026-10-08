---
title: Measuring contrast
version: 1
---

**Contrast** between two colours is measured as a ratio of their relative luminances, the quantity
lesson 11 computed:

```localised
contrast = (lighter luminance + 0.05) ÷ (darker luminance + 0.05)
```

It runs from **1:1**, two identical colours, to 21:1, black on white. The Web Content Accessibility
Guidelines, **WCAG 2.2**, set the thresholds that most organisations and many laws adopt:

| what | WCAG 2.2 criterion | level AA asks |
|---|---|---|
| text, including labels and numbers on a chart | 1.4.3 Contrast (Minimum) | **4.5:1**, or 3:1 for large text |
| the parts of a chart a reader needs: lines, bars, points, their outlines | 1.4.11 Non-text Contrast | **3:1** against what is next to them |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 250\" role=\"img\" data-fig=\"l14-contrast\" aria-label=\"Four pairs of colours with their contrast ratios, against two thresholds marked on a scale: 3 to 1 for graphics and 4.5 to 1 for text. Mid grey on white, 4.54, passes both. Light grey on white, 1.61, fails both. This course's blue on white, 6.66, passes both. Red against green, 1.48, fails both.\"><rect x=\"30.0\" y=\"40.0\" width=\"60.0\" height=\"34.0\" rx=\"2\" fill=\"#ffffff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"46.0\" y=\"48.0\" width=\"28.0\" height=\"18.0\" rx=\"1\" fill=\"#767676\" stroke=\"#767676\" stroke-width=\"1\"></rect><text x=\"110.0\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">#767676 / #ffffff</text><path d=\"M250.0 47.0 h167.0 v20.0 h-167.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"423.0\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">4.54</text><rect x=\"30.0\" y=\"86.0\" width=\"60.0\" height=\"34.0\" rx=\"2\" fill=\"#ffffff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"46.0\" y=\"94.0\" width=\"28.0\" height=\"18.0\" rx=\"1\" fill=\"#c8ccd4\" stroke=\"#c8ccd4\" stroke-width=\"1\"></rect><text x=\"110.0\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">#c8ccd4 / #ffffff</text><path d=\"M250.0 93.0 h28.8 v20.0 h-28.8 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"284.8\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1.61</text><rect x=\"30.0\" y=\"132.0\" width=\"60.0\" height=\"34.0\" rx=\"2\" fill=\"#ffffff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"46.0\" y=\"140.0\" width=\"28.0\" height=\"18.0\" rx=\"1\" fill=\"#2b52c9\" stroke=\"#2b52c9\" stroke-width=\"1\"></rect><text x=\"110.0\" y=\"149.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">#2b52c9 / #ffffff</text><path d=\"M250.0 139.0 h266.8 v20.0 h-266.8 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"522.8\" y=\"149.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">6.66</text><rect x=\"30.0\" y=\"178.0\" width=\"60.0\" height=\"34.0\" rx=\"2\" fill=\"#2ca02c\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"46.0\" y=\"186.0\" width=\"28.0\" height=\"18.0\" rx=\"1\" fill=\"#d62728\" stroke=\"#d62728\" stroke-width=\"1\"></rect><text x=\"110.0\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">#d62728 / #2ca02c</text><path d=\"M250.0 185.0 h22.5 v20.0 h-22.5 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"278.5\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1.48</text><path d=\"M344.3 34.0 L344.3 226.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"348.3\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">graphics need 3:1</text><path d=\"M415.0 34.0 L415.0 226.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"419.0\" y=\"224.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">text needs 4.5:1</text></svg>", "caption": "Contrast is a ratio of luminances, from 1:1 for identical colours to 21:1 for black on white. WCAG 2.2 asks 4.5:1 for text and 3:1 for the parts of a chart a reader needs."}
```

## Measuring it

```schooling-example
{"language": "python", "file": "access.py", "parts": [{"code": "import sys\n"}, {"code": "# Machado, Oliveira and Fernandes (2009): full deuteranopia, applied to linear RGB.\nDEUTAN = [[0.367322, 0.860646, -0.227968],\n          [0.280085, 0.672501, 0.047413],\n          [-0.011820, 0.042940, 0.968881]]\n\n", "note": "The simulation matrix for full deuteranopia, from Machado, Oliveira and Fernandes, applied to linear light."}, {"code": "def to_linear(hex_colour):\n    out = []\n    for i in (1, 3, 5):\n        c = int(hex_colour[i:i + 2], 16) / 255\n        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)\n    return out\n\n", "note": "Convert a hex colour to linear light. Every calculation below happens in linear light, as in lesson 11."}, {"code": "def to_hex(linear):\n    out = \"\"\n    for c in linear:\n        c = min(1.0, max(0.0, c))\n        c = 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055\n        out += f\"{round(c * 255):02x}\"\n    return \"#\" + out\n\n", "note": "And back again, clipping to what a screen can show."}, {"code": "def luminance(hex_colour):\n    r, g, b = to_linear(hex_colour)\n    return 0.2126 * r + 0.7152 * g + 0.0722 * b\n\n", "note": "Relative luminance, by the WCAG weights."}, {"code": "def contrast(a, b):\n    la, lb = sorted([luminance(a), luminance(b)], reverse=True)\n    return (la + 0.05) / (lb + 0.05)\n\n", "note": "The WCAG contrast ratio: the lighter luminance plus 0.05, divided by the darker plus 0.05."}, {"code": "def deutan(hex_colour):\n    rgb = to_linear(hex_colour)\n    return to_hex([sum(m * c for m, c in zip(row, rgb)) for row in DEUTAN])\n\n", "note": "Apply the matrix to one colour: what a person with deuteranopia perceives, as a hex colour."}, {"code": "for pair in sys.argv[1:]:\n    a, b = pair.split(\":\")\n    print(f\"{a} on {b}: {contrast(a, b):5.2f} : 1   \"\n          f\"as deuteranopia sees them, {deutan(a)} and {deutan(b)}: \"\n          f\"{contrast(deutan(a), deutan(b)):5.2f} : 1\")\n", "note": "For each pair given as `foreground:background`, print the contrast as most people see it and as deuteranopia sees it."}]}
```

```
ana@vm:~/viz$ .venv/bin/python access.py "#d62728:#2ca02c" "#d62728:#1f77b4" "#c8ccd4:#ffffff" "#767676:#ffffff" "#5a6274:#ffffff"
#d62728 on #2ca02c:  1.48 : 1   as deuteranopia sees them, #8b7c1f and #968838:  1.17 : 1
#d62728 on #1f77b4:  1.04 : 1   as deuteranopia sees them, #8b7c1f and #456cb3:  1.24 : 1
#c8ccd4 on #ffffff:  1.61 : 1   as deuteranopia sees them, #c9cbd4 and #ffffff:  1.62 : 1
#767676 on #ffffff:  4.54 : 1   as deuteranopia sees them, #767676 and #ffffff:  4.54 : 1
#5a6274 on #ffffff:  6.12 : 1   as deuteranopia sees them, #5a6174 and #ffffff:  6.18 : 1
```

Five pairs, five lessons:

- **Red and green**, matplotlib's `tab:red` and `tab:green`, have a contrast of only 1.48:1, and for
  deuteranopia they become `#8b7c1f` and `#968838`, two olives at 1.17:1. Nothing separates them.
- Red and blue have even less contrast, 1.04:1, and still work as two series, because for
  deuteranopia they become olive and blue: **the hues stay different**. Contrast measures lightness;
  telling two series apart can also come from hue, as long as the hues survive.
- **`#c8ccd4` on white, 1.61:1, fails the 3:1 that a needed bar requires.** It is the grey lesson 13's
  `highlight.py` used for the context bars, chosen by eye because it looked quiet. Measured, it is too
  quiet: a reader with low vision, or anyone on a washed-out projector, loses the context the
  highlight depends on.
- **`#767676` on white, 4.54:1**, is the lightest grey that passes for text. It is a useful number to
  remember.
- **`#5a6274`, 6.12:1**, the dim text colour of this course's light theme, passes comfortably.

## What to measure on a chart

- **Every piece of text**: titles, labels, tick values, annotations, against the background behind
  them. 4.5:1.
- **Every mark a reader needs**: bars, lines, points, against the background, and against neighbours
  when they touch, such as the segments of a stacked bar. 3:1, or a visible border between them.
- **Gridlines do not count**, as long as the chart can be read without them. They are meant to be
  quiet.
