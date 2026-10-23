---
title: An automatic fix, judged by the pipeline
version: 1
---

A bot's change is a change like any other, and the pipeline is what judges it. This section makes
that concrete on the branch with the month-old lock. First the pipeline finds the advisory; then a
tool that writes fixes for you makes one; then the pipeline judges the fix.

### The pipeline finds it

Push the branch to the CI server. Every branch runs the pipeline:

@@CAPTURE push-stale@@

The composition stage broke the build, with lesson 7's gate saying why: werkzeug 3.1.8 has an
advisory, PYSEC-2026-4312, with a fixed version, 3.1.9. On 20 September there was nothing to report,
because the fix and the advisory both came after. **A lock that was safe when it was compiled is not
safe for ever**, and this is how it shows: nothing in the branch changed, and the verdict did.

### The automatic fix

pip-audit can fix what it finds. `--fix` moves each vulnerable package to the first version that
fixes its advisories and writes the result back into the requirements files:

@@CAPTURE fix@@

It reports success, and the version line agrees: `werkzeug==3.1.9`. Read the two lines under it.
**Those hashes belong to werkzeug 3.1.8**; they are the same two hashes the stale lock had. pip-audit
edited the version and left the rest of the entry alone, and it made two more changes nobody asked
for: it added werkzeug to `requirements-dev.txt` as a pin of its own, saying so in its warning, and
it rewrote the indentation of the `# via` comments, which is most of the diff's 40 changed lines.
`requirements.in` still says nothing about werkzeug, so the next compile would undo the fix.

Nothing in that output looks wrong unless you know what a hash line is for. Commit it as a bot
would, and let the pipeline judge:

@@CAPTURE push-fix@@

The tests stage broke, before any scanner ran. uv refused to install werkzeug 3.1.9 because the file
it downloaded does not match either hash in the lock, and **that refusal is lesson 15's control
working as designed**: a lock that names a version and the hash of a different file is exactly what
an attacker's tampering would look like, and the installer cannot tell the difference, so it
refuses both. The automatic fix did not fix the build; it moved the failure from the security gate
to the install.

### The fix a lock wants

Throw the bot's commit away and make the change the way lesson 15 made every change to the lock:
compile again. `-P werkzeug` lets uv move that one package and keeps every other pin as the file
has it, and the new `--exclude-newer` date allows the fixed release:

@@CAPTURE right-fix@@

The diff is the header line, which records the new command, and three lines of werkzeug: a new
version and the two hashes that go with it. Push it:

@@CAPTURE push-right@@

Every stage passes. pluggy 1.6.0, markupsafe 3.0.3 and iniconfig 2.3.0 are still old, and that is
fine: they carry no advisory, and they are the routine updates the bots will propose on a Monday,
after their cooldown.

### What this says about automatic fixes

| | `pip-audit --fix` | `uv pip compile -P werkzeug` |
|---|---|---|
| finds the version that fixes the advisory | yes | no, you name the package |
| knows the file is a compiled lock | no | yes, it wrote it |
| writes hashes for the new version | no | yes |
| changes only what it was asked to | no: a new pin in the dev file, and every comment | yes: one package and the header |
| the pipeline's verdict | broken at the install | passed |

The point is not that pip-audit is a bad tool. Its `--fix` is written for a plain list of pins, and
on one it does the right thing. **A fixing tool is only as good as its understanding of the file it
edits**, and a bot's pull request deserves the same question as anybody's: did the pipeline that
judged it check the thing that matters? Here it did, because lesson 15 made the install check hashes.
A pipeline without that check would have installed werkzeug 3.1.9, passed every stage, and shipped a
lock whose hashes protected nothing.

The branch has done its job. Leave it unmerged: `main` never had the old lock, and merging would
bring four month-old pins back with the one fix.
