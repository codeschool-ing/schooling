---
title: Target size, measured against each platform's minimum
version: 1
---

**A touch target is the area that answers a finger, and it may be larger than what is drawn.** The
planner's tick is a 24 by 24 circle on the screen; nothing stops the area that responds to it from
being twice that. The common mistake is to treat the drawing and the target as one thing, and then
either draw everything huge or leave small icons with small targets. Both platforms ask for the
second number to meet a minimum, and leave the first to the designer.

## The numbers, and where they come from

| | minimum target | source, read on 30 October 2026 |
|---|---|---|
| Android | **48 × 48 dp** | Android's documentation: "a focusable area, or touch target size, of at least 48dpx48dp. Larger is even better." |
| iOS | **44 × 44 pt** | the HIG on buttons: "a button needs a hit region of at least 44x44 pt" |
| the web, WCAG 2.2 | **24 × 24 CSS pixels** | success criterion 2.5.8, Target Size (Minimum), level AA |

Three remarks on the table. **The two phone numbers are in each platform's own unit**, `dp` and
`pt`, which lesson 7 explained, so 48 and 44 are physical sizes of roughly the same order rather
than pixel counts. **The HIG's accessibility page gives two numbers for iOS**: 44 × 44 pt as the
default control size and 28 × 28 pt as the minimum, so 44 is what to aim for and 28 the smallest
size it lists at all. And **WCAG's 24 is a floor for the web, with exceptions**: a
smaller target passes if a 24-pixel circle centred on it touches no other target, or if the same
function is available from another control. The phone platforms ask for numbers about twice as large, and the
planner follows the phones.

## Checking the planner

The planner has four kinds of control on its week screen, and each has a drawn size on each
platform. A small program checks them all against the platform's minimum and says, for each one that
falls short, how much padding brings it up. Save it as `targets.ts` in `~/planner`:

```typescript
// targets.ts: the planner's touch targets against each platform's minimum
const MIN = { android: 48, ios: 44 }; // dp on Android, pt on iOS

type Target = { name: string; android: number[]; ios: number[] }; // [width, height]

const targets: Target[] = [
  { name: "add session", android: [56, 56], ios: [44, 44] },
  { name: "mark done", android: [24, 24], ios: [24, 24] },
  { name: "delete session", android: [40, 40], ios: [32, 32] },
  { name: "tab: Week", android: [96, 64], ios: [96, 49] },
];

// The padding that brings one side up to the minimum, split evenly around the control.
function padding(size: number, min: number): number {
  return Math.max(0, Math.ceil((min - size) / 2));
}

for (const t of targets) {
  for (const os of ["android", "ios"] as const) {
    const [w, h] = t[os];
    const unit = os === "android" ? "dp" : "pt";
    const pad = Math.max(padding(w, MIN[os]), padding(h, MIN[os]));
    const verdict = pad === 0 ? "ok" : `too small: add ${pad} ${unit} on each side`;
    console.log(`${t.name.padEnd(16)}${os.padEnd(8)}${`${w}x${h} ${unit}`.padEnd(11)}${verdict}`);
  }
}
```

```
ana@dev:~/planner$ node targets.ts
add session     android 56x56 dp   ok
add session     ios     44x44 pt   ok
mark done       android 24x24 dp   too small: add 12 dp on each side
mark done       ios     24x24 pt   too small: add 10 pt on each side
delete session  android 40x40 dp   too small: add 4 dp on each side
delete session  ios     32x32 pt   too small: add 6 pt on each side
tab: Week       android 96x64 dp   ok
tab: Week       ios     96x49 pt   ok
```

**Two controls fail, on both platforms, and they are the two the student uses most often after
adding.** The tick is 24 on each, so it needs 12 dp of padding on every side on Android, which makes
48, and 10 pt on iOS, which makes 44. The delete button needs 4 dp and 6 pt. The floating action
button at 56 dp, and the tab at 96 by 64, pass with room to spare, and the iOS toolbar button sits
exactly on 44, which passes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l19-padding\" aria-label=\"Two squares, each a touch target with the drawn tick in its centre. Left, Android: the tick is 24 by 24 dp, the target 48 by 48 dp, with 12 dp of padding on every side. Right, iOS: the tick is 24 by 24 pt, the target 44 by 44 pt, with 10 pt of padding on every side. The drawing stays the same size; only the area that answers a finger grows.\"><defs><marker id=\"l19-padding-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"190\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Android</text><rect x=\"118.0\" y=\"78.0\" width=\"144\" height=\"144\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"154\" y=\"114\" width=\"72\" height=\"72\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"190.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">24 × 24</text><text x=\"190\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">target 48 × 48 dp</text><text x=\"190\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">drawn tick</text><path d=\"M118.0 150 L154 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-padding-ah-paper-dim)\" marker-start=\"url(#l19-padding-ah-paper-dim)\"></path><text x=\"112.0\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">12 dp</text><path d=\"M190 78.0 L190 114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-padding-ah-paper-dim)\" marker-start=\"url(#l19-padding-ah-paper-dim)\"></path><text x=\"196\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">12 dp</text><text x=\"530\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">iOS</text><rect x=\"464.0\" y=\"84.0\" width=\"132\" height=\"132\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"494\" y=\"114\" width=\"72\" height=\"72\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"530.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">24 × 24</text><text x=\"530\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">target 44 × 44 pt</text><text x=\"530\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">drawn tick</text><path d=\"M464.0 150 L494 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-padding-ah-paper-dim)\" marker-start=\"url(#l19-padding-ah-paper-dim)\"></path><text x=\"458.0\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10 pt</text><path d=\"M530 84.0 L530 114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-padding-ah-paper-dim)\" marker-start=\"url(#l19-padding-ah-paper-dim)\"></path><text x=\"536\" y=\"99.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10 pt</text></svg>", "caption": "The fix targets.ts asked for. The tick is still drawn at 24; the padding around it makes the area a finger can hit reach each platform's minimum."}
```

**The fix leaves the drawing alone.** On Android, Compose's Material components such as `Button`,
`IconButton` and `ListItem` already enforce the 48 dp minimum, as Android's documentation notes, and a custom
control gets it with `Modifier.sizeIn(minWidth = 48.dp, minHeight = 48.dp)` around a smaller drawing.
In SwiftUI the same is a `.frame(minWidth: 44, minHeight: 44)` with `.contentShape(Rectangle())`, so
that the whole frame answers a tap and not only the pixels of the symbol. Neither fragment was run for
this course; the numbers they meet are the ones above.

**Padding has a cost the program cannot see.** Two 24-pixel ticks side by side, each grown to 48, now
overlap, and a finger between them hits whichever the system picks. The planner has one tick per row
and rows taller than 48, so its targets never collide; a toolbar with five icon buttons in a row is
where this bites, and where the HIG's advice to put fewer items in a toolbar is also an accessibility
rule.
