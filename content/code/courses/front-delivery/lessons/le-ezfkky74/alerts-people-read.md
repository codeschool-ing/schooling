---
title: Alerts people read
version: 1
---

**A monitor is useful only if somebody acts on what it says, and the way it fails is by saying too much.**
Every browser extension that throws into the page, every network that drops a request in a tunnel,
every old tab running last week's build sends a report. A team that is told about all of them stops
reading, and misses the one that matters.

## Counting, not reading

The first step is to stop reading reports one by one and count them by what they say. Even the planner's
file can be counted, with a pipe:

```
ana@dev:~/planner$ grep -o '"message":"[^"]*"' api/errors.jsonl | sort | uniq -c | sort -rn
      1 "message":"Response not successful: Received status code 502"
      1 "message":"A bug, on purpose"
```

Two reports, two messages. On a real site this list is thousands of lines long, and its top is the work
for the week. A hosted service does this grouping with the stack as well as the message, so two
different bugs that happen to throw the same `TypeError` stay apart.

## What earns an alert

An alert interrupts a person, so it is kept for what cannot wait. Three rules cover most teams:

- **New in this release.** An issue that has never been seen before, first reported by the build deployed
  an hour ago, is almost always that deploy's fault, and the cheapest moment to fix it is now.
- **A sudden rise.** An issue that usually arrives ten times an hour and now arrives a thousand is an
  outage, whatever its message says.
- **Regressed.** An issue marked fixed that comes back in a newer release.

Everything else goes to a list that is read on a schedule, not pushed at anybody.

## Noise, filtered at the source

Some reports are known to be nobody's bug, and filtering them in the page saves everyone:

- errors whose stack is only in a browser extension's files, `chrome-extension://` and the like;
- *Script error.* with no stack, from a script on another origin the planner does not own;
- `ResizeObserver loop completed with undelivered notifications`, which browsers report and which almost
  never affects a user;
- requests that failed because the device went offline, which `navigator.onLine` can tell apart.

Each filter is a decision that a kind of error does not matter, so each is written down in the code with
the reason, and reviewed like any other change. **A filter nobody can explain is a bug that has been
hidden on purpose.**

That is the end of the course's last subject. The planner now builds, deploys, looks the same everywhere,
reads from a server, and tells its team when it breaks.
