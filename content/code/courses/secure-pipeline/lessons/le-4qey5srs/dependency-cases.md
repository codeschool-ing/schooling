---
title: Three dependency cases, decided
version: 1
---

Three situations every team with dependencies meets in its first month of composition analysis.
Each one is a branch pushed to your CI server, and each one ends in a decision argued from the
rule of the first section: **break only for what the person who broke it can fix, now.**

### Case 1: an advisory with a fix, in a direct dependency

An advisory is published against a version you pin, and the advisory names a fixed version. On
your machine the way to stand in for "published this morning" is to move a pin back to a version
that has advisories with fixes. Jinja2 3.1.4 has three:

@@CAPTURE fixable@@

**Decision: break.** The pin is a line in a file the developer controls, the fixed version is
named in the log, and moving it is a change of one line plus a run of the tests. Nothing about
that is out of their reach, so the rule says break, and the build broke.

The gate never read a severity, and that is deliberate rather than an omission. pip-audit's JSON
carries no score, but the stronger reason is that severity does not change the move: a critical
with a fix and a low with a fix are both one pin away, and a gate that let lows through would
leave a backlog of one-line fixes that nobody schedules. Severity matters when the fix is
expensive, which is the third case.

### Case 2: an advisory nobody can fix

A branch adds a package to verify the signatures of incoming webhooks, at its latest version:

@@CAPTURE unfixable@@

**Decision: warn.** There is no version to move to, so breaking the build would stop every push of
the project until somebody else publishes a release, which may never happen. The warning is
printed with the end of the log and counted in the last line, so it is not a pass.

A warning still needs a person to read the advisory, and to decide whether it applies. Its text:

@@CAPTURE advisory@@

The last two sentences settle the reading. The flaw is in signing, a side-channel through which
the timing of signatures leaks the private key, and **verification is unaffected**. A service that
only checks signatures made by somebody else holds no private key to leak. That decision is
written down with the warning, by whoever owns it, and revisited when the advisory changes. The
other half of the advisory, that the project considers side channels out of scope and plans no
fix, is a fact about the package rather than about this branch, and lesson 15 takes it up as a
reason to replace a dependency.

### Case 3: a fix that cannot land today

Back to Jinja2. Suppose moving to 3.1.6 broke templates the team needs a fortnight to rework. The
build is broken by a finding that is fixable in principle and not this week. Breaking every push
for two weeks gets the gate switched off; ignoring the advisory for ever forgets it. **An exception
is the third option: the advisory, the last day it holds, and why.** Add one line per advisory to
`ci/exceptions.txt` on the branch:

@@CAPTURE excepted@@

**Decision: pass, until 20 November.** The log says *excepted until*, not *no advisories*, so the
advisory is visible every run. Each line names one advisory and not the package: a fourth advisory
published against Jinja2 3.1.4 next week is not covered, and breaks the build like any other.

Then time passes. The gate warns in an exception's last week, so the date is seen before it
arrives. Here it is with the date moved to four days from the recording:

@@CAPTURE near@@

And the day after the date, the exception is ignored and the finding breaks the build again, as
if it had never been excepted:

@@CAPTURE expired@@

**Nothing renews an exception except a new commit**: a new date and a new reason, read by a
reviewer like any other change. That is the property a baseline, two sections on, does not have.
