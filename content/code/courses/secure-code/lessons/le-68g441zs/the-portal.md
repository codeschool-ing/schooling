---
title: The portal, and how every lesson works
version: 1
---

Advice about secure code with no code in it slides off. So every lesson of this course works on
pieces of one system. **Vereda Fisioterapia** is a small chain of four physiotherapy clinics in São
Paulo, invented for this catalogue. Its **patient portal** lets about nine thousand patients book
and cancel sessions, pay for them, and upload the PDFs of exams their doctor asked for. A separate
**staff console** lets receptionists manage the agenda and physiotherapists write clinical notes.

The portal was written mostly by **ana**, Vereda's one full-time developer. She is careful and
busy, which is the normal condition of a developer, and the portal has the flaws a careful, busy
person writes. Every lesson takes one of them, in a small Flask application of its own that holds
just enough of the portal to show it: the cancel button here, the search in lesson 5, the exam
upload in lesson 14.

The data is invented too. Patients have first names only (`lucia`, `rafael`, `marta`), addresses
end in `.example`, and every date is in November 2026. Health data is the most sensitive category
of personal data in Brazil's data protection law, the LGPD, and the portal holds plenty of it. That
is why its flaws matter, and why nothing real is ever used to show them.

### How every lesson works

Each lesson follows the same loop, and you will do it yourself at the end of this one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l01-method\" aria-label=\"The loop every lesson of this course follows, drawn as four steps in a circle. One: write the test that states the requirement. Two: run it and watch it fail, which proves the flaw is there. Three: fix the code. Four: run it and watch it pass, then commit both. The test stays in the folder, so the flaw cannot come back unnoticed.\"><defs><marker id=\"l01-method-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"260\" y=\"20\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"38.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">write the test that</text><text x=\"360.0\" y=\"51.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">states the requirement</text><rect x=\"500\" y=\"110\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"128.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">watch it fail:</text><text x=\"595.0\" y=\"141.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the flaw is real</text><rect x=\"260\" y=\"200\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fix the code</text><rect x=\"30\" y=\"110\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"128.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">watch it pass,</text><text x=\"125.0\" y=\"141.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">commit both</text><path d=\"M460 45 L595 45 L595 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-method-ah-paper-dim)\"></path><path d=\"M595 160 L595 225 L460 225\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-method-ah-paper-dim)\"></path><path d=\"M260 225 L125 225 L125 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-method-ah-paper-dim)\"></path><path d=\"M125 110 L125 45 L260 45\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01-method-ah-paper-dim)\"></path><text x=\"360\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the test stays, so the flaw cannot come back unnoticed</text></svg>", "caption": "Four steps, in every lesson. A fix with no failing test before it is a fix nobody can show worked."}
```

1. **A test states what the code must do**, including what it must refuse. A requirement nobody
   wrote down becomes a test function with a name that reads as a sentence.
2. **You run it against the flawed code and watch it fail.** The failure is the evidence. A request
   whose answer shows the defect, in your own application, is worth more than any description of
   the flaw.
3. **You change the code**, using the safe call the lesson explains.
4. **You run the tests again and watch them pass**, then commit the code and the test together.
   The test stays, so if the unsafe line ever comes back, somebody finds out on the same day.

Test-driven development calls the first two steps *red* and *green*, and this course borrows the
order on purpose: a fix with no failing test before it is a fix nobody can show worked. Lesson 19 turns the tests of the whole course into a
suite that runs on every change.

### The rules of the lab

This is a course about defending code, and it holds itself to three rules.

- **The flaws live only in your own application, on your own computer.** Every program here
  listens on `127.0.0.1`, which only your own machine can reach. Never start one of them on
  `0.0.0.0`, and never deploy one: a deliberately flawed program on a network is a target.
- **A flaw is shown by a test or by one request, and then fixed at once.** The course never
  collects tricks for getting past a defence, because a defender does not need them. What a
  defender needs is to recognise the flaw in code, a log or a configuration, fix it, and prove the
  fix.
- **Nothing here is ever pointed at a system you do not own.** Getting into somebody else's system
  without permission is a crime in Brazil (Law 12.737 of 2012) and in most other countries, whatever
  the intention.
