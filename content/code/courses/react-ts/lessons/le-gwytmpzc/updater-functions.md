---
title: When the next value depends on the last
version: 1
---

**When the new value is computed from the old one, pass the setter a function.** React calls it with
the latest value, including any change queued earlier in the same event, and uses what it returns:

```
ana@dev:~/planner$ sed -i 's|setMonday(addDays(monday, 7))|setMonday((m) => addDays(m, 7))|' src/TwoWeeks.tsx
ana@dev:~/planner$ sed -n 12,16p src/TwoWeeks.tsx
    setMonday((m) => addDays(m, 7))
    setMonday((m) => addDays(m, 7))
    console.log('after both calls, monday is', monday)
  }
  return (
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Two weeks on' | head -n 11
-- click button Two weeks on
after both calls, monday is 2026-10-19
- main:
  - heading "Study planner" [level=1]
  - navigation "Week":
    - button "Previous week"
    - button "Next week"
  - button "Two weeks on"
  - region "This week":
    - paragraph: Week of 2 Nov 2026
    - paragraph: 0 of 0 minutes done
ana@dev:~/planner$ sed -i '/TwoWeeks/d' src/App.tsx && rm src/TwoWeeks.tsx
```

The week moved two weeks, to 2 November. React queued two functions and ran them in order: the first
received the 19th and returned the 26th, the second received the 26th and returned 2 November. The
log still says `2026-10-19`, and should: `monday` in this render is still the snapshot it always was.
Only the queue saw the intermediate value.

So there are two forms, and the rule for choosing is short:

| you write | React does | use it when |
|---|---|---|
| `setMonday(addDays(monday, 7))` | replaces the value with the one you computed from this render | the new value does not depend on the old, or this is the only update in the event |
| `setMonday((m) => addDays(m, 7))` | queues the function and runs it on the latest value | the new value is computed from the old one, and more than one update may be queued |

The second form is never wrong where the first is right, and it is the safer habit when an update is
computed from the previous value. `WeekNav` keeps the first form because it calls its setter once
per click, from a value its parent just rendered; the planner's `toggleDone`, in the section after
next, uses the second.

`TwoWeeks` goes, and `App` is back to lesson 3's. The last command of the transcript removed both.
