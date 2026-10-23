---
title: Accessibility, on both sides
version: 1
---

**A React Native app is accessible through the platform's own screen reader**: TalkBack on Android,
VoiceOver on iOS. What they announce comes from the same props you have been writing: `role` says what
an element is, `aria-label` names it when its text does not, and a `Text` with `role="alert"` is read
out when it appears. React Native also accepts the older names, `accessibilityRole` and
`accessibilityLabel`, which you will meet in most code written before 2023.

Four rules carry most of the weight:

- **Every control has a role and a name.** A `Pressable` without `role="button"` is announced as
  nothing in particular, and a field without a label is announced as "text field", which says nothing
  about which one.
- **A touch target is big enough to hit.** Apple's guidelines ask for 44 by 44 points and Google's for
  48 by 48 density-independent pixels; padding is the usual way to get there, as the course rows do.
- **Text grows with the person's settings**, as the last section said, and the layout has to let it.
- **Grouping is deliberate.** By default a screen reader stops at every `Text`. A row that reads better
  as one sentence, a session's date and length, can be made one element with `accessible` on its
  `View`; a row with a button inside should not be, or the button disappears into it.

## Checking it in a browser, with axe

**axe** is the accessibility checker this repository runs over its own screens. It reads a page and
reports what breaks WCAG rules a machine can decide: contrast, missing names, roles that do not fit.
Run over the web build, it checks what `react-native-web` produced from your props, which is a fair test
of the props themselves. Install it beside Playwright, at the version this course used:

```
ana@dev:~/planner-native$ npm install -E -D @axe-core/playwright@4.14.0

added 2 packages, and audited 538 packages in 1s

5 high severity vulnerabilities

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

And a short program around it, saved as `axe.mjs`:

```javascript
// axe.mjs: run axe, the accessibility checker, over one address, and print what it found.
//
//   node axe.mjs URL [--click NAME]
import { chromium } from "playwright";
import { AxeBuilder } from "@axe-core/playwright";

const [url, flag, name] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await (await browser.newContext()).newPage();
await page.goto(url);
if (flag === "--click") await page.getByRole("button", { name, exact: true }).click();
await page.getByRole("main").waitFor();
const { violations, passes } = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa", "wcag21aa", "wcag22aa"]).analyze();
for (const v of violations) console.log(`${v.id} (${v.impact}): ${v.help}, ${v.nodes.length} element(s)`);
console.log(`${violations.length} rule(s) failed, ${passes.length} passed`);
await browser.close();
```

Both screens:

```
ana@dev:~/planner-native$ node axe.mjs 'http://localhost:8082/?today=2026-10-21'
0 rule(s) failed, 18 passed
ana@dev:~/planner-native$ node axe.mjs 'http://localhost:8082/?today=2026-10-21' --click Statistics
0 rule(s) failed, 25 passed
```

**Nothing failed.** To see what a failure looks like, give "Mark done" a lighter blue, `#7aa7e8`, the
kind of colour that looks fine on a bright screen, and run it on the course screen again:

```
ana@dev:~/planner-native$ sed -i 's/action: { color: "#0a58ca"/action: { color: "#7aa7e8"/' 'app/course/[id].tsx'
ana@dev:~/planner-native$ npx expo export --platform web > /dev/null
ana@dev:~/planner-native$ node axe.mjs 'http://localhost:8082/?today=2026-10-21' --click Statistics
color-contrast (serious): Elements must meet minimum color contrast ratio thresholds, 1 element(s)
1 rule(s) failed, 25 passed
```

**`color-contrast` is the rule**, and the element is the one "Mark done" label on that screen, the
Statistics session still to do. The
colour went back to `#0a58ca` afterwards. axe on the web build cannot tell you how TalkBack reads a
screen, or whether the focus order makes sense, which is why the real test of an app's accessibility is
the phone's own screen reader, turned on, with your eyes closed. *That test was not run for this
course; it needs a phone.*
