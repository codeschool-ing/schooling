---
title: Preparing, without pretending
version: 1
---

Two weeks before an audit, auditors send a **request list**: the documents and records they want to
see, often called a PBC list, for *prepared by client*. The insurer's arrived on 2 October with eight
items. ana put it in the repository beside the model, with a third column naming the file that
answers each request:

```
(.venv) ana@vm:~/tm/portal-model$ cat pbc.csv
id,request,evidence
P01,The current threat model of the patient portal,model.py
P02,The risk assessment with owners and estimates,risks.csv
P03,The risk treatment plan,controls.csv
P04,Approval of residual risks by their owners,decisions/RA-001-crafted-pdf.md
P05,Last review of each accepted risk,decisions/RA-002-cancellation-record.md
P06,Proof that staff sign-in requires a second factor,evidence/C1-second-factor-test.txt
P07,Controls mapped to ISO 27001,mapping.csv
P08,Security awareness training records,
```

### Checking the list before the auditor does

`pbc.py` reads that file and asks git about each piece of evidence:

```schooling-example
{"language": "python", "file": "pbc.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Check the auditor's request list: does each request name evidence, and is it in the repository?\"\"\"\nimport csv\nimport subprocess\n\n"}, {"code": "def last_change(path):\n    \"\"\"The date and author of the last commit that touched path, or None if git has never seen it.\"\"\"\n    out = subprocess.run([\"git\", \"log\", \"-1\", \"--format=%ad %an\", \"--date=short\", \"--\", path],\n                         capture_output=True, text=True, check=True).stdout.strip()\n    return out or None\n\n", "note": "Ask git for the last commit that touched the file. A file git has never seen gives an empty answer, which becomes None: the evidence is not in the repository, whatever is on somebody's disk."}, {"code": "for row in csv.DictReader(open(\"pbc.csv\")):\n    if not row[\"evidence\"]:\n        status = \"NOTHING NAMED\"\n    else:\n        seen = last_change(row[\"evidence\"])\n        status = f\"ok, {seen}\" if seen else \"MISSING\"\n    print(f\"{row['id']}  {status:19}  {row['request']}\")", "note": "Three outcomes per request: nothing named, named and missing, or present with the date and author of its last change."}]}
```

```
(.venv) ana@vm:~/tm/portal-model$ python3 pbc.py
P01  ok, 2026-09-10 ana   The current threat model of the patient portal
P02  ok, 2026-09-22 ana   The risk assessment with owners and estimates
P03  ok, 2026-09-29 ana   The risk treatment plan
P04  ok, 2026-10-01 ana   Approval of residual risks by their owners
P05  ok, 2026-10-01 ana   Last review of each accepted risk
P06  MISSING              Proof that staff sign-in requires a second factor
P07  ok, 2026-10-05 ana   Controls mapped to ISO 27001
P08  NOTHING NAMED        Security awareness training records
```

Two problems the program can see. **P06 names a file that does not exist**: C1 is planned for phase
1 and has no test result yet. **P08 names nothing**, because Vereda has no training, which lesson 13
found through the mapping.

### And the problems it cannot see

A program checks that evidence exists. Only a person checks that it **answers the request**. Read
P02 and P05 against their files:

- **P02 asks for owners.** `risks.csv` has estimates and no owner column. The owners are in
  `decisions/`, for the three risks that have a decision, and nowhere for the other six.
- **P05 asks for the last review of each accepted risk.** The file named is RA-002, whose review was
  due on 2 October and has not happened. The evidence exists, and what it proves is the gap.

This is a **readiness review**: the audit done in advance, by the side being audited. It is worth
more than the audit itself, because everything it finds can still be fixed, or at least explained
honestly before somebody else finds it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l14-preparation\" aria-label=\"Vereda’s preparation for the audit on a timeline. 2 October: the request list arrives. 6 October: pbc.py checks it and finds one item missing and one with nothing named. October: gaps are fixed or explained, and the answers rehearsed in a mock walkthrough. 9 to 11 November: fieldwork. 30 November: the report.\"><path d=\"M50.0 120.0 L680.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"60.3\" cy=\"120.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M60.3 114.0 L60.3 48.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"60.3\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">request list</text><text x=\"60.3\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 Oct</text><circle cx=\"101.6\" cy=\"120.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M101.6 114.0 L101.6 78.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"101.6\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pbc.py: 2 gaps</text><text x=\"101.6\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6 Oct</text><circle cx=\"452.8\" cy=\"120.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M452.8 114.0 L452.8 78.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"452.8\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">fieldwork</text><text x=\"452.8\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9–11 Nov</text><circle cx=\"669.7\" cy=\"120.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M669.7 114.0 L669.7 48.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"669.7\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">report</text><text x=\"669.7\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30 Nov</text><rect x=\"112.0\" y=\"160.0\" width=\"330.5\" height=\"22.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"277.2\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">fix or explain each gap; rehearse the walkthrough</text><text x=\"360.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">nothing is created to look older than it is</text></svg>", "caption": "Five weeks between the request and the fieldwork. Most of the value of an audit is spent in them, by the side being audited."}
```

### What preparing may and may not do

For each gap there are two honest moves. **Fix it**, if it can be fixed properly in five weeks:
review RA-002 with daniel and record the review; add an owner column to `risks.csv`. Or **explain
it**: P06 is answered with the plan, its phase and its date, and P08 with "none, and here is the
decision about it" once there is one.

There is one dishonest move, and it is tempting precisely because it is easy: **making evidence look
older than it is**. Writing a review of RA-002 dated 2 October, or committing a test result with a
date in September, turns a late review into a falsified record. The first is a minor finding; the
second ends the auditor's trust in every other item, and in a contract it may be fraud. Every fix
made in October is dated October, and says so.

The last step is a **walkthrough rehearsal**: ana explains the model to somebody who has not seen
it, in the order the auditor will ask, from the DFD to the decisions. Most audits go wrong in the
explanation rather than the evidence, when nobody in the room can say why a control exists. Here
the answer to "why?" is always a threat id, and that is what the rehearsal checks.
