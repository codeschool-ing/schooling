---
title: A hook that refuses the commit
version: 1
---

Everything so far found the key after it was committed. **The cheapest place to stop a secret is
one step earlier, before the commit exists**, because a commit that was never made needs no
rotation and no rewritten history. git can run a program of your choosing at that moment, a
**pre-commit hook**, and refuse the commit when the program fails.

## The hook

A hook is an executable file in `.git/hooks/`, named after the moment it runs. In `~/leaky`, open
`nano .git/hooks/pre-commit`, paste this in, and make it executable with the `chmod` below:

```sh
#!/bin/sh
# leaky/.git/hooks/pre-commit
# Refuses the commit when what is staged looks like a secret. Prints no secret.
exec gitleaks git --pre-commit --staged --redact --verbose --no-banner --no-color
```

`--pre-commit --staged` tells gitleaks to read **only what is about to be committed**, the staged
changes, rather than the history; that keeps the hook as fast as a commit should be. `--redact`
keeps the value out of the terminal, and `--verbose` says which file and line to fix. `exec`
hands gitleaks's exit code straight back to git, and a code other than 0 is a refusal.

Now repeat the afternoon mistake: copy the key into the settings file to try the provider, and
commit.

```
ana@nft:~/leaky$ chmod +x .git/hooks/pre-commit
ana@nft:~/leaky$ grep KEY payment.env >> settings.ini
ana@nft:~/leaky$ git commit -am "try the payment provider"
Finding:     PAYMENT_API_KEY=REDACTED
Secret:      REDACTED
RuleID:      generic-api-key
Entropy:     4.875000
File:        settings.ini
Line:        7
Fingerprint: settings.ini:generic-api-key:7

4:53PM INF 0 commits scanned.
4:53PM INF scanned ~49 bytes (49 bytes) in 57ms
4:53PM WRN leaks found: 1
ana@nft:~/leaky$ git status --short
 M settings.ini
ana@nft:~/leaky$ git restore settings.ini
```

**The commit was refused.** git printed nothing of its own; the finding is the hook's output, with
the value redacted, the file and the line. `git status` shows `settings.ini` still modified and
not committed, and `git restore` puts it back as the last commit had it. Nothing reached the
history, so there is nothing to rotate.

## A hook is a convenience, not a control

Two facts keep the hook from being the whole answer. **It lives in `.git/`, which is not part of
the repository**, so a fresh clone has no hook until somebody installs one; and **anybody can skip
it** with `--no-verify`, which exists for good reasons and gets used for bad ones. Watch what that
leaves behind, and what catches it:

```
ana@nft:~/leaky$ grep KEY payment.env >> settings.ini
ana@nft:~/leaky$ git commit -q --no-verify -am "try the payment provider"
ana@nft:~/leaky$ gitleaks git --no-banner --no-color --redact
4:53PM INF 4 commits scanned.
4:53PM INF scanned ~310 bytes (310 bytes) in 50.5ms
4:53PM WRN leaks found: 2
ana@nft:~/leaky$ git reset -q --hard HEAD~1
ana@nft:~/leaky$ git log --oneline
7734329 keep env files out of the repository
d35bad3 take the key out of the settings
ad0a6bc payment settings
```

The commit went in. The scan of the history, the one meant to run in the pipeline on every push,
**now reports two leaks**: the old one in `ad0a6bc` and the new one. That is the layer that does
not depend on anybody's machine or anybody's discipline. It is why a team runs both: the hook
so that most mistakes never become commits, the pipeline so that the ones that do never reach the
shared branch unnoticed.

The last two commands remove the bad commit. **That is only safe because it was never pushed**:
`git reset` rewrites history on this machine alone, and nobody else has a copy. Had it been pushed,
this would be the situation of "How a key ends up in a repository", and the first step would be
rotation.

Teams that want the hook on every machine use the pre-commit framework, from pre-commit.com, which
installs hooks from a file committed to the repository; gitleaks publishes a hook for it. It
downloads its hooks from GitHub, so it was not run here, and it changes nothing above: the hook
still runs on a machine somebody controls, and the pipeline is still the check that counts.

## A finding that has been dealt with

One finding is left, and it will be reported on every push for as long as the history exists:
`ad0a6bc`, the key committed and deleted at the start of this lesson. Suppose it was real and was
rotated this morning. The history still holds it, the scan is still right to say so, and a
pipeline that fails on every push teaches everybody to ignore it.

The answer is to record that this particular finding was handled, by its fingerprint, in a
`.gitleaksignore` file committed beside the code, with a line saying what was done and by whom:

```
ana@nft:~/leaky$ printf '%s\n' '# The payment key of ad0a6bc was revoked and replaced on 2026-10-01 (ana).' 'ad0a6bc9d70d4677797a3da73054ec968696f1b0:settings.ini:generic-api-key:7' > .gitleaksignore
ana@nft:~/leaky$ cat .gitleaksignore
# The payment key of ad0a6bc was revoked and replaced on 2026-10-01 (ana).
ad0a6bc9d70d4677797a3da73054ec968696f1b0:settings.ini:generic-api-key:7
ana@nft:~/leaky$ git add .gitleaksignore && git commit -q -m "record the revoked payment key"
4:53PM INF 0 commits scanned.
4:53PM INF scanned ~147 bytes (147 bytes) in 49.2ms
4:53PM INF no leaks found
ana@nft:~/leaky$ gitleaks git --no-banner --no-color; echo "exit $?"
4:53PM INF 4 commits scanned.
4:53PM INF scanned ~408 bytes (408 bytes) in 46.9ms
4:53PM INF no leaks found
exit 0
```

The commit of `.gitleaksignore` went through the hook, which scanned it and found nothing. The
history scan now reports **no leaks and exits 0**, and every new finding still fails it, because
the fingerprint names one commit, one file, one rule and one line. That is the difference between
accepting a known finding and switching the rule off. The same file is where a reviewed false
positive goes, a value that matched a rule and is not a secret, always with the reason beside it.

**Every line of a `.gitleaksignore` is a decision somebody made, and the file is reviewed like
code.** A fingerprint added without a reason, or for a key that was never rotated, is the hole the
pipeline was built to close.
