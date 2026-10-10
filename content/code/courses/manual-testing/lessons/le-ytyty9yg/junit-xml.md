---
title: JUnit XML, the format results travel in
version: 1
---

The name misleads people twice. JUnit is a unit-testing framework for Java, so JUnit XML sounds
like something only Java programmers produce, and only for unit tests. **JUnit XML is the closest
thing testing has to a common language for results: almost every test runner can write it, and
almost every continuous-integration server and report tool can read it.** It began as the file
JUnit's runs left behind in Java builds, other tools copied it so that they could plug into the
same readers, and it spread from there. Nobody ever published it as a standard, so tools differ at
the edges; the core below is what they agree on.

## The shape of the file

A file holds one **testsuite**, or several inside a **testsuites** element. The suite says how
many cases it holds and how many of them did not pass. Each **testcase** names one case, and what
is inside it is the result:

| inside the testcase | the result |
|---|---|
| nothing | passed |
| `failure` | it ran and the check did not hold; the message says what was seen |
| `error` | it could not run to the end, because something unexpected broke |
| `skipped` | it was not run |

A case also carries a `classname`, which groups cases the way a suite does in a case tool, and
most runners add a `time` in seconds to every case and suite.

## Your manual run, as JUnit XML

Nothing about the format requires an automated test. The 1.1 column of the `cases.csv` you saved
in lesson 18 is a run with a result per case, which is everything the format holds. The program
below reads one run column and writes it as JUnit XML. Create a new file in your `boxoffice`
directory, paste the program into it, and save it. Save it as `to_junit.py`, exactly that name:

```python
"""to_junit.py: one run of the case spreadsheet, written as a JUnit XML file.

    python3 to_junit.py cases.csv 1.1 > results-1.1.xml
"""
import csv
import sys
import xml.etree.ElementTree as ET

path, run = sys.argv[1], sys.argv[2]
with open(path, newline="", encoding="utf-8") as f:
    rows = list(csv.DictReader(f))

suite = ET.Element("testsuite", name=f"boxoffice {run}")
failures = skipped = 0
for row in rows:
    case = ET.SubElement(suite, "testcase", classname=row["requirement"],
                         name=f"{row['id']} {row['title']}")
    result = row[run]
    if result.startswith("failed"):
        failures += 1
        ET.SubElement(case, "failure", message=result.removeprefix("failed: "))
    elif result != "passed":
        skipped += 1
        ET.SubElement(case, "skipped", message="not run")
suite.set("tests", str(len(rows)))
suite.set("failures", str(failures))
suite.set("skipped", str(skipped))

ET.indent(suite)
print('<?xml version="1.0" encoding="UTF-8"?>')
print(ET.tostring(suite, encoding="unicode"))
```

It uses only Python's standard library, like boxoffice. Run it in the `boxoffice` directory, with
the run you want as the second word, and send what it prints into a file:

```
ana@laptop:~/boxoffice$ python3 to_junit.py cases.csv 1.1 > results-1.1.xml
ana@laptop:~/boxoffice$ cat results-1.1.xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="boxoffice 1.1" tests="17" failures="7" skipped="0">
  <testcase classname="R1" name="TC-01 Shows are listed" />
  <testcase classname="R2" name="TC-02 Sign up" />
  <testcase classname="R2" name="TC-03 E-mail already used" />
  <testcase classname="R4" name="TC-04 Book one ticket" />
  <testcase classname="R4" name="TC-05 Book six tickets" />
  <testcase classname="R4" name="TC-06 Seven tickets refused" />
  <testcase classname="R4" name="TC-07 Seats go down" />
  <testcase classname="R5" name="TC-08 Member discount" />
  <testcase classname="R5" name="TC-09 Largest discount only" />
  <testcase classname="R5" name="TC-10 Student pays half">
    <failure message="10% off, R$ 144,00" />
  </testcase>
  <testcase classname="R7" name="TC-11 Quantity in words">
    <failure message="error 500, a traceback" />
  </testcase>
  <testcase classname="R6" name="TC-12 Pay an order" />
  <testcase classname="R6" name="TC-13 No refund after use">
    <failure message="refunded" />
  </testcase>
  <testcase classname="R6" name="TC-14 Message for a refused move">
    <failure message="says cannot be useed" />
  </testcase>
  <testcase classname="R6" name="TC-15 No refund once started">
    <failure message="refunded" />
  </testcase>
  <testcase classname="R8" name="TC-16 Shows on a phone">
    <failure message="scrolls sideways" />
  </testcase>
  <testcase classname="R9" name="TC-17 Every field labelled">
    <failure message="Tickets has no label" />
  </testcase>
</testsuite>
```

`>` works the same in a terminal on Linux, on a Mac and in Windows; on Windows without WSL, open
`results-1.1.xml` in your editor or your browser instead of using `cat`.

## Reading it

The first line inside says the whole run: **17 tests, 7 failures, 0 skipped.** Every case that
passed is one empty line, which is why a file of thousands of passing cases is still easy to scan
for the few that did not. Every failure carries the message from the spreadsheet cell, the thing
that was seen instead of the expected result. And the requirement went into `classname`, so a
reader that groups by class, as most do, shows the results by requirement: four for R6, three for
R5, one for R9.

The 1.0 column goes through the same program:

```
ana@laptop:~/boxoffice$ python3 to_junit.py cases.csv 1.0 > results-1.0.xml
ana@laptop:~/boxoffice$ head -n 2 results-1.0.xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="boxoffice 1.0" tests="17" failures="5" skipped="3">
```

Three cases were not run on 1.0, because they did not exist yet, and they came out as `skipped`.
That is a **decision this program made**, and it is worth seeing as one. A case tool has at least
four results, and the format has four outcomes that do not line up with them: blocked has no
element of its own, and becomes `skipped` in one team's converter and `error` in another's. Whoever
converts manual results writes down the mapping, or two reports from the same run disagree about
how many cases were tested.

## Who reads it

Nobody reads this file for pleasure. It is the hand-over between the thing that ran the tests and
the thing that shows them, which for automated suites is usually a CI server's results page or a
report tool such as the one in section 03 of this lesson. Its value is that it is boring and
shared: a run recorded this way can be read by tools that know nothing about boxoffice, Python or
the spreadsheet it came from.
