---
title: Every story in both themes
version: 1
---

**A component has to be checked in every theme it can appear in, so the workshop needs a way to switch
theme for every story at once.** Lesson 5 made a theme a value of `data-theme` on the root element; the
workshop gets a toolbar menu that sets it.

Storybook calls such a setting a **global**: a value that applies to every story, shown in the toolbar,
and passed to every story's render. A **decorator** is a function that wraps every story, and this one
writes the global onto the root element before the story draws. `preview.ts` grows to this:

```schooling-example
{"language": "typescript", "file": ".storybook/preview.ts", "parts": [
 {"code": "// .storybook/preview.ts\nimport type { Preview } from \"@storybook/html-vite\";\nimport \"../src/style.css\";\n\nconst preview: Preview = {", "note": "As before: the planner's stylesheet, with its tokens and both themes, loaded into every story's frame."},
 {"code": "  globalTypes: {\n    theme: {\n      description: \"Colour theme\",\n      toolbar: { title: \"Theme\", items: [\"light\", \"dark\"], dynamicTitle: true },\n    },\n  },\n  initialGlobals: { theme: \"light\" },", "note": "A global called `theme`, drawn as a menu in the toolbar with two items. `dynamicTitle` makes the menu show the current choice. Light is where every story starts."},
 {"code": "  decorators: [\n    (story, context) => {\n      document.documentElement.dataset.theme = context.globals.theme;\n      return story();\n    },\n  ],", "note": "Before each story draws, the root element gets `data-theme`, which the generated `tokens.css` turns into one set of values or the other. The story itself knows nothing about themes, which is the point of the semantic layer."},
 {"code": "  tags: [\"autodocs\"],\n};\n\nexport default preview;", "note": "Unchanged: a docs page for every component."}
]}
```

The toolbar now has a **Theme** menu. Choosing *dark* redraws the story in the dark values, and every
other story follows, since a global is not per story.

## A global in the address

Globals can also be set in a story's address, which matters for the next sections because a test opens
stories by address. The frame Storybook draws a story in is `iframe.html`, and the theme rides along as a
parameter:

```
http://127.0.0.1:6006/iframe.html?id=planner-session-row--to-do&viewMode=story&globals=theme:dark
```

That address shows one row, alone, in the dark theme, with none of Storybook's own interface around it.
It is the address a screenshot test wants, because it contains only the component.
