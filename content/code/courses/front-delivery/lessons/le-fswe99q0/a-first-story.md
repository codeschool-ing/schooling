---
title: A first story
version: 1
---

**A story is a named state of a component: the component, plus the arguments that put it in that
state.** Stories are written in **Component Story Format**, CSF: a module whose default export describes
the component, and whose every other export is one story. Storybook reads the exports; nothing else in the
file is special.

The session row's stories live beside the component:

```schooling-example
{"language": "typescript", "file": "src/session-row.stories.ts", "parts": [
 {"code": "// src/session-row.stories.ts\nimport type { Meta, StoryObj } from \"@storybook/html-vite\";\nimport { fn } from \"storybook/test\";\nimport { sessionRow } from \"./components\";\nimport type { Session } from \"./planner\";\n\ntype Args = Session & { onDone: (id: number) => void };", "note": "A story's arguments are typed: a session's fields plus the handler. `fn` makes a spy function that Storybook shows in its Actions panel each time it is called."},
 {"code": "\nconst meta: Meta<Args> = {\n  title: \"Planner/Session row\",\n  render: ({ onDone, ...session }) => {\n    const list = document.createElement(\"ul\");\n    list.append(sessionRow(session, onDone));\n    return list;\n  },\n  args: { id: 6, course: \"javascript\", date: \"2026-10-15\", minutes: 45, done: false, onDone: fn() },\n};\nexport default meta;", "note": "The default export. `title` places the component in the sidebar. `render` turns arguments into an element, inside a `<ul>` because a row is a list item. `args` are the defaults every story starts from: session 6 from `courses.json`."},
 {"code": "\ntype Story = StoryObj<Args>;\n\nexport const ToDo: Story = {};\nexport const Done: Story = { args: { done: true } };\nexport const Long: Story = { args: { minutes: 135 } };", "note": "Three stories, each a difference from the defaults. `ToDo` changes nothing; `Done` is the same session finished; `Long` is one that runs over two hours. Storybook turns `ToDo` into the name *To Do* in the sidebar."}
]}
```

With `npm run storybook` running, the sidebar now shows **Planner, Session row** with three stories and
a docs page. Each story's frame shows one row; the Controls panel lists the arguments, and changing
`minutes` to 60 redraws the row as *1 h*. Pressing *Mark done* does nothing to the row, because the story
holds no state, and logs a call to `onDone` with `6` in the Actions panel, which is the evidence that the
component calls its handler with the right id.

## What Storybook built from it

Stories are found by the file name and indexed with an id made from the title and the export's name.
The build writes that index as `index.json`, which is how tests and other tools find every story:

```
ana@dev:~/planner$ npx storybook build > /dev/null 2>&1 && node -e "for (const id in require('./storybook-static/index.json').entries) console.log(id)"
planner-session-row--docs
planner-session-row--to-do
planner-session-row--done
planner-session-row--long
planner-week-summary--docs
planner-week-summary--in-progress
planner-week-summary--all-done
planner-week-summary--empty
```

`planner-session-row--to-do` is the address of the first story from now on. The ids come from the
names, so **renaming a story changes its id**, and anything that links to it, a test or a bookmark,
breaks. Name stories for the state they show, and leave them alone.
