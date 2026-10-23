---
title: Why a list of bad values fails
version: 1
---

The first instinct when a field worries somebody is to write down what must not be in it: no angle
brackets, no semicolons, no double hyphens. That list is a **denylist**, and it fails for a reason
that has nothing to do with how carefully it was written. **It has to know every bad value in
advance, and the input it meets was written by people who did not read it.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l02-sets\" aria-label=\"Two ways to decide what a field accepts, drawn as regions of every possible input. On the left, a denylist: everything is accepted except a few listed bad values, so anything nobody thought of gets through, including an impossible date and a clinic that does not exist. On the right, an allowlist: nothing is accepted except a small described region, the four clinics, real dates, opening hours, so whatever nobody thought of is refused.\"><text x=\"180\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">denylist</text><rect x=\"20\" y=\"40\" width=\"320\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"180\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">every possible input</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">allowlist</text><rect x=\"380\" y=\"40\" width=\"320\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"540\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">every possible input</text><rect x=\"40\" y=\"80\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the values somebody listed</text><text x=\"180\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">accepted: everything else,</text><text x=\"180\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the unforeseen included</text><rect x=\"460\" y=\"90\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"112.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">what is described:</text><text x=\"540.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">four clinics, real dates,</text><text x=\"540.0\" y=\"137.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">opening hours</text><text x=\"540\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">refused: everything else</text></svg>", "caption": "A denylist has to know every bad value in advance. An allowlist only has to know the good ones, and there are far fewer."}
```

Vereda's booking form has four fields: the clinic, the date, the time and the patient's phone. A
denylist on all four, the one ana inherited, refuses `<`, `>`, `;` and `--`. Here is what it lets
through, every item of which is a real problem and none of which contains a forbidden character:

| field | accepted by the denylist | why it is wrong |
|---|---|---|
| clinic | `Moema`, `paulista` | the clinics are written in lower case, and there is no clinic on Paulista |
| date | `2026-11-31` | November has 30 days |
| time | `23:00` | the clinics close at eight in the evening |
| phone | `1198765`, or no phone at all | a phone in São Paulo has 10 or 11 digits, and the reminder needs one |

None of those is an attack. They are what people type, and what other programs send, on an
ordinary Tuesday. **A field that accepts them stores data the rest of the system cannot use**: a
reminder sent to seven digits, a booking for a day that does not exist, an agenda screen that
crashes on a clinic it has no colour for. Some of the flaws later in this course start exactly
there, with code downstream that assumed the value had been checked.

### The list is about the wrong thing

A denylist also answers a question nobody should be asking at the input. `<` is dangerous inside
HTML and harmless in a phone number field that is never shown as HTML; `--` matters in SQL and not
in a date. **Whether a character is dangerous depends on where the value goes next**, and the
input does not know that. Lesson 4 handles the output side, where the context is known, and
lesson 5 the database side. At the input, the useful question is a different one: is this a
valid clinic, a real date, an opening hour, a phone number?

### When a denylist is still right

A short denylist has a place **on top of** a check that already describes what is good. A password
field accepts almost anything by design, so the useful check there is a list of passwords known to
have leaked, which lesson 11 builds. That is a denylist doing the one job a denylist can do:
refusing specific known values inside a space that is otherwise open. As the only check on a field
with a shape, it is the wrong tool.
