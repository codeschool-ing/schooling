---
title: Colour, and the contrast every pair must reach
version: 1
---

**Every pair of text and background the tokens can produce has to be readable, and readable is a number:
the contrast ratio WCAG defines, at least 4.5 to 1 for ordinary text at level AA.** The ratio compares the
relative luminance of the two colours, from 1 for identical colours to 21 for black on white. It can be
checked by eye only by people with the eyes it is meant to protect, so it is checked by a script.

## The check

`contrast.mjs` reads the same `tokens.json`, resolves each semantic token to its hex, and measures the six
pairs the planner actually draws, in both themes:

```schooling-example
{"language": "javascript", "file": "contrast.mjs", "parts": [
 {"code": "// contrast.mjs\nimport { readFile } from \"node:fs/promises\";\n\nconst tokens = JSON.parse(await readFile(\"tokens.json\", \"utf8\"));\nconst hex = (ref) => tokens.color[ref.match(/\\{color\\.([\\w-]+)\\}/)[1]].$value;", "note": "From `{color.grey-600}` to `#59626a`, by looking the primitive up."},
 {"code": "const luminance = (h) => {\n  const [r, g, b] = [1, 3, 5]\n    .map((i) => parseInt(h.slice(i, i + 2), 16) / 255)\n    .map((c) => (c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4));\n  return 0.2126 * r + 0.7152 * g + 0.0722 * b;\n};", "note": "WCAG's relative luminance: each channel from 0 to 1, made linear by the sRGB curve, then weighted the way the eye weights them, green most and blue least."},
 {"code": "const ratio = (a, b) => {\n  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);\n  return (hi + 0.05) / (lo + 0.05);\n};", "note": "The contrast ratio: the lighter over the darker, each plus 0.05. The order of the two colours does not matter."},
 {"code": "const pairs = [[\"text\", \"surface\"], [\"text\", \"raised\"], [\"muted\", \"surface\"], [\"muted\", \"raised\"], [\"accent\", \"surface\"], [\"on-accent\", \"accent\"]];\nlet failed = 0;\nfor (const name of Object.keys(tokens.theme)) {\n  for (const [fg, bg] of pairs) {\n    const r = ratio(hex(tokens.theme[name][fg].$value), hex(tokens.theme[name][bg].$value));\n    const ok = r >= 4.5;\n    if (!ok) failed++;\n    console.log(`${name.padEnd(6)} ${`${fg} on ${bg}`.padEnd(20)} ${r.toFixed(2).padStart(5)}  ${ok ? \"AA\" : \"FAIL\"}`);\n  }\n}\nprocess.exitCode = failed ? 1 : 0;", "note": "Every pair the planner draws, in every theme the file has. A failure sets the exit code, so the script can stop a pipeline the way a failing test does."}
]}
```

```
ana@dev:~/planner$ npm pkg set scripts.contrast="node contrast.mjs"
ana@dev:~/planner$ npm run contrast

> planner@0.0.0 contrast
> node contrast.mjs

light  text on surface      17.63  AA
light  text on raised       16.25  AA
light  muted on surface      6.21  AA
light  muted on raised       5.72  AA
light  accent on surface     5.99  AA
light  on-accent on accent   5.99  AA
dark   text on surface      16.25  AA
dark   text on raised       12.29  AA
dark   muted on surface      8.59  AA
dark   muted on raised       6.49  AA
dark   accent on surface     8.25  AA
dark   on-accent on accent   8.25  AA
```

Twelve pairs, all at AA. **Now see what it is for.** The first draft of these tokens used `grey-400` for
quieter text, a grey that looks perfectly readable on a bright screen to somebody with good eyesight. Put
it back in the light theme:

```
ana@dev:~/planner$ sed -i 's/{color.grey-600}/{color.grey-400}/' tokens.json
ana@dev:~/planner$ node contrast.mjs
light  text on surface      17.63  AA
light  text on raised       16.25  AA
light  muted on surface      3.12  FAIL
light  muted on raised       2.88  FAIL
light  accent on surface     5.99  AA
light  on-accent on accent   5.99  AA
dark   text on surface      16.25  AA
dark   text on raised       12.29  AA
dark   muted on surface      8.59  AA
dark   muted on raised       6.49  AA
dark   accent on surface     8.25  AA
dark   on-accent on accent   8.25  AA
ana@dev:~/planner$ sed -i 's/{color.grey-400}/{color.grey-600}/' tokens.json
```

**3.12 on white and 2.88 on the raised panel**, where 4.5 is the floor, and the last command put the
right grey back. Nobody looking at the screen would have called that a bug. The dark theme has its own version of the same trap: `grey-400` passes on
the dark page and fails on the dark raised panel, so **a colour has to be checked against every surface
it can land on, in every theme**, which is why the script measures pairs rather than colours:

```
ana@dev:~/planner$ sed -i 's/{color.grey-300}/{color.grey-400}/' tokens.json
ana@dev:~/planner$ node contrast.mjs | grep FAIL
dark   muted on raised       4.27  FAIL
ana@dev:~/planner$ sed -i 's/{color.grey-400}/{color.grey-300}/' tokens.json
```

## Where the check belongs

In the pipeline, beside the type check. A token change is a change to every screen at once, and a
contrast failure introduced by one is exactly the kind of mistake nobody notices in review. Adding
`npm run contrast` as a step in lesson 3's workflow puts it there. The ratio is not the whole of
accessibility: it says nothing about colour used as the only signal, or text over an image. It is the
part that is arithmetic, and arithmetic is what a machine should do.
