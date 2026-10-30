---
title: When last write wins is the right rule
version: 1
---

**Last write wins is right when the newest value is the whole truth and the older one is worth
nothing.** That is a property of the data, not of the app, so the question is asked per field: a
planner can use the rule safely for some of its columns and lose work with it on others.

## Where it is right

- **A setting.** The hour of the daily reminder, the theme, the first day of the week. If Ana sets
  the reminder to 8:00 on her phone and to 7:30 on her tablet, the later choice is what she wants,
  and losing 8:00 costs her nothing she did.
- **A field one person changes from one place.** A course's name in a personal planner is edited
  rarely and by its owner; two concurrent edits are unlikely, and when they happen either result is
  acceptable.
- **A value replaced as a whole.** A course's colour, a profile picture, a chosen language. Nobody
  edits half a colour.

## Where it loses work

| data | two concurrent changes | what last write wins keeps |
|---|---|---|
| a counter, such as total minutes studied | +30 on the phone, +45 on the tablet | one of them: 30 or 45 minutes added, never 75 |
| a list stored in one field, such as a course's tags | one device adds `exam`, the other adds `weekly` | one tag |
| text two people edit, such as shared notes | each adds a paragraph | one paragraph |
| a row with independent fields, such as a session | minutes on one device, done on the other | one of the two changes |

The counter is the cleanest failure, because the arithmetic shows it. Both increments were made on
top of the same starting value, so each device sends its total, and the server keeps one total.
**Forty-five minutes of studying vanish from a statistic, and the person who did them has no way
to find out.** Lesson 15 builds a counter that cannot lose an increment, by sending increments per
device instead of totals.

The session row is the case of this lesson, and it has the cheapest fix: stamp each field rather
than the row, and apply the rule field by field. The phone's `minutes` and the tablet's `done` then
both survive, because they never competed. Lesson 14 does that properly, against the version both
devices started from, so that it can also tell the one case that remains a real conflict: both
devices changing the same field.

**So choose the rule column by column, and write the choice down beside the schema.** Last write
wins on a setting is a decision; last write wins on a counter is a bug that every report built on
it will repeat.
