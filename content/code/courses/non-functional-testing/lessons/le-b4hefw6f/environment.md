---
title: The environment, and what it does not hide
version: 1
---

The usual advice is to keep secrets out of the code and put them in **environment variables**, and
it is good advice for one reason: the value stops being part of anything that gets committed. The
code says *read `PAYMENT_API_KEY`*, the machine says what it is, and the repository can be read by
anybody on the team without handing them the key. That is what `account.py` already does with
`ACCOUNT_DB`, `ACCOUNT_UPLOADS` and `ACCOUNT_SESSION_SECONDS`, none of which is a secret.

**What an environment variable does not do is hide the value from the machine it runs on.** This
section moves the key out of the repository into the environment, and then looks at who can still
read it there.

## The key in a file of its own, ignored

On a developer's machine the environment is usually filled from a small file that never leaves it.
In `~/leaky`, create `payment.env` with `nano payment.env`:

```sh
# leaky/payment.env
# The payment key, for this machine only. Never committed: *.env is in .gitignore.
PAYMENT_API_KEY=nft7Zq2vRmX9kLp4Tn8Wc3Yb6Hd1Jf5G
```

Then tell git never to take any file ending in `.env`, check that it listens, and scan the
directory again:

```
ana@nft:~/leaky$ echo '*.env' > .gitignore
ana@nft:~/leaky$ git status --short
?? .gitignore
ana@nft:~/leaky$ git check-ignore -v payment.env
.gitignore:1:*.env	payment.env
ana@nft:~/leaky$ git add .gitignore && git commit -q -m "keep env files out of the repository"
ana@nft:~/leaky$ gitleaks dir --no-banner --no-color --redact --verbose
Finding:     PAYMENT_API_KEY=REDACTED
Secret:      REDACTED
RuleID:      generic-api-key
Entropy:     4.875000
File:        payment.env
Line:        3
Fingerprint: payment.env:generic-api-key:3

4:53PM INF scanned ~360 bytes (360 bytes) in 4.37ms
4:53PM WRN leaks found: 1
```

`git status` lists the new `.gitignore` and **does not list `payment.env` at all**, and
`check-ignore` names the rule that hides it: line 1 of `.gitignore`, `*.env`. A `git add .` from
now on leaves it out.

And `gitleaks dir` reports it, which is right. The key is in a file on this disk, and that is what
a scan of the directory is for. The two scans now disagree for a reason worth remembering: `git`
says what the repository holds, and `dir` says what the machine holds. The `--redact` flag replaces
the value with `REDACTED` in the report, so that a scan's own output, kept in a pipeline's log,
does not become the next place the key leaks from.

## A service started with it

The pattern is the same for any program: fill the environment, then start the program, which
reads the value when it needs it. `account.py` has no use for a payment key, but it is a real
service on this machine and the question is the same for any process. Stop it if it is running,
and start it in its first terminal with the file loaded:

```
ana@nft:~/boxoffice$ set -a; . ~/leaky/payment.env; set +a
ana@nft:~/boxoffice$ python3 account.py
account on http://127.0.0.1:8001
```

`set -a` makes every variable the next command sets an exported one, so `. ~/leaky/payment.env`
puts `PAYMENT_API_KEY` into the environment of everything started from this terminal, and
`set +a` switches that off again. Now, from the second terminal, ask the system what the service
was started with:

```
ana@nft:~/boxoffice$ pgrep -f '^python3 account.py'
141
ana@nft:~/boxoffice$ tr '\0' '\n' < /proc/$(pgrep -f '^python3 account.py')/environ | grep KEY
PAYMENT_API_KEY=nft7Zq2vRmX9kLp4Tn8Wc3Yb6Hd1Jf5G
ana@nft:~/boxoffice$ ps eww -p $(pgrep -f '^python3 account.py') | grep -o 'PAYMENT_API_KEY=[^ ]*'
PAYMENT_API_KEY=nft7Zq2vRmX9kLp4Tn8Wc3Yb6Hd1Jf5G
ana@nft:~/boxoffice$ sudo -u nobody cat /proc/$(pgrep -f '^python3 account.py')/environ
cat: /proc/141/environ: Permission denied
```

**Anybody logged in as `ana` reads the key in one command**, from either of two places.
`/proc/<pid>/environ` holds the environment a process was started with, separated by zero bytes,
which `tr` turns into lines; `ps` with `e` prints the same thing after the command. The last line
is the boundary: `nobody` is another user on the same machine and gets `Permission denied`. The
environment is protected exactly as well as the account that runs the process, and no better.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l18-reach\" aria-label=\"A process, python3 account.py, started with PAYMENT_API_KEY in its environment, inside a dashed boundary labelled user ana. Inside the boundary, two ways to read the value, both allowed: the file /proc/&lt;pid&gt;/environ and the command ps eww. Outside the boundary, the user nobody asks for the same file and gets Permission denied. On the right, three ways the value leaves the process without anybody deciding it should: every child process inherits a copy, a log line or an error page can print it, and a crash report can collect it.\"><defs><marker id=\"l18-reach-nf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-reach-nf-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"360.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">protected as well as the account that runs it, and no better</text><path d=\"M30.0 44.0 L450.0 44.0 L450.0 220.0 L30.0 220.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"38.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">user ana</text><rect x=\"200.0\" y=\"76.0\" width=\"220.0\" height=\"62.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"310.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">python3 account.py</text><text x=\"310.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">PAYMENT_API_KEY=…</text><rect x=\"48.0\" y=\"160.0\" width=\"170.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"133.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/proc/&lt;pid&gt;/environ</text><rect x=\"240.0\" y=\"160.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"295.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ps eww</text><path d=\"M200.0 120.0 L150.0 158.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-reach-nf-ah-phosphor)\"></path><path d=\"M295.0 138.0 L295.0 158.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-reach-nf-ah-phosphor)\"></path><text x=\"372.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">reads it</text><rect x=\"48.0\" y=\"236.0\" width=\"110.0\" height=\"30.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"103.0\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">nobody</text><text x=\"170.0\" y=\"251.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">Permission denied</text><text x=\"590.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">and copies it carries out</text><rect x=\"490.0\" y=\"74.0\" width=\"200.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"590.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">every child process</text><path d=\"M420.0 107.0 L486.0 92.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-reach-nf-ah-amber)\"></path><rect x=\"490.0\" y=\"126.0\" width=\"200.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"590.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a log line, an error page</text><path d=\"M420.0 107.0 L486.0 144.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-reach-nf-ah-amber)\"></path><rect x=\"490.0\" y=\"178.0\" width=\"200.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"590.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a crash report</text><path d=\"M420.0 107.0 L486.0 196.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-reach-nf-ah-amber)\"></path></svg>", "caption": "The environment is readable by the account that runs the process, and travels with everything the process starts or prints."}
```

That is enough for a laptop. On a server it is the start of a list of places the value travels
without anybody deciding it should:

- **Child processes inherit it.** Everything the service starts, a shell command, a helper
  script, a crash reporter, receives a copy of the whole environment, key included.
- **Logs and error pages print it.** A debug page that lists the environment, a startup line that
  prints the configuration "to help", a CI job that runs `env` or traces its shell with `set -x`.
  Lesson 19 adds the rule that a log line never carries a secret.
- **Crash reports and support bundles collect it.** Error-tracking tools can capture the
  environment and local variables with every exception, and a diagnostic bundle attached to a
  ticket often includes both.
- **Container and orchestration tools show it.** The environment of a container is part of its
  configuration, readable by anybody allowed to inspect it.

## Where secrets go on a real deployment

A **secret manager** is a service whose whole job is to hold secrets: it stores them encrypted,
hands each one only to the identity allowed to read it, writes down every read, and can rotate a
value without a deployment. HashiCorp Vault, AWS Secrets Manager, Google Cloud Secret Manager and
Azure Key Vault are the common ones. A CI system has its own smaller version, such as GitHub
Actions secrets or GitLab's CI/CD variables, which also mask the value in the job's log. **The
application asks for the value at start-up, and the value never exists in any file the team
writes.**

Two rules hold whichever is used, and a tester can check both by reading the code:

- **A secret has no default.** `ACCOUNT_DB` has a default, `data/account.db`, and that is right:
  a missing path should not stop the service. A missing payment key should, so the code reads it
  as `os.environ["PAYMENT_API_KEY"]`, which raises an error at start-up, and never with a default
  value written next to it, which would put a working key back in the file.
- **A secret is never printed.** Not in a startup line, not in an error message, not in a test's
  output. If something has to show that a key is set, it shows that it is set.
