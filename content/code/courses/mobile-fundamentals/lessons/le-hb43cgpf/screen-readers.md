---
title: What a screen reader reads, and how its user moves
version: 1
---

**A screen reader turns the screen into a list and reads it aloud, one element at a time, from what
the app declared about each element.** It does not look at the pixels. A tick drawn in green means
nothing to it; a button that declared "mark done" means a great deal. Android's screen reader is
**TalkBack**, iPhone's is **VoiceOver**, and both work the same way at the level this lesson needs.

The common picture is that accessibility is a matter of large buttons and big text, something an
app adds at the end for a few users. The screen reader is the case that breaks that picture: for a
person who cannot see the screen, an app that declared nothing is an app with no interface at all,
and nothing added at the end can repair a screen whose controls were never described.

## How the user moves

**A sighted user touches what they see; a screen reader user moves a focus through the list and
then acts on it.** Android's documentation on testing with TalkBack describes the two common ways.
In *linear navigation* the user swipes right or left to move to the next or previous element, and
double-taps anywhere on the screen to activate the one in focus. In *explore by touch* they drag a
finger across the screen and hear whatever is under it, and again double-tap to act. Apple's page on
testing with VoiceOver lists the same swipe right or left to select the next or previous item among
the gestures a tester needs.

Two consequences follow, and both shape the planner. **The order of the list is the order the
screen is heard in**, so the week's total should come before the sessions it sums, as it does on the
screen. And **every element in that list costs a swipe**: a session row heard as four separate pieces,
course, date, minutes, tick, takes four swipes to pass, and a week of seven sessions takes
twenty-eight.

## What it reads for each element

For each element in focus, the screen reader speaks a short sequence, and each part comes from
something the app declared:

| part | what it says | where it comes from |
|---|---|---|
| **label** | what the element is: "SQL, Friday 23 October, 60 minutes" | the text, or a label the app sets |
| **role** | what kind of thing it is: button, checkbox, heading | the component, or a role the app sets |
| **state** | how it is now: checked, not checked, selected, disabled | the component's state, or a description the app sets |
| **hint** | what happens on activation, if that is not obvious | an optional hint, read after a pause |

Android calls the second part a *role* and the third a *state description*; Apple calls the second a
*trait* and puts the state into the element's *value* or traits. React Native has a property for
each: `accessibilityRole`, `accessibilityState`, `accessibilityHint`. The words differ and the four
slots are the same.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l19-announce\" aria-label=\"The sequence a screen reader speaks when focus arrives on the planner's mark-done row. A swipe moves the focus onto the row. Then four parts in order: the label, SQL, Friday 23 October, 60 minutes, which comes from the text or a label the app sets; the role, checkbox, from the component or a declared role; the state, not checked, from the component's state; and a hint, optional and read after a pause, which this row does not need. A double tap then toggles it and the state is read again as checked.\"><defs><marker id=\"l19-announce-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">a swipe right: focus arrives</text><path d=\"M30 34 L30 70 L40 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l19-announce-ah-paper-dim)\"></path><text x=\"120\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">label</text><rect x=\"44\" y=\"62\" width=\"152\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"82.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SQL, Fri 23 Oct,</text><text x=\"120.0\" y=\"95.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">60 minutes</text><text x=\"120\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">the text, or a label</text><path d=\"M196 89 L212 89\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-announce-ah-paper-dim)\"></path><text x=\"288\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">role</text><rect x=\"212\" y=\"62\" width=\"152\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"288.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">checkbox</text><text x=\"288\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">the component's role</text><path d=\"M364 89 L380 89\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-announce-ah-paper-dim)\"></path><text x=\"456\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">state</text><rect x=\"380\" y=\"62\" width=\"152\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"456.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">not checked</text><text x=\"456\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">the component's state</text><path d=\"M532 89 L548 89\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-announce-ah-paper-dim)\"></path><text x=\"624\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">hint</text><rect x=\"548\" y=\"62\" width=\"152\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"624.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">(none needed)</text><text x=\"624\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">optional, after a pause</text><rect x=\"44\" y=\"168\" width=\"656\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"372.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a double tap: the row toggles, and the state is read again: checked</text><path d=\"M370 146 L370 166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l19-announce-ah-paper-dim)\"></path></svg>", "caption": "What a screen reader says for one row, in order. It is a diagram of the sequence, not a recording: the exact words and pauses differ between TalkBack and VoiceOver and with the user's settings."}
```

The figure shows the parts in the order they come, for the planner's tick button on one session. It
is a diagram of the sequence, not a recording: the exact words and pauses differ between TalkBack and
VoiceOver, between versions, and with the user's settings. React Native's documentation notes, for
instance, that VoiceOver reads the hint "if the user has hints enabled".

**The label carries the most and goes wrong most often.** Without one, the user hears the role
alone, "button", on every tick in the list, and has no way to tell which session each belongs to.
Android's documentation gives the rule from the other side: describe "the purpose and result of the
interaction, not the visual details". It also asks you not to repeat the role in the label ("Submit", not "Submit
button"), and to make each description unique, because a list of seven buttons all called "mark done"
is a list of seven identical sounds.

**State is the part a sighted designer forgets**, because a sighted user sees it at a glance. The
tick is filled or empty. A screen reader user hears "checked" or "not checked", and only if the app
declared the control as something with a state. A button that changes colour when pressed, with
nothing declared, tells the screen reader user nothing happened.

## Trying it

Both readers are part of the phone, under Settings, then Accessibility. Android's documentation
suggests turning TalkBack on and swiping through each element of your app in order, listening for
anything missing, vague or too long. That is the test that finds what this lesson's checks cannot.
On the iPhone route, `ios-apps` gives its lesson 19 to VoiceOver and Dynamic Type. Here, the next
section writes the declarations themselves.
