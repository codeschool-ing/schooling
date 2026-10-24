---
title: The planner's data, and its dates
version: 1
---

**The planner works on one small file of data and one small module of date arithmetic, and both are
plain JavaScript that knows nothing about Svelte.** That separation is worth keeping from the first
day: the data and the rules about weeks can be tested on their own in lesson 19, and the components
only have to show them.

## The data

Three courses and six sessions in October 2026. Each session points at its course by the course's
`id`, has a date written as `YYYY-MM-DD`, a number of minutes and whether it is done. Save it as
`src/lib/planner.json`:

```schooling-example
{"language": "json", "file": "src/lib/planner.json", "parts": [
 {"code": "{\n\t\"courses\": [\n\t\t{ \"id\": \"algebra\", \"name\": \"Linear algebra\" },\n\t\t{ \"id\": \"spanish\", \"name\": \"Spanish\" },\n\t\t{ \"id\": \"guitar\", \"name\": \"Guitar\" }\n\t],", "note": "Three courses. The `id` is what a session uses to say which course it belongs to; the `name` is only for people."},
 {"code": "\t\"sessions\": [\n\t\t{ \"id\": 1, \"course\": \"algebra\", \"date\": \"2026-10-13\", \"minutes\": 60, \"done\": true },\n\t\t{ \"id\": 2, \"course\": \"spanish\", \"date\": \"2026-10-15\", \"minutes\": 30, \"done\": true },\n\t\t{ \"id\": 3, \"course\": \"algebra\", \"date\": \"2026-10-19\", \"minutes\": 90, \"done\": true },\n\t\t{ \"id\": 4, \"course\": \"guitar\", \"date\": \"2026-10-20\", \"minutes\": 45, \"done\": false },\n\t\t{ \"id\": 5, \"course\": \"spanish\", \"date\": \"2026-10-22\", \"minutes\": 30, \"done\": false },\n\t\t{ \"id\": 6, \"course\": \"algebra\", \"date\": \"2026-10-24\", \"minutes\": 60, \"done\": false }\n\t]\n}", "note": "Six sessions, in date order. Two fall in the week of 12 October and four in the week of 19 October."}
]}
```

A date as a string in this form has one property that makes everything below short: **two of them
compare correctly as text.** `"2026-10-19" < "2026-10-24"` is true for the same reason the dates are
in that order, so there is no need to turn them into `Date` objects to sort or compare them.

## The week

A week in the planner starts on Monday. Four functions are enough for everything the planner will
ever do with dates: find a date's Monday, move a date by some days, ask whether a date is in a given
week, and write a date for people to read. Save them as `src/lib/week.js`:

```schooling-example
{"language": "javascript", "file": "src/lib/week.js", "parts": [
 {"code": "// week.js: dates as 'YYYY-MM-DD' strings, and the week they fall in.\n// Weeks start on Monday.\nconst DAY = 24 * 60 * 60 * 1000;\nconst toTime = (date) => Date.parse(`${date}T00:00:00Z`);\nconst toDate = (time) => new Date(time).toISOString().slice(0, 10);", "note": "Every calculation happens in UTC, at midnight, so the answer is the same on every computer whatever its time zone."},
 {"code": "/** The Monday of the week `date` falls in. */\nexport function mondayOf(date) {\n\tconst day = new Date(toTime(date)).getUTCDay();\n\treturn toDate(toTime(date) - ((day + 6) % 7) * DAY);\n}\n\n/** `date` moved by `days`, which may be negative. */\nexport function addDays(date, days) {\n\treturn toDate(toTime(date) + days * DAY);\n}", "note": "`getUTCDay` says 0 for Sunday and 1 for Monday, so `(day + 6) % 7` is how many days have passed since Monday."},
 {"code": "/** Whether `date` falls in the week that starts on `monday`. */\nexport function inWeek(date, monday) {\n\treturn date >= monday && date < addDays(monday, 7);\n}", "note": "Plain string comparison, which works because of the date format."},
 {"code": "/** `2026-10-19` as `19 Oct 2026`. */\nexport function format(date) {\n\treturn new Date(toTime(date)).toLocaleDateString('en-GB', {\n\t\tday: 'numeric',\n\t\tmonth: 'short',\n\t\tyear: 'numeric',\n\t\ttimeZone: 'UTC'\n\t});\n}", "note": "`en-GB` writes the day before the month, and `timeZone: 'UTC'` keeps it from moving to the day before in the Americas."}
]}
```

Nothing in either file is reactive, and nothing needs to be. **Runes go where values change while the
page is open**, and the rest of this lesson puts them in the page component, one at a time. A date
calculation that gives the same answer for the same input belongs in a plain module, where it is
simplest to read and to test.

You can try the module from the terminal before any component uses it:

```
ana@dev:~/planner$ node -e "import('./src/lib/week.js').then((w) => console.log(w.mondayOf('2026-10-24'), w.format('2026-10-19'), w.inWeek('2026-10-25', '2026-10-19')))"
2026-10-19 19 Oct 2026 true
```

Saturday the 24th is in the week that starts on Monday the 19th, and so is Sunday the 25th.
