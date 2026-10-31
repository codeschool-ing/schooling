---
title: Flexbox, with two defaults turned around
version: 1
---

**Every `View` is a flex container, and Flexbox is the only layout there is.** No floats, no grid, no
`display: block`. The properties are the web's, `flexDirection`, `justifyContent`, `alignItems`,
`flex`, `gap`, and Yoga computes them, as lesson 1 described. Two defaults differ from the web's, and
both explain screens that look wrong on the first try.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l05-axes\" aria-label=\"Two flex containers. On the left, the default: flexDirection column, so the main axis runs top to bottom, justifyContent moves children along it and alignItems across it, and children stretch across by default. On the right, flexDirection row, as the planner's header uses: the main axis runs left to right, and alignItems center centres the icon and the title vertically.\"><defs><marker id=\"l05-axes-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l05-axes-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"160\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">flexDirection: column (default)</text><rect x=\"60\" y=\"34\" width=\"200\" height=\"190\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"76\" y=\"50\" width=\"168\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"160.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">child A</text><rect x=\"76\" y=\"104\" width=\"168\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"160.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">child B</text><rect x=\"76\" y=\"158\" width=\"168\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"160.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">child C</text><path d=\"M40 40 L40 220\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-axes-ah-amber)\"></path><text x=\"30\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">main axis · justifyContent</text><path d=\"M60 236 L260 236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-axes-ah-paper-dim)\"></path><text x=\"160\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">cross axis · alignItems</text><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">flexDirection: row</text><rect x=\"400\" y=\"80\" width=\"290\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"416\" y=\"100\" width=\"40\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"436.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">icon</text><rect x=\"468\" y=\"106\" width=\"150\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"543.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Study planner</text><path d=\"M400 180 L690 180\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-axes-ah-amber)\"></path><text x=\"545\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">main axis · justifyContent</text><path d=\"M706 80 L706 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-axes-ah-paper-dim)\"></path><text x=\"690\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">cross axis · alignItems</text></svg>", "caption": "The same two properties, turned through a right angle: in a column, justifyContent works vertically; in a row, horizontally."}
```

## A column, not a row

**`flexDirection` is `column` by default.** Children stack top to bottom, which is what a phone screen
mostly does. So the **main axis** is vertical: `justifyContent` places children up and down, and
`alignItems` places them across, left to right. The planner's heading row turns this around on purpose,
with `flexDirection: "row"`, to put the icon beside the title; there, `alignItems: "center"` centres
them vertically.

## `flex` is one number, and it means grow

On the web, `flex: 1` is shorthand for three values. **In React Native, `flex` takes a single number**:
a positive one means *share the free space along the main axis in proportion to this number*. Two
siblings with `flex: 1` and `flex: 2` take a third and two thirds. A child with no `flex` takes the size
of its content.

That is everything a progress bar needs. The planner's week bar is a row whose two children have `flex`
set to the minutes done and the minutes left. Save it as `src/WeekBar.tsx`:

```tsx
// src/WeekBar.tsx: the week's minutes as a bar, done against planned, laid out by flex alone.
import { StyleSheet, View } from "react-native";
import { useTheme } from "./theme";

type Props = { done: number; planned: number };

export function WeekBar({ done, planned }: Props) {
  const t = useTheme();
  return (
    <View
      testID="week-bar"
      accessible
      role="progressbar"
      aria-label="Minutes done this week"
      aria-valuemin={0}
      aria-valuemax={planned}
      aria-valuenow={done}
      style={[styles.track, { backgroundColor: t.track }]}
    >
      <View testID="week-done" style={{ flex: done, backgroundColor: t.accent }} />
      <View testID="week-left" style={{ flex: planned - done }} />
    </View>
  );
}

const styles = StyleSheet.create({
  track: { flexDirection: "row", height: 12, borderRadius: 6, overflow: "hidden" },
});
```

`overflow: "hidden"` clips the coloured part to the rounded track. The `aria-` props tell a screen
reader it is a progress bar and how far along it is, and `accessible` makes the three views one element
to it. No width is computed anywhere: **the bar is 75 parts done and 50 parts left, and Yoga divides
whatever width there is in that ratio.**

## Measuring it

A test can say what `flex` was set to; only a layout engine can say what it produced. This program
opens the web build at a phone's size, 390 by 844, and prints where each element with a `testID` landed,
with its background colour. Save it as `boxes.mjs`, beside `look.mjs`:

```javascript
// boxes.mjs: open a page at a phone's size and print where every element
// with a testID was laid out, and its background colour.
//
//   node boxes.mjs URL [WIDTH HEIGHT] [--dark]
import { chromium } from "playwright";

const args = process.argv.slice(2);
const dark = args.includes("--dark");
const [url, width = "390", height = "844"] = args.filter((a) => a !== "--dark");
const browser = await chromium.launch();
const page = await browser.newPage({
  viewport: { width: Number(width), height: Number(height) },
  colorScheme: dark ? "dark" : "light",
});
await page.goto(url);
await page.waitForLoadState("networkidle");
for (const el of await page.locator("[data-testid]").all()) {
  const id = await el.getAttribute("data-testid");
  const b = await el.boundingBox();
  const bg = await el.evaluate((e) => getComputedStyle(e).backgroundColor);
  const box = [b.x, b.y, b.width, b.height].map((n) => Math.round(n));
  console.log(`${id.padEnd(12)} x=${box[0]} y=${box[1]} w=${box[2]} h=${box[3]}  ${bg}`);
}
await browser.close();
```

With the week bar in the screen, as the last section of this lesson puts it:

```
ana@dev:~/planner$ node boxes.mjs 'http://localhost:8082/?today=2026-10-21'
header       x=24 y=64 w=342 h=40  rgba(0, 0, 0, 0)
week-bar     x=24 y=147 w=342 h=12  rgb(230, 235, 240)
week-done    x=24 y=147 w=205 h=12  rgb(47, 111, 78)
week-left    x=229 y=147 w=137 h=12  rgba(0, 0, 0, 0)
row-spanish  x=24 y=175 w=342 h=62  rgba(0, 0, 0, 0)
row-statistics x=24 y=237 w=342 h=62  rgba(0, 0, 0, 0)
row-guitar   x=24 y=299 w=342 h=62  rgba(0, 0, 0, 0)
```

The bar is 342 wide, the 390 of the window less 24 of padding each side. Done is 205 and left is 137,
which is 75 to 50 to the nearest point. `alignItems` defaults to `stretch`, the other default worth
knowing, which is why the header and the rows are 342 wide too without anybody asking.
