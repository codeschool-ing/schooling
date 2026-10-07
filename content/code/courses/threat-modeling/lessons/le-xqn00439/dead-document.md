---
title: How a model dies
version: 1
---

A threat model is usually written once, carefully, at the start of a project, and then filed. A
year later it describes a system that no longer exists, and it is still the document somebody
sends an auditor. Nobody decided to let it die. It died one unrecorded change at a time.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l15-drift\" aria-label=\"The system and its model drifting apart. Along the top, what happens to the system: features ship, a vendor changes its API, a new integration is added, staff come and go. Along the bottom, changes to the model. A model updated only once, at the start, describes a system further from the real one with every event above it. A living model changes whenever one of those events changes what it draws.\"><text x=\"20.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">system</text><text x=\"20.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">dead model</text><text x=\"20.0\" y=\"200.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">living model</text><path d=\"M130.0 40.0 L700.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M130.0 130.0 L700.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M130.0 200.0 L700.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"170.0\" cy=\"40.0\" r=\"6\" fill=\"var(--paper)\"></circle><circle cx=\"260.0\" cy=\"40.0\" r=\"6\" fill=\"var(--paper)\"></circle><circle cx=\"330.0\" cy=\"40.0\" r=\"6\" fill=\"var(--paper)\"></circle><circle cx=\"430.0\" cy=\"40.0\" r=\"6\" fill=\"var(--paper)\"></circle><circle cx=\"520.0\" cy=\"40.0\" r=\"6\" fill=\"var(--paper)\"></circle><circle cx=\"610.0\" cy=\"40.0\" r=\"6\" fill=\"var(--paper)\"></circle><circle cx=\"680.0\" cy=\"40.0\" r=\"6\" fill=\"var(--paper)\"></circle><circle cx=\"170.0\" cy=\"130.0\" r=\"6\" fill=\"var(--amber)\"></circle><circle cx=\"170.0\" cy=\"200.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"260.0\" cy=\"200.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"430.0\" cy=\"200.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"520.0\" cy=\"200.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"680.0\" cy=\"200.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M170 112 L700 64\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"560.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">the gap grows with every change</text><text x=\"415.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">not every change moves the model: only those that change what it draws</text></svg>", "caption": "Nobody decides to let a model die. It dies one unrecorded change at a time."}
```

### The signs

A dead model is easy to recognise once you know where to look, and every sign is something a
program or a git log can show:

- **Its last change is older than the system's.** The portal shipped twice in September; if
  `threats.csv` had last changed in March, the model would be describing an older portal.
- **Its threats name things that are gone,** or the system has things its threats never name. A
  threat on an element nobody can find in the diagram, or a new integration with no threat at all.
- **Its review dates have passed with nobody noticing.** RA-002 was reviewed seven days late, on 9
  October, and only because lesson 12 happened to run `acceptances.py` on the 7th.
- **Its problems were found by somebody else.** In lesson 13 the gateway's SOC 2 report raised two
  questions Vereda's model had never asked. They are now threats T18 and T19:

```
(.venv) ana@vm:~/tm/portal-model$ tail -2 threats.csv
T18,Payment gateway,S,Anybody who obtains the gateway API key from the portal's configuration can create charges and refunds in Vereda's name.
T19,Payment gateway,E,A former employee who still has a login to the gateway's dashboard can see patients' payments and refund them.
```

Neither is exotic. Both were found from outside, by reading a supplier's report against a trust
boundary, which is a good thing to have done and a poor way to depend on finding things.

### Why it happens

Three reasons, and none of them is laziness.

**The model is separate from the work.** It lives in a document nobody opens while building, so a
change to the system never passes through it. Every lesson of this course kept the model in git
beside the code for this reason, and it is necessary rather than sufficient.

**Nobody owns the trigger.** Everybody agrees the model should be updated "when the design
changes". Nobody is the person who notices that a design changed, so nobody updates it.

**Updating it is expensive.** A model rebuilt from scratch every time is a two-day job. A team
facing that every sprint stops doing it, which is a reasonable decision on the wrong premise. **A
change to the system needs a change to the model of the same size**, and the rest of this lesson
is how to keep it that small.

### Re-reading the RA-002 renewal

The late review of RA-002 produced a new record rather than an edit, as lesson 12 asked:

```
(.venv) ana@vm:~/tm/portal-model$ head -9 decisions/RA-003-cancellation-record-renewed.md
---
id: RA-003
threat: T06
decision: accept
owner: daniel
decided: 2026-10-09
review by: 2026-12-15
supersedes: RA-002
---
```

And `acceptances.py`, written in lesson 12, still reports the old one:

```
(.venv) ana@vm:~/tm/portal-model$ python3 acceptances.py 2026-10-09
        threat decision  owner   review by   status
DR-001  T03    mitigate  daniel  2027-09-30  ok
RA-001  T14    accept    daniel  2027-04-01  ok
RA-002  T06    accept    daniel  2026-10-02  OVERDUE by 7 days
RA-003  T06    accept    daniel  2026-12-15  ok
```

The record says it supersedes RA-002, and the tool does not know the field. That is the small,
ordinary way models die: a convention is added and the program that reads the files is not told.
The check later in this lesson reads `supersedes`.
