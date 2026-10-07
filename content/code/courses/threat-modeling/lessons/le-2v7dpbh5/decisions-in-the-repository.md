---
title: Decisions in the repository
version: 1
---

Vereda's decision records live in a folder beside the model, one Markdown file each:

```
(.venv) ana@vm:~/tm/portal-model$ ls decisions
DR-001-second-factor.md
RA-001-crafted-pdf.md
RA-002-cancellation-record.md
```

The acceptance of T14, in full:

```
(.venv) ana@vm:~/tm/portal-model$ cat decisions/RA-001-crafted-pdf.md
---
id: RA-001
threat: T14
decision: accept
owner: daniel
decided: 2026-10-01
review by: 2027-04-01
---

# Accept T14, a crafted PDF attacking a clinic computer, until April 2027

## The risk

A patient uploads a PDF built to exploit the viewer a physiotherapist opens it in, and code runs on
a clinic computer. Expected loss R$ 9,000 a year; in a bad year, one in a hundred, about R$ 390,000.

## Why it is accepted

The only control proposed, an isolated viewer (C6), costs R$ 18,000 a year and removes about
R$ 7,200. Vereda will not buy it now.

## What is in place instead

- Staff open exams only in the console's viewer, never in a desktop program.
- The clinic computers are updated automatically every week.
- The backups of the clinic computers were restored in a test on 2026-09-12.
- An insurance quote covering losses above R$ 50,000 has been requested.

## When this is looked at again

By 2027-04-01, or before that if any of these happens: a viewer flaw is published that affects the
console's viewer; the insurance quote arrives; a clinic computer is infected by anything.
```

The other two records have the same shape. DR-001 is a decision to mitigate, and RA-002 is the
acceptance daniel signed in April:

```
(.venv) ana@vm:~/tm/portal-model$ cat decisions/DR-001-second-factor.md
---
id: DR-001
threat: T03
decision: mitigate
owner: daniel
decided: 2026-09-30
review by: 2027-09-30
---

# Require a second factor for every staff sign-in (C1)

## The decision

Staff sign in to the console with a password and a code from an authenticator app. Two hardware
keys per clinic are kept for staff without a suitable phone.

## Why

T03 is more than half of Vereda's expected loss. C1 removes about R$ 60,000 a year of it for
R$ 3,000 a year, and with C5, C8 and C4 it brings the yearly loss curve under the appetite daniel
set in lesson 10.

## Consequences

Every sign-in takes a few seconds longer. A lost phone means a call to bruno, who resets the factor
after checking who is calling. Staff accounts that cannot use a second factor cannot sign in.
(.venv) ana@vm:~/tm/portal-model$ cat decisions/RA-002-cancellation-record.md
---
id: RA-002
threat: T06
decision: accept
owner: daniel
decided: 2026-04-02
review by: 2026-10-02
---

# Accept T06, no record of who cancelled a session, for six months

## The risk

A patient denies cancelling a session and Vereda cannot show that the cancellation came from their
account. Disputes so far: two in a year, settled by refunding the session.

## Why it is accepted

Recording cancellations needs a change to the booking code that was already planned for the
second half of the year. Refunding a disputed session costs less than bringing it forward.

## What is in place instead

Reception notes the date and the patient's account in the support inbox when a dispute arrives.

## When this is looked at again

By 2026-10-02, when the booking change is due.
```

### Which decisions are due

A review date nobody checks is decoration. `acceptances.py` reads the front matter of every record
in `decisions/` and compares each review date with a day, today's by default:

```schooling-example
{"language": "python", "file": "acceptances.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"List the decisions in decisions/, and which ones are due or overdue for review.\n\n    python3 acceptances.py              against today's date\n    python3 acceptances.py 2026-10-07   against another date\n\"\"\"\nimport datetime\nimport pathlib\nimport sys\n\ntoday = datetime.date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else datetime.date.today()\n", "note": "The day to compare against: today's, or a date given on the command line, which is how a capture or a report stays repeatable."}, {"code": "\ndef front_matter(path):\n    lines = path.read_text().split(\"\\n\")\n    end = lines.index(\"---\", 1)\n    return dict(line.split(\": \", 1) for line in lines[1:end])\n\n", "note": "The front matter is the lines between the first --- and the next one, each a key, a colon and a space, and a value."}, {"code": "print(f\"{'':7} {'threat':6} {'decision':9} {'owner':7} {'review by':10}  status\")\nfor path in sorted(pathlib.Path(\"decisions\").glob(\"*.md\")):\n    d = front_matter(path)\n    days = (datetime.date.fromisoformat(d[\"review by\"]) - today).days\n    status = f\"OVERDUE by {-days} days\" if days < 0 else f\"due in {days} days\" if days <= 30 else \"ok\"\n    print(f\"{d['id']:7} {d['threat']:6} {d['decision']:9} {d['owner']:7} {d['review by']:10}  {status}\")", "note": "One line per record. Negative days are overdue; thirty days or fewer are due soon, so the review can be booked in time."}]}
```

Run on the day this lesson was recorded:

```
(.venv) ana@vm:~/tm/portal-model$ python3 acceptances.py 2026-10-07
        threat decision  owner   review by   status
DR-001  T03    mitigate  daniel  2027-09-30  ok
RA-001  T14    accept    daniel  2027-04-01  ok
RA-002  T06    accept    daniel  2026-10-02  OVERDUE by 5 days
```

**RA-002 is overdue.** daniel accepted T06, patients disputing cancellations, in April, for six
months, until a change to the booking code that was due in the second half of the year. The date
passed five days ago and nobody noticed, which is exactly how an acceptance becomes permanent
without anybody deciding it should be. Lesson 8's R09, recording who cancelled and when, is that
change. The overdue line is the prompt to check whether R09 has shipped: if it has, RA-002 is
closed by a new record that says T06 is now mitigated; if it has not, daniel renews the acceptance
with a new date, or brings R09 forward.

The program says *due in N days* for anything within a month, so that a review can be booked before
it is late rather than after.

### The history is part of the record

```
(.venv) ana@vm:~/tm/portal-model$ git log --format="%h %ad %s" --date=short -- decisions
7060908 2026-10-01 Record the first decisions
```

When the auditor of lesson 14 asks when T14 was accepted and by whom, the answer is the file and
this log: what was decided, by whom, on which day, and that nothing has been changed in it since.
