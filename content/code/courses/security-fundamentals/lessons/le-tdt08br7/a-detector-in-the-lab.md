---
title: A detector in the lab
version: 1
---

To count the four outcomes you need two things: a detector, and the truth to hold it against. The
truth is the hard part in real life, because nobody labels attacks for you. Here it comes from the
same place a real team gets it during a purple exercise: **the exercise's own schedule.**

The lab holds a week of sign-in attempts at the shop's systems, from Monday 28 September to Sunday
4 October. It is generated, not recorded, so that every line's truth is known; the lab's build script
says exactly what went into it. In short: the nine staff signing in with the occasional typing
mistake, a backup job whose password expired failing every night, and an authorised exercise from
two addresses on the internet, one guessing fast and one guessing slowly.

```
ana@laptop:~$ wc -l logins.csv
275 logins.csv
ana@laptop:~$ grep -m 3 ",fail$" logins.csv
2026-09-28T02:00:05,192.168.20.40,svc-backup,fail
2026-09-28T02:00:25,192.168.20.40,svc-backup,fail
2026-09-28T02:00:45,192.168.20.40,svc-backup,fail
ana@laptop:~$ cat red-team-sources.txt
203.0.113.50
203.0.113.77
```

The file has a header and 274 attempts, one per line: when, from where, which account, and whether it
worked. The first failures of the week are the backup account at two in the morning. The exercise's
schedule names its two source addresses, and that is the whole truth the detector will be measured
against: **a failure from one of those two addresses was the exercise, and any other was not.**

### The detector

The rule is the one most systems start with: **raise an alert when one address fails to sign in at
least N times within ten minutes.** Here it is, in about twenty lines of Python, with the note beside
each piece saying what it does. You do not need to write Python to read the notes.

```schooling-example
{"language": "python", "file": "detect.py", "parts": [{"code": "import csv\nimport sys\nfrom collections import Counter"}, {"code": "threshold = int(sys.argv[1])\nignored = set(sys.argv[2:])", "note": "The threshold N comes from the command line, and so does an optional list of accounts to leave out; the last run in this lesson uses it."}, {"code": "failures = Counter()\nfor row in csv.DictReader(open('logins.csv')):\n    if row['result'] == 'fail' and row['user'] not in ignored:\n        window = row['time'][:15]\n        failures[(row['source'], window)] += 1", "note": "Count the failures per address and per ten-minute window. Successes are not counted, and neither are the accounts left out."}, {"code": "red = set(open('red-team-sources.txt').read().split())\ntp = fp = fn = tn = 0\nfor (source, window), count in failures.items():\n    alert = count >= threshold\n    attack = source in red\n    if alert and attack:\n        tp += 1\n    elif alert:\n        fp += 1\n    elif attack:\n        fn += 1\n    else:\n        tn += 1", "note": "The truth is the exercise's two addresses. Every case is sorted into one of the four boxes: did the rule alert, and was it the exercise?"}, {"code": "print(f'threshold {threshold}: {tp + fp} alerts')\nprint(f'  TP {tp:3}   FP {fp:3}')\nprint(f'  FN {fn:3}   TN {tn:3}')\nprint(f'precision {tp / (tp + fp):.0%}   recall {tp / (tp + fn):.0%}')", "note": "Print the matrix, and the two numbers the next section explains."}]}
```

The ten minutes come from cutting the time down to its first fifteen characters:
`2026-09-29T14:03:12` becomes `2026-09-29T14:0`, which is the same for every second from 14:00:00 to
14:09:59. Each address in each ten-minute window that had at least one failure is one **case**, and
every case lands in exactly one of the four boxes from the previous section.
