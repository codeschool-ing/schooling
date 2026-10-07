---
title: Writing a requirement somebody can check
version: 1
---

"The portal must be secure" is a sentence nobody can disagree with and nobody can test. It is also
the most common security requirement in the world. **A good security requirement is one a person
who was not in the room can verify**, and four properties make that possible.

| property | the question | fails like this |
|---|---|---|
| **specific** | does it say which part of the system and which behaviour? | "access must be controlled" |
| **testable** | can somebody write a test, or a review step, that passes or fails? | "passwords must be strong" |
| **one thing** | does it say a single thing, so that half of it cannot be done and the whole ticked? | "uploads must be validated and scanned and limited" |
| **behaviour, not hope** | does it say what the system does, not what nobody will do? | "attackers must not be able to read exams" |

The last one deserves a second look. "Attackers must not be able to read exams" sounds like a
requirement and is a hope: it describes something the system cannot control. The version that
works describes what the portal does: *it returns an exam only to the patient it belongs to.* A
test can ask for somebody else's exam and check the answer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l08-hope\" aria-label=\"Three requirements as first written and as rewritten. Attackers must not be able to read exams, a hope, becomes: the portal returns an exam only to its patient. Uploads must be limited in size, with no number, becomes: an upload over 20 MB or not a PDF is refused. Passwords must be strong, not testable, becomes: sign-up refuses passwords found in breach lists.\"><defs><marker id=\"l08-hope-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"300.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"170.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">“attackers must not be able to read exams”</text><text x=\"170.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">a hope</text><path d=\"M320.0 44.0 L370.0 44.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-hope-tm-ah-paper-dim)\"></path><rect x=\"370.0\" y=\"20.0\" width=\"330.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"535.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the portal returns an exam only to its patient</text><rect x=\"20.0\" y=\"85.0\" width=\"300.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"170.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">“uploads must be limited in size”</text><text x=\"170.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">no number</text><path d=\"M320.0 109.0 L370.0 109.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-hope-tm-ah-paper-dim)\"></path><rect x=\"370.0\" y=\"85.0\" width=\"330.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"535.0\" y=\"109.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">an upload over 20 MB or not a PDF is refused</text><rect x=\"20.0\" y=\"150.0\" width=\"300.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"170.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">“passwords must be strong”</text><text x=\"170.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">not testable</text><path d=\"M320.0 174.0 L370.0 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-hope-tm-ah-paper-dim)\"></path><rect x=\"370.0\" y=\"150.0\" width=\"330.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"535.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sign-up refuses passwords in breach lists</text></svg>", "caption": "The rewrite names a part, a behaviour and, where there is one, a number. A person who was not in the room can then check it."}
```

### Numbers are decisions, write them

"Uploads must be limited in size" is not testable until somebody writes the number. **20 MB** in
R13 was a decision: the largest exam a patient had uploaded in a year was under 9 MB, and 20 left
room. Writing it down turns an argument into a value that can be changed later with a reason.
The same goes for R03's ten failed attempts an hour, and R06's thirty days.

### Using a standard as a catalogue

Nobody has to invent security requirements from nothing. The **OWASP Application Security
Verification Standard (ASVS)** is a catalogue of hundreds of them, grouped by area
(authentication, session management, access control, validation, logging and more) and graded in
three levels of rigour. Version 5.0, published in 2025, is the current one.

The ASVS is the right place to look for **how** to state a requirement and for requirements the
team forgot. It is the wrong place to start: adopting a whole level of it gives a list nobody can
trace back to a threat, and the model loses the reason each requirement exists. Vereda's habit is
the other way round: write the requirement from the threat, then look up the ASVS area it belongs
to and borrow its wording if it is clearer. The `secure-code` course (lesson 20) uses the ASVS from
the developer's side, as a checklist during the build.

### Verified by what

Every requirement says how it will be checked, and there are three honest answers:

- **a test**, automated, run on every change: R01, R10, R13;
- **a review**, a person checking a configuration or a design: R07, R15, R16, which are about
  cloud permissions and networks that no unit test can see;
- **nothing yet**, which is allowed as long as it is written down. It is a known gap, and the
  traceability program finds every one of them.
