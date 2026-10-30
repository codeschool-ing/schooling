---
title: Two screens, two copies of the data
version: 1
---

**Since lesson 8 the planner has had a defect it has been carrying on purpose: the week and the
course page each hold a copy of the data, and the copies drift apart.** `Week` and `CoursePage`
each declare `resource({ loader: loadPlanner })`, so each fetches `courses.json` and keeps what came
back. Ticking a session done changes `CoursePage`'s copy, and `Week` has no way of knowing.

The JavaScript course has one session still to do this week, on Saturday the 24th, for 50 minutes.
Tick it, and read the week's total afterwards:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week-summary --network --do 'check 2026-10-24, 50 minutes'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /courses.json  200
net  GET /courses.json  200
-- check 2026-10-24, 50 minutes
165 minutes planned, 90 done.

75 minutes to go.

Done this week
```

Two requests for the same file, one per component, and after the tick the week still says 90 minutes
done, where it should say 140. Each number on the page is right about its own copy. Nothing is
broken in either component, which is why a defect like this survives: the error is in how the two
are arranged, and that is not in either file.

## The arrangement it needs

Both screens want the same thing: **one** set of courses and sessions, loaded once, changed in one
place, and read by whoever needs it. That is what lesson 10's hierarchy section ended on: one
instance in the root injector, asked for by both, is one copy.

A class that holds that copy and the operations on it, with no template of its own, is what
Angular calls a **service**. It is not a separate kind of thing to the framework. `@Injectable`,
`providedIn: 'root'`, `inject`: everything in it is lesson 10, applied to a class whose job is the
application's data rather than a greeting.
