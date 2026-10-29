---
title: The planner's components, as functions
version: 1
---

**Before anything can be shown on its own, it has to exist on its own.** The planner's view code built
every element inline, so a session row was ten lines in the middle of `coursePage`. It comes out into
a file of its own, with two more pieces the planner repeats: the action button and the week's summary.

The new file is the planner's component library. Each component is a function that takes data and
returns an element, which is the shape a Web Component, a React component or an Angular one has too,
under other names:

```schooling-example
{"language": "typescript", "file": "src/components.ts", "parts": [
 {"code": "// src/components.ts\nimport { duration } from \"./format\";\nimport type { Session } from \"./planner\";", "note": "The library depends on the planner's types and its duration formatter, and on nothing in `view.ts`. That direction matters: the page uses the library, never the other way round."},
 {"code": "\n/** The button for the one action of a row or a form. */\nexport function actionButton(label: string, onClick?: () => void): HTMLButtonElement {\n  const button = document.createElement(\"button\");\n  button.textContent = label;\n  if (onClick) button.addEventListener(\"click\", onClick);\n  return button;\n}", "note": "A button with a label and, optionally, something to do. A form's submit button needs no handler: the form's own submit event does the work. The comment above the function is a JSDoc comment, which Storybook's documentation reads."},
 {"code": "\n/** One session: its date and length, then either \"done\" or a button that marks it done. */\nexport function sessionRow(session: Session, onDone?: (id: number) => void): HTMLLIElement {\n  const item = document.createElement(\"li\");\n  item.textContent = `${session.date} · ${duration(session.minutes)} `;\n  if (session.done) {\n    const done = document.createElement(\"span\");\n    done.textContent = \"done\";\n    item.append(done);\n  } else {\n    item.append(actionButton(\"Mark done\", () => onDone?.(session.id)));\n  }\n  return item;\n}", "note": "The row, as lesson 1 drew it, using the button above. What happens when the button is pressed is the caller's business, passed in as `onDone`."},
 {"code": "\n/** The week's total as a sentence, or a sentence saying there is nothing in it. */\nexport function weekSummary(week: { planned: number; done: number }): HTMLParagraphElement {\n  const summary = document.createElement(\"p\");\n  summary.textContent =\n    week.planned === 0\n      ? \"Nothing planned this week\"\n      : `This week: ${duration(week.planned)} planned, ${duration(week.done)} done`;\n  return summary;\n}", "note": "The front page's line, now with durations in hours and minutes, and a state it never had: an empty week. It is the kind of state a workshop makes you write, because writing the examples makes you ask what happens at zero."}
]}
```

`view.ts` becomes shorter, because it now uses the library instead of building the pieces. Replace it
whole:

```typescript
// src/view.ts
import { actionButton, sessionRow, weekSummary } from "./components";
import { title } from "./env";
import type { Course, Session } from "./planner";

export interface Actions {
  add(date: string, minutes: number): void;
  done(id: number): void;
}

const base = import.meta.env.BASE_URL;

function el<K extends keyof HTMLElementTagNameMap>(tag: K, text = ""): HTMLElementTagNameMap[K] {
  const node = document.createElement(tag);
  node.textContent = text;
  return node;
}

export function courseList(courses: Course[], week: { planned: number; done: number }): HTMLElement {
  const main = el("main");
  const list = el("ul");
  for (const course of courses) {
    const link = el("a", course.title);
    link.href = `${base}course/${course.id}`;
    list.append(el("li"));
    list.lastElementChild!.append(link);
  }
  main.append(el("h1", title), weekSummary(week), list);
  return main;
}

export function coursePage(course: Course, sessions: Session[], actions: Actions): HTMLElement {
  const main = el("main");
  const back = el("a", "All courses");
  back.href = base;
  const list = el("ul");
  for (const s of sessions) list.append(sessionRow(s, actions.done));
  const form = el("form");
  const date = el("input");
  date.type = "date";
  date.required = true;
  const minutes = el("input");
  minutes.type = "number";
  minutes.min = "5";
  minutes.required = true;
  const dateLabel = el("label", "Date ");
  dateLabel.append(date);
  const minutesLabel = el("label", "Minutes ");
  minutesLabel.append(minutes);
  form.append(dateLabel, minutesLabel, actionButton("Add session"));
  form.addEventListener("submit", (event) => {
    event.preventDefault();
    actions.add(date.value, Number(minutes.value));
  });
  main.append(back, el("h1", course.title), list, el("h2", "New session"), form);
  return main;
}

export function notFound(): HTMLElement {
  const main = el("main");
  const back = el("a", "All courses");
  back.href = base;
  main.append(el("h1", "Not found"), back);
  return main;
}
```

The checks from lesson 3 say nothing broke:

```
ana@dev:~/planner$ npx tsc && npm test 2>&1 | grep Tests
      Tests  5 passed (5)
```

Open the front page and its line now reads *This week: 2 h 10 min planned, 1 h done*: the same numbers,
written by `weekSummary`.
