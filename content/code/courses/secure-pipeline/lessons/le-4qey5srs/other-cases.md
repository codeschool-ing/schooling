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

@@CAPTURE secret@@

**Decision: break, with no warning level and no exception file.** It meets the rule easily: the
person who pushed can act at once, by revoking the secret, and nobody else can. The only entries
`.gitleaksignore` takes are secrets already revoked, which is a statement about the past, not a
permission. And the run stopped at the first stage, so no image and no later stage copied the
value anywhere.

The response is lesson 6's, in lesson 6's order: revoke, replace, remove, then decide about the
history. Deleting the branch on the server is the tidy-up, not the fix:

@@CAPTURE secret-cleanup@@

The branch is gone from the list, and the commit is still in the server's object store until Git
collects unreachable objects, as well as in the run's clone in `~/ci/runs`. That is the copies
argument from lesson 6 again, and why the revocation comes first.

### Case 5: a warning that is a false positive

Lesson 4 found that ZAP's rule 10031, *User Controllable HTML Element Attribute*, fires on the
search page, and that the response proves it false: Jinja escapes the reflected value. It is not
listed in `ci/zap-rules.conf`, so it warns. Lesson 2 runs the nightly checks by hand the way the
scheduler would, on a clean clone of `main`:

@@CAPTURE nightly@@

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

@@CAPTURE deadcode@@

Bandit's B108 is medium severity: a fixed path under `/tmp` is a name any other user of the machine
can create first, and then the export writes into their file. The developer's answer is that
nothing calls the function, so nothing is exposed.

**Decision: break, and delete the function.** "Nobody calls it" is a claim with no check behind
it, true today and false the day somebody wires the export to a route, and a static analyser
cannot tell the two days apart. Unlike case 2, this one is fixable now and by the person who
pushed it, in one of three ways, cheapest first: delete it until it is needed; write it properly,
with `tempfile` choosing the path; or, if the path is genuinely right, a `# nosec B108` on the line
with the reason, as lesson 3 argued for every suppression. Proving that code is unreachable costs
more than any of the three.

### The six, side by side

| case | verdict | the reason, in one line |
|---|---|---|
| an advisory with a fix | break | one pin, in the developer's own file |
| an advisory with no fix | warn | nobody can act by changing this change; somebody reads it |
| a fix that cannot land yet | pass, until a date | an exception: one advisory, a date, a reason, a name |
| a secret | break | its owner can always act, by revoking it, and every minute costs |
| a false positive in DAST | warn | proven false, kept visible, scoped out the day it becomes noise |
| a medium in code nobody calls | break | fixable now, and "nobody calls it" is not checked by anything |
