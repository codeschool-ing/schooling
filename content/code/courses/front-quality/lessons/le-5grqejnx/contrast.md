---
title: Contrast is arithmetic
version: 1
---

**A contrast ratio compares how much light two colours give off, and it is computed, not judged.** Lesson
10 took two of them from axe, 2.32:1 and 5.33:1. This section works them out, so that a colour can be
chosen before anybody runs a checker on it.

WCAG defines it in two steps. First the **relative luminance** of each colour, from 0 for black to 1 for white. Each channel is turned
from the screen's encoded value into the light it actually makes, and the three are added with weights
for how sensitive the eye is to each, green most and blue least. Then the
**ratio** of the lighter to the darker, with 0.05 added to both for the light a screen reflects:

| step | formula |
|---|---|
| channel, as light | *c* / 12.92 if *c* ≤ 0.04045, otherwise ((*c* + 0.055) / 1.055)^2.4, for *c* from 0 to 1 |
| relative luminance | *L* = 0.2126 *R* + 0.7152 *G* + 0.0722 *B* |
| contrast ratio | (*L*₁ + 0.05) / (*L*₂ + 0.05), lighter over darker, from 1:1 to 21:1 |

## The thresholds

| what | AA | AAA | criterion |
|---|---|---|---|
| text | 4.5:1 | 7:1 | 1.4.3, 1.4.6 |
| large text: 24 px, or 18.66 px bold | 3:1 | 4.5:1 | 1.4.3, 1.4.6 |
| the parts of a control, a focus ring, a graph's lines | 3:1 | none | 1.4.11 |
| a disabled control, a logo, pure decoration | none | none | exempt |

## The arithmetic, in the planner

Here is the formula as a module, `src/contrast.ts`:

```schooling-example
{"language": "typescript", "file": "src/contrast.ts", "parts": [{"code": "// src/contrast.ts\nexport function luminance(hex: string): number {\n  const [r, g, b] = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255);\n", "note": "A colour written `#rrggbb` holds three channels of two hex digits each. Each is read and divided by 255, so that it runs from 0 to 1."}, {"code": "  const light = (c: number) => (c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);\n", "note": "A screen stores a channel encoded, not as the light it makes; this undoes the encoding. WCAG 2.2 writes the threshold as 0.04045, where older versions wrote 0.03928, and no 8-bit colour falls between the two."}, {"code": "  return 0.2126 * light(r) + 0.7152 * light(g) + 0.0722 * light(b);\n}\n", "note": "The three are weighted by how sensitive the eye is to each: green most, blue least. White gives 1 and black 0."}, {"code": "export function contrast(a: string, b: string): number {\n  const [lighter, darker] = [luminance(a), luminance(b)].sort((x, y) => y - x);\n  return (lighter + 0.05) / (darker + 0.05);\n}", "note": "The lighter over the darker, whichever order they come in, with 0.05 added to both for the light the screen reflects. Black on white is (1 + 0.05) / (0 + 0.05), which is 21."}]}
```

And a test that holds it to the numbers axe printed in lesson 10. Save it as `src/contrast.test.ts`:

```typescript
// src/contrast.test.ts
import { expect, test } from "vitest";
import { contrast } from "./contrast";

test("the arithmetic agrees with axe", () => {
  expect(contrast("#aaaaaa", "#ffffff")).toBeCloseTo(2.32, 2);
  expect(contrast("#6b6b6b", "#ffffff")).toBeCloseTo(5.33, 2);
  expect(contrast("#000000", "#ffffff")).toBe(21);
  expect(contrast("#ffffff", "#000000")).toBe(21);
});
```

```
ana@dev:~/planner$ npx vitest run src/contrast.test.ts

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  1 passed (1)
   Start at  21:35:49
   Duration  229ms (transform 73%, import 16%, worker 7%, tests 4%)
```

The last two lines say that the order of the arguments does not matter, which is the `sort` in
`contrast`. `toBeCloseTo(2.32, 2)` accepts anything that rounds to 2.32 at two decimals, which is how
axe reports it.
