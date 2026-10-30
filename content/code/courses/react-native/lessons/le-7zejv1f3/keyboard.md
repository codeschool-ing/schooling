---
title: The keyboard that covers the field
version: 1
---

**When a text field is focused, the system's keyboard slides up over the bottom half of the screen**, and
whatever was there, the next field, the *Save* button, is now underneath it. Neither platform moves your
content out of the way by itself in the same manner, and each of the form's keyboard props is an answer
to one part of that.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" data-fig=\"l11-keyboard\" aria-label=\"Two phone screens with the keyboard open. On the left, without KeyboardAvoidingView, the keyboard covers the minutes field and the Save button. On the right, with it on iOS, padding equal to the keyboard's height pushes the form up, so the focused field and Save stay visible above the keyboard.\"><text x=\"170\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">without</text><text x=\"510\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">with KeyboardAvoidingView</text><rect x=\"70\" y=\"30\" width=\"200\" height=\"300\" rx=\"14\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"90\" y=\"140\" width=\"160\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"153.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Date</text><rect x=\"72\" y=\"180\" width=\"196\" height=\"146\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">keyboard</text><text x=\"170\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">hidden under the keyboard</text><rect x=\"410\" y=\"30\" width=\"200\" height=\"300\" rx=\"14\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"430\" y=\"50\" width=\"160\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"440\" y=\"63.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Date</text><rect x=\"430\" y=\"90\" width=\"160\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"440\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Minutes</text><rect x=\"430\" y=\"130\" width=\"160\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"510.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Save session</text><rect x=\"412\" y=\"180\" width=\"196\" height=\"146\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"510\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">keyboard</text></svg>", "caption": "The keyboard takes half the screen; the form has to move out of its way, and each platform does that differently."}
```

## KeyboardAvoidingView

`KeyboardAvoidingView` adjusts its contents when the keyboard appears. Its `behavior` has to differ by
platform, which is why the form writes it with a ternary:

| platform | `behavior` | why |
|---|---|---|
| iOS | `"padding"` | adds padding equal to the keyboard's height, pushing the content up |
| Android | none | Android resizes the app's window itself, by default in Expo projects |

Inside it, the form is a `ScrollView`, so that a screen too tall for what remains above the keyboard can
still be scrolled to its last field. *How this looks with a keyboard open was not run for this course*:
the web build has no on-screen keyboard to push anything, and there was no phone. It is taught from
React Native's documentation for `KeyboardAvoidingView`, and it is the part of a form most worth trying
on a real device.

## Taps while the keyboard is open

`keyboardShouldPersistTaps="handled"` on the `ScrollView`, as lesson 4 said. Without it, the first tap on
*Save* with the keyboard open only closes the keyboard, and the person has to tap again; with it, a tap
on something that handles it, a button, goes to that thing.

## Moving through the fields

The date field's return key is labelled *next* (`returnKeyType="next"`), and pressing it calls
`onSubmitEditing`, which focuses the minutes field through a ref:

```tsx
onSubmitEditing={() => minutesRef.current?.focus()}
```

The minutes field's key says *done*, and pressing it saves. A person can fill the form without ever
taking a finger to the screen above the keyboard, which is how forms on phones are meant to feel.

## The right keyboard for each field

`keyboardType="numbers-and-punctuation"` for the date, because it needs digits and hyphens;
`number-pad` for the minutes, which need digits alone. On iOS, `number-pad` has no return key at all, so
the minutes field cannot be submitted from the keyboard there: the *Save* button is the way, and it is
always reachable because the view moved up. That is a platform difference of exactly lesson 6's kind,
found by reading the documentation of `keyboardType` rather than by guessing.
