---
title: Contrast, computed rather than judged by eye
version: 1
---

**Whether a colour can be read against another is a number, and the number is a published formula,
not a matter of taste.** A designer at a bright monitor sees a pale grey date perfectly well. A
student on a cheap screen, outdoors, with the brightness turned down to save battery, or with low
vision, does not. The Web Content Accessibility Guidelines, WCAG 2.2, published by the W3C at
`w3.org/TR/WCAG22`, define the arithmetic, and both platforms point at it: the HIG's accessibility
page names WCAG, and Android's documentation gives the same thresholds in its own units.

## The thresholds

| what | ratio at least | WCAG 2.2 |
|---|---|---|
| ordinary text | **4.5 : 1** | 1.4.3 Contrast (Minimum), level AA |
| large text: 18 point, or 14 point bold | **3 : 1** | the same criterion's exception for large-scale text |
| the parts of a control a user needs to see it, such as a checkbox's edge | **3 : 1** | 1.4.11 Non-text Contrast, level AA |

Android's documentation states the text rule in `sp`: 4.5:1 for text smaller than 18sp, or bold
and smaller than 14sp, and 3:1 for the rest. The HIG's table says the same in points. **Both apply in
each appearance separately**, which is why the planner checks its light and its dark colours.

## The formula

WCAG defines it in two steps. The **relative luminance** of a colour is its brightness on a scale
from 0 for black to 1 for white, computed from its red, green and blue after undoing the curve sRGB
stores them with. The **contrast ratio** of two colours is the lighter luminance plus 0.05, divided
by the darker plus 0.05: 1 for a colour against itself, 21 for black on white. Both definitions were
read from the W3C's text of WCAG 2.2 on 30 October 2026, and the program follows them line for line.
Save it as `contrast.ts` in `~/planner`, beside lesson 18's `tokens.ts`, which it reads its colours
from:

```schooling-example
{"language": "typescript", "file": "contrast.ts", "parts": [{"code": "// contrast.ts: WCAG's contrast ratio, checked on the planner's colour pairs\nimport { brand } from \"./tokens.ts\";\n", "note": "The program reads the planner's colours from lesson 18's `tokens.ts`, so it checks the colours both themes actually use, not a copy of them."}, {"code": "// Relative luminance of an sRGB colour such as \"#2F6F4E\", as WCAG 2.2 defines it.\nexport function luminance(hex: string): number {\n  const [r, g, b] = [1, 3, 5].map((i) => {\n    const c = parseInt(hex.slice(i, i + 2), 16) / 255;\n    return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;\n  });\n  return 0.2126 * r + 0.7152 * g + 0.0722 * b;\n}\n", "note": "WCAG's relative luminance, line for line: each channel from 0 to 255 becomes 0 to 1, the sRGB curve is undone, and the three are weighted. Green weighs most because the eye is most sensitive to it."}, {"code": "// (lighter + 0.05) / (darker + 0.05): 1 for the same colour, 21 for black on white.\nexport function ratio(a: string, b: string): number {\n  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);\n  return (hi + 0.05) / (lo + 0.05);\n}\n", "note": "The ratio itself. Sorting puts the lighter colour on top, so the order the pair is written in does not matter."}, {"code": "// Each pair the planner draws, and what WCAG asks of it: 4.5 for text, 3 for a control's edge.\nconst pairs = [\n  { what: \"session title\", fg: \"onSurface\", bg: \"surface\", need: 4.5 },\n  { what: \"date under it\", fg: \"muted\", bg: \"surface\", need: 4.5 },\n  { what: \"button label\", fg: \"onPrimary\", bg: \"primary\", need: 4.5 },\n  { what: \"checkbox edge\", fg: \"primary\", bg: \"surface\", need: 3 },\n] as const;\n", "note": "Four pairs the week screen draws, each with the threshold that applies to it: text needs 4.5, the edge of a control 3. The names are keys of `brand.light` and `brand.dark`."}, {"code": "let failed = 0;\nfor (const mode of [\"light\", \"dark\"] as const) {\n  for (const p of pairs) {\n    const fg = brand[mode][p.fg];\n    const bg = brand[mode][p.bg];\n    const r = ratio(fg, bg);\n    const ok = r >= p.need;\n    if (!ok) failed++;\n    console.log(`${mode.padEnd(6)}${p.what.padEnd(15)}${fg} on ${bg}  ${r.toFixed(2).padStart(5)}:1  needs ${p.need}  ${ok ? \"pass\" : \"FAIL\"}`);\n  }\n}\nconsole.log(failed === 0 ? \"every pair passes\" : `${failed} pair(s) fail`);\nprocess.exitCode = failed === 0 ? 0 : 1;", "note": "Every pair, in both appearances, with the ratio to two decimals so that a near miss shows as one. A failure also sets the exit code to 1."}]}
```

Run it:

```
ana@dev:~/planner$ node contrast.ts; echo "exit $?"
light session title  #1C1B1F on #FFFFFF  17.13:1  needs 4.5  pass
light date under it  #8A8A8A on #FFFFFF   3.45:1  needs 4.5  FAIL
light button label   #FFFFFF on #2F6F4E   5.99:1  needs 4.5  pass
light checkbox edge  #2F6F4E on #FFFFFF   5.99:1  needs 3  pass
dark  session title  #E6E1E5 on #1C1B1F  13.27:1  needs 4.5  pass
dark  date under it  #938F99 on #1C1B1F   5.41:1  needs 4.5  pass
dark  button label   #00391F on #8FD3AE   7.54:1  needs 4.5  pass
dark  checkbox edge  #8FD3AE on #1C1B1F   9.87:1  needs 3  pass
1 pair(s) fail
exit 1
```

**One pair fails, and it is the one lesson 18 left a question over.** The date under each session is
`muted`, `#8A8A8A`, on white: 3.45:1 against the 4.5 that text needs. The same grey's dark
counterpart passes at 5.41, and every other pair passes easily. The program also sets its exit code
to 1 when anything fails, which is what lets a check like this one stop a build.

## The fix, made in one place

**A failing colour is fixed by moving its lightness, and the smallest move that passes keeps the
design closest to what was intended.** The brand wanted a quiet grey under a dark title, and that
intention survives a slightly darker grey. In `tokens.ts`, change the light `muted` from `"#8A8A8A"`
to `"#777777"`, a step darker, and run the check again:

```
ana@dev:~/planner$ node contrast.ts; echo "exit $?"
light session title  #1C1B1F on #FFFFFF  17.13:1  needs 4.5  pass
light date under it  #777777 on #FFFFFF   4.48:1  needs 4.5  FAIL
light button label   #FFFFFF on #2F6F4E   5.99:1  needs 4.5  pass
light checkbox edge  #2F6F4E on #FFFFFF   5.99:1  needs 3  pass
dark  session title  #E6E1E5 on #1C1B1F  13.27:1  needs 4.5  pass
dark  date under it  #938F99 on #1C1B1F   5.41:1  needs 4.5  pass
dark  button label   #00391F on #8FD3AE   7.54:1  needs 4.5  pass
dark  checkbox edge  #8FD3AE on #1C1B1F   9.87:1  needs 3  pass
1 pair(s) fail
exit 1
```

**4.48 is not 4.5, and a threshold is a threshold.** Rounded to one decimal it would look like a
pass, which is why the program prints two. One more step does it. Change `"#777777"` to `"#767676"`:

```
ana@dev:~/planner$ node contrast.ts; echo "exit $?"
light session title  #1C1B1F on #FFFFFF  17.13:1  needs 4.5  pass
light date under it  #767676 on #FFFFFF   4.54:1  needs 4.5  pass
light button label   #FFFFFF on #2F6F4E   5.99:1  needs 4.5  pass
light checkbox edge  #2F6F4E on #FFFFFF   5.99:1  needs 3  pass
dark  session title  #E6E1E5 on #1C1B1F  13.27:1  needs 4.5  pass
dark  date under it  #938F99 on #1C1B1F   5.41:1  needs 4.5  pass
dark  button label   #00391F on #8FD3AE   7.54:1  needs 4.5  pass
dark  checkbox edge  #8FD3AE on #1C1B1F   9.87:1  needs 3  pass
every pair passes
exit 0
```

`#767676` reaches 4.54:1, the lightest neutral grey, red, green and blue all equal, that passes on
white. The edit was one
line in `tokens.ts`, and both themes from lesson 18 read it, so the Material theme's
`onSurfaceVariant` and the iOS theme's `secondaryLabel` changed together. That is the arrangement
lesson 18 made the case for, paying for itself.

## What the number does not cover

**Contrast measures two flat colours.** Text over a photograph, over a gradient or over Liquid
Glass, which lets the content beneath show through, has no single background to measure against,
and the HIG asks that it be checked in each appearance and with the system's Increase Contrast
setting turned on. **And contrast says nothing about colour blindness**: two colours can have
excellent contrast against white and be the same to a person who cannot tell red from green, which
is the next section's last subject.
