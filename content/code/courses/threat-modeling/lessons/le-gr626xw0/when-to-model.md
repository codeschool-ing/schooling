---
title: When to do it, and how much
version: 1
---

The common mistake is treating threat modelling as a phase: done once, at the start, signed off,
filed. A system changes every week, and a model of last year's system describes a building that has
since grown two floors. **The answer to "when" is: whenever the design changes in a way that
matters for security, and as early in that change as the change can be drawn.**

### The moments that call for one

| moment | what to model |
|---|---|
| a new system is being designed | the whole thing, at the level of its main parts |
| a feature adds a new kind of data | where the data enters, where it is kept, who can read it |
| a feature adds a new way in | a new endpoint, a new upload, a new integration with somebody else's system |
| trust changes | a new role, a new partner with access, a service moved to another network or another company |
| a dependency changes | a new library that parses untrusted input, a new vendor that receives personal data |
| after an incident | the part of the design that let it happen, and its neighbours |

Most changes trigger none of these. A new colour on the booking page does not. A field on the
booking form that asks for the patient's health insurance number does, because it brings a new
piece of personal data into the system and the design has to say where it goes.

### How much is enough

**Proportional to what is at stake and to what changed.** A new system that will hold clinical
records deserves an afternoon with the people who will build it. A new field deserves ten minutes
at the next refinement meeting: draw the flow it rides on, ask what can go wrong, write down the
answer. Lesson 15 turns that second shape into a routine.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l01-proportional\" aria-label=\"How much modelling a change deserves, by what is at stake and how much changed. A small change with little at stake, such as a new field on a form: ten minutes at the next refinement. A large change with a lot at stake, such as a new system holding clinical records: an afternoon with the people who will build it. Between them, a short design review.\"><defs><marker id=\"l01-proportional-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M90.0 220.0 L690.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-proportional-tm-ah-paper-dim)\"></path><path d=\"M90.0 220.0 L90.0 20.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-proportional-tm-ah-paper-dim)\"></path><text x=\"390.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">how much changed</text><text x=\"30.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">at stake</text><rect x=\"110.0\" y=\"150.0\" width=\"190.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"205.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">ten minutes in refinement</text><text x=\"205.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a new field on a form</text><rect x=\"300.0\" y=\"95.0\" width=\"190.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"395.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a short design review</text><text x=\"395.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a new upload or integration</text><rect x=\"490.0\" y=\"35.0\" width=\"190.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">an afternoon with the builders</text><text x=\"585.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a new system with clinical data</text></svg>", "caption": "The effort follows the change, not the calendar. Most changes deserve ten minutes, and that is still a threat model."}
```

Two signs that a model has gone past useful:

- **It lists threats nobody will act on.** A threat with no decision attached is noise, and a list
  of two hundred of them hides the five that matter. Lesson 3 meets a tool that produces exactly
  that list.
- **It is more detailed than the design.** A model is a drawing of a design. If the design says
  "the portal calls the payment gateway", modelling each HTTP header of that call is guessing at
  an implementation that does not exist yet.

### Before the code, and also after

Modelling before the code exists is cheapest, for the reason the previous section drew. It is not
the only time it pays. A system that was never modelled can be modelled now: draw it as it is, ask
the same questions, and the flaws you find are flaws that are live today. Vereda's portal is in
that position. It exists, it has patients, and nobody has drawn it with security in mind. That is
the most common starting point there is, and it is where this course starts.
