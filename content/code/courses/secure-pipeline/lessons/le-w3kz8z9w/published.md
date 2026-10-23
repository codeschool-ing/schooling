---
title: A secret in Git is a secret published
version: 1
---

linkbox has carried its administration token in `settings.py` since the day it was handed over,
and lesson 3 left Bandit's low-severity warning about it for this lesson. The usual way to think
about it is that the repository is private, so the token is seen by the team and nobody else. That
picture is wrong in two ways, and both decide what the response has to be.

**A commit is not a change to a file. It is a snapshot of every file, and every clone copies every
snapshot.** Deleting the line tomorrow adds a sixth snapshot without the token; the five before it
still have it, in every copy of the repository that exists.

### Count the copies

Ask your own repository which of its commits hold the token. `git rev-list --all` names every
commit, and `git grep` searches the files of each one:

```
ana@vm:~$ cd linkbox
ana@vm:~/linkbox$ git rev-list --all | wc -l
5
ana@vm:~/linkbox$ git grep -l lbx_7Rq2 $(git rev-list --all)
19d07382f253145808a4b99c02849049c0355c42:settings.py
d1186dff5922c15623d2ade11437f5298686abca:settings.py
3afa289dec6ea8fa854b60518eecb2feb97971cb:settings.py
ed9bbb4ba57f364006501e459dbcab550bea50c8:settings.py
3f932db1ab33201959dc1dd9270d46dc0485e297:settings.py
ana@vm:~/linkbox$ git -C ~/ci/linkbox.git grep -n lbx_7Rq2 main -- settings.py
main:settings.py:4:ADMIN_TOKEN = "lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x"
```

**All five commits carry it**, not only the first, because every snapshot after the first kept the
file as it was. The last command asks the CI server, which holds its own copy of the whole history:
lesson 1 pushed to it, and every push since has added to it. That is two repositories on one
laptop, and each pipeline run of the earlier lessons cloned a third into `~/ci/runs/N/src`.

On a team the count grows without anybody deciding it. Every developer has a clone, and so has every
CI runner that ever built the project. A fork on a hosted platform is another full copy, made by
somebody else and kept under their account. Backups of the server copy it again. None of these is
told when you delete a line, and none of them shrinks when somebody leaves the team.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"sp-l06-copies\" aria-label=\"Where linkbox's history, and the token with it, is copied. On your machine: ~/linkbox, where five commits hold it; the CI server ~/ci/linkbox.git, which received every push; and ~/ci/runs/N/src, one full clone per pipeline run. On a team, as well: a colleague's clone, a fork on a hosted platform and a backup of the server, each with the whole history.\"><defs><marker id=\"sp-l06-copies-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l06-copies-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l06-copies-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"118\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"24\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">your machine</text><rect x=\"25\" y=\"50\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">~/linkbox</text><text x=\"115.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5 commits hold it</text><rect x=\"265\" y=\"50\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">~/ci/linkbox.git</text><text x=\"360.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5 commits hold it</text><rect x=\"515\" y=\"50\" width=\"185\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"607.5\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">~/ci/runs/N/src</text><text x=\"607.5\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a full clone per run</text><path d=\"M205 78 L263 78\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l06-copies-ah-phosphor)\"></path><text x=\"234\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">git push</text><path d=\"M455 78 L513 78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l06-copies-ah-paper-dim)\"></path><text x=\"484\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">clone</text><rect x=\"10\" y=\"150\" width=\"700\" height=\"128\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"24\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on a team, as well</text><rect x=\"25\" y=\"200\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"120.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a colleague's clone</text><text x=\"120.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the whole history</text><rect x=\"265\" y=\"200\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a fork</text><text x=\"360.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the whole history</text><rect x=\"505\" y=\"200\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a backup</text><text x=\"600.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the whole history</text><path d=\"M360 106 L360 135 L120 135 L120 198\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l06-copies-ah-amber)\"></path><path d=\"M360 135 L360 198\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l06-copies-ah-amber)\"></path><path d=\"M360 135 L600 135 L600 198\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l06-copies-ah-amber)\"></path></svg>", "caption": "Every box holds the whole history and the token with it. A commit that deletes the line changes nothing any of them already holds."}
```

### Private is a list of people, and the list changes

A private repository is readable by whoever is on its access list today, and by everybody who was
on it on any day since the secret was committed. The contractor who left in March still has the
clone they made in February. A repository made public a year later publishes every commit in it,
and making a repository public is a setting somebody changes in a minute. Verizon's yearly Data
Breach Investigations Report has put stolen credentials at or near the top of its list of ways in
for years, and the leak is rarely somebody breaking in to read a repository: it is a repository
read by somebody who was allowed to, once.

So the rule this lesson works from is a strict one. **A secret that was committed has been
published to everybody who could ever read the repository**, and the response is the one you would
give to a published secret: it stops working first, and the cleaning comes after.

### What counts as a secret

Anything that grants access by being known: an API token like linkbox's, a password, a private key,
a database connection string with a password in it, a webhook's signing secret, a session cookie
somebody pasted into a bug report. A public key is not one, and neither is a value made only for
the tests that opens nothing anywhere else, which is exactly what this lesson gives the tests in
`tests/conftest.py`.

A scanner cannot know which strings grant access. It guesses from two things a person would also
notice: the shape of the value, where a provider's tokens carry a known prefix and length, and the
words around it, such as `TOKEN`, `KEY` or `PASSWORD`, together with how random the value looks.
The next section runs one, and the lines it prints show both guesses at work.
