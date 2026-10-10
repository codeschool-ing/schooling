---
title: Where secrets live, and the places they leak
version: 1
---

**A secret belongs in the environment of the process that uses it, and nowhere that is copied:
not in the code, not in the repository, not in a log.** Every secret in this lesson so far has been
in plain sight, and on purpose. `ci-secret`, `lab-only-staff-key` and the signing secret
`lab-only-secret` are written in `boxoffice.mjs` as defaults, so that the lab works the moment you
start it. On a real server they would be the first thing an attacker tried.

## The signing secret, from the environment

boxoffice reads `TOKEN_SECRET` and `STAFF_KEY` from its environment and falls back to the lab values
only when they are missing. Make a real one: 32 random bytes in base64url, written into a file
called `.env` without ever appearing on the screen:

```
ana@laptop:~/boxoffice$ echo "TOKEN_SECRET=$(node -e 'console.log(require("crypto").randomBytes(32).toString("base64url"))')" > .env
ana@laptop:~/boxoffice$ wc -c .env
57 .env
```

`wc -c` confirms the file holds something, 57 bytes, without printing it. Node reads such a file
itself when started with `--env-file`. Stop boxoffice in the second terminal and start it like this:

```
ana@laptop:~/boxoffice$ node --env-file=.env boxoffice.mjs
boxoffice listening on http://localhost:8080
```

Every token signed with the old secret is now worthless. The `TOKEN` fetched earlier:

```
ana@laptop:~/boxoffice$ curl -si localhost:8080/v1/orders/ord-1001 -H "authorization: Bearer $TOKEN" | grep -iE '^HTTP|^www'
HTTP/1.1 401 Unauthorized
www-authenticate: Bearer error="invalid_token", error_description="bad signature"
```

`bad signature`, the same refusal an edited token got in section 04. This is also a test worth
keeping: **a server started with its own secret refuses tokens signed with the default one**. A
deployment that forgot to set `TOKEN_SECRET` would accept a token anybody can make from the source
code, and this request is how you find out.

The rest of the course starts boxoffice with a plain `node boxoffice.mjs` and the lab's values,
because the transcripts depend on them. Keep `.env` for the habit, and for the day you test a server
that is not yours.

## Not in the repository

A file of secrets in a project directory is one `git add .` away from being published. Git skips
the files named in `.gitignore`, so the project gets one. Open your editor, write these two lines
and save it as `.gitignore`:

```
# Secrets live in .env, on this machine only.
.env
```

Then make the project a git repository, if it is not one already; lesson 6's pipeline assumes one.
`git init` creates it, and `git status --short` lists what git would offer to commit:

```
ana@laptop:~/boxoffice$ git init -q
ana@laptop:~/boxoffice$ git status --short
?? .gitignore
?? boxoffice.mjs
?? openapi.yaml
```

Three files, and `.env` is not among them. **Check this before the first commit, not after**: a
secret that reached a repository has to be treated as leaked even if the commit is removed, because
every clone made in between still has it. The fix then is to change the secret, not to rewrite
history.

## Not in a log

A pipeline's log is read by everybody who can see the project, and it is kept. The easiest way to
put a token in it is to ask the shell to explain itself. `bash -x` prints every command before it
runs it, with the variables already replaced, and pipelines turn it on to make failures easier to
read:

```
ana@laptop:~/boxoffice$ bash -xc 'curl -s -o /dev/null localhost:8080/v1/orders/ord-1001 -H "authorization: Bearer $TOKEN"'
+ curl -s -o /dev/null localhost:8080/v1/orders/ord-1001 -H 'authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJjaS10ZXN0cyIsInNjb3BlIjoib3JkZXJzOnJlYWQgb3JkZXJzOndyaXRlIiwiaWF0IjoxNzkxNjYxMzg3LCJleHAiOjE3OTE2NjIyODd9.ZYNygARAi8VHK-A59GydT_uT2q6wG8ebDb8D67_sJQU'
```

The whole token, in the clear, in a line that looks like harmless debugging. Lesson 6 runs requests
in GitHub Actions, which hides the values you register as secrets wherever they appear in a log;
**a token the job fetched for itself is not registered, so nothing hides it** unless the step marks
it with `::add-mask::` first. That was not run for this course, and lesson 6 shows the workflow. What
a tester can check anywhere is the log itself: search a run's output for `Bearer ` and for the start
of a JWT, `eyJ`, and treat either as a defect in the pipeline.

The same rule covers test reports. A tool that saves every request and response for a failed test
saves the `Authorization` header with it, so a report attached to a ticket can carry a live token.
Lesson 6's reporters are the first place to look.
