---
title: A link is input, and the parser refuses what it does not know
version: 1
---

**However a link arrives, the app ends up holding a string, and turning that string into a screen is
the app's own code.** The system decides *whether* the planner opens. What it opens on is decided by a
function that reads the URL, and that function is the one place where a link from a stranger meets
the app. So it is written the way Apple's documentation asks: everything it does not recognise is
refused, by name, and nothing it accepts can do more than open a screen.

The planner accepts three addresses, in both spellings:

| screen | custom scheme | verified link |
|---|---|---|
| the list of courses | `planner://courses` | `https://planner.example.com/courses` |
| one course | `planner://course/sql` | `https://planner.example.com/course/sql` |
| the week | `planner://week` | `https://planner.example.com/week` |

The parser turns one of these into a route, and the route into the stacks of lesson 10, so this
lesson's files sit beside `backstack.ts` in `~/planner`. Save this as `links.ts`:

```schooling-example
{"language": "typescript", "file": "links.ts", "parts": [{"code": "// links.ts: a link from outside the app, turned into a planner screen or refused\nimport { start, open, tap, type Nav } from \"./backstack.ts\";\n\nexport type Route = { screen: \"courses\" } | { screen: \"course\"; id: string } | { screen: \"week\" };\n\nconst HOST = \"planner.example.com\";\nconst ID = /^[a-z0-9-]{1,40}$/; // a course id as the planner writes them\n", "note": "A `Route` is the whole list of places a link may lead, and there are three. Nothing in the type can say \"delete\" or \"send\", so no link can ask for either. `ID` is the shape of a course id: lower-case letters, digits and hyphens, never a title."}, {"code": "// The parts of the path, the same for planner://course/sql and\n// https://planner.example.com/course/sql; anything else is refused.\nfunction parts(url: URL): string[] {\n  const path = url.pathname.split(\"/\").filter((p) => p !== \"\");\n  if (url.protocol === \"planner:\") return [url.host, ...path];\n  if (url.protocol === \"https:\" && url.host === HOST) return path;\n  throw new Error(`not a planner link: ${url.protocol}//${url.host}`);\n}\n", "note": "In `planner://course/sql` the URL parser reads `course` as the host, so it goes back at the front of the list. An `https` link counts only on the planner's own host, compared whole, port included. Every other scheme and host stops here."}, {"code": "export function parse(link: string): Route {\n  if (!URL.canParse(link)) throw new Error(\"not a URL at all\");\n  const p = parts(new URL(link));\n  if (p.length === 1 && p[0] === \"courses\") return { screen: \"courses\" };\n  if (p.length === 1 && p[0] === \"week\") return { screen: \"week\" };\n  if (p.length === 2 && p[0] === \"course\" && ID.test(p[1])) return { screen: \"course\", id: p[1] };\n  throw new Error(`no such screen: /${p.join(\"/\")}`);\n}\n", "note": "An allow-list, read top to bottom: three exact shapes are accepted and everything else falls through to the refusal. Checking the length first is what refuses a known screen with something extra on the end."}, {"code": "// The stacks a link opens: the screen it names, with the screens the app\n// would have shown before it put underneath, so that back and up still work.\nexport function toNav(route: Route): Nav {\n  if (route.screen === \"course\") return open(start(), `course:${route.id}`);\n  if (route.screen === \"week\") return tap(start(), \"Week\");\n  return start();\n}", "note": "The route becomes lesson 10's `Nav`. A course opens with `courses` under it, the stack the student would have built by tapping, and the week is the Week tab at its root."}]}
```

**`toNav` is where lesson 10's *up* pays off.** A student who taps a link to one course never saw the
list of courses, but the stack the link opens has `courses` under `course:sql` all the same. Android's
navigation principles call this a synthetic back stack and ask that it be one the student could have
reached by tapping, which is exactly what `open(start(), ...)` builds. Back from the course then lands
on the list, inside the app, instead of dropping the student out of it at the first press.

## Ten links, four accepted

A second file feeds the parser links the way they turn up in practice: the four it should accept,
and six that look close enough to fool something less strict. Save it as `follow.ts`:

```typescript
// follow.ts: links from outside, and what the planner makes of each
import { parse, toNav } from "./links.ts";

const links = [
  "planner://course/sql",
  "https://planner.example.com/course/sql",
  "https://planner.example.com/week?from=email",
  "planner://courses",
  "http://planner.example.com/course/sql",
  "https://planner.example.net/course/sql",
  "planner://course/SQL Databases",
  "planner://settings/reset",
  "planner://course/sql/delete",
  "planner course sql",
];

for (const link of links) {
  try {
    const nav = toNav(parse(link));
    console.log(`open    ${link}\n        ${nav.tab}: ${nav.stacks[nav.tab].join(" > ")}`);
  } catch (e) {
    console.log(`refuse  ${link}\n        ${(e as Error).message}`);
  }
}
```

It needs `backstack.ts` from lesson 10 beside it, and nothing else. Run it:

```
ana@dev:~/planner$ node follow.ts
open    planner://course/sql
        Courses: courses > course:sql
open    https://planner.example.com/course/sql
        Courses: courses > course:sql
open    https://planner.example.com/week?from=email
        Week: week
open    planner://courses
        Courses: courses
refuse  http://planner.example.com/course/sql
        not a planner link: http://planner.example.com
refuse  https://planner.example.net/course/sql
        not a planner link: https://planner.example.net
refuse  planner://course/SQL Databases
        no such screen: /course/SQL%20Databases
refuse  planner://settings/reset
        no such screen: /settings/reset
refuse  planner://course/sql/delete
        no such screen: /course/sql/delete
refuse  planner course sql
        not a URL at all
```

**The two spellings of one course open the same stack.** That is what the `parts` function is for:
after it, `planner://course/sql` and the `https` address are the same list, `course` and `sql`, and
the rest of the parser never asks how the link was spelt.

**Each refusal names a different mistake.** `http://` is not `https://`, and a verified link is only
ever `https`, so the plain one is refused rather than quietly upgraded. `planner.example.net` is one
letter from the planner's domain and belongs to somebody else. `SQL Databases` is a course's title
where its id should be; the URL parser has already turned the space into `%20`, which is why the
message shows it that way, and the id pattern refuses it. Lesson 1 made sessions point at a course by
its id and never by its title, and a link is held to the same rule. `settings/reset` names a screen
the planner does not have, and `course/sql/delete` adds an action to a real one: a link opens a
screen, and a path with one part too many is not a request to do something.

**The query string on the week link is ignored, not trusted.** `?from=email` is the kind of tag a
newsletter adds to every link it sends, and refusing it would break the links people actually
receive. The parser reads only the scheme, the host and the path, so whatever the query says has no
way to reach a screen. Lesson 13 comes back to tags like this one, from the side of what they reveal.
