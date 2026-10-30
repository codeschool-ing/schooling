---
title: The safe area and the add-session button, worked out
version: 1
---

**This program takes a screen and its insets, works out the safe area, and then places the
planner's add-session button three ways: on the screen's edge, on the safe area's edge, and above
the keyboard.** For each placement it says what covers the button, if anything. The screen size,
the insets and the keyboard's height are **example values**, round numbers of the kind a phone
reports in points or dp; they are not measurements of any particular phone, and a real device
reports its own. Save it as `insets.ts` in `~/planner`:

```typescript
// insets.ts: the part of a screen an app can use, and whether the keyboard hides a button
type Insets = { top: number; bottom: number; left: number; right: number };
type Case = { name: string; w: number; h: number; insets: Insets; keyboard: number };

// Example values in dp or points, round numbers of the kind a phone reports.
// They are not measurements of any particular device.
const cases: Case[] = [
  { name: "portrait", w: 390, h: 844, insets: { top: 48, bottom: 32, left: 0, right: 0 }, keyboard: 0 },
  { name: "landscape", w: 844, h: 390, insets: { top: 0, bottom: 24, left: 48, right: 48 }, keyboard: 0 },
  { name: "portrait, keyboard up", w: 390, h: 844, insets: { top: 48, bottom: 32, left: 0, right: 0 }, keyboard: 300 },
];

const BUTTON = 48; // the "add session" button's height
const MARGIN = 16; // its gap above whatever edge it sits on

// Where the button lands if its bottom edge sits MARGIN above `edge`
function button(edge: number) {
  return { top: edge - MARGIN - BUTTON, bottom: edge - MARGIN };
}

// What covers it: the keyboard, the bottom inset, or nothing
function covered(b: { top: number; bottom: number }, c: Case): string {
  if (c.keyboard > 0 && b.bottom > c.h - c.keyboard) return "under the keyboard";
  if (b.bottom > c.h - c.insets.bottom) return "under the bottom inset";
  return "clear";
}

for (const c of cases) {
  const i = c.insets;
  const safe = { x0: i.left, x1: c.w - i.right, y0: i.top, y1: c.h - i.bottom };
  console.log(`${c.name}: screen ${c.w} x ${c.h}, keyboard ${c.keyboard}`);
  console.log(`  ${"safe area".padEnd(26)} x ${safe.x0}-${safe.x1}, y ${safe.y0}-${safe.y1}` +
    ` (${safe.x1 - safe.x0} x ${safe.y1 - safe.y0})`);
  const placements: [string, number][] = [
    ["at the screen edge", c.h],
    ["in the safe area", c.h - i.bottom],
    ["above the keyboard", c.h - Math.max(i.bottom, c.keyboard)],
  ];
  for (const [label, edge] of placements) {
    if (label === "above the keyboard" && c.keyboard === 0) continue;
    const b = button(edge);
    console.log(`  button ${label.padEnd(19)} y ${b.top}-${b.bottom}  ${covered(b, c)}`);
  }
}
```

```
ana@dev:~/planner$ node insets.ts
portrait: screen 390 x 844, keyboard 0
  safe area                  x 0-390, y 48-812 (390 x 764)
  button at the screen edge  y 780-828  under the bottom inset
  button in the safe area    y 748-796  clear
landscape: screen 844 x 390, keyboard 0
  safe area                  x 48-796, y 0-366 (748 x 366)
  button at the screen edge  y 326-374  under the bottom inset
  button in the safe area    y 302-350  clear
portrait, keyboard up: screen 390 x 844, keyboard 300
  safe area                  x 0-390, y 48-812 (390 x 764)
  button at the screen edge  y 780-828  under the keyboard
  button in the safe area    y 748-796  under the keyboard
  button above the keyboard  y 480-528  clear
```

## Reading it

**In portrait with no keyboard, the safe area is the screen less 48 at the top and 32 at the
bottom**: 390 by 764 out of 390 by 844. A button placed 16 above the screen's own bottom edge
lands between 780 and 828, and the bottom inset starts at 812, so the gesture area covers its
lower part. Placed 16 above the safe area's bottom instead, at 748 to 796, it is clear. That is
the whole of the first mistake and its fix, in two lines.

**In landscape the insets move to the sides.** The example puts 48 on the left and on the right,
where the cutout and the rounded corners now are, and only 24 at the bottom, so the safe area is
748 wide and 366 tall. The button follows the same rule and is clear in the safe area again. An
app that read "top 48" at launch and kept it would now leave an empty band at the top and draw
its list into the cutout at the side.

**With the keyboard up, the safe area alone is not enough.** The keyboard is 300 tall and covers
everything below 544, so the button at 748 to 796, clear a moment ago, is under the keys. Placed
16 above the higher of the two bottom edges, the keyboard's top or the safe area's bottom, it lands
at 480 to 528 and is clear. That `Math.max` is the line each platform's tool from the previous
section runs for you: `imePadding()`, SwiftUI's keyboard region, `KeyboardAvoidingView`.

## What the program leaves out

It works in one dimension, the height, because the button and the keyboard are both at the bottom;
a real layout applies the left and right insets to the button's width too, which the safe area
line already shows. It treats the keyboard as appearing at once, where a real one animates, and
an app can follow the animation frame by frame, on the main thread of lesson 6. And it knows
nothing about how tall the keyboard really is: a phone's keyboard can change height with the
language, the suggestion bar and the user's own settings, which is the reason every platform
reports it as an inset rather than a constant.
