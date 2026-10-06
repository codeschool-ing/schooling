---
title: When the three pull against each other
version: 1
---

It would be convenient if every control made all three properties stronger. **Many controls buy
one property with another**, and a beginner who does not see the trade ends up defending the
corner of the triangle they happen to be looking at.

```schooling-figure
{"svg": "<svg id=\"sf-tradeoffs\" viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three tensions between the properties. Encrypting the database protects confidentiality and puts availability at the mercy of one key. Keeping more copies protects availability and gives confidentiality more places to fail. Locking an account after three wrong passwords protects confidentiality and lets anybody who knows a username make that account unavailable.\"><text x=\"20\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">the control</text><text x=\"270\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">what it buys</text><text x=\"500\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">what it can cost</text><rect x=\"20\" y=\"34\" width=\"220\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">encrypt the database</text><rect x=\"260\" y=\"34\" width=\"210\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">protects confidentiality</text><rect x=\"490\" y=\"34\" width=\"210\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">lose the key, lose the data</text><path d=\"M240 56 L260 56\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M470 56 L490 56\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><rect x=\"20\" y=\"104\" width=\"220\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"126.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">keep five copies</text><rect x=\"260\" y=\"104\" width=\"210\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"126.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">protects availability</text><rect x=\"490\" y=\"104\" width=\"210\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"126.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">five places to leak from</text><path d=\"M240 126 L260 126\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M470 126 L490 126\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><rect x=\"20\" y=\"174\" width=\"220\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">lock after 3 wrong passwords</text><rect x=\"260\" y=\"174\" width=\"210\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">protects confidentiality</text><rect x=\"490\" y=\"174\" width=\"210\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">anyone can lock you out</text><path d=\"M240 196 L260 196\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M470 196 L490 196\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path></svg>", "caption": "A control that protects one property can cost another. The design question is which cost is acceptable."}
```

Three cases that come up again and again:

**Encryption and availability.** Encrypting the order database means a stolen disk is useless to
the thief, which protects confidentiality. It also means the shop needs the key every time it
reads its own data. Lose the key, or let ransomware encrypt the one copy of it, and the shop has
locked itself out as thoroughly as any attacker could. Encryption is still the right call; it
just moves the problem to **keeping the key available**, which is a problem somebody has to own.

**Copies and confidentiality.** Availability likes copies: a backup, a replica, a spare laptop
with the files. Every copy is also one more place the data can leak from. The backup drive in a
desk drawer has the same customer list as the database, and usually far less protection around
it. Lesson 12 deals with backups that are both restorable and protected.

**Lockouts and availability.** Locking an account after three wrong passwords protects
confidentiality against somebody guessing. It also gives anybody who knows a username a way to
lock its owner out, on purpose and repeatedly. That is why many systems slow down repeated
failures instead of locking outright, and why lesson 9 prefers a second factor to a stricter
lockout.

### Which property matters most depends on the information

There is no fixed ranking. The triad becomes useful when you rank the three **for one particular
piece of information**, because that ranking tells you which trade to accept:

| information at the shop | first concern | why |
|---|---|---|
| the customer list | confidentiality | a leak harms the customers and breaks the law (lesson 17) |
| the price list | integrity | it is public anyway; a wrong price costs money on every sale |
| the shop's front page | availability | it is public by design; when it is down, nothing sells |
| the payroll file | confidentiality, then integrity | a leak embarrasses; a changed salary is fraud |

Notice the price list. Its confidentiality is worth almost nothing, since every visitor sees the
prices, so spending money to hide it would be waste. Its integrity is worth a great deal. **The
same file can be public and critical at once**, and the triad is what lets you say that precisely
instead of calling it "sensitive" and treating it like everything else.

This ranking is the first step of every risk assessment in lessons 2 and 3. Information is
classified by what its loss would cost in each property, and the controls follow from the
classification rather than from habit.
