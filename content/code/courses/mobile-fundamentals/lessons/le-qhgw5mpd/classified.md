---
title: Nine windows, sorted into classes
version: 1
---

**This program applies Android's breakpoints and the planner's two-pane rule to a list of windows,
so the decisions of the previous sections can be checked one window at a time.** The windows are
examples. Their sizes in dp are round numbers chosen to land in each class and to show the same
device in two shapes; **they are not measurements of any real phone, foldable or tablet**, and a
real device of each kind can fall in a different class. Save it as `sizeclass.ts` in `~/planner`:

```typescript
// sizeclass.ts: a window's size classes, and one pane or two for the planner
type Win = { name: string; w: number; h: number }; // sizes in dp

// Android's width breakpoints, in dp, as its documentation lists them
function widthClass(w: number): string {
  if (w < 600) return "compact";
  if (w < 840) return "medium";
  if (w < 1200) return "expanded";
  if (w < 1600) return "large";
  return "extra-large";
}

// And its height breakpoints
function heightClass(h: number): string {
  if (h < 480) return "compact";
  if (h < 900) return "medium";
  return "expanded";
}

// The planner's rule: the course list and a course's detail side by side
// only in a window at least expanded wide and not compact tall
function panes(win: Win): string {
  return win.w >= 840 && win.h >= 480 ? "two: list | detail" : "one: list, then detail";
}

// Example windows, in dp. They are round numbers chosen to land in each class,
// not measurements of any real device.
const windows: Win[] = [
  { name: "phone, portrait", w: 360, h: 800 },
  { name: "phone, landscape", w: 800, h: 360 },
  { name: "foldable, folded", w: 360, h: 780 },
  { name: "foldable, open, portrait", w: 700, h: 880 },
  { name: "foldable, open, landscape", w: 880, h: 700 },
  { name: "tablet, portrait", w: 800, h: 1280 },
  { name: "tablet, landscape", w: 1280, h: 800 },
  { name: "tablet, half in split screen", w: 640, h: 800 },
  { name: "desktop window, short", w: 1000, h: 420 },
];

console.log(`${"window".padEnd(29)}${"dp".padStart(11)}  ${"width".padEnd(9)} ${"height".padEnd(9)} panes`);
for (const win of windows) {
  const size = `${win.w} x ${win.h}`;
  console.log(
    `${win.name.padEnd(29)}${size.padStart(11)}  ${widthClass(win.w).padEnd(9)} ${heightClass(win.h).padEnd(9)} ${panes(win)}`,
  );
}
```

```
ana@dev:~/planner$ node sizeclass.ts
window                                dp  width     height    panes
phone, portrait                360 x 800  compact   medium    one: list, then detail
phone, landscape               800 x 360  medium    compact   one: list, then detail
foldable, folded               360 x 780  compact   medium    one: list, then detail
foldable, open, portrait       700 x 880  medium    medium    one: list, then detail
foldable, open, landscape      880 x 700  expanded  medium    two: list | detail
tablet, portrait              800 x 1280  medium    expanded  one: list, then detail
tablet, landscape             1280 x 800  large     medium    two: list | detail
tablet, half in split screen   640 x 800  medium    medium    one: list, then detail
desktop window, short         1000 x 420  expanded  compact   one: list, then detail
```

## Reading it row by row

**The same phone is two different windows.** In portrait it is compact wide and medium tall; turned
on its side it is medium wide and compact tall. Neither gets two panes: the first is too narrow, and
the second is too short, which is exactly the landscape case Android's documentation describes.

**The same foldable crosses the line when it opens, and only in one direction of holding it.**
Folded, 360 dp wide, it is a phone. Open and held in portrait, 700 dp, it is medium and still shows
one pane. Open and turned, 880 dp, it is expanded and shows list and detail side by side. A real app
on a real foldable makes that switch while the student is looking at a course, which is why the
selected course has to survive it.

**The same tablet is three windows.** In portrait it is medium wide, one pane; in landscape it is
large, two panes; and half of it in split screen, 640 dp, is medium again. Nothing about the device
changed between the last two rows. Only the window did.

**The last row is the reason for the height condition.** A desktop window 1000 dp wide and 420 dp
tall is expanded by width and compact by height. Two panes 420 dp tall would each show a few rows
of a list and a cramped detail, so the rule falls back to one.

## What the program does not decide

It does not draw anything; deciding the class is the part that is the same on every platform, and
drawing two panes is the toolkit's job after the fork. **It does not cover iOS's own classes**,
compact and regular, because Apple does not publish them as numbers to compare: an iOS app asks the
system which one it is in. And it puts the planner's breakpoint at expanded because the detail of a
course needs room; an app whose detail is a single short card could reasonably split at medium.
The rule is a decision the app makes once and writes down, which is the whole of what this lesson
asks.
