---
title: False positives, and why the check matters
version: 1
---

**A DLP rule that fires on things that are not personal data gets switched off.** Not by a policy:
by the people it keeps stopping, who learn to rename files, zip them or send them another way, and
by the administrator who stops reading its alerts. So the first number to know about any rule is
how often it is wrong.

Run the scanner without the arithmetic, keeping every match the patterns find:

```
ana@desk:~$ python3 scan.py --no-check docs
docs/clientes.csv: 20 CPF, 20 card, 0 rejected, e.g. 881******41
docs/pedidos.txt: 3 CPF, 0 card, 0 rejected, e.g. 123******01
```

The order file now reports three CPFs where there were one, and the example it shows is an order
number. On a real file server, full of invoices, protocols and phone extensions, the gap between
the two runs is the difference between a report somebody can act on and one nobody opens.

The check removes most false positives and never all of them, and the order `98765432100` is the
one that is left: a valid number that is not anybody's CPF in this file. Three things reduce what
is left, and every product offers some form of each:

- **Context.** A number next to the word *CPF*, or in a column headed `cpf`, is far more likely to
  be one than the same digits after *Pedido*. Rules that look at the words around a match cut false
  positives sharply, and miss the CPF somebody typed into a free-text note.
- **Thresholds.** One CPF in a document is often legitimate: a contract names one client. Fifty in a
  spreadsheet is a client list. Many rules fire only above a count, which is also why the scanner
  reports a count.
- **Exact data match**, from the last section: a number that is in the real client list is a
  client's; anything else is not.

## Monitor before you block

**Every DLP deployment starts by watching and not stopping.** For weeks the rules only log what they
would have blocked, and somebody reads the log: which rules fire, on whose files, for what work.
Only the rules whose hits were real are switched to blocking, and the others are tuned or dropped.
Turning blocking on from the first day stops the payroll the first time it runs, and the rule that
did it never comes back on.

When blocking is on, a good product also offers **justification**: the person sees why the file was
held and can send it anyway with a written reason, which is logged. That keeps a legitimate send to
an auditor possible at three in the afternoon, and turns the deliberate case into a person signing
their name to it.
