---
title: Before the commit, a hook; before the push, the platform
version: 1
---

Everything so far has been the response to a secret that got in. The cheapest secret to deal with
is the one that never reached a commit, because a commit is the first copy. **A pre-commit hook
scans what you are about to commit, on your own laptop, and refuses the commit if it finds
anything.** Nothing has been copied anywhere yet, so there is nothing to revoke.

### The hook

Git runs `.git/hooks/pre-commit` before it writes a commit, and a hook that exits with anything but
0 stops the commit. `gitleaks git --pre-commit --staged` scans only what is staged, which is a few
lines and takes a fraction of a second, short enough that nobody is tempted to turn it off.
`--verbose` makes the refusal say where the secret is, and `--redact` keeps the value itself out
of the terminal, which may be shared on a call or recorded. Save it as
`~/linkbox/.git/hooks/pre-commit`:

```sh
#!/bin/sh
# Refuse a commit that adds a secret. Only what is staged is scanned, so it
# takes a fraction of a second; the pipeline still reads the whole history.
exec gitleaks git --pre-commit --staged --no-banner --no-color --redact --verbose
```

Like the CI server's hook in lesson 1, it runs only if it is executable:

```
ana@vm:~/linkbox$ chmod +x .git/hooks/pre-commit
```

### The hook, refusing

Somebody is writing an export to a reporting service and pastes the service's key into the code
to try it. The key here is made up and opens nothing; the hook cannot tell, and should not try:

```
ana@vm:~/linkbox$ printf "EXPORT_KEY = \"kq83JdZ0p1Vx7LmN4tR6sW9yB2cF5hG8\"\n" > export.py
ana@vm:~/linkbox$ git add export.py
ana@vm:~/linkbox$ git commit -m "export the links to the reporting service"
Finding:     EXPORT_KEY = "REDACTED"
Secret:      REDACTED
RuleID:      generic-api-key
Entropy:     4.937500
File:        export.py
Line:        1
Fingerprint: export.py:generic-api-key:1

2:00AM INF 0 commits scanned.
2:00AM INF scanned ~48 bytes (48 bytes) in 202ms
2:00AM WRN leaks found: 1
ana@vm:~/linkbox$ git log --oneline -1
cecdf72 the rotated token, recorded as a dead finding
ana@vm:~/linkbox$ git restore --staged export.py && rm export.py
```

**The commit was not made.** `git log` still shows the last commit before it, and the file is still
staged, untouched, waiting for its author to decide. The way out is the one the rest of this
lesson argues for: the key goes into the environment, read the way `settings.py` now reads
`LINKBOX_TOKEN`, and the file is staged again without it. If the key had really been pasted from
the service's console, it has still not left the laptop, and nothing about it needs revoking.

### What the hook does not do

**A hook is a convenience for the person committing, and it is not a control.** Three reasons, each
a fact about Git rather than about gitleaks:

- Hooks live in `.git/hooks`, which is not part of the repository. A clone gets none of them, so
  every developer has to install it on every clone, and a new colleague starts without it.
- `git commit --no-verify` skips it, and so does any tool that commits on somebody's behalf.
- It reads only what is staged in this commit, on this laptop. A secret that arrived some other
  way, in a merge or in a branch from somebody without the hook, never passes through it.

Tools exist that install and update hooks for a whole team from a file in the repository; the
pre-commit framework is the common one in Python projects. They solve the first reason and neither
of the other two. **What is enforced runs on the server**, where nobody can skip it: the pipeline
stage of the next section, which reads the whole history on every push. The hook only makes that
stage fail less often.

### Push protection on hosted platforms

Hosted platforms add a layer between the two. GitHub's documentation describes push protection: on
a repository where it is turned on, a push that contains a secret matching one of the providers'
token formats GitHub knows is refused before it lands, and the person pushing sees which secret and
where. They can bypass it by choosing a reason, such as a test value or a false positive, , and the
bypass is recorded where the repository's administrators can see it. GitLab documents a similar
feature under the name secret push protection.

It sits on the server, so it cannot be skipped by a missing hook, and it refuses before the secret
reaches the repository, which the pipeline stage cannot do: by the time a pipeline runs, the commit
has been pushed. Its limit is the shape of what it recognises. It looks for the formats of known
providers, so a token of your own invention, like linkbox's `lbx_` token, passes it unless you add
a custom pattern. **None of this was run for this course**: it needs a hosted repository, and the
lab is your own machine. The layers it describes are drawn below, with what each one sees.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"sp-l06-layers\" aria-label=\"Three places a secret can be stopped, in the order a change passes them. The pre-commit hook, on your laptop, reads what is staged and is skipped by --no-verify or a clone without it. Push protection, on a hosted platform, reads the pushed commits for known providers' token formats; it was not run for this course. The pipeline stage, on the CI server, reads the whole history on every push and cannot be skipped.\"><defs><marker id=\"sp-l06-layers-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"200\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pre-commit hook</text><text x=\"120\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">on your laptop</text><text x=\"120\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">reads what is staged</text><text x=\"120\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">skipped by --no-verify</text><rect x=\"260\" y=\"50\" width=\"200\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">push protection</text><text x=\"360\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">on a hosted platform</text><text x=\"360\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">known providers' formats</text><text x=\"360\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">not run for this course</text><rect x=\"500\" y=\"50\" width=\"200\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pipeline stage</text><text x=\"600\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">on the CI server</text><text x=\"600\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">reads the whole history</text><text x=\"600\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nobody can skip it</text><path d=\"M220 115 L258 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l06-layers-ah-paper-dim)\"></path><path d=\"M460 115 L498 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l06-layers-ah-paper-dim)\"></path><text x=\"120\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">when you commit</text><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">when you push</text><text x=\"600\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">after the push</text></svg>", "caption": "Three places a secret can be stopped. The last one reads everything and cannot be skipped; the first two make it fail less often."}
```
