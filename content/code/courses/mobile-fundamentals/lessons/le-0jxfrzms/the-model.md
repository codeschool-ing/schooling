---
title: One permission, two platforms, four scenarios
version: 1
---

**The rules of the last two sections fit in a file of five small functions, and running them side by
side makes the difference between the two kinds of app plain.** `permission.ts` holds one runtime
permission, the planner's reminder permission, as a value with a platform and a state. Each function
is one sentence of the platforms' documentation: whether asking shows a dialog, what an answer does,
when Android says to explain, what turning it on in Settings does, and what the planner does next.
Save it as `permission.ts` in `~/planner`:

```schooling-example
{"language": "typescript", "file": "permission.ts", "parts": [{"code": "// permission.ts: one runtime permission, as each platform's documentation describes it\nexport type Platform = \"android\" | \"ios\";\nexport type State = \"not-asked\" | \"granted\" | \"denied\" | \"denied-for-good\";\nexport type Permission = { platform: Platform; state: State };\n\nexport function fresh(platform: Platform): Permission {\n  return { platform, state: \"not-asked\" };\n}\n", "note": "A permission is a platform and a state, and nothing else. The four states are the ones the documentation names; `not-asked` and `denied-for-good` are the two an app cannot tell apart from Android's rationale call alone, which is why the model keeps them separate."}, {"code": "// Does asking show the system's dialog? Android shows it again after one\n// \"no\"; iOS shows it once, ever. After that, asking answers at once.\nexport function showsDialog(p: Permission): boolean {\n  if (p.state === \"not-asked\") return true;\n  return p.platform === \"android\" && p.state === \"denied\";\n}\n", "note": "The rule that differs. A first request shows the dialog on both; after one no, only Android shows it again. In every other state the request answers at once, with no dialog for the person to see."}, {"code": "// The person's answer to the dialog. A second \"no\" on Android, and the\n// first on iOS, is final: the dialog never comes back.\nexport function answer(p: Permission, yes: boolean): Permission {\n  if (yes) return { ...p, state: \"granted\" };\n  const final = p.platform === \"ios\" || p.state === \"denied\";\n  return { ...p, state: final ? \"denied-for-good\" : \"denied\" };\n}\n", "note": "`final` is the whole difference between the platforms in one line: on iOS any no is final, on Android a no is final when one has already been given."}, {"code": "// Android's shouldShowRequestPermissionRationale(): true after one \"no\",\n// while one more dialog is still possible. iOS has no such call.\nexport function rationale(p: Permission): boolean {\n  return p.platform === \"android\" && p.state === \"denied\";\n}\n", "note": "`true` only in the window between the two Android dialogs, which is when the documentation says to explain. Before any ask and after the final no it is `false` alike."}, {"code": "// The person can always change their mind in the system's Settings app.\nexport function turnedOnInSettings(p: Permission): Permission {\n  return { ...p, state: \"granted\" };\n}\n", "note": "The way back from any state, on either platform, and the person's choice alone: no call of the app's leads here."}, {"code": "// What the planner does next, in each state. Planning sessions never needs\n// the permission; only the reminder for a session does.\nexport function next(p: Permission): string {\n  if (p.state === \"granted\") return \"send reminders\";\n  if (p.state === \"not-asked\") return \"ask when a reminder is wanted\";\n  if (p.state === \"denied\") return \"explain why, then ask once more\";\n  return \"plan without reminders; offer Settings\";\n}", "note": "What the planner does with the answer. Every state but `granted` still plans sessions; only the reminder waits on the permission."}]}
```

**Nothing in the file asks the person anything.** It is the system's half: a model of what the
platform will and will not do when the app asks. The app's half is the order in which it asks, and
that is what the second file varies. It plays four scenarios, two per platform. In one the app asks
at launch and the student refuses; in the other the app waits until the student taps "remind me".
Save it as `ask.ts`:

```typescript
// ask.ts: when the planner asks to send reminders, and what it may do after
import { fresh, showsDialog, answer, rationale, turnedOnInSettings, next } from "./permission.ts";
import type { Platform, Permission } from "./permission.ts";

type Step = { when: string; ask?: "yes" | "no" | "nothing"; settings?: true };
type Scenario = { title: string; platform: Platform; steps: Step[] };

const scenarios: Scenario[] = [
  { title: "asked at launch, refused twice", platform: "android", steps: [
    { when: "first launch", ask: "no" },
    { when: "second launch", ask: "no" },
    { when: "taps 'remind me'", ask: "nothing" },
    { when: "turns it on in Settings", settings: true },
  ] },
  { title: "asked in context, after explaining", platform: "android", steps: [
    { when: "first launch" },
    { when: "taps 'remind me'", ask: "yes" },
  ] },
  { title: "asked at launch, refused once", platform: "ios", steps: [
    { when: "first launch", ask: "no" },
    { when: "taps 'remind me'", ask: "nothing" },
  ] },
  { title: "asked in context, after explaining", platform: "ios", steps: [
    { when: "first launch" },
    { when: "taps 'remind me'", ask: "yes" },
  ] },
];

function row(...cells: string[]) {
  const widths = [24, 8, 8, 17, 11];
  console.log("  " + cells.map((c, i) => c.padEnd(widths[i] ?? 0)).join("").trimEnd());
}

for (const s of scenarios) {
  console.log(`${s.platform}: ${s.title}`);
  row("when", "dialog", "answer", "state", "rationale", "the planner will");
  let p: Permission = fresh(s.platform);
  for (const step of s.steps) {
    let dialog = "-";
    let said = "-";
    if (step.settings) {
      p = turnedOnInSettings(p);
    } else if (step.ask !== undefined) {
      const shown = showsDialog(p);
      dialog = shown ? "shown" : "none";
      if (shown && step.ask !== "nothing") {
        said = step.ask;
        p = answer(p, step.ask === "yes");
      }
    }
    row(step.when, dialog, said, p.state, rationale(p) ? "yes" : "no", next(p));
  }
  console.log();
}
```

A step with no `ask` is a moment when the app asks nothing; `"nothing"` means the app asked but the
person was shown no dialog to answer. Run it:

```
ana@dev:~/planner$ node ask.ts
android: asked at launch, refused twice
  when                    dialog  answer  state            rationale  the planner will
  first launch            shown   no      denied           yes        explain why, then ask once more
  second launch           shown   no      denied-for-good  no         plan without reminders; offer Settings
  taps 'remind me'        none    -       denied-for-good  no         plan without reminders; offer Settings
  turns it on in Settings -       -       granted          no         send reminders

android: asked in context, after explaining
  when                    dialog  answer  state            rationale  the planner will
  first launch            -       -       not-asked        no         ask when a reminder is wanted
  taps 'remind me'        shown   yes     granted          no         send reminders

ios: asked at launch, refused once
  when                    dialog  answer  state            rationale  the planner will
  first launch            shown   no      denied-for-good  no         plan without reminders; offer Settings
  taps 'remind me'        none    -       denied-for-good  no         plan without reminders; offer Settings

ios: asked in context, after explaining
  when                    dialog  answer  state            rationale  the planner will
  first launch            -       -       not-asked        no         ask when a reminder is wanted
  taps 'remind me'        shown   yes     granted          no         send reminders
```

## Reading the four tables

**The first table is the costly one.** The planner asked at the first launch and the student, who had
not seen a session yet, said no. Android then gave the app one more chance, and `rationale` said
`yes`: this was the moment to explain. The app asked again at the second launch, with no more reason
than the first time, and the second no made the denial permanent. When the student finally wanted a
reminder and tapped "remind me", the dialog column says `none`: the system answered for them. Only
the last row, where the student goes to Settings by their own choice, brings reminders back.

**The second table is the same student and the same app, asking at a different moment.** Nothing
happens at launch. The first dialog appears when the student taps "remind me", the student can see
why it is there, and says yes. The permission was never in danger.

**The iOS tables are shorter because iOS has one dialog.** Asked at launch and refused, the
permission is `denied-for-good` after a single answer, and `rationale` never says `yes` because
the platform has no such call. Asked in context, it is granted at the first and only dialog. On both
platforms the right column agrees with the previous section: after the final no, the planner keeps
planning, and offers Settings.

**Count the dialogs, because they are what the person sees.** The app that asked at launch on Android
showed two dialogs and ended with no reminders; the one that asked in context showed one and ended
with them. Nothing about the permission changed between the two, only the moment, which is the
argument of this lesson in two tables.
