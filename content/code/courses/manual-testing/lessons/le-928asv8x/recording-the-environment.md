---
title: Recording the environment in every report
version: 1
---

A report of defect 9 that says "booking closes early" is true and useless. Rui would try it on his
laptop, see an order, and close the report as not reproducible, and he would be right to. **The
environment is part of the steps**: for a defect that lives in a difference between machines, it is
the most important part, and for every other defect it costs one short block to include. Lesson 15
gave a defect report its fields; this section fills in the one that is easiest to skip.

The wrong habit is to add the environment only when you already suspect it matters. By then you
have usually filed three reports without it, and one of them was defect 9 under another name.
Record it every time, and record it the same way, so that two reports can be compared line by line.

## Five readings that take a minute

For boxoffice, the environment fits in five readings, and four of them come from the terminal. In
the second terminal, with boxoffice running:

```
ana@laptop:~/boxoffice$ python3 --version
Python 3.13.16
ana@laptop:~/boxoffice$ grep PRETTY_NAME /etc/os-release
PRETTY_NAME="Ubuntu 24.04.5 LTS"
ana@laptop:~/boxoffice$ date
Sat Oct 10 04:11:20 -03 2026
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/health
ok boxoffice 1.1
```

**The version of Python** runs the program, and a defect that appears on one version of a language
and not another is common enough to rule out first.

**The operating system** is the second line. On Linux `/etc/os-release` names it. On a Mac, the
command `sw_vers` prints the macOS version, and on Windows, typing `winver` in the Start menu opens
a window that shows it; neither was run for this course.

**The clock and its zone**, which `date` prints. The `-03` at the end is the zone, and after this
lesson you know why it earns a line. Look also at the time it printed, 04:11, which is not the
14:00 that boxoffice believed during that capture: `BOXOFFICE_NOW` moves the application's clock and
nothing else. So a report must also say **how the program was started**, with every variable you
set, because a defect seen under a pinned clock is a different observation from one seen under the
real one.

**The application's own version**, from `/health`. It is the one reading that cannot be taken from
memory, because the file in your folder is whatever you last saved, and lesson 9 made a second
version of it. The footer of every page carries the same number, `boxoffice 1.1`, for anybody who is
testing in a browser.

**The browser and its version** are the fifth reading, and the only one the terminal cannot give
you. Every browser shows its exact version on an About page: Firefox and Chrome both keep it under
Help in their main menu. Write the size of the window as well when the defect is about layout, as
lesson 7 did for the narrow screens.

## A block to paste

Readings are only useful if they arrive in the same shape every time. Keep a block like this in a
text file and paste it into every report, filled in from the commands above:

```
Environment
  application:  boxoffice 1.1 (from /health)
  started with: TZ=UTC BOXOFFICE_NOW=2026-10-10T17:30:00-03:00
  python:       Python 3.13.16
  system:       Ubuntu 24.04.5 LTS, zone -03 (America/Sao_Paulo)
  browser:      <name and version, from its About page>, window <width> px
```

The line `started with` is the one that turns defect 9 from an argument into two runs anybody can
repeat. Without it, a reader starts boxoffice the ordinary way and gets an order.

**Copy, do not retype.** A version typed from memory is where `1.1` becomes `1.0` and a report
describes a defect that version never had. Paste the output of the commands, and if a reading looks
surprising, take it again rather than correcting it by hand.

## How much is enough

Not everything about a machine belongs in a report, and a page of settings hides the one line that
matters. A fair rule is to record **what could plausibly differ between your machine and the
reader's**: versions, the zone, the language of the system, how the program was started, and the
data you began from. For boxoffice that is "a fresh start"; for a real product it is the name of a
data set (lesson 20). If a defect turns out to depend on something outside the block, add that line
to the block, and every report after it carries it.

And when a defect appears in one environment and not another, **say both**. "Closed on UTC,
open on America/Sao_Paulo, same instant" tells Rui where to look before he reads another word. A
report that records only the failing side leaves him to rediscover the passing one, which is the
"works on my machine" conversation all over again.
