---
title: A standard you can check against
version: 1
---

Every lesson of this course ended with one refusal an application owes. A real project needs the
whole list, and nobody should have to invent it. **The OWASP Application Security Verification
Standard, ASVS, is that list**: a catalogue of security requirements for web applications and
services, each one written so that somebody can check whether an application meets it.

It is maintained by OWASP, the Open Worldwide Application Security Project, a non-profit
foundation whose material is free and openly licensed. Version 5.0.0 was released in May 2025,
replacing 4.0.3 from 2021, and it is the version this lesson uses.

### What a requirement looks like

Every requirement begins with **"Verify that"** and states something that is true or false of an
application. That shape is the point. *"The application is secure"* cannot be checked; *"verify
that client-side validation is not relied upon as a security control"* can be, by reading the code,
by a test, or by sending one request. Lesson 3 was that requirement.

### Three levels

Requirements are graded in three levels, and the levels are **cumulative**: meeting level 2 means
meeting every level 1 requirement as well.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l20-levels\" aria-label=\"The three levels of ASVS 5.0.0 as nested boxes, counted from the standard's own file. Level 1 holds 70 requirements, the minimum for any application. Level 2 adds 183, for 253 in all, the level most applications handling personal data should aim at. Level 3 adds 92, for all 345, for applications where a failure would be most severe. Each level includes everything in the levels inside it.\"><rect x=\"20\" y=\"14\" width=\"680\" height=\"222\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"40\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">level 3</text><text x=\"40\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">+92, all 345: where failure costs most</text><rect x=\"60\" y=\"70\" width=\"600\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">level 2</text><text x=\"80\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">+183, 253 in all: personal data, Vereda's portal</text><rect x=\"100\" y=\"126\" width=\"520\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">level 1</text><text x=\"120\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">70 requirements: the floor for any application</text></svg>", "caption": "Levels are cumulative. A portal holding health data aims at level 2 and meets level 1 first."}
```

| level | meant for | for Vereda |
|---|---|---|
| **1** | the minimum for any application | the floor, met first |
| **2** | applications that handle personal data or anything worth protecting | the target: the portal holds health data |
| **3** | applications that need the highest assurance, where a failure would be most severe | not the portal's target, though some of its requirements are worth taking |

Choosing a level is a decision with an owner, like the risk decisions lessons 17 and 18 asked to be
written down. It belongs to the people who answer for the application, it is recorded, and it says
which requirements the project has promised to meet.

### What ASVS is not

It is not a list of attacks, and it does not tell anybody how to break an application. It describes
what a **well-built** one does. It is also not a certificate: an application that meets level 2 has
met 253 written requirements, which is a great deal and still says nothing about a flaw no
requirement describes. Lesson 1's missing sentence about whose booking it was is in ASVS only as a
general requirement about authorisation; recognising it in a particular story is still a person's
job.
