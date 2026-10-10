---
title: Action items, and why they do not get done
version: 1
---

A postmortem's value is in what changes afterwards, and what changes is decided by its action items. The commonest failure of postmortems is not a bad analysis; it is good action items that are never done.

## What a good action item looks like

- **Specific.** "Add an idempotency key to every card retry", not "improve payment reliability".
- **Owned by one person.** Not "the team"; a name, who may delegate the work and still answers for it.
- **Dated.** A due date, short enough that the people who were in the incident still care.
- **Few.** Three to five per postmortem. Twelve action items is a list nobody finishes, and it hides the two that matter.
- **Of the right kind.** A mix of the four: **prevent** the cause, **detect** it sooner, **mitigate** it faster, **improve the process** that let it through.

## Measuring whether they get done

The Billing team has held four postmortems since June, one for each failed deployment. **Save the program below as `actions.py`.** It reads the team's action items, as of the day of the latest postmortem, and reports what happened to them.

```schooling-example
{
  "language": "python",
  "file": "actions.py",
  "parts": [
    {
      "code": "\"\"\"actions.py: which postmortem action items got done, and which are still waiting.\"\"\"\nfrom datetime import date\n\nTODAY = date(2026, 10, 2)\n\n# One row per action item: the incident it came from, what it is, when it was due,\n# and when it was done (None if it is still open).\nACTIONS = [\n    (\"D004\", \"alert on the card payment error rate\", \"2026-07-10\", \"2026-07-22\"),\n    (\"D004\", \"write a runbook for rolling back a release\", \"2026-07-03\", None),\n    (\"D004\", \"deploy smaller releases\", \"2026-07-15\", \"2026-08-03\"),\n    (\"D008\", \"integration test for the statement export\", \"2026-08-07\", \"2026-08-05\"),\n    (\"D008\", \"release to 5% of shops before the rest\", \"2026-08-15\", None),\n    (\"D008\", \"document the month-end load on the card provider\", \"2026-08-01\", None),\n    (\"D027\", \"fix the flaky refund test\", \"2026-09-07\", \"2026-09-04\"),\n    (\"D027\", \"alert when charges per minute double after a deploy\", \"2026-09-14\", None),\n    (\"D047\", \"idempotency key on every card retry\", \"2026-10-09\", None),\n    (\"D047\", \"alert on duplicate charges for the same invoice\", \"2026-10-09\", None),\n]\n\n",
      "note": "**The tracker is a list**, written into the program for the course: every action item from the Billing team's four postmortems since June, named after the deployment that failed. On a real team it is a label in the issue tracker, and the program would read an export of it."
    },
    {
      "code": "due = [a for a in ACTIONS if date.fromisoformat(a[2]) <= TODAY]\ndone = [a for a in due if a[3] and date.fromisoformat(a[3]) <= TODAY]\nprint(f\"{len(ACTIONS)} action items, {len(due)} already due, {len(done)} of those done\")\nfor incident, what, by, finished in ACTIONS:\n    late = (TODAY - date.fromisoformat(by)).days\n    if not finished and late > 0:\n        print(f\"  {incident}  {late:3} days overdue  {what}\")\n",
      "note": "**Two numbers and a list.** How many items are due and how many of those are done, and every open item past its date, with how late it is."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 actions.py
10 action items, 8 already due, 4 of those done
  D004   91 days overdue  write a runbook for rolling back a release
  D008   48 days overdue  release to 5% of shops before the rest
  D008   62 days overdue  document the month-end load on the card provider
  D027   18 days overdue  alert when charges per minute double after a deploy
```

**Half the action items that are due have been done.** The rate matters less than which half. Read the open items against the incident of 30 September:

- **"Release to 5% of shops before the rest"**, from July. Done, it would have limited the double charges to a few dozen shops.
- **"Document the month-end load on the card provider"**, from July. Done, it would have warned that the afternoon of the 30th was a bad time to release a change to card charges.
- **"Alert when charges per minute double after a deploy"**, from August. Done, it would very likely have fired within minutes of 17:20, instead of a customer's call at 17:38.

**The September incident was made larger by three action items the team had already agreed to and not done.** That is the strongest argument there is for tracking them.

## Why they do not get done

- **They compete with planned work and lose.** Action items arrive after the plan was made, with no place in it. Lesson 12's slack is where they belong.
- **Nobody owns them once the incident is over.** The urgency fades within a week.
- **They are too big.** "Release to 5% of shops first" is a project, not a task, and it sits undone because nobody can start it on a Tuesday afternoon.

## What makes them get done

- **Track them like any other work**, on the board, with a label, so they age where everybody can see them, lesson 3.
- **Report the completion rate**, every month, beside the incident count. It is the one number that says whether the postmortems are worth the time.
- **Split the big ones.** The first step of a canary release is a decision about how to route 5% of shops, which fits in a day.
- **Review the open items at every new postmortem**, as this section just did. An overdue item that would have prevented the incident under review is a conversation the team should have, and it usually gets the item done.
