---
title: Submitting, and what happens after
version: 1
---

**A submit handler does four things in order: stop the browser's own submit, check, act, and reset the
form for the next entry.** Each step has a way to go wrong that the student notices immediately, which
makes it worth writing in the same order every time.

The planner's handler:

```javascript
function submit() {
  tried.value = true
  if (!valid.value) {
    saved.value = ''
    return
  }
  planner.add({ ...draft })
  saved.value = `Added ${draft.minutes} minutes of ${planner.titles[draft.course]} on ${formatDay(draft.date)}.`
  Object.assign(draft, { course: '', minutes: 30 })
  tried.value = false
  courseField.value.focus()
}
```

and the form that calls it, `<form novalidate @submit.prevent="submit">`. In order:

1. **`.prevent`** stops the browser from sending the form to an address and reloading the page, which
   lesson 5 showed would lose every ref.
2. **`tried.value = true`** turns the messages on, and an invalid form stops there, with the status line
   emptied so that an old "Added…" does not linger over a new failure.
3. **`planner.add({ ...draft })`** hands the store a *copy*. Lesson 3's `addSession` builds a new object
   from the three fields anyway, so today the copy changes nothing; it is there so that the form does not
   depend on what the store does with what it is given. A store that kept the object itself would be
   holding the form's reactive draft, and the next keystroke would change a session already in the list:
   lesson 6's object prop, in a new place.
4. **Reset**: the course is cleared and the minutes go back to 30, but **the date stays**, because the
   next session is often on the same day. `tried` goes back to false, so the cleared course field is not
   shown as an error; and the focus returns to the first field.

The store's new action is one line beside `toggle`, through lesson 3's rule, which has waited since
then to be used:

```javascript
function add(session) {
  sessions.value = addSession(sessions.value, session)
}
```

with `addSession` added to the import from `../planner.js`, and `add` to what the store returns.

## Fill it in and send it

Choose guitar, the 24th, 25 minutes, and add it:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'select select guitar' --do 'fill input[type=date] 2026-10-24' --do 'fill input[type=number] 25' --do 'click text=Add the session' --text main
[vite] connecting...
[vite] connected.
-- select select guitar
-- fill input[type=date] 2026-10-24
-- fill input[type=number] 25
-- click text=Add the session
== the text of main
This week
Courses
Statistics

45 of 105 minutes done, goal 180

 25% of the weekly goal

Spanish

30 of 70 minutes done, goal 120

 25% of the weekly goal

Guitar

0 of 45 minutes done, goal 90

 0% of the weekly goal

Week of 19 October 2026
Previous weekNext week
 19 October 2026, Statistics, 45 minutes
 19 October 2026, Spanish, 30 minutes
 21 October 2026, Statistics, 60 minutes (today)
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes
 24 October 2026, Guitar, 25 minutes
75 of 220 minutes done
Add a session
Course
Choose…
Statistics
Spanish
Guitar
Date
Minutes
Add the session

Added 25 minutes of Guitar on 24 October 2026.
```

**The session is in the week's list, on the 24th, and the total planned went from 195 to 220.** The
status line says what was added, and the form is ready for the next one. `select` is an action `look`
has for a `<select>`, choosing the option by its value; your own browser chooses with the mouse, or with
the arrow keys once the field has focus.

## Async submits

The planner saves to the browser at once. A form that sends to a server waits, and the wait needs two
more things: **disable the button while sending**, `:disabled="sending"`, so a double click does not
create two sessions. And **say what happened when it fails**, in the same status line, without clearing
the form, so the student can try again without typing everything twice.
