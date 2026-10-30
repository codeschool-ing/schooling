---
title: The brand stays, the conventions move
version: 1
---

**The question every team argues about is whether the app should look the same on both phones, and
the useful answer splits the screen in two.** The planner's colours, its spacing, the tone of its
words and the shape of its week belong to the planner: a student who uses it on a friend's iPhone
should recognise it. Where the main action sits, which bar switches sections, which font draws a
paragraph and how a sheet appears belong to the platform: a student should not have to learn the
planner's private idea of a tab bar. Both guides draw the line in roughly that place. Material is
built to carry a brand through its roles; the HIG asks for the brand as a tint and keeps the rest.

| belongs to the brand | belongs to the platform |
|---|---|
| the accent colour and the other colours the planner chose | where the primary action lives |
| the spacing steps, 8, 16, 24 | the bar that switches sections, and its place |
| the words, the icons drawn for the planner | the system font on iOS, and text styles |
| what the week screen shows, and in what order | back: the system gesture, or a button at the top |
| a light and a dark set of colours | dark mode switching with the system setting |

**The wrong version of "the same everywhere" draws one set of screens and ships it twice**: a
floating button on the iPhone, a tab bar of its own invention on Android. It looks consistent to
the team that sees both phones side by side every day, and odd to every user, who sees one.

## Design tokens

**A design token is one design decision, named and written down once, in a form both platforms can
read.** `primary` is `#2F6F4E`; the medium gap is 16; body text is 16. A team keeps them in one file,
and each platform's theme is built from it, so changing the brand's green is one edit and not two
that drift. The planner's are small enough to show whole. Save this as `tokens.ts` in `~/planner`:

```schooling-example
{"language": "typescript", "file": "tokens.ts", "parts": [{"code": "// tokens.ts: the planner's design decisions, written once\ntype Palette = { primary: string; onPrimary: string; surface: string; onSurface: string; muted: string };\n\nexport const brand = {\n  light: { primary: \"#2F6F4E\", onPrimary: \"#FFFFFF\", surface: \"#FFFFFF\", onSurface: \"#1C1B1F\", muted: \"#8A8A8A\" },\n  dark: { primary: \"#8FD3AE\", onPrimary: \"#00391F\", surface: \"#1C1B1F\", onSurface: \"#E6E1E5\", muted: \"#938F99\" },\n  space: { s: 8, m: 16, l: 24 }, // dp on Android, pt on iOS\n  text: { body: 16, title: 22 }, // the brand's sizes; iOS keeps its own text styles\n};\n", "note": "The brand, and nothing else. Five colours by role, once for light and once for dark; three spacing steps; two text sizes. `muted` is the grey of the date under a session. No platform word appears here."}, {"code": "// Material 3: colour roles by name, sizes in dp and sp, Roboto, the action in a FAB.\nexport function materialTheme(mode: \"light\" | \"dark\") {\n  const c: Palette = brand[mode];\n  return {\n    colorScheme: { primary: c.primary, onPrimary: c.onPrimary, surface: c.surface, onSurface: c.onSurface, onSurfaceVariant: c.muted },\n    spacingDp: brand.space,\n    typography: { bodyLarge: `Roboto ${brand.text.body}sp`, titleLarge: `Roboto ${brand.text.title}sp` },\n    primaryAction: \"floating action button\",\n    sections: \"navigation bar\",\n  };\n}\n", "note": "Material's theme takes the brand's values into Material's own names: the grey becomes `onSurfaceVariant`, the body size becomes `bodyLarge` in `sp`. The last two fields are not values at all: they are the conventions the previous section drew."}, {"code": "// The HIG: the brand colour as the tint, sizes in pt, the system font through text styles.\nexport function iosTheme(mode: \"light\" | \"dark\") {\n  const c: Palette = brand[mode];\n  return {\n    tint: c.primary,\n    colors: { background: c.surface, label: c.onSurface, secondaryLabel: c.muted },\n    spacingPt: brand.space,\n    typography: { body: \"system font, .body\", title: \"system font, .largeTitle\" },\n    primaryAction: \"toolbar button, top trailing\",\n    sections: \"tab bar\",\n  };\n}", "note": "The iOS theme takes the same colours under the HIG's names, `tint`, `label`, `secondaryLabel`, and does not pass the brand's text sizes on: it asks for text styles, so Dynamic Type keeps working. Same brand, other conventions."}]}
```

A second file asks for both themes and prints them side by side, marking with `=` every row where
the two hold the same value. Save it as `themes.ts`:

```typescript
// themes.ts: the two themes side by side, to see what stayed and what moved
import { materialTheme, iosTheme } from "./tokens.ts";

const mode = process.argv[2] === "dark" ? "dark" : "light";
const m = materialTheme(mode);
const i = iosTheme(mode);
const rows = [
  ["accent", m.colorScheme.primary, i.tint],
  ["text", m.colorScheme.onSurface, i.colors.label],
  ["secondary text", m.colorScheme.onSurfaceVariant, i.colors.secondaryLabel],
  ["background", m.colorScheme.surface, i.colors.background],
  ["medium gap", `${m.spacingDp.m} dp`, `${i.spacingPt.m} pt`],
  ["body text", m.typography.bodyLarge, i.typography.body],
  ["primary action", m.primaryAction, i.primaryAction],
  ["sections", m.sections, i.sections],
];
console.log(`${mode}`.padEnd(18) + "Material".padEnd(26) + "iOS");
for (const [role, a, b] of rows) {
  const kept = a.split(" ")[0] === b.split(" ")[0]; // the same value, whatever the unit
  console.log((kept ? "= " : "  ") + role.padEnd(16) + a.padEnd(26) + b);
}
```

Run it for the light appearance, and then for the dark one:

```
ana@dev:~/planner$ node themes.ts
light             Material                  iOS
= accent          #2F6F4E                   #2F6F4E
= text            #1C1B1F                   #1C1B1F
= secondary text  #8A8A8A                   #8A8A8A
= background      #FFFFFF                   #FFFFFF
= medium gap      16 dp                     16 pt
  body text       Roboto 16sp               system font, .body
  primary action  floating action button    toolbar button, top trailing
  sections        navigation bar            tab bar
ana@dev:~/planner$ node themes.ts dark
dark              Material                  iOS
= accent          #8FD3AE                   #8FD3AE
= text            #E6E1E5                   #E6E1E5
= secondary text  #938F99                   #938F99
= background      #1C1B1F                   #1C1B1F
= medium gap      16 dp                     16 pt
  body text       Roboto 16sp               system font, .body
  primary action  floating action button    toolbar button, top trailing
  sections        navigation bar            tab bar
```

**Read the `=` column.** The first five rows are the brand, and they are equal on both platforms in
both appearances: the same green, the same text colour, the same 16 for the medium gap, measured in
`dp` on one and `pt` on the other, which are lesson 7's subject. The last three are the
conventions, and every one of them differs. Body text sits between the two: the brand's 16 reaches
Material as `bodyLarge`, while iOS keeps the system's `.body` text style, which is 17 points at the
default size and follows Dynamic Type at every other.

**Nothing here draws a screen**, and that is why it runs on Node.js. Compose would read
`materialTheme` into a `ColorScheme` and a `Typography`; SwiftUI would read the tint into `.tint()`. Those are the jobs of the `android-apps` course,
whose lesson 7 is Material 3 theming, and of `ios-apps`, if you take one of those routes; a React
Native app can import `tokens.ts` as it is, since it is TypeScript. In every case the file the team edits is the
tokens.

## What the tokens do not settle

**A token says what the colour is, and nothing about whether it can be read.** The planner's
`muted` grey is the colour of the date under each session, and both themes carry it faithfully. Lesson
19 runs it through the contrast formula and finds that the light one fails, which is the
reason this file keeps colours in one place: the fix will be one line, here, and both platforms will
get it.

Commit the two files with the rest of the planner. The hash on the last line will be different on
yours, because it depends on every commit before it:

```
ana@dev:~/planner$ git add tokens.ts themes.ts
ana@dev:~/planner$ git commit -q -m "Design tokens, and a theme for each platform"
ana@dev:~/planner$ git log --oneline -1
2ad5024 Design tokens, and a theme for each platform
```
