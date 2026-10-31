---
title: Dark mode is a question the phone answers
version: 1
---

**Both platforms let the person choose a light or a dark appearance, and apps are expected to follow
it.** In React Native the choice arrives as a value, from `useColorScheme()`, which returns `"light"`,
`"dark"`, or `null` when the platform does not say, and re-renders the component when the person
switches. There are no media queries to write; there is a hook to read.

## One palette per scheme

The planner keeps its colours in one file, so that no component ever writes a colour of its own. Save
this as `src/theme.ts`:

```typescript
// src/theme.ts: the planner's colours, one set for each colour scheme.
import { useColorScheme } from "react-native";

const light = {
  background: "#ffffff",
  text: "#1f2328",
  muted: "#57606a",
  line: "#d0d7de",
  pressed: "#eef2f6",
  track: "#e6ebf0",
  accent: "#2f6f4e",
};
const dark: typeof light = {
  background: "#0d1117",
  text: "#e6edf3",
  muted: "#9198a1",
  line: "#3d444d",
  pressed: "#161b22",
  track: "#21262d",
  accent: "#57ab7a",
};
export type Theme = typeof light;

export function useTheme(): Theme {
  return useColorScheme() === "dark" ? dark : light;
}
```

`useTheme()` is a **hook of the planner's own**, a function whose name starts with `use` and which calls
another hook inside it. A component calls `const t = useTheme()` and writes `color: t.text`; when the
phone switches to dark, every component that called it renders again with the other set. Lesson 9 says
what makes a hook a hook; here it is enough that it works like `useState` does, from the top of a
component.

**The template opts the app out of all this.** Its `app.json` says `"userInterfaceStyle": "light"`, so
that the native parts, the status bar and the keyboard, stay light whatever the phone says. Change it to
`"automatic"` once the app follows the scheme, or the status bar draws dark text on the planner's dark
background.

## Choosing the colours

**Every pair of text and background must be readable, in both palettes.** Against the background, the
normal text in this file reaches 15.8 to 1 in the light palette and 16.0 in the dark, and the muted grey
6.4 and 6.5; on a pressed row, where the background changes, the grey still keeps 5.7 and 5.9. The WCAG's
AA level asks 4.5 to 1 for normal text. The accent is used for the done part of the bar, which carries
no text, and the bar says its value to a screen reader in words. A palette is checked once, with a
contrast checker, and then nobody has to think about it again, which is the argument for one file.

## Measured in both

The measuring program of the flexbox section takes `--dark`, which asks the browser for the dark scheme
the way a phone in dark mode would:

```
ana@dev:~/planner$ node boxes.mjs 'http://localhost:8082/?today=2026-10-21' --dark
header       x=24 y=64 w=342 h=40  rgba(0, 0, 0, 0)
week-bar     x=24 y=147 w=342 h=12  rgb(33, 38, 45)
week-done    x=24 y=147 w=205 h=12  rgb(87, 171, 122)
week-left    x=229 y=147 w=137 h=12  rgba(0, 0, 0, 0)
row-spanish  x=24 y=175 w=342 h=62  rgba(0, 0, 0, 0)
row-statistics x=24 y=237 w=342 h=62  rgba(0, 0, 0, 0)
row-guitar   x=24 y=299 w=342 h=62  rgba(0, 0, 0, 0)
```

Same boxes, other colours: the track and the done part are the dark palette's. `rgba(0, 0, 0, 0)` on
the header is *transparent*, which is right: it has no background of its own and shows the screen's.
