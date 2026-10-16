---
title: How a key ends up in a repository
version: 1
---

A **secret** is any value that lets whoever holds it act as the system: an API key for the payment
provider, a database password, the key that signs session cookies, a token for the cloud account.
It works for anybody who has it, the way a key to a door does, and that is the whole problem.
Nobody commits one on purpose. **It arrives in a repository the way every other mistake does: on
an ordinary afternoon, in a hurry, through a file that looked harmless.**

## The usual ways in

- **A settings file** that holds the key "just for now", because the code reads its settings from
  there and the environment variable was not set up yet.
- **A test or a script** with the key pasted in to try the provider once, committed together with
  the change that made the test pass.
- **A file that should have been ignored**: a `.env`, a copy of the production configuration, a
  database dump, a notebook whose output cells printed the configuration.
- **A log or an error message** that printed the key, saved into a file that was then committed
  as an example.

In every case the key is in **one commit**, and the next commit is usually the one that notices.
Somebody sees it in the review, deletes the line and commits again. The file is clean. That second
commit fixes nothing that matters, because git is a history: the first commit is still there, with
the key in it, and anyone with a copy of the repository can ask for it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l18-history\" aria-label=\"A repository drawn as two commits and the files on disk. Commit 1 adds the key; commit 2 deletes the line. The files on disk no longer hold the key, and a scan of the files finds nothing. A scan of the history reads both commits and finds the key in commit 1. Below, four copies made before the deletion: your clone, a colleague's clone, a fork and a CI cache. Each of them holds commit 1, key included, and deleting the line reaches none of them.\"><defs><marker id=\"l18-history-nf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-history-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"360.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">deleting the line changes the files, not the history</text><path d=\"M60.0 50.0 L460.0 50.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60.0 46.0 L60.0 54.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M460.0 46.0 L460.0 54.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"260.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">gitleaks git: every commit</text><path d=\"M510.0 50.0 L680.0 50.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M510.0 46.0 L510.0 54.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M680.0 46.0 L680.0 54.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"595.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">gitleaks dir: only these</text><rect x=\"60.0\" y=\"66.0\" width=\"170.0\" height=\"54.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"145.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">commit 1</text><text x=\"145.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">adds the key</text><path d=\"M230.0 93.0 L286.0 93.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-history-nf-ah-paper-dim)\"></path><rect x=\"290.0\" y=\"66.0\" width=\"170.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">commit 2</text><text x=\"375.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">deletes the line</text><rect x=\"510.0\" y=\"66.0\" width=\"170.0\" height=\"54.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"595.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the files on disk</text><text x=\"595.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no key: no leaks found</text><text x=\"360.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">copies made before the deletion</text><path d=\"M145.0 120.0 L145.0 140.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M70.0 140.0 L650.0 140.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M130.0 140.0 L130.0 176.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l18-history-nf-ah-amber)\"></path><rect x=\"70.0\" y=\"180.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"130.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">your clone</text><text x=\"130.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">has commit 1</text><path d=\"M280.0 140.0 L280.0 176.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l18-history-nf-ah-amber)\"></path><rect x=\"220.0\" y=\"180.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"280.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a colleague's clone</text><text x=\"280.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">has commit 1</text><path d=\"M430.0 140.0 L430.0 176.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l18-history-nf-ah-amber)\"></path><rect x=\"370.0\" y=\"180.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"430.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a fork</text><text x=\"430.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">has commit 1</text><path d=\"M580.0 140.0 L580.0 176.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l18-history-nf-ah-amber)\"></path><rect x=\"520.0\" y=\"180.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"580.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a CI cache</text><text x=\"580.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">has commit 1</text><text x=\"360.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">only revoking the key makes all of them harmless</text></svg>", "caption": "Deleting the line makes a new commit. The one before it still holds the key, here and in every copy already made."}
```

## Why a pushed key is a known key

Once a commit has left your machine, you cannot list everybody who has it. Every clone has the
history, and so does every fork, every runner that built it, every cache and every mirror, and the
laptop of the colleague who pulled before you noticed. On a public repository it is worse and
faster: bots read every push to public hosting services looking for exactly this, and a working
key published there is in use within minutes.

**So a key that reached a shared repository is treated as known to strangers**, whether or not
anybody has seen it. The fix follows from that, in this order:

1. **Rotate it.** Revoke the key at the provider, issue a new one and deploy the new one. From
   that moment the leaked value opens nothing, and every copy of the history holds a dead key.
2. **Look at what it did.** The provider's own log says whether the old key was used, from where,
   and for what, between the push and the revocation. That is what decides whether the leak was an
   incident or a near miss.
3. **Clean the history, if at all.** Tools exist that rewrite every commit without the file or
   the line: `git filter-repo` and the BFG Repo-Cleaner are the two most used. Rewriting changes
   every hash after the commit, needs a forced push and a fresh clone by everybody, and reaches
   none of the copies that already exist. It tidies the repository; it does not un-leak the key.

This lesson does the first step on paper and the third not at all. It is the order that matters:
**a team that rewrites the history and does not rotate has hidden the leak and kept it.**

## What the tester owns here

The tester's part is the same as in the rest of this third: write down what must not happen, and
make something fail when it does. For secrets that means four rows in the test plan.

| the requirement | what holds it |
|---|---|
| no secret in any file of the repository, in any commit | a secret scanner over the whole history, on every push |
| no secret in a commit to begin with | the same scanner on what is staged, before the commit is made |
| the code holds no secret, and has no default for one | configuration from the environment or a secret manager, reviewed |
| a secret that was found is rotated, not only deleted | the response procedure, and a record of each one |

`account.py` already keeps the third row. **Its first lines take everything that differs between
machines from the environment**: where the database lives, where uploads go, how long a session
lasts. None of those is a secret, and the file can be read, reviewed and committed whole, which is
what lesson 16 meant by "nothing secret in the file". The rest of this lesson builds the other
three rows, on a small repository of your own with a key in it that nobody ever issued.
