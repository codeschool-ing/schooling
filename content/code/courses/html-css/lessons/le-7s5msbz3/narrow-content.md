---
title: Long words and wide tables on a narrow screen
version: 1
---

A layout can be perfect and the page still scroll sideways, because one piece of **content** is wider than the screen. The two usual culprits are a long unbroken string, such as a web address, and a table:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      body { margin: 0; padding: 0 1rem; font-family: system-ui, sans-serif; }
      th, td { padding: 0.25rem 0.75rem; text-align: left; white-space: nowrap; }
    </style>
  </head>
  <body>
    <main>
      <h1>Events</h1>
      <p>Our catalogue is at https://andorinha.example/catalogue/second-hand/poetry-and-plays</p>
      <table>
        <caption>Events this week</caption>
        <thead>
          <tr><th scope="col">Day</th><th scope="col">Time</th><th scope="col">Event</th><th scope="col">Places</th></tr>
        </thead>
        <tbody>
          <tr><td>Thursday</td><td>7 pm</td><td>Poetry reading</td><td>40</td></tr>
          <tr><td>Saturday</td><td>2 pm</td><td>Bookbinding workshop</td><td>12</td></tr>
        </tbody>
      </table>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe --width 320 reflow.html overflow spill p
page is 458 wide in a 320 window: it scrolls sideways
p  content 347 wide in a box 288 wide: it spills
```

On a window 320 wide, the page is **458** wide and scrolls sideways. The paragraph's content is **347** wide in a box of 288: the address has no spaces, so the browser has nowhere to break the line. And the table, which keeps every cell on one line, is what made the page 458.

Two different fixes, because the two problems are different:

```css
.url { overflow-wrap: anywhere; }
.table-wrap { overflow-x: auto; }
```

**`overflow-wrap: anywhere`** lets the browser break a word that would not fit otherwise, anywhere in it. It is right for addresses, codes and long names, where breaking is better than spilling; ordinary words never need it, because they are short enough. **A table cannot be broken** without losing what makes it a table, the columns. So it goes in a wrapper with **`overflow-x: auto`**, the scroll container of lesson 6 section 11, and the table scrolls inside its own box while the page stays still:

```
ana@laptop:~/site$ probe --width 320 reflow-fixed.html overflow spill .url spill .table-wrap
page fits: 320 wide in a 320 window
p.url  content 288 wide in a box 288 wide
div.table-wrap  content 442 wide in a box 288 wide: it spills
```

The page fits, **320** in 320. The address now fits its box, 288 in 288. The wrapper's content is still **442** wide in 288: the table scrolls inside it, which is intended.

## The wrapper needs a keyboard

A box that scrolls has to be scrollable without a mouse. Here is the same page with the wrapper's `tabindex="0"` taken out:

```
ana@laptop:~/site$ probe --width 320 notab.html axe tab
scrollable-region-focusable (serious, 1 element): Scrollable region must have keyboard access
focus: div "Events this week DayTimeEventPlaces Thur"
ana@laptop:~/site$ probe --width 320 reflow-fixed.html axe
axe: no violations
```

axe reports **`scrollable-region-focusable`**: a scrolling region a keyboard user may not be able to reach, and then cannot scroll, so the last columns are out of reach. Then Tab put the focus on the wrapper anyway: recent versions of Chromium make a scroll container focusable by themselves, and not every browser does, which is why axe still asks. With `tabindex="0"` the wrapper takes focus everywhere and the arrow keys scroll it; `role="region"` and `aria-label` give it a name, so a screen reader announces what has received focus.
