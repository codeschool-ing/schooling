---
title: Asking at the moment the person can see why
version: 1
---

**Because a refusal can be final, the moment an app asks is part of the design, not a detail of the
code.** The tempting place is the first launch: ask for everything at once, get it over with. It is
also the worst place. The person has not seen a single screen of the app yet, the dialog names a
permission with no reason in sight, and "no" is the safe answer to a question you do not understand.
On iOS that no is already final; on Android it uses up half of what the app will ever get.

**Ask when the person does the thing that needs it.** In the planner, that is the moment a student
taps "remind me" on a study session. The question now explains itself: they asked for a reminder, and
a reminder is a notification. Android's documentation on requesting permissions puts the rule in so
many words, saying to prompt "only when they need access to a specific feature", because otherwise
"you might inadvertently lose the ability to re-request permissions".

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 396\" role=\"img\" data-fig=\"l12-flow\" aria-label=\"The flow of asking for the reminder permission. The student taps remind me. If the permission is granted, the planner reminds. If it was refused for good, the planner plans without reminders and offers Settings. Otherwise, if Android's rationale call returns true, the planner first shows its own explanation; then the system dialog appears. A yes means the planner reminds; a no means it plans without reminders.\"><defs><marker id=\"l12-flow-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12-flow-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l12-flow-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"250\" y=\"10\" width=\"220\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the student taps “remind me”</text><rect x=\"300\" y=\"62\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"75.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">granted</text><text x=\"360.0\" y=\"88.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">already?</text><path d=\"M360 40 L360 62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-flow-ah-paper-dim)\"></path><rect x=\"560\" y=\"62\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">remind</text><path d=\"M420 82 L560 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-flow-ah-phosphor)\"></path><text x=\"490\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">yes</text><rect x=\"300\" y=\"132\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"145.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">refused</text><text x=\"360.0\" y=\"158.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">for good?</text><path d=\"M360 102 L360 132\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-flow-ah-paper-dim)\"></path><text x=\"372\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no</text><rect x=\"530\" y=\"132\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">plan without reminders;</text><text x=\"620.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">offer Settings</text><path d=\"M420 152 L530 152\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-flow-ah-amber)\"></path><text x=\"475\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">yes</text><rect x=\"290\" y=\"202\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"215.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Android: rationale</text><text x=\"360.0\" y=\"228.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">returns true?</text><path d=\"M360 172 L360 202\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-flow-ah-paper-dim)\"></path><text x=\"372\" y=\"187\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no</text><rect x=\"40\" y=\"202\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"215.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the planner's own</text><text x=\"115.0\" y=\"228.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">explanation</text><path d=\"M290 222 L190 222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-flow-ah-paper-dim)\"></path><text x=\"240\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">yes</text><rect x=\"300\" y=\"274\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"287.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the system's</text><text x=\"360.0\" y=\"300.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dialog</text><path d=\"M360 242 L360 274\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-flow-ah-paper-dim)\"></path><text x=\"372\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no</text><path d=\"M115 242 L115 294 L300 294\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-flow-ah-paper-dim)\"></path><rect x=\"560\" y=\"274\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"294.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">remind</text><path d=\"M420 294 L560 294\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-flow-ah-phosphor)\"></path><text x=\"490\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">yes</text><rect x=\"295\" y=\"344\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"358.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">plan without</text><text x=\"360.0\" y=\"370.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">reminders</text><path d=\"M360 314 L360 344\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-flow-ah-amber)\"></path><text x=\"372\" y=\"329\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no</text></svg>", "caption": "The dialog is the last step, and only reached by a person who has just asked for the thing it guards."}
```

## Explain before the dialog, in your own screen

**The system's dialog is short and the same for every app; the explanation belongs to the app.** The
flow above shows where it goes. Before the dialog, when the reason is not obvious from what the person
just tapped, the app shows a screen or a sheet of its own: what the permission is for, in the app's
words, and a button that leads on to the system dialog. On Android, a `true` from
`shouldShowRequestPermissionRationale()` is the system saying that this explanation is now owed. On
iOS there is no such signal and only one dialog, so the explanation, if one is needed, comes before
the first ask.

**The explanation must never imitate the system's dialog.** It is a screen of the app, it says so,
and its button leads to the real dialog, where the person decides. A screen that looks like the
system and records "yes" on its own is a trick played on the person, whatever it gains the app.

**Android 13's notification permission makes the moment the app's choice.** Its documentation says
that an app targeting Android 13 or higher "has complete control over when the permission dialog is
displayed". An app that still targets an older version gets the dialog the system chooses instead,
which for most apps is at start-up, the worst moment above. That difference is one of the quiet
reasons to keep an app's target version current.

## After a no

**A refused permission switches one feature off, not the app.** Android's documentation on handling
denial asks for the same things a person would: keep everything that does not need the permission
working, show the gap where the feature would have been, say specifically which feature is missing,
and do not block the screen with a warning. The planner without notifications plans sessions, marks
them done and sums the week exactly as before; the "remind me" button says reminders are off.

**And do not keep asking.** The same page warns that "persistent nagging to reconsider is not
respectful" of the person's choice. After the final no, the one useful thing the app can offer is a
way to the system's Settings, at the moment the person reaches the feature again, with a sentence
saying what to switch on. Both platforms make that a single call: on iOS, opening
`UIApplication.openSettingsURLString` shows the app's own page of Settings, and on Android an intent
opens the app's details screen. The person decides there, and the app checks the permission again the
next time it needs it, because only the system knows what they chose.

| moment | what the planner does |
|---|---|
| first launch | asks for nothing |
| student taps "remind me" | asks, and the tap is the explanation |
| Android, after one no | shows its own explanation, then asks once more |
| after the final no | plans without reminders, and offers Settings when "remind me" is tapped |
| person turns it on in Settings | finds it granted on the next check, and reminds |
