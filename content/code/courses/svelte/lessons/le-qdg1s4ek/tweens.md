---
title: Tween and Spring, for numbers that change
version: 1
---

**A transition is for an element; a tween is for a value.** When a number on the page changes, it can
jump to the new value or travel there, and travelling helps the eye see that something changed and by
how much. `svelte/motion` provides two classes for it: `Tween`, which moves to its target over a fixed
time, and `Spring`, which moves like a physical spring and may overshoot a little and settle.

The planner's "90 of 225 minutes done" is a good case: tick a session and the number should count up
rather than jump. In `Planner.svelte`, import `Tween` and make a tweened copy of `doneMinutes`, just
under the line that derives it:

```javascript
import { Tween } from 'svelte/motion';
```

```javascript
const shownDone = Tween.of(() => doneMinutes, { duration: 400 });
```

and show the tweened value, rounded, in the sentence:

```html
<p>{Math.round(shownDone.current)} of {total} minutes done.</p>
```

`Tween.of(fn)` creates a tween that follows whatever `fn` returns: each time `doneMinutes` changes, the
tween takes the new value as its target and moves `current` towards it over 400 milliseconds. Reading
`current` is tracked like any state, so the paragraph updates on every frame of the way.

Tick the session of the 24th, an hour, and print the page at four moments after the click:

```
ana@dev:~/planner$ look http://localhost:5173/ --check '24 Oct 2026, 60 min' --wait 0
-- check 24 Oct 2026, 60 min
-- wait 0
at /
title: 225 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 150 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
  - paragraph: 91 of 225 minutes done.
  - list "Minutes per day":
    - listitem: "19 Oct 2026: 90 min"
    - listitem: "20 Oct 2026: 45 min"
    - listitem: "21 Oct 2026: 0 min"
    - listitem: "22 Oct 2026: 30 min"
    - listitem: "23 Oct 2026: 0 min"
    - listitem: "24 Oct 2026: 60 min"
    - listitem: "25 Oct 2026: 0 min"
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - list:
      - listitem:
        - checkbox "19 Oct 2026, 90 min" [checked]
        - text: 19 Oct 2026, 90 min
      - listitem:
        - checkbox "24 Oct 2026, 60 min" [checked]
        - text: 24 Oct 2026, 60 min
    - paragraph: 150 minutes for Linear algebra this week (2 h 30 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

```
ana@dev:~/planner$ look http://localhost:5173/ --check '24 Oct 2026, 60 min' --wait 100
-- check 24 Oct 2026, 60 min
-- wait 100
at /
title: 225 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 150 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
  - paragraph: 106 of 225 minutes done.
  - list "Minutes per day":
    - listitem: "19 Oct 2026: 90 min"
    - listitem: "20 Oct 2026: 45 min"
    - listitem: "21 Oct 2026: 0 min"
    - listitem: "22 Oct 2026: 30 min"
    - listitem: "23 Oct 2026: 0 min"
    - listitem: "24 Oct 2026: 60 min"
    - listitem: "25 Oct 2026: 0 min"
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - list:
      - listitem:
        - checkbox "19 Oct 2026, 90 min" [checked]
        - text: 19 Oct 2026, 90 min
      - listitem:
        - checkbox "24 Oct 2026, 60 min" [checked]
        - text: 24 Oct 2026, 60 min
    - paragraph: 150 minutes for Linear algebra this week (2 h 30 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

```
ana@dev:~/planner$ look http://localhost:5173/ --check '24 Oct 2026, 60 min' --wait 200
-- check 24 Oct 2026, 60 min
-- wait 200
at /
title: 225 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 150 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
  - paragraph: 121 of 225 minutes done.
  - list "Minutes per day":
    - listitem: "19 Oct 2026: 90 min"
    - listitem: "20 Oct 2026: 45 min"
    - listitem: "21 Oct 2026: 0 min"
    - listitem: "22 Oct 2026: 30 min"
    - listitem: "23 Oct 2026: 0 min"
    - listitem: "24 Oct 2026: 60 min"
    - listitem: "25 Oct 2026: 0 min"
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - list:
      - listitem:
        - checkbox "19 Oct 2026, 90 min" [checked]
        - text: 19 Oct 2026, 90 min
      - listitem:
        - checkbox "24 Oct 2026, 60 min" [checked]
        - text: 24 Oct 2026, 60 min
    - paragraph: 150 minutes for Linear algebra this week (2 h 30 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

```
ana@dev:~/planner$ look http://localhost:5173/ --check '24 Oct 2026, 60 min' --wait 600
-- check 24 Oct 2026, 60 min
-- wait 600
at /
title: 225 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 150 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
  - paragraph: 150 of 225 minutes done.
  - list "Minutes per day":
    - listitem: "19 Oct 2026: 90 min"
    - listitem: "20 Oct 2026: 45 min"
    - listitem: "21 Oct 2026: 0 min"
    - listitem: "22 Oct 2026: 30 min"
    - listitem: "23 Oct 2026: 0 min"
    - listitem: "24 Oct 2026: 60 min"
    - listitem: "25 Oct 2026: 0 min"
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - list:
      - listitem:
        - checkbox "19 Oct 2026, 90 min" [checked]
        - text: 19 Oct 2026, 90 min
      - listitem:
        - checkbox "24 Oct 2026, 60 min" [checked]
        - text: 24 Oct 2026, 60 min
    - paragraph: 150 minutes for Linear algebra this week (2 h 30 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

**From 90 to 150, read four times on the way**: 91 a moment after the click, then 106, 121, and 150
once it has arrived. Each is a real reading of the page at that moment, and in the middle they climb by
about fifteen minutes every hundred milliseconds, a quarter of the distance per quarter of the time:
**a `Tween`'s default easing is linear**, a constant speed. An `easing` option changes that, and the
section on writing a transition draws the curves to choose from.

## What should not be tweened

A tween is a display of a value, never the value. `doneMinutes` is still the truth and every
calculation reads it; only the sentence reads `shownDone.current`. Tween a value that something else
then reads, and that something will act on a number that is halfway between two real ones.

And the screen reader reads the page as it is when it reads it, so a number in motion may be announced
at 106. That is harmless in a sentence a reader will read again, and a reason not to tween anything in
a live region that is announced the moment it changes.
