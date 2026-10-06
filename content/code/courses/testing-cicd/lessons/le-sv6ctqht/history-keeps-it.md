---
title: Removed from the code, still in the history
version: 1
---

The commonest leak is the simplest: a secret committed to the repository. It happens with the best
intentions, keeping the production settings beside the code so they are versioned like everything
else, and the usual reaction, deleting the file in the next commit, does not undo it.

Here is that sequence on a throwaway branch of `shipquote`. One commit adds `deploy/production.env`
with the carrier URL and the token; twenty minutes later another commit removes it:

```
ana@laptop:~/shipquote$ git log --oneline -3
9c9d357 Remove the production settings again
ee23fb4 Keep the production settings with the code
cd46eb9 Ask the carrier when the environment names one
ana@laptop:~/shipquote$ ls deploy/production.env
ls: cannot access 'deploy/production.env': No such file or directory
ana@laptop:~/shipquote$ git log --oneline -S lab-live-token
9c9d357 Remove the production settings again
ee23fb4 Keep the production settings with the code
ana@laptop:~/shipquote$ git show HEAD~1:deploy/production.env
SHIPQUOTE_CARRIER_URL=http://127.0.0.1:9092
SHIPQUOTE_CARRIER_TOKEN=lab-live-token
```

The working copy no longer has the file. **The history does**: `git log -S` lists every commit that
added or removed the string, and `git show` prints the file exactly as it was committed, token
included. Anybody who cloned or fetched the repository in those twenty minutes, and anybody who ever
reads its history, has the value. On a hosted service, forks, caches and the service's own backups
have it too.

## What follows from that

**Treat a secret that reached a commit as leaked**, whatever happened next: a later commit, a force
push, a private repository. Rewriting history to remove it is worth doing to stop it spreading
further, and it cannot recall the copies already made. So the order is the one section 10 sets out:
rotate the secret first, then clean up.

## Finding them before they land

`git log -S <string>` is how you search your own history for a value you know. For values you do not
know, **secret scanners** look for the shapes secrets have: the prefix a provider puts on its tokens,
a private key's header, a high-entropy string next to the word `password`. They run as a pre-commit
hook on the developer's machine, as a step in CI, and as a service on the hosting platform, which
for public repositories often notifies the provider so the token is revoked within minutes. In the
`devsecops` track, `secure-pipeline` lesson 6 treats secret scanning in the repository and its
history in depth.

The cheapest defence is structural: **keep secrets in files the repository ignores**, or out of the
working copy altogether. `shipquote`'s environments keep theirs in `~/envs/<name>/config.env`, which
is not in any repository; `.gitignore` entries for `*.env` and a scanner in the pre-commit hook are
the usual belt and braces.
