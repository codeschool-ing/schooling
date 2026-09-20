---
title: What a password is actually for
version: 1
---

A password protects against two completely different attacks, and almost all the advice people
remember is aimed at the one that matters least.

## Guessing, and why length is the answer

Somebody trying passwords against your account, one after another, is stopped by there being too
many to try. What decides how many there are is **length**, overwhelmingly, and the alphabet you
drew from, weakly.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 304\" role=\"img\" aria-label=\"A table of four passwords with two estimates each. An eight-character mangled word: minutes if random, instantly in practice. A capitalised word with a symbol and a year: months if random, minutes in practice. Four unrelated words: centuries in both columns. A sixteen-character random string from a manager: centuries in both columns.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Four passwords, and the two numbers that differ</text><text x=\"44\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the password</text><text x=\"360\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">if nobody guessed the shape</text><text x=\"552\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what actually happens</text><rect x=\"24\" y=\"64\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">p4ssw0rd</text><rect x=\"344\" y=\"64\" width=\"176\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minutes</text><rect x=\"536\" y=\"64\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"552\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">instantly</text><rect x=\"24\" y=\"116\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"138\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Password@2024</text><rect x=\"344\" y=\"116\" width=\"176\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"138\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">months</text><rect x=\"536\" y=\"116\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"552\" y=\"138\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">minutes</text><rect x=\"24\" y=\"168\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">horse staple battery saddle</text><rect x=\"344\" y=\"168\" width=\"176\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">centuries</text><rect x=\"536\" y=\"168\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"552\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">centuries</text><rect x=\"24\" y=\"220\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"242\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">k7Qv2mXz9RtL4pWd</text><rect x=\"344\" y=\"220\" width=\"176\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"242\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">centuries</text><rect x=\"536\" y=\"220\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"552\" y=\"242\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">centuries</text><text x=\"24\" y=\"286\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">The middle column is arithmetic. The right-hand one is what a guessing tool does, which is to try the shapes people were taught to make first.</text></svg>", "caption": "The second row is the advice everybody learned, and the gap between its two columns is the whole reason the advice changed."}
```

That is the whole of the arithmetic, and it is why the advice everybody learned — a capital, a
number, a symbol — produces `Password@2024`, which is short, and which every guessing tool tries
early precisely because it is the shape people were taught to make.

**Four unrelated words beat a mangled one.** `horse staple battery saddle` is longer, easier to
remember and enormously harder to guess than `P@ssw0rd!23`. The only rule about the words is that
they must not be a phrase anybody has written down — a line from a song is not four random words,
it is one thing.

## And the attack that actually happens

**Reuse.** A site you signed up to in 2015 is breached, and its list of addresses and passwords is
published. Nobody is guessing anything: they take your address and your password and they try
them on the bank, the e-mail and the marketplace, automatically, within hours.

This is how ordinary people lose accounts, and it is why the strongest password in the world is
worthless as soon as it is the password for two things.

So the rule that matters is not *make it complicated.* It is **never use it twice**, which is
impossible by memory and trivial with the next section.

## Password managers, honestly

A password manager generates a different long random password for every site, stores them
encrypted behind one password you do know, and fills them in for you.

The objection everybody raises is the real one: **it puts everything behind a single point of
failure.** That is true, and it is still the right trade, for two reasons. The alternative in
practice is not fifty memorised passwords — it is one password used fifty times, which is a
single point of failure with no encryption on it. And the manager's own protection can be made
very strong, because it is the only one you have to remember.

Three practical notes:

- **The master password is one you type**, so it wants to be long and memorable: the four-word
  rule, and nothing else you use anywhere.
- **Filling in is also a safety feature**, and this is the part nobody mentions: a manager fills
  in a password only on the address it was saved for. A convincing copy of your bank's page gets
  nothing, because the manager does not recognise it — and *the manager did not offer to fill it
  in* is the best warning you will ever get.
- **Write the master password down and put it somewhere physical.** Not on the desk. In the
  place where important papers are kept.

## And the one that is not a password

Three questions with answers that are public facts — your mother's surname, the city you were
born in, your first school — are not a second password. Where a site insists on them, **the
answer does not have to be true**, and the manager can store an invented one.
