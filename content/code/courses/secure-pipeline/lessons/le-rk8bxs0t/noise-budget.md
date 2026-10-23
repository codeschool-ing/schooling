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

```
ana@vm:~/linkbox$ git switch -q main
ana@vm:~/linkbox$ python3 ~/releases.py 2026-10-16 requirements.txt requirements-dev.txt
blinker            0
click              7
flask              1
gunicorn          13
iniconfig          3
itsdangerous       0
jinja2             0
markupsafe         1
packaging          4
pluggy             1
pygments           2
pytest             6
werkzeug           6
one per release   44
one per week      29
one per month     12
```

### Reading the count

linkbox has 13 pinned packages and 3 direct dependencies, and the count is per year:

- One pull request per release would have been 44 of them, almost one a week, each
  arriving whenever its release did.
- Grouped by week, the same releases fit in 29 pull requests: that many weeks of the
  year had at least one release.
- Grouped by month, 12: no month of that year passed without a release.

The spread is uneven, which is typical. gunicorn alone released 13 times; three packages
released nothing. A group by week therefore carries a gunicorn update in a large share of its pull
requests, which is a reason to read gunicorn's changelog once a month rather than to skip it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 316\" role=\"img\" data-fig=\"sp-l18-releases\" aria-label=\"Releases in the year to 16 October 2026 of each package linkbox pins: blinker 0, click 7, flask 1, gunicorn 13, iniconfig 3, itsdangerous 0, jinja2 0, markupsafe 1, packaging 4, pluggy 1, pygments 2, pytest 6, werkzeug 6. 44 in all.\"><defs></defs><text x=\"120\" y=\"24\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">blinker</text><text x=\"138.0\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"120\" y=\"46\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">click</text><rect x=\"130\" y=\"38\" width=\"269.2307692307692\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"407.2307692307692\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><text x=\"120\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">flask</text><rect x=\"130\" y=\"60\" width=\"38.46153846153846\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"176.46153846153845\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><text x=\"120\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">gunicorn</text><rect x=\"130\" y=\"82\" width=\"500.0\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"638.0\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">13</text><text x=\"120\" y=\"112\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">iniconfig</text><rect x=\"130\" y=\"104\" width=\"115.38461538461539\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"253.3846153846154\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><text x=\"120\" y=\"134\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">itsdangerous</text><text x=\"138.0\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"120\" y=\"156\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">jinja2</text><text x=\"138.0\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"120\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">markupsafe</text><rect x=\"130\" y=\"170\" width=\"38.46153846153846\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"176.46153846153845\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><text x=\"120\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">packaging</text><rect x=\"130\" y=\"192\" width=\"153.84615384615384\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"291.8461538461538\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><text x=\"120\" y=\"222\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pluggy</text><rect x=\"130\" y=\"214\" width=\"38.46153846153846\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"176.46153846153845\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><text x=\"120\" y=\"244\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pygments</text><rect x=\"130\" y=\"236\" width=\"76.92307692307692\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"214.9230769230769\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><text x=\"120\" y=\"266\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pytest</text><rect x=\"130\" y=\"258\" width=\"230.76923076923077\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"368.7692307692308\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><text x=\"120\" y=\"288\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">werkzeug</text><rect x=\"130\" y=\"280\" width=\"230.76923076923077\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"368.7692307692308\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text></svg>", "caption": "44 releases in a year from thirteen pins, 13 of them from one package, and none from three."}
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
