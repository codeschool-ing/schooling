---
title: The NIST CSF, and the gap it shows
version: 1
---

The NIST Cybersecurity Framework 2.0, published in February 2024, sorts security into **six
functions**, each split into categories and those into outcomes, 22 categories and 106 outcomes in
all. `security-fundamentals` lesson 15 walks through them. The owners asked for one page, and the
six functions fit on one page, which is why their accountant suggested it.

An outcome has an id: **PR.AA-03** is the third outcome in Protect's category for identity
management, authentication and access control, and it reads "users, services, and hardware are
authenticated". That id is what `mapping.csv` holds.

### The controls, by function

```
(.venv) ana@vm:~/tm/portal-model$ python3 crosswalk.py csf
Govern         0
Identify       0
Protect        6
  PR.AA-03  C1  C7
  PR.AA-05  C4  C5  C11
  PR.DS-02  C3  C8
  PR.IR-01  C2
  PR.IR-04  C9  C10
  PR.PS-05  C6 (not bought)
Detect         0
Respond        0
Recover        0
```

**Every one of the eleven controls is in Protect.** Not most of them: all. And inside Protect, the
one category nothing reaches is PR.AT, awareness and training, empty for the same reason 6.3 was in
Annex A.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l13-csf-functions\" aria-label=\"The six functions of NIST CSF 2.0 and their 22 categories, with the categories Vereda’s controls reach. Govern: 0 of 6. Identify: 0 of 3. Protect: 4 of 5. Detect: 0 of 2. Respond: 0 of 4. Recover: 0 of 2.\"><rect x=\"30.0\" y=\"20.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">GV</text><text x=\"80.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Govern</text><rect x=\"50.0\" y=\"75.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"50.0\" y=\"97.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"50.0\" y=\"119.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"50.0\" y=\"141.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"50.0\" y=\"163.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"50.0\" y=\"185.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"80.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">0 of 6</text><rect x=\"142.0\" y=\"20.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"192.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ID</text><text x=\"192.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Identify</text><rect x=\"162.0\" y=\"75.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"162.0\" y=\"97.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"162.0\" y=\"119.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"192.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">0 of 3</text><rect x=\"254.0\" y=\"20.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"304.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">PR</text><text x=\"304.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Protect</text><rect x=\"274.0\" y=\"75.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"274.0\" y=\"97.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"274.0\" y=\"119.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"274.0\" y=\"141.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"274.0\" y=\"163.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"304.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">4 of 5</text><rect x=\"366.0\" y=\"20.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"416.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">DE</text><text x=\"416.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Detect</text><rect x=\"386.0\" y=\"75.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"386.0\" y=\"97.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"416.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">0 of 2</text><rect x=\"478.0\" y=\"20.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"528.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">RS</text><text x=\"528.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Respond</text><rect x=\"498.0\" y=\"75.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"498.0\" y=\"97.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"498.0\" y=\"119.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"498.0\" y=\"141.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"528.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">0 of 4</text><rect x=\"590.0\" y=\"20.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">RC</text><text x=\"640.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Recover</text><rect x=\"610.0\" y=\"75.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"610.0\" y=\"97.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">0 of 2</text></svg>", "caption": "Every category the controls reach is in Protect. A threat model asks what could go wrong in a design, and its answers are mostly ways to stop it; noticing and recovering are questions it rarely asks."}
```

### Why a threat model leans this way

This is the most useful thing the mapping has shown so far, and it is a property of the method
rather than of Vereda. A threat model is built at design time, from a drawing, and asks **what could
go wrong** in it. The natural answer to "this could go wrong" is "then stop it", and every answer of
that shape is a Protect outcome.

The other three functions answer questions the model never asked:

| function | the question | what it would be for T03 |
|---|---|---|
| **Detect** | how would we know it happened? | an alert when a staff account signs in from outside the clinics, or opens many more records than its usual day |
| **Respond** | what do we do in the first hour? | who can end a staff account's sessions, and who tells daniel |
| **Recover** | how do we get back? | restoring a clinical note an intruder changed, and telling the patients the LGPD says must be told |

None of these is in the plan, and some of them would have been cheap. For T03, a staff sign-in
alert is a few lines in the console's log configuration. It does not lower the chance of the attack,
which is why the cost ranking of lesson 11 could not see it: **a detection control lowers the cost of
the attack by shortening it**, and the model estimated loss events without asking how long each one
would last before somebody noticed.

### The model's own work, in the CSF

Two functions look empty only because `mapping.csv` maps controls. The work of building the model is
itself a set of outcomes, and they are in Identify and Govern:

| outcome | what it says | where it is in this course |
|---|---|---|
| ID.RA-03 | internal and external threats are identified and recorded | `threats.csv`, lessons 3 to 7 |
| ID.RA-04 | potential impacts and likelihoods are identified and recorded | `risks.csv`, lesson 9 |
| ID.RA-05 | threats, vulnerabilities, likelihoods and impacts are used to understand inherent risk and inform prioritisation | `fair.py`, `prioritise.py`, lessons 10 and 11 |
| ID.RA-06 | risk responses are chosen, prioritised, planned, tracked and communicated | the plan in two phases, and `decisions/` |
| GV.RM-02 | risk appetite and risk tolerance statements are established, communicated and maintained | daniel's 10% at R$ 500,000, lesson 10 |

So the one page for the owners has two kinds of line. Protect, Identify and Govern have real
answers, with ids behind them. **Detect, Respond and Recover say "not yet"**, and say it in a shape
the owners can read: a target profile with those three filled in is the next thing worth arguing
about.
