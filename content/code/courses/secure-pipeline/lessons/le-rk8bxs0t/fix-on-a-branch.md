---
title: An automatic fix, judged by the pipeline
version: 1
---

A bot's change is a change like any other, and the pipeline is what judges it. This section makes
that concrete on the branch with the month-old lock. First the pipeline finds the advisory; then a
tool that writes fixes for you makes one; then the pipeline judges the fix.

### The pipeline finds it

Push the branch to the CI server. Every branch runs the pipeline:

```
ana@vm:~/linkbox$ git push ci stale-lock
remote: run 2: stale-lock at 159779d        
remote: secrets: passed in 1s        
remote: workflows: passed in 0s        
remote: test: passed in 1s        
remote: sast: passed in 4s        
remote: sca: FAILED in 7s, the end of sca.log:        
remote:   Found 1 known vulnerability in 1 package        
remote:   BREAKS: werkzeug 3.1.8 PYSEC-2026-4312, fixed in 3.1.9        
remote: run 2: failed, the logs are in ~/ci/runs/2/logs        
To /home/ana/ci/linkbox.git
 * [new branch]      stale-lock -> stale-lock
```

The composition stage broke the build, with lesson 7's gate saying why: werkzeug 3.1.8 has an
advisory, PYSEC-2026-4312, with a fixed version, 3.1.9. On 20 September there was nothing to report,
because the fix and the advisory both came after. **A lock that was safe when it was compiled is not
safe for ever**, and this is how it shows: nothing in the branch changed, and the verdict did.

### The automatic fix

pip-audit can fix what it finds. `--fix` moves each vulnerable package to the first version that
fixes its advisories and writes the result back into the requirements files:

```
ana@vm:~/linkbox$ pip-audit --fix -r requirements.txt -r requirements-dev.txt
WARNING:pip_audit._dependency_source.requirement:added fixed subdependency explicitly to requirements file requirements-dev.txt: werkzeug
Found 1 known vulnerability in 1 package and fixed 1 vulnerability in 1 package
Name     Version ID              Fix Versions Applied Fix
-------- ------- --------------- ------------ -----------------------------------------------
werkzeug 3.1.8   PYSEC-2026-4312 3.1.9        Successfully upgraded werkzeug (3.1.8 => 3.1.9)
ana@vm:~/linkbox$ grep -A2 "^werkzeug" requirements.txt requirements-dev.txt
requirements.txt:werkzeug==3.1.9 \
requirements.txt-    --hash=sha256:63a77fb8892bf28ebc3178683445222aa500e48ebad5ec77b0ad80f8726b1f50 \
requirements.txt-    --hash=sha256:9bad61a4268dac112f1c5cd4630a56ede601b6ed420300677a869083d70a4c44
--
requirements-dev.txt:werkzeug==3.1.9
ana@vm:~/linkbox$ git diff --stat
 requirements-dev.txt | 12 +++++++-----
 requirements.txt     | 24 ++++++++++++------------
 2 files changed, 19 insertions(+), 17 deletions(-)
```

It reports success, and the version line agrees: `werkzeug==3.1.9`. Read the two lines under it.
**Those hashes belong to werkzeug 3.1.8**; they are the same two hashes the stale lock had. pip-audit
edited the version and left the rest of the entry alone, and it made two more changes nobody asked
for: it added werkzeug to `requirements-dev.txt` as a pin of its own, with no hash at all, saying so in
its warning; and it rewrote the indentation of the `# via` comments, which is most of the diff's
36 changed lines.
`requirements.in` still says nothing about werkzeug, so the next compile would undo the fix.

Nothing in that output looks wrong unless you know what a hash line is for. Commit it as a bot
would, and let the pipeline judge:

```
ana@vm:~/linkbox$ git commit -q -am "pip-audit --fix"
10:18AM INF 0 commits scanned.
10:18AM INF scanned ~313 bytes (313 bytes) in 207ms
10:18AM INF no leaks found
ana@vm:~/linkbox$ git push ci stale-lock
remote: run 3: stale-lock at b5392bd        
remote: secrets: passed in 1s        
remote: workflows: passed in 0s        
remote: test: FAILED in 0s, the end of test.log:        
remote:   error: In `--require-hashes` mode, all requirements must have a hash, but none were provided for: werkzeug==3.1.9        
remote: run 3: failed, the logs are in ~/ci/runs/3/logs        
To /home/ana/ci/linkbox.git
   159779d..b5392bd  stale-lock -> stale-lock
```

The tests stage broke, before any scanner ran, and uv names the first thing it refused: in
`--require-hashes` mode every requirement needs a hash, and the pin pip-audit added to
`requirements-dev.txt` has none. That is only the first refusal. Install `requirements.txt` on its
own, into a scratch environment, and the second is waiting; the last six lines of uv's error are
the part that matters:

```
ana@vm:~/linkbox$ uv venv -q /tmp/hashcheck
ana@vm:~/linkbox$ uv pip install -q --python /tmp/hashcheck --require-hashes -r requirements.txt 2>&1 | tail -n 6
      Expected:
        sha256:63a77fb8892bf28ebc3178683445222aa500e48ebad5ec77b0ad80f8726b1f50
        sha256:9bad61a4268dac112f1c5cd4630a56ede601b6ed420300677a869083d70a4c44

      Computed:
        sha256:6392e50c78460ba618e5b21f08a71f59c99ce99cdc6cf6e3dd7e6ccca8754fab
```

uv downloaded werkzeug 3.1.9, computed its hash, and found it was neither of the two the lock expects, because those belong to 3.1.8. **Both refusals are lesson 15's control working as designed**: a pin with no hash, or with
the hash of a different file, is exactly what tampering would look like, and the installer cannot
tell an honest mistake from an attack, so it refuses both. The automatic fix did not fix the build;
it moved the failure from the security gate to the install.

### The fix a lock wants

Revert the bot's commit, which puts the stale lock back as a new commit rather than rewriting a
branch the CI server already has, and make the change the way lesson 15 made every change to the
lock: compile again. `-P werkzeug` lets uv move that one package and keeps every other pin as the file
has it, and the new `--exclude-newer` date allows the fixed release:

```
ana@vm:~/linkbox$ git revert --no-edit HEAD
[stale-lock 4709680] Revert "pip-audit --fix"
 Date: Fri Oct 23 10:18:28 2026 -0300
 2 files changed, 17 insertions(+), 19 deletions(-)
ana@vm:~/linkbox$ uv pip compile -q requirements.in --generate-hashes --exclude-newer 2026-10-16 -P werkzeug -o requirements.txt
ana@vm:~/linkbox$ git diff
diff --git a/requirements.txt b/requirements.txt
index 39214f3..e765172 100644
--- a/requirements.txt
+++ b/requirements.txt
@@ -1,5 +1,5 @@
 # This file was autogenerated by uv via the following command:
-#    uv pip compile requirements.in --generate-hashes --exclude-newer 2026-09-20 -o requirements.txt
+#    uv pip compile requirements.in --generate-hashes --exclude-newer 2026-10-16 -o requirements.txt
 blinker==1.9.0 \
     --hash=sha256:b4ce2265a7abece45e7cc896e98dbebe6cead56bcf805a3d23136d145f5445bf \
     --hash=sha256:ba0efaa9080b619ff2f3459d1d500c57bddea4a6b424b60a91141db6fd2f08bc
@@ -118,7 +118,7 @@ markupsafe==3.0.3 \
     #   flask
     #   jinja2
     #   werkzeug
-werkzeug==3.1.8 \
-    --hash=sha256:63a77fb8892bf28ebc3178683445222aa500e48ebad5ec77b0ad80f8726b1f50 \
-    --hash=sha256:9bad61a4268dac112f1c5cd4630a56ede601b6ed420300677a869083d70a4c44
+werkzeug==3.1.9 \
+    --hash=sha256:55ca7c70a75689be937aa27f8ff4b018f06ff4838fc73045560bf0f5a1291060 \
+    --hash=sha256:6392e50c78460ba618e5b21f08a71f59c99ce99cdc6cf6e3dd7e6ccca8754fab
     # via flask
```

The diff is the header line, which records the new command, and three lines of werkzeug: a new
version and the two hashes that go with it. Push it:

```
ana@vm:~/linkbox$ git commit -q -am "werkzeug 3.1.9, for PYSEC-2026-4312"
10:18AM INF 0 commits scanned.
10:18AM INF scanned ~287 bytes (287 bytes) in 213ms
10:18AM INF no leaks found
ana@vm:~/linkbox$ git push ci stale-lock
remote: run 4: stale-lock at 3576bfa        
remote: secrets: passed in 0s        
remote: workflows: passed in 1s        
remote: test: passed in 1s        
remote: sast: passed in 3s        
remote: sca: passed in 8s        
remote: build: passed in 3s        
remote: image: passed in 1s        
remote: push: passed in 1s        
remote: sbom: passed in 4s        
remote: sign: passed in 2s        
remote: pipeline passed with 0 warning(s)        
remote: run 4: passed        
To /home/ana/ci/linkbox.git
   b5392bd..3576bfa  stale-lock -> stale-lock
```

Every stage passes. pluggy 1.6.0, markupsafe 3.0.3 and iniconfig 2.3.0 are still old, and that is
fine: they carry no advisory, and they are the routine updates the bots will propose on a Monday,
after their cooldown.

### What this says about automatic fixes

| | `pip-audit --fix` | `uv pip compile -P werkzeug` |
|---|---|---|
| finds the version that fixes the advisory | yes | no, you name the package |
| knows the file is a compiled lock | no | yes, it wrote it |
| writes hashes for the new version | no, and adds a pin with none | yes |
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
