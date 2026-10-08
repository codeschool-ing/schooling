---
title: What the tool finds
version: 1
---

pytm reads the model from lesson 2 and applies its own library of threats to it: about a hundred
rules, each a condition over the facts the model declares, most of them drawn from MITRE's CAPEC
catalogue of attack patterns. It is fair to ask why the team spent an afternoon on fourteen threats
when a program can produce a list in a second. This section runs the program and answers that.

### Run it

`findings.py` reads the JSON that `model.py --json` writes. With one argument it counts the
findings per element; with an element's name it lists that element's findings, optionally only
the first few:

```schooling-example
{"language": "python", "file": "findings.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Summarise what pytm found: where the findings landed, or the list for one element.\"\"\"\nimport collections\nimport json\nimport sys\n\nfindings = json.load(open(sys.argv[1]))[\"findings\"]\n", "note": "The JSON pytm writes has a `findings` list: one entry per rule that fired, naming the element it fired on."}, {"code": "if len(sys.argv) == 2:\n    print(f\"{len(findings)} findings on {len({f['target'] for f in findings})} elements\")\n    for target, n in collections.Counter(f[\"target\"] for f in findings).most_common():\n        print(f\"  {n:3}  {target}\")", "note": "With only the file, count the findings per element, most first."}, {"code": "else:\n    mine = [f for f in findings if f[\"target\"] == sys.argv[2]]\n    show = int(sys.argv[3]) if len(sys.argv) > 3 else len(mine)\n    for f in mine[:show]:\n        print(f\"  {f['threat_id']:6} {f['severity']:9} {f['description']}\")\n    if show < len(mine):\n        print(f\"  ... and {len(mine) - show} more\")", "note": "With an element's name, list its findings: the rule's id, the severity pytm assigns, and its description. A third argument shows only the first few."}]}
```

```
(.venv) ana@vm:~/tm/portal-model$ python3 model.py --json model.json
(.venv) ana@vm:~/tm/portal-model$ python3 findings.py model.json
196 findings on 17 elements
   47  Portal
   47  Staff console
   34  Reminder worker
    5  Sign in and book
    5  Pages and booking status
    5  Upload exam PDF
    5  Store exam PDF
    5  Read and write bookings
    5  Charge for a session
    5  Payment webhook
    5  Manage the agenda
    5  Read and write records
    5  Open exam PDF
    5  Read tomorrow's bookings
    5  Send reminder
    4  Records database
    4  Exam files
```

**196 findings.** The three processes carry 128 of them, every flow carries exactly five, and the
four external entities carry none.

```
(.venv) ana@vm:~/tm/portal-model$ python3 findings.py model.json 'Staff console' 12
  INP03  High      Server Side Include (SSI) Injection
  CR01   High      Session Sidejacking
  INP05  Very High Command Line Execution through SQL Injection
  AA01   Medium    Authentication Abuse/ByPass
  DS01   Medium    Excavation
  DE02   Medium    Double Encoding
  AC01   Medium    Privilege Abuse
  DO01   Medium    Flooding
  HA01   Very High Path Traversal
  DO02   Medium    Excessive Allocation
  INP08  High      Format String Injection
  INP09  High      LDAP Injection
  ... and 35 more
```

The portal and the staff console get the same 47, because the model describes them the same way:
two servers in the cloud, keeping sessions, answering HTTPS. The tool cannot tell that one serves
patients and the other reads every patient's record, because nothing in the model says so. Further
down the console's list:

```
(.venv) ana@vm:~/tm/portal-model$ python3 findings.py model.json 'Staff console' | grep -i php
  INP16  High      PHP Remote File Inclusion
```

There is no PHP anywhere at Vereda. The rule fires because nothing in the model says otherwise.

```
(.venv) ana@vm:~/tm/portal-model$ python3 findings.py model.json 'Payment webhook'
  DE01   Medium    Interception
  AC05   Medium    Content Spoofing
  DE03   Medium    Sniffing Attacks
  CR06   High      Communication Channel Manipulation
  CR08   Medium    Client-Server Protocol Manipulation
```

Of the five on the webhook, **Content Spoofing** comes closest to T01. It fires because of the facts
the model declares about the flow: nothing says it is encrypted, and nothing says the portal
authenticates its source. That is a rule matching on missing attributes rather than somebody
noticing that a stranger can mark a booking paid, and it would fire the same way on a flow where
the consequence was trivial.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l03-tool-and-hand\" aria-label=\"Where the findings land, by kind of element. pytm’s 196 findings: 128 on the three processes, 60 on the twelve flows, 8 on the two data stores and none on the external entities. The 14 threats written by hand: 2 on processes, 10 on flows, 1 on a data store and 1 on an external entity.\"><text x=\"190.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pytm: 196 findings</text><text x=\"140.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">processes</text><rect x=\"150.0\" y=\"48.0\" width=\"200.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"150.0\" y=\"48.0\" width=\"130.6\" height=\"28.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"286.6\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">128  (65%)</text><text x=\"140.0\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">data flows</text><rect x=\"150.0\" y=\"96.0\" width=\"200.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"150.0\" y=\"96.0\" width=\"61.2\" height=\"28.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"217.2\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">60  (31%)</text><text x=\"140.0\" y=\"158.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">data stores</text><rect x=\"150.0\" y=\"144.0\" width=\"200.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"150.0\" y=\"144.0\" width=\"8.2\" height=\"28.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"164.2\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">8  (4%)</text><text x=\"140.0\" y=\"206.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">external entities</text><rect x=\"150.0\" y=\"192.0\" width=\"200.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"156.0\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">0  (0%)</text><text x=\"550.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">by hand: 14 threats</text><text x=\"500.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">processes</text><rect x=\"510.0\" y=\"48.0\" width=\"200.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"510.0\" y=\"48.0\" width=\"28.6\" height=\"28.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"544.6\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">2  (14%)</text><text x=\"500.0\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">data flows</text><rect x=\"510.0\" y=\"96.0\" width=\"200.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"510.0\" y=\"96.0\" width=\"142.9\" height=\"28.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"658.9\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">10  (71%)</text><text x=\"500.0\" y=\"158.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">data stores</text><rect x=\"510.0\" y=\"144.0\" width=\"200.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"510.0\" y=\"144.0\" width=\"14.3\" height=\"28.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"530.3\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">1  (7%)</text><text x=\"500.0\" y=\"206.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">external entities</text><rect x=\"510.0\" y=\"192.0\" width=\"200.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"510.0\" y=\"192.0\" width=\"14.3\" height=\"28.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"530.3\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">1  (7%)</text></svg>", "caption": "Both lists are about the same drawing. The tool counts what each element could suffer; the people counted where trust changes."}
```

### What the tool cannot see

Three of the fourteen hand-written threats depend on facts the model does not hold, and no rule
can find them:

- **T12, the console on the internet.** The model puts the console in Vereda's cloud, as
  designed. The tool believes the drawing.
- **T13, the worker as the database owner.** pytm has no attribute for which database account a
  process uses.
- **T08, the SMS that reveals treatment.** That is about what the text of a message says to
  somebody holding the phone, which is outside anything a rule over elements can reach.

### What it is good for

A list like this is a **reminder of mechanisms**, read by somebody who knows the system. Path
traversal on the console is worth one question: does the console ever build a file path from
what a user typed? If the answer is no, the finding is closed in a sentence. If nobody knows,
it has done its job. Used that way, an hour with the 196 adds two or three questions to the
afternoon's list.

Used the other way, as the threat model itself, it buries T01 at position 2 of 5 on one flow
among 196, ranked medium, next to PHP on a system with no PHP. **A threat model is the fourteen
sentences, with a decision coming for each. The tool's list is input to it.**
