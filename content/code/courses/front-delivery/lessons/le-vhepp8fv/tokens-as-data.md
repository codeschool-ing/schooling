---
title: The planner's tokens, as data
version: 1
---

**The planner's tokens live in one JSON file at the root of the project, and a short script writes them
out as CSS.** Nothing in the stylesheet holds a colour or a size of its own any more; every value comes
from the file, through the script. That one direction, data to CSS and never back, is what lets the same
file feed other outputs later.

The file follows the shape of the **Design Tokens Community Group** format, the W3C community group's
specification for exchanging tokens between tools: each token is an object with a `$value` and, where it
matters, a `$type`, and one token refers to another as `{group.name}`. It simplifies one thing: colours are
written as plain hex strings, where the format's stable version writes an object naming the colour space.

```schooling-example
{"language": "json", "file": "tokens.json", "parts": [
 {"code": "{\n  \"color\": {\n    \"green-300\": { \"$type\": \"color\", \"$value\": \"#7fbf9a\" },\n    \"green-600\": { \"$type\": \"color\", \"$value\": \"#2f6f4e\" },\n    \"grey-0\": { \"$type\": \"color\", \"$value\": \"#ffffff\" },\n    \"grey-50\": { \"$type\": \"color\", \"$value\": \"#f4f6f5\" },\n    \"grey-300\": { \"$type\": \"color\", \"$value\": \"#aeb6bd\" },\n    \"grey-400\": { \"$type\": \"color\", \"$value\": \"#8a939b\" },\n    \"grey-600\": { \"$type\": \"color\", \"$value\": \"#59626a\" },\n    \"grey-800\": { \"$type\": \"color\", \"$value\": \"#2a3036\" },\n    \"grey-900\": { \"$type\": \"color\", \"$value\": \"#16191d\" }\n  },", "note": "The primitives: every colour the planner may use, named by hue and lightness, 0 lightest and 900 darkest. Nothing in the app refers to these directly."},
 {"code": "  \"theme\": {\n    \"light\": {\n      \"surface\": { \"$value\": \"{color.grey-0}\" },\n      \"raised\": { \"$value\": \"{color.grey-50}\" },\n      \"text\": { \"$value\": \"{color.grey-900}\" },\n      \"muted\": { \"$value\": \"{color.grey-600}\" },\n      \"accent\": { \"$value\": \"{color.green-600}\" },\n      \"on-accent\": { \"$value\": \"{color.grey-0}\" }\n    },", "note": "The semantic layer, for the light theme. Six meanings: the page, a raised panel, text, quieter text, the action colour, and text written on the action colour. Each refers to a primitive by name."},
 {"code": "    \"dark\": {\n      \"surface\": { \"$value\": \"{color.grey-900}\" },\n      \"raised\": { \"$value\": \"{color.grey-800}\" },\n      \"text\": { \"$value\": \"{color.grey-50}\" },\n      \"muted\": { \"$value\": \"{color.grey-300}\" },\n      \"accent\": { \"$value\": \"{color.green-300}\" },\n      \"on-accent\": { \"$value\": \"{color.grey-900}\" }\n    }\n  },", "note": "The same six names for the dark theme, pointing at other primitives. The accent is a lighter green here, because the brand's dark green would be unreadable on a near-black page."},
 {"code": "  \"type\": {\n    \"base\": { \"$type\": \"dimension\", \"$value\": \"1rem\" },\n    \"ratio\": { \"$type\": \"number\", \"$value\": 1.25 },\n    \"steps\": { \"$type\": \"number\", \"$value\": 5 }\n  },", "note": "Not a list of sizes but the rule that makes them: a base, a ratio and how many steps. The next section is about it."},
 {"code": "  \"space\": {\n    \"unit\": { \"$type\": \"dimension\", \"$value\": \"0.25rem\" },\n    \"steps\": { \"$type\": \"number\", \"$value\": 8 }\n  }\n}", "note": "The same for spacing: a unit of a quarter of a rem, four pixels at the browser's default size, and eight multiples of it."}
]}
```

## The script

`tokens.mjs` reads that file and writes `src/tokens.css`. It is plain Node with nothing installed:

```schooling-example
{"language": "javascript", "file": "tokens.mjs", "parts": [
 {"code": "// tokens.mjs\nimport { readFile, writeFile } from \"node:fs/promises\";\n\nconst tokens = JSON.parse(await readFile(\"tokens.json\", \"utf8\"));\nconst css = (ref) => ref.replace(/\\{color\\.([\\w-]+)\\}/, \"var(--color-$1)\");\nconst lines = [\"/* src/tokens.css is written by tokens.mjs from tokens.json: edit those, not this */\", \":root {\"];", "note": "A reference such as `{color.grey-0}` becomes `var(--color-grey-0)`, so a semantic token in CSS still points at its primitive rather than copying the hex. The first line of the output says where it came from, so nobody edits it by hand."},
 {"code": "for (const [name, token] of Object.entries(tokens.color)) lines.push(`  --color-${name}: ${token.$value};`);", "note": "Every primitive, as a custom property."},
 {"code": "const base = parseFloat(tokens.type.base.$value);\nfor (let step = 0; step < tokens.type.steps.$value; step++) {\n  lines.push(`  --font-size-${step}: ${+(base * tokens.type.ratio.$value ** step).toFixed(3)}rem;`);\n}\nconst unit = parseFloat(tokens.space.unit.$value);\nfor (let n = 1; n <= tokens.space.steps.$value; n++) lines.push(`  --space-${n}: ${unit * n}rem;`);\nlines.push(\"}\");", "note": "The two scales, computed from their rules. `toFixed(3)` and the `+` in front of it round to three decimals and drop any trailing zeros."},
 {"code": "const theme = (name) => Object.entries(tokens.theme[name]).map(([key, token]) => `  --${key}: ${css(token.$value)};`);\nlines.push(\"\", \":root,\", '[data-theme=\"light\"] {', ...theme(\"light\"), \"}\");\nlines.push(\"\", \"@media (prefers-color-scheme: dark) {\", '  :root:not([data-theme=\"light\"]) {', ...theme(\"dark\").map((l) => \"  \" + l), \"  }\", \"}\");\nlines.push(\"\", '[data-theme=\"dark\"] {', ...theme(\"dark\"), \"}\");", "note": "The themes, three times: light by default, dark when the reader's system asks for it, and either one when the page sets `data-theme` on an element, which overrides the system. The section on themes explains the selectors."},
 {"code": "await writeFile(\"src/tokens.css\", lines.join(\"\\n\") + \"\\n\");\nconsole.log(`src/tokens.css: ${lines.length} lines`);", "note": "Written whole every time, so the CSS can never hold something the JSON does not."}
]}
```

Run it, through an npm script so the command is in `package.json` for everybody:

```
ana@dev:~/planner$ npm pkg set scripts.tokens="node tokens.mjs"
ana@dev:~/planner$ npm run tokens

> planner@0.0.0 tokens
> node tokens.mjs

src/tokens.css: 55 lines
ana@dev:~/planner$ sed -n '1,14p' src/tokens.css
/* src/tokens.css is written by tokens.mjs from tokens.json: edit those, not this */
:root {
  --color-green-300: #7fbf9a;
  --color-green-600: #2f6f4e;
  --color-grey-0: #ffffff;
  --color-grey-50: #f4f6f5;
  --color-grey-300: #aeb6bd;
  --color-grey-400: #8a939b;
  --color-grey-600: #59626a;
  --color-grey-800: #2a3036;
  --color-grey-900: #16191d;
  --font-size-0: 1rem;
  --font-size-1: 1.25rem;
  --font-size-2: 1.563rem;
```

**Commit `src/tokens.css` along with its source**, even though it is generated. The build reads it, and a
fresh clone has to build without running anything first. What keeps it honest is a check the next lessons
could add to CI: run `npm run tokens` and fail if `git diff` shows a change, which means somebody edited
the CSS by hand or forgot to run the script.

The planner does this in twenty lines. **Style Dictionary**, an open-source tool, is what most teams
use for the same job at scale: it reads the same kind of file and writes CSS, JavaScript, Android and iOS
outputs from it, with transforms for each platform. The idea is identical, and reading twenty lines first
makes its configuration much less mysterious.
