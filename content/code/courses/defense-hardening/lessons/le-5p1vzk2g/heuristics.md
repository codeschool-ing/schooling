---
title: Heuristics: judging what has not been seen
version: 1
---

**A heuristic flags a file for what it looks like or what it does, rather than for being a known
file.** Signatures answer "have we seen this?". Heuristics answer "does this look like the kind of thing
we would not want?", and so they can flag a file nobody has ever seen. The price is uncertainty: a
heuristic gives a likelihood, not an identity, and it is wrong more often than a signature.

Nothing in this section was run beyond the rules of the last one. Heuristic engines are the core of
commercial products and are not described by their vendors in enough detail to reproduce; what follows
is how they work in general, from the published documentation of ClamAV and the vendors' own
explanations.

## Three families

**Static heuristics** read the file without running it and score its properties: a document format
carrying a macro that runs when it is opened, an executable whose sections are compressed or
encrypted, an archive protected by a password so that nothing inside it can be read, a file whose
extension says one type and whose content says another. Each property alone is common in legitimate
files. A combination is suspicious. ClamAV exposes a few of these as options, among them
`--alert-macros` for documents with macros and `--alert-encrypted` for encrypted archives and
documents, which a mail gateway often switches on.

**Emulation** runs a small part of the program inside a simulated processor, long enough to see what
it does to itself: a program that unpacks a second program into memory is showing behaviour that a
static look could not. It is expensive, so scanners do it briefly and only for files that earned
suspicion.

**Machine-learning models**, trained on millions of known good and known bad files, score a new file
by its resemblance to each. They generalise well to variants and badly to anything genuinely new,
which is what they were trained on in the first place.

## Living with the false positives

The training note in the last section is what a heuristic produces every day, in larger numbers. The
answers are organisational more than technical:

- **an allow-list** of files the organisation has decided are good, by hash, for the in-house tools
  that a heuristic will always find odd;
- **quarantine rather than deletion**, so that a wrong verdict costs a delay, not a file;
- **a person who reviews** what was quarantined, and a way to ask for it back;
- **tuning by evidence**: a rule that fired on a hundred files and was right on none is turned down or
  removed, and that decision is recorded like any other exception from lesson 2.

A heuristic that is never wrong is set so cautiously that it catches nothing a signature would not. A
heuristic that floods people with alerts is soon ignored, and an ignored alert is worse than none,
because everybody believes something is watching.
