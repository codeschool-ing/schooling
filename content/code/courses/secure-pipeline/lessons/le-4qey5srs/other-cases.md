---
title: A secret, a false positive and code nobody calls
version: 1
---

The other three cases come from the other stages, and each one tests a different half of the
rule. A secret tests what "can fix" means. A false positive tests whether a warning is worth
keeping. Code nobody calls tests "now", and whether a finding can be argued away.

### Case 4: a secret, past the hook

Somebody writes the webhook check by hand after all, pastes the shared secret into a file, and
commits with `--no-verify` because the hook "was slow today". The value is made up and opens
nothing; the CI cannot tell, and should not try:

```
ana@vm:~/linkbox$ git switch -q main && git switch -q -c webhook
ana@vm:~/linkbox$ printf "WEBHOOK_SECRET = \"Zr4tq8LmW2xK9vB6nP3sH7yC1dF5gJ0a\"\n" >webhook.py
ana@vm:~/linkbox$ git add webhook.py && git commit -q --no-verify -m "verify incoming webhooks"
ana@vm:~/linkbox$ git push ci webhook
remote: run 5: webhook at 3d1183f        
remote: secrets: FAILED in 1s, the end of secrets.log:        
remote:   Finding:     WEBHOOK_SECRET = "REDACTED"        
remote:   Secret:      REDACTED        
remote:   RuleID:      generic-api-key        
remote:   Entropy:     5.000000        
remote:   File:        webhook.py        
remote:   Line:        1        
remote:   Commit:      3d1183f8fcc944e3a929df90fded0c12046f2e4e        
remote:   Author:      Ana Lima        
remote:   Email:       ana@example.org        
remote:   Date:        2026-10-23T12:36:07Z        
remote:   Fingerprint: 3d1183f8fcc944e3a929df90fded0c12046f2e4e:webhook.py:generic-api-key:1        
remote:           
remote:   9:36AM INF 11 commits scanned.        
remote:   9:36AM INF scanned ~15312 bytes (15.31 KB) in 276ms        
remote:   9:36AM WRN leaks found: 1        
remote: run 5: failed, the logs are in ~/ci/runs/5/logs        
To /home/ana/ci/linkbox.git
 * [new branch]      webhook -> webhook
```

**Decision: break, with no warning level and no exception file.** It meets the rule easily: the
person who pushed can act at once, by revoking the secret, and nobody else can. The only entries
`.gitleaksignore` takes are secrets already revoked, which is a statement about the past, not a
permission. And the run stopped at the first stage, so no image and no later stage copied the
value anywhere.

The response is lesson 6's, in lesson 6's order: revoke, replace, remove, then decide about the
history. Deleting the branch on the server is the tidy-up, not the fix:

```
ana@vm:~/linkbox$ git push -q ci --delete webhook
ana@vm:~/linkbox$ git switch -q main && git branch -q -D webhook
```

The branch is gone, and the commit is still in the server's object store until Git
collects unreachable objects, as well as in the run's clone in `~/ci/runs`. That is the copies
argument from lesson 6 again, and why the revocation comes first.

### Case 5: a warning that is a false positive

Lesson 4 found that ZAP's rule 10031, *User Controllable HTML Element Attribute*, fires on the
search page, and that the response proves it false: Jinja escapes the reflected value. It is not
listed in `ci/zap-rules.conf`, so it warns. Lesson 2 runs the nightly checks by hand the way the
scheduler would, on a clean clone of `main`:

```
ana@vm:~/linkbox$ rm -rf /tmp/nightly && git clone -q ~/ci/linkbox.git /tmp/nightly
ana@vm:~/linkbox$ /tmp/nightly/ci/pipeline.sh && /tmp/nightly/ci/pipeline.sh ci/nightly
secrets: passed in 1s
test: passed in 1s
sast: passed in 3s
sca: passed in 10s
build: passed in 0s
pipeline passed with 0 warning(s)
rebuild: passed in 11s
dast: WARNING in 21s, the end of dast.log:
  PASS: Sub Resource Integrity Attribute Missing [90003]
  PASS: Charset Mismatch [90011]
  PASS: Application Error Disclosure [90022]
  PASS: WSDL File Detection [90030]
  PASS: Loosely Scoped Cookie [90033]
  WARN-NEW: User Controllable HTML Element Attribute (Potential XSS) [10031] x 1 
  	http://linkbox-staging-8690-app:8000/search?q=ZAP (200 OK)
  FAIL-NEW: 0	FAIL-INPROG: 0	WARN-NEW: 1	WARN-INPROG: 0	INFO: 0	IGNORE: 0	PASS: 60
pipeline passed with 1 warning(s)
```

Before this lesson, the same run said `dast: passed` and the warning was invisible. Now **it is one
counted warning, and the decision is to keep it as one**. Each alternative is worse in its own
way:

| choice | what it costs |
|---|---|
| FAIL | breaks every nightly run on a finding everybody agrees is false; the shortest road to switching the scan off |
| IGNORE | silences rule 10031 on every page, including the next one somebody writes that reflects a value without escaping it |
| OUTOFSCOPE for `/search` | the precise tool, and the next step: ZAP's configuration takes a rule, `OUTOFSCOPE` and a regular expression for the addresses where the rule is not to be applied |
| WARN, as now | one known line on a report read every morning |

While it is the only warning, WARN costs one line a day, and the line says the rule still runs. The
day the nightly report carries twenty warnings and this one is lost among them, the rule gets
scoped out of `/search`, with the reason, and every other page keeps it. **A warning budget is
worth naming**: a report somebody reads every morning stays read only while it is short.

### Case 6: a finding in code nobody calls

A branch adds an export for a quarterly report. It writes a file under `/tmp`, and nothing calls it
yet:

```
ana@vm:~/linkbox$ git switch -q -c export
ana@vm:~/linkbox$ git diff | grep '^+'
+++ b/app.py
+
+
+def export_links():
+    with open("/tmp/linkbox-export.csv", "w") as out:
+        for code, url in db().execute("SELECT code, url FROM links"):
+            out.write(f"{code},{url}\n")
ana@vm:~/linkbox$ git commit -q -am "an export of every link, for the quarterly report"
9:36AM INF 0 commits scanned.
9:36AM INF scanned ~187 bytes (187 bytes) in 188ms
9:36AM INF no leaks found
ana@vm:~/linkbox$ git push ci export
remote: run 6: export at 407638e        
remote: secrets: passed in 1s        
remote: test: passed in 2s        
remote: sast: FAILED in 2s, the end of sast.log:        
remote:   	Total lines skipped (#nosec): 0        
remote:   	Total potential issues skipped due to specifically being disabled (e.g., #nosec BXXX): 0        
remote:           
remote:   Run metrics:        
remote:   	Total issues (by severity):        
remote:   		Undefined: 0        
remote:   		Low: 0        
remote:   		Medium: 1        
remote:   		High: 0        
remote:   	Total issues (by confidence):        
remote:   		Undefined: 0        
remote:   		Low: 0        
remote:   		Medium: 1        
remote:   		High: 0        
remote:   Files skipped (0):        
remote: run 6: failed, the logs are in ~/ci/runs/6/logs        
To /home/ana/ci/linkbox.git
 * [new branch]      export -> export
```

The end of the log is Bandit's summary, one issue of medium severity. The issue itself is further
up:

```
ana@vm:~/linkbox$ grep -A3 ">> Issue" ~/ci/runs/6/logs/sast.log
>> Issue: [B108:hardcoded_tmp_directory] Probable insecure usage of temp file/directory.
   Severity: Medium   Confidence: Medium
   CWE: CWE-377 (https://cwe.mitre.org/data/definitions/377.html)
   More Info: https://bandit.readthedocs.io/en/1.9.4/plugins/b108_hardcoded_tmp_directory.html
```

Bandit's B108 is medium severity: a fixed path under `/tmp` is a name any other user of the machine
can create first, and then the export writes into their file. The developer's answer is that
nothing calls the function, so nothing is exposed.

**Decision: break, and delete the function.** "Nobody calls it" is a claim with no check behind
it, true today and false the day somebody wires the export to a route, and a static analyser
cannot tell the two days apart. Unlike case 2, this one is fixable now, by the person who
pushed it. There are three ways, cheapest first: delete it until it is needed; write it properly,
with `tempfile` choosing the path; or, if the path is genuinely right, put a `# nosec B108` on the
line with the reason, as lesson 3 argued for every suppression. Proving that code is unreachable costs
more than any of the three.

### The six, side by side

| case | verdict | the reason, in one line |
|---|---|---|
| an advisory with a fix | break | one pin, in the developer's own file |
| an advisory with no fix | warn | nothing in this change can fix it; somebody reads it |
| a fix that cannot land yet | pass, until a date | an exception: one advisory, a date, a reason, a name |
| a secret | break | its owner can always act, by revoking it, and every minute costs |
| a false positive in DAST | warn | proven false, kept visible, scoped out the day it becomes noise |
| a medium in code nobody calls | break | fixable now, and "nobody calls it" is not checked by anything |
