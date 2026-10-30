---
title: Eleven presses, and every stack after each one
version: 1
---

**A second file plays a student's session against `backstack.ts`.** Two screens are opened in Courses,
then a switch to Week and one screen there, a switch back, and back presses until nothing is left. It
prints one row per step: which tab is showing, what each stack holds from the root up, and whether an
iPhone would draw a back button at that moment. Save it as `taps.ts`, beside `backstack.ts`:

```typescript
// taps.ts: taps and back presses on the planner, and the stacks after each
import { start, open, tap, back, backButton, type Nav, type Tab } from "./backstack.ts";

type Step = { tap: Tab } | { open: string } | { back: true };
const steps: Step[] = [
  { open: "course:sql" },
  { open: "new-session" },
  { tap: "Week" },
  { open: "session:s3" },
  { tap: "Courses" },
  { back: true },
  { tap: "Courses" },
  { tap: "Week" },
  { back: true },
  { back: true },
  { back: true },
];

function row(...cells: string[]) {
  const widths = [18, 9, 36, 20, 10];
  console.log(cells.map((c, i) => c.padEnd(widths[i] ?? 0)).join("").trimEnd());
}
function line(label: string, nav: Nav, note = "") {
  row(label, nav.tab, nav.stacks.Courses.join(" > "), nav.stacks.Week.join(" > "),
    backButton(nav) ? "yes" : "no", note);
}

let nav = start();
row("step", "tab", "Courses stack", "Week stack", "iOS back");
line("(app opens)", nav);
for (const s of steps) {
  if ("open" in s) {
    nav = open(nav, s.open);
    line("open " + s.open, nav);
  } else if ("tap" in s) {
    nav = tap(nav, s.tap);
    line("tap " + s.tap, nav);
  } else {
    const r = back(nav);
    nav = r.nav;
    line("Android back", nav, r.left ? "(the app leaves)" : "");
  }
}
```

`Step` is a union of three shapes, and `"open" in s` tells them apart; TypeScript narrows `s` inside
each branch, so `s.open` and `s.tap` are known to exist where they are read. Run it:

```
ana@dev:~/planner$ node taps.ts
step              tab      Courses stack                       Week stack          iOS back
(app opens)       Courses  courses                             week                no
open course:sql   Courses  courses > course:sql                week                yes
open new-session  Courses  courses > course:sql > new-session  week                yes
tap Week          Week     courses > course:sql > new-session  week                no
open session:s3   Week     courses > course:sql > new-session  week > session:s3   yes
tap Courses       Courses  courses > course:sql > new-session  week > session:s3   yes
Android back      Courses  courses > course:sql                week > session:s3   yes
tap Courses       Courses  courses                             week > session:s3   no
tap Week          Week     courses                             week > session:s3   yes
Android back      Week     courses                             week                no
Android back      Courses  courses                             week                no
Android back      Courses  courses                             week                no        (the app leaves)
```

## Reading it row by row

**Rows 4 to 6 are the point of tabs.** After the switch to Week, the Courses column still reads
`courses > course:sql > new-session`, untouched while the student pushed `session:s3` onto Week. Tapping
Courses brings it back as it was, form and all. A single history list could not do this: the Week
screen would have been pushed on top of the form, and back from it would land in the middle of Courses.

**The `iOS back` column changes with the tab, not with the time.** On row 4 it reads `no`, though the
student has opened three screens: the tab showing is Week, at its root, and an iPhone draws no back
button there. One row later Week has a screen on it and the answer is `yes`.

**Row 8 is a second tap on the tab already showing.** The Courses stack drops from two screens to one
in a single step, while Week keeps `session:s3`, because the rule touches only the tab that was tapped.

**The last three rows are Android's back running out of screens.** The first pops `session:s3`. The
second finds Week at its root, so it switches to Courses, the start tab, and pops nothing. The third
finds Courses at its root, and the app has nowhere left to go: the state is unchanged and the row says
the app leaves. On an iPhone none of those three presses exist, and the column has said `no` since the
Week stack emptied.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l10-stacks\" aria-label=\"The Courses and Week stacks at seven moments of the session in taps.ts. After opening new-session, Courses holds courses, course:sql and new-session, and Week holds week. After opening session:s3 on Week, Week holds week and session:s3 while Courses is unchanged. After Android back on Courses, Courses loses new-session. After a second tap on Courses, Courses holds only its root. Then on Week, back pops session:s3, the next back switches to Courses, and the last back finds Courses at its root and the app leaves.\"><text x=\"14\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Courses</text><text x=\"14\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Week</text><text x=\"118\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">open new-session</text><text x=\"118\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">row 3</text><rect x=\"76\" y=\"112\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"118.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">courses</text><rect x=\"76\" y=\"88\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"118.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">course:sql</text><rect x=\"76\" y=\"64\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"118.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">new-session</text><rect x=\"76\" y=\"232\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"118.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">week</text><text x=\"210\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">open session:s3</text><text x=\"210\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">row 5</text><rect x=\"168\" y=\"112\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">courses</text><rect x=\"168\" y=\"88\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">course:sql</text><rect x=\"168\" y=\"64\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">new-session</text><rect x=\"168\" y=\"232\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">week</text><rect x=\"168\" y=\"208\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">session:s3</text><text x=\"302\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Android back</text><text x=\"302\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">row 7</text><rect x=\"260\" y=\"112\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"302.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">courses</text><rect x=\"260\" y=\"88\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"302.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">course:sql</text><rect x=\"260\" y=\"232\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"302.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">week</text><rect x=\"260\" y=\"208\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"302.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">session:s3</text><text x=\"394\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">tap Courses</text><text x=\"394\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">row 8</text><rect x=\"352\" y=\"112\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"394.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">courses</text><rect x=\"352\" y=\"232\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"394.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">week</text><rect x=\"352\" y=\"208\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"394.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">session:s3</text><text x=\"486\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Android back</text><text x=\"486\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">row 10</text><rect x=\"444\" y=\"112\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"486.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">courses</text><rect x=\"444\" y=\"232\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"486.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">week</text><text x=\"578\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Android back</text><text x=\"578\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">row 11</text><rect x=\"536\" y=\"112\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"578.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">courses</text><rect x=\"536\" y=\"232\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"578.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">week</text><text x=\"670\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Android back</text><text x=\"670\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">row 12</text><rect x=\"628\" y=\"112\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"670.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">courses</text><rect x=\"628\" y=\"232\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"670.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">week</text><rect x=\"76\" y=\"150\" width=\"636\" height=\"1\" rx=\"0\" fill=\"var(--wire)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"628\" y=\"160\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"670.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">the app leaves</text><rect x=\"20\" y=\"272\" width=\"14\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"40\" y=\"277\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the tab showing</text></svg>", "caption": "Each tab's pile changes only while that tab is showing. The last three back presses pop, switch to the start tab, and leave."}
```

**Count the presses from the deepest point.** Say Courses holds three screens and Week two. From the
new-session form, two backs bring Courses down to its root and one more leaves: three in all, because
the student is already on the start tab. From `session:s3` on Week it takes three as
well: one pop, one switch, one exit. Commit the two files, so that this lesson's additions are a commit
of their own:

```
ana@dev:~/planner$ git add backstack.ts taps.ts
ana@dev:~/planner$ git commit -q -m "Two tabs, each with its own back stack"
ana@dev:~/planner$ git log --oneline
c001117 Two tabs, each with its own back stack
87ae50d The planner core, as lesson 1 gives it
```
