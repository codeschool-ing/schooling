---
title: Evidence
version: 1
---

Steps tell the reader how to see the failure. **Evidence lets them see it without running
anything**, and that matters often: the developer is reading on a phone
between meetings, the product owner at triage has no copy of the application, the defect only
happens on your machine. A report whose evidence is good can be judged before anybody reproduces
it, and a report with none waits until somebody has the time.

Three kinds of evidence cover almost every defect in a web application, and the defect from
section 02 of this lesson has all three.

## The transcript

What the application sent back, as text, with the command that asked for it. Section 03 already
has it: the curl command and the traceback it printed. **Text is the best evidence there is**,
because the reader can search it, copy a line of it into their own terminal, and compare it
character by character with what they get. The line that matters is the last one:

```
ValueError: invalid literal for int() with base 10: 'two'
```

Paste that into the report as text, inside a code block if the tracker has one. A screenshot of
the same line cannot be searched, cannot be copied, and is unreadable on a phone. The full
traceback belongs in the report too, below it, because the developer will want the line numbers.

## The server's log line

The browser and curl show what the customer saw. The server's terminal shows what the server
thought it did, and the two can disagree, which is why a report carries both when it can. In the
terminal where boxoffice is running, the request from section 03 added this line:

```
127.0.0.1 - - [10/Oct/2026 04:13:43] "POST /book HTTP/1.1" 500 -
```

It says who asked (`127.0.0.1`, this machine), when, what was asked (`POST /book`) and what was
answered (`500`). The time in the brackets is your computer's clock, so yours will differ; quote
it as you see it. **A log line ties the report to a moment**, and on a shared test server, where
a developer can open the full log, that moment is how they find your request among everybody
else's.

boxoffice's log is short because the program is small. A real server writes more around a failure,
often the whole traceback, and the rule is the same: quote the lines that belong to your request,
and say where the rest of the log is, rather than attaching an afternoon of it.

## The screenshot

A screenshot is the evidence for what can only be seen: a layout, a colour, a page that renders
wrong. For this defect it adds one fact the text does not hold. In the browser the traceback is
the whole page, with no title in the tab, none of the theatre's links and no footer, so a
customer sees no way back except the browser's own button.

A good screenshot shows the address bar, so the reader knows which page it was, and as little
else as possible. **Crop it to the window, not the whole desktop**, and mark the part that matters
with a box if the image is busy. If the defect is about a sequence, for example a button that
flickers, a short screen recording replaces the screenshot; a recording of something a screenshot
would show is a minute of somebody's time to find one frame.

## What evidence must not carry

Evidence leaves your machine and lives in a tracker that many people read. Before you attach
anything, look at it as a stranger would.

**Passwords, tokens and other people's data come out.** boxoffice's seeded account and its password
are test data, and the course prints them on purpose. A real customer's name, e-mail or card number
in a screenshot is a leak with your name on it, and lesson 20 is about making test data that never
needed hiding in the first place. Blur or replace them, and say in the report that you did.

**A security defect goes to the people who need it, not to everybody.** The traceback is a small
example of the kind lesson 14 described: it shows file paths and code to whoever triggers it. In
a tracker the whole company reads, or in a public one, a report of how to make a page leak its
insides is information for an attacker too. Most trackers can restrict who sees an issue, and most
organisations say where security reports go; follow that, and keep the reproduction exact anyway,
because the people fixing it need it as much as anybody.

**Evidence matches the report.** A transcript from 1.0 attached to a report against 1.1, or a
screenshot from a different account than the steps name, makes the reader doubt everything else on
the page. When the version changes, run it again and replace the evidence.
