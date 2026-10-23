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

```
ana@vm:~/linkbox$ git switch -q -c jinja-3.1.4
ana@vm:~/linkbox$ sed -i s/jinja2==3.1.6/jinja2==3.1.4/ requirements.txt
ana@vm:~/linkbox$ git commit -q -am "jinja2 back to 3.1.4"
9:34AM INF 0 commits scanned.
9:34AM INF scanned ~14 bytes (14 bytes) in 259ms
9:34AM INF no leaks found
ana@vm:~/linkbox$ git push ci jinja-3.1.4
remote: run 2: jinja-3.1.4 at c068c95        
remote: secrets: passed in 0s        
remote: test: passed in 2s        
remote: sast: passed in 3s        
remote: sca: FAILED in 11s, the end of sca.log:        
remote:   Found 6 known vulnerabilities in 1 package        
remote:   BREAKS: jinja2 3.1.4 PYSEC-2026-1475, fixed in 3.1.5        
remote:   BREAKS: jinja2 3.1.4 PYSEC-2026-1472, fixed in 3.1.5        
remote:   BREAKS: jinja2 3.1.4 PYSEC-2026-1471, fixed in 3.1.6        
remote: run 2: failed, the logs are in ~/ci/runs/2/logs        
To /home/ana/ci/linkbox.git
 * [new branch]      jinja-3.1.4 -> jinja-3.1.4
```

**Decision: break.** The pin is a line in a file the developer controls, the fixed version is
named in the log, and moving it is a change of one line plus a run of the tests. Nothing about
that is out of their reach, so the rule says break, and the build broke.

The gate never read a severity, and that is deliberate rather than an omission. pip-audit's JSON
carries no score. The stronger reason is that severity does not change the move: a critical with a
fix and a low with a fix are both one pin away. A gate that let lows through would leave a backlog
of one-line fixes that nobody schedules. Severity matters when the fix is
expensive, which is the third case.

### Case 2: an advisory nobody can fix

A branch adds a package to verify the signatures of incoming webhooks, at its latest version:

```
ana@vm:~/linkbox$ git switch -q main && git switch -q -c ecdsa
ana@vm:~/linkbox$ echo ecdsa==0.19.2 >>requirements.txt
ana@vm:~/linkbox$ git commit -q -am "ecdsa, to check the signatures of incoming webhooks"
9:35AM INF 0 commits scanned.
9:35AM INF scanned ~14 bytes (14 bytes) in 230ms
9:35AM INF no leaks found
ana@vm:~/linkbox$ git push ci ecdsa
remote: run 3: ecdsa at c6418bf        
remote: secrets: passed in 1s        
remote: test: passed in 2s        
remote: sast: passed in 3s        
remote: sca: WARNING in 11s, the end of sca.log:        
remote:   Found 2 known vulnerabilities in 1 package        
remote:   warns: ecdsa 0.19.2 PYSEC-2026-1325, no fixed version yet        
remote: build: passed in 1s        
remote: pipeline passed with 1 warning(s)        
remote: run 3: passed        
To /home/ana/ci/linkbox.git
 * [new branch]      ecdsa -> ecdsa
```

**Decision: warn.** There is no version to move to, so breaking the build would stop every push of
the project until somebody else publishes a release, which may never happen. The warning is
printed with the end of the log and counted in the last line, so it is not a pass.

A warning still needs a person to read the advisory, and to decide whether it applies. Its text:

```
ana@vm:~/linkbox$ pip-audit -r requirements.txt -f json 2>/dev/null | jq -r ".dependencies[] | select(.name == \"ecdsa\") | .vulns[0].description"
python-ecdsa has been found to be subject to a Minerva timing attack on the P-256 curve. Using the `ecdsa.SigningKey.sign_digest()` API function and timing signatures an attacker can leak the internal nonce which may allow for private key discovery. Both ECDSA signatures, key generation, and ECDH operations are affected. ECDSA signature verification is unaffected. The python-ecdsa project considers side channel attacks out of scope for the project and there is no planned fix.
```

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

```
ana@vm:~/linkbox$ git switch -q jinja-3.1.4
ana@vm:~/linkbox$ tail -n 3 ci/exceptions.txt
PYSEC-2026-1475 2026-11-20 templates need rework for 3.1.5; Ana, see issue 41
PYSEC-2026-1472 2026-11-20 templates need rework for 3.1.5; Ana, see issue 41
PYSEC-2026-1471 2026-11-20 templates need rework for 3.1.6; Ana, see issue 41
ana@vm:~/linkbox$ git commit -q -am "jinja2 3.1.4 excepted for four weeks, while the templates are reworked"
9:35AM INF 0 commits scanned.
9:35AM INF scanned ~234 bytes (234 bytes) in 228ms
9:35AM INF no leaks found
ana@vm:~/linkbox$ git push ci jinja-3.1.4
remote: run 4: jinja-3.1.4 at ae520bf        
remote: secrets: passed in 0s        
remote: test: passed in 2s        
remote: sast: passed in 3s        
remote: sca: passed in 9s        
remote: build: passed in 1s        
remote: pipeline passed with 0 warning(s)        
remote: run 4: passed        
To /home/ana/ci/linkbox.git
   c068c95..ae520bf  jinja-3.1.4 -> jinja-3.1.4
ana@vm:~/linkbox$ cat ~/ci/runs/4/logs/sca.log
Found 6 known vulnerabilities in 1 package
excepted until 2026-11-20: jinja2 3.1.4 PYSEC-2026-1475
excepted until 2026-11-20: jinja2 3.1.4 PYSEC-2026-1472
excepted until 2026-11-20: jinja2 3.1.4 PYSEC-2026-1471
```

**Decision: pass, until 20 November.** The log says *excepted until*, not *no advisories*, so the
advisory is visible every run. Each line names one advisory and not the package: a fourth advisory
published against Jinja2 3.1.4 next week is not covered, and breaks the build like any other.

Then time passes. The gate warns in an exception's last week, so the date is seen before it
arrives. Here it is with the date moved to four days from the recording:

```
ana@vm:~/linkbox$ sed -i 's/ 2026-11-20 / 2026-10-27 /' ci/exceptions.txt
ana@vm:~/linkbox$ bash ci/sca.sh; echo "exit $?"
Found 6 known vulnerabilities in 1 package
excepted until 2026-10-27: jinja2 3.1.4 PYSEC-2026-1475
excepted until 2026-10-27: jinja2 3.1.4 PYSEC-2026-1472
excepted until 2026-10-27: jinja2 3.1.4 PYSEC-2026-1471
exit 3
```

And the day after the date, the exception is ignored and the finding breaks the build again, as
if it had never been excepted:

```
ana@vm:~/linkbox$ sed -i 's/ 2026-10-27 / 2026-10-22 /' ci/exceptions.txt
ana@vm:~/linkbox$ bash ci/sca.sh; echo "exit $?"
Found 6 known vulnerabilities in 1 package
BREAKS: jinja2 3.1.4 PYSEC-2026-1475, fixed in 3.1.5
BREAKS: jinja2 3.1.4 PYSEC-2026-1472, fixed in 3.1.5
BREAKS: jinja2 3.1.4 PYSEC-2026-1471, fixed in 3.1.6
exit 1
ana@vm:~/linkbox$ git checkout -q ci/exceptions.txt
```

**Nothing renews an exception except a new commit**: a new date and a new reason, read by a
reviewer like any other change. That is the property a baseline, two sections on, does not have.
