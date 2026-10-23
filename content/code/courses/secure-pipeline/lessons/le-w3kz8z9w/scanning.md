---
title: Scanning the files and the history
version: 1
---

gitleaks is a secret scanner: a single program, a set of rules written as regular expressions, and
two ways of reading a repository. **`gitleaks dir` reads the files as they are on disk. `gitleaks
git` reads every commit's changes, from the first commit to the last.** The first answers whether
a secret is in the code now. The second answers whether one was ever in it, which after the last
section is the question that matters.

### Installing it

The same way lesson 1 installed uv: the release, its published checksum, `install`. From your home
directory:

```
ana@vm:~$ curl -fsSLO https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_x64.tar.gz
ana@vm:~$ curl -fsSL https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_checksums.txt | grep linux_x64.tar.gz | sha256sum --check
gitleaks_8.30.1_linux_x64.tar.gz: OK
ana@vm:~$ tar -xzf gitleaks_8.30.1_linux_x64.tar.gz gitleaks
ana@vm:~$ install -m 755 gitleaks ~/.local/bin/ && rm gitleaks gitleaks_8.30.1_linux_x64.tar.gz
ana@vm:~$ gitleaks version
8.30.1
```

`sha256sum --check` prints `OK` only when the file you downloaded is the file the project
published. The archive also holds a licence and a README; the `tar` command takes only the binary.

### The files, as they are now

Run it from the project, with `-v` so that each finding is printed whole rather than only counted:

```
ana@vm:~/linkbox$ gitleaks dir --no-banner --no-color -v .
Finding:     ADMIN_TOKEN = "lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x"
Secret:      lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x
RuleID:      generic-api-key
Entropy:     5.058814
File:        settings.py
Line:        4
Fingerprint: settings.py:generic-api-key:4

2:00AM INF scanned ~35843 bytes (35.84 KB) in 31.7ms
2:00AM WRN leaks found: 1
```

Each field answers a question a person triaging the finding would ask:

| field | what it says |
|---|---|
| `Finding` | the line as written, so you can see what it is without opening the file |
| `Secret` | the part of the line the rule matched |
| `RuleID` | which rule matched: `generic-api-key` is the catch-all, explained below |
| `Entropy` | how random the matched value is, in bits per character |
| `File`, `Line` | where it is |
| `Fingerprint` | an identity for this one finding, used to mark it as handled |

**The exit status is the verdict**: gitleaks exits 1 when it finds anything and 0 when it finds
nothing, which is what lets a pipeline stage use it with no glue. `--no-banner` drops the logo it
prints first and `--no-color` the colour codes, which a log file shows as noise.

### The history

The same scan over every commit:

```
ana@vm:~/linkbox$ gitleaks git --no-banner --no-color -v .
2:00AM INF Unknown SCM platform. Use --platform to include links in findings. host=
Finding:     ADMIN_TOKEN = "lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x"
Secret:      lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x
RuleID:      generic-api-key
Entropy:     5.058814
File:        settings.py
Line:        4
Commit:      3f932db1ab33201959dc1dd9270d46dc0485e297
Author:      Ana Lima
Email:       ana@example.org
Date:        2026-10-05T13:00:00Z
Fingerprint: 3f932db1ab33201959dc1dd9270d46dc0485e297:settings.py:generic-api-key:4

2:00AM INF 5 commits scanned.
2:00AM INF scanned ~8969 bytes (8.97 KB) in 224ms
2:00AM WRN leaks found: 1
```

**It reports the token once, in the first commit, though the last section counted five commits that
hold it.** `gitleaks git` reads what each commit *added*, the lines `git log -p` shows with a `+`,
so a value added once and never touched again is one finding, in the commit that brought it in. The
`Commit` line names that commit in full, along with its author and date, and the fingerprint now
starts with the commit too, because the same line in two commits would be two findings.

That date is the start of the window the next section has to close: the token has been readable by
anybody with the repository since the morning of 5 October. On your machine the commit, its date
and the fingerprint are your own, because your first commit was made at a different moment by a
different person.

### Generic rules and specific ones

gitleaks ships with rules for the tokens of a long list of providers: cloud keys, GitHub and GitLab
tokens, payment providers, chat webhooks. **Those rules are precise** because the tokens are
designed to be found, with a fixed prefix and length. A GitHub personal access token starts with
`ghp_`, and nothing else does by accident.

linkbox's token is its own invention, so no specific rule knows it, and `generic-api-key` caught
it: a word such as `token`, `key` or `secret` in the name being assigned, and a value random enough
to be one. The entropy line is that second test, measured. **The generic rule is the noisy one.** It
misses a token whose variable is called `ADMIN` and flags a long random identifier that opens
nothing. Both kinds of mistake are why a finding is triaged by a person, and why the triage is
written down, as the lesson's history section does with this one.

If your own project mints tokens, give them a prefix of their own, as `lbx_` is here. It is the
cheapest thing you can do for every scanner that will ever read your code: a rule for them is one
line, and it is never confused with anything else.

### Neither scan reads everything

`gitleaks git` reads the commits of the repository it is given, so a branch that exists only in a
colleague's clone is not in it, and neither is a file somebody attached to a ticket. `gitleaks
dir` reads the directory you name. The CI server's copy is the one place where every branch that
was pushed ends up, which is why the pipeline stage at the end of this lesson scans the history
there, on every push.
