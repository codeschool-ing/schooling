---
title: Measuring a colour yourself
version: 1
---

A colour's real brightness can be computed in a few lines, and doing it once makes the previous two
sections concrete.

```schooling-example
{"language": "python", "file": "colours.py", "parts": [{"code": "import colorsys\nimport sys\n"}, {"code": "\ndef channels(hex_colour):\n    return [int(hex_colour[i:i + 2], 16) / 255 for i in (1, 3, 5)]\n", "note": "Turn a colour written as `#rrggbb` into three numbers between 0 and 1."}, {"code": "\ndef linear(c):\n    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4\n", "note": "Screens store colour with a curve applied, called gamma. `linear` undoes it, because brightness adds up only in linear light."}, {"code": "\ndef oklab_lightness(rgb):\n    r, g, b = (linear(c) for c in rgb)\n    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)\n    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)\n    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)\n    return 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s\n", "note": "OKLab lightness, from Björn Ottosson's published matrices: linear light, then a matrix, then a cube root, then the weighted sum that is L."}, {"code": "\nprint(\"colour     hue  sat  light(HSL)  luminance  OKLab L\")\nfor hex_colour in sys.argv[1:]:\n    rgb = channels(hex_colour)\n    h, l, s = colorsys.rgb_to_hls(*rgb)\n    r, g, b = (linear(c) for c in rgb)\n    luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b\n    print(f\"{hex_colour}  {h * 360:4.0f} {s:4.0%}  {l:9.0%}  {luminance:9.3f}  {oklab_lightness(rgb):7.3f}\")\n", "note": "For each colour given on the command line, print its HSL values from Python's own `colorsys`, its relative luminance by the WCAG weights, and its OKLab lightness."}]}
```

```
ana@vm:~/viz$ .venv/bin/python colours.py "#ff0000" "#ffff00" "#00ff00" "#00ffff" "#0000ff" "#ff00ff"
colour     hue  sat  light(HSL)  luminance  OKLab L
#ff0000     0 100%        50%      0.213    0.628
#ffff00    60 100%        50%      0.928    0.968
#00ff00   120 100%        50%      0.715    0.866
#00ffff   180 100%        50%      0.787    0.905
#0000ff   240 100%        50%      0.072    0.452
#ff00ff   300 100%        50%      0.285    0.702
```

Read the columns from left to right:

- **hue** goes round the circle in 60-degree steps, as it should;
- **saturation** and **HSL lightness** are 100% and 50% for all six, so by HSL they are equally vivid
  and equally light;
- **luminance** runs from 0.072 for blue to 0.928 for yellow, the thirteenfold difference from the
  figure;
- **OKLab lightness** agrees on the order, blue darkest and yellow lightest, and compresses the range,
  0.452 to 0.968, because perceived lightness grows more slowly than physical brightness.

## Two quick checks without code

**Turn the chart grey.** Most image editors and operating systems have a greyscale mode, and some
browsers' developer tools can simulate it. A chart whose meaning survives in grey has a palette that
works by lightness; one that turns into identical greys was relying on hue alone.

**Squint.** Blurring your eyes removes detail and leaves lightness. Whatever stands out when you squint
is what stands out to a hurried reader.

## In a spreadsheet

Spreadsheets do not report luminance, but every colour dialog shows the RGB values, and the formula
above can be typed into cells: one column per channel, the linear conversion, and the weighted sum.
It is worth doing once for your organisation's brand colours, which are often chosen for logos and not
for charts.
