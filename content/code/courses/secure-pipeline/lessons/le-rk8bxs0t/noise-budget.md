---
title: The noise budget
version: 1
---

Every proposal a bot makes costs a person some attention: open the pull request, read what changed,
look at the pipeline, decide. **A team has a fixed amount of that attention, and a bot configured
without regard to it spends all of it**, after which the pull requests are merged unread or left to
pile up. Both outcomes are worse than no bot: the first merges what nobody judged, and the second
teaches everybody that the bot's pull requests are noise, including the one that fixes an advisory.
It is lesson 7's alert fatigue, arriving as pull requests instead of failed builds.

So before switching a bot on, count. The count that matters is how many proposals a configuration
would have made over a real year, and the package index has the data.

### Counting a year of releases

This program asks PyPI when each pinned package published each release, and counts the releases in
the year before a date. Then it counts what three configurations would have opened: one pull request
per release, one per week that had a release, and one per month. Save it as `~/releases.py`:

```python
"""How many releases each pinned dependency published in the year before a
date, and how many pull requests a bot would have opened for them: one per
release, one per week with a release, or one per month with a release.

    python3 ~/releases.py 2026-10-16 requirements.txt requirements-dev.txt

Versions with a letter in them (alphas, betas, release candidates, post
releases) are left out, as the bots leave them out by default.
"""
import datetime
import json
import re
import sys
import urllib.request


def pinned(paths):
    for path in paths:
        for line in open(path):
            found = re.match(r"([A-Za-z0-9_.-]+)==", line)
            if found:
                yield found.group(1).lower()


def release_days(name, start, end):
    with urllib.request.urlopen(f"https://pypi.org/pypi/{name}/json") as answer:
        releases = json.load(answer)["releases"]
    for version, files in releases.items():
        days = [f["upload_time_iso_8601"][:10] for f in files if not f["yanked"]]
        if days and not re.search(r"[a-z]", version) and start < min(days) <= end:
            yield datetime.date.fromisoformat(min(days))


end = datetime.date.fromisoformat(sys.argv[1])
start = (end - datetime.timedelta(days=365)).isoformat()
every = []
for name in sorted(set(pinned(sys.argv[2:]))):
    days = list(release_days(name, start, end.isoformat()))
    every += days
    print(f"{name:16} {len(days):3}")
weeks = {day.isocalendar()[:2] for day in every}
months = {(day.year, day.month) for day in every}
print(f"{'one per release':16} {len(every):3}")
print(f"{'one per week':16} {len(weeks):3}")
print(f"{'one per month':16} {len(months):3}")
```

It reads the package names out of the requirements files, so it counts linkbox's own dependencies,
direct and transitive alike, because a bot proposes updates for every pin in the lock. Run it for
the year that ends on the date the lock was compiled:

@@CAPTURE releases@@

### Reading the count

linkbox has 13 pinned packages and 3 direct dependencies, and the count is per year:

- One pull request per release would have been @@N_RELEASE@@ of them, almost one a week, each
  arriving whenever its release did.
- Grouped by week, the same releases fit in @@N_WEEK@@ pull requests: that many weeks of the
  year had at least one release.
- Grouped by month, @@N_MONTH@@: no month of that year passed without a release.

The spread is uneven, which is typical. gunicorn alone released @@N_GUNICORN@@ times; three packages
released nothing. A group by week therefore carries a gunicorn update in a large share of its pull
requests, which is a reason to read gunicorn's changelog once a month rather than to skip it.

```schooling-figure
{}
```

A small Flask service is the easy case. The same arithmetic for a service with two hundred
transitive dependencies, a few base images and a dozen actions multiplies the first number by ten or
more, and the grouping is what makes a bot bearable there. The other counts this program leaves out
point the same way: linkbox's two base images and its actions would add their own updates on the
same Monday.

### Setting the budget

Turn the count around and ask what the team can read. If one person can give the bot's pull
requests an hour on Monday, and a careful review of a grouped update with a passing pipeline takes
ten to fifteen minutes, the budget is about four pull requests a week. The configuration should fit
inside that, and linkbox's does: one Python group, one action group, base images on their own, and
at most three open at a time, so a missed week does not become a backlog of eight.

Three rules keep the budget honest as the project grows:

1. Measure the bot's own output: how many of its pull requests were merged, closed or left open
   past a week, each month. A rising number left open is the bot going unread, and it shows up
   long before anybody admits it.
2. Cut the noise, never the security updates. If the budget is exceeded, group more, lengthen the
   schedule, or stop proposing minor updates of test tools. The advisory-driven updates stay
   immediate and ungrouped, because those are the reason the bot is there.
3. **Fewer dependencies is the cheapest budget.** Lesson 15's third move, replacing a dependency,
   also removes every future pull request about it. A package that releases a dozen times a year and gives
   you one function is a dozen interruptions a year for one function.

Lesson 20 turns counts like these into the measurements a team reports, and asks what each one
hides.
