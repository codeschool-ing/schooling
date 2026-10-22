---
title: Secrets are not flags
version: 1
---

A token, a password or a database URL with a password in it is configuration too, and it varies between
environments like the rest. **Where it comes from matters more than for anything else**, because of who
else on the machine can read each source. Start `knobs` with a token in its environment and a password as
an argument, and look at it from another terminal while it runs, first as the user `nobody`, who has no
business with it:

```
ana@vm:~/knobs$ sudo -u nobody ps -o user=,args= -C knobs
ana      ./knobs -wait 3s -addr localhost:8080 hunter2
```

**Every user on the machine can read every process's command line**, through `ps` or `/proc`. A flag such as
`-token=…` is published to all of them for as long as the process runs, and it lands in shell history on top
of that. So secrets never come from flags, and boxoffice declares no flag for one.

```
ana@vm:~/knobs$ sudo -u nobody cat /proc/$(pgrep -x knobs)/environ
cat: /proc/26459/environ: Permission denied
```

**The environment is private to the process's owner and root**, so `nobody` is refused. Ana herself can
read it:

```
ana@vm:~/knobs$ tr '\0' '\n' < /proc/$(pgrep -x knobs)/environ | grep TOKEN
BOXOFFICE_MANAGER_TOKEN=3f9c1e7a2b8d4f60
```

That is better than a flag and still not airtight. An exported variable reaches every program its owner
starts, as section 04 showed, including the ones that have no use for it; a debugging page or a crash
report that prints the environment prints the secret; and the tokens you have exported since lesson 2,
kept in `~/.profile` beside lesson 6's `DATABASE_URL`, are in every terminal you open.

## A file of its own

The next step up is a file that holds only the secret, readable only by its owner, with the variable
holding the file's path rather than the secret. The convention is a variable with `_FILE` on the end of the
name: the official PostgreSQL container image reads `POSTGRES_PASSWORD_FILE`, for example. It fits how
platforms hand secrets over: Docker and Kubernetes can both mount secrets into a container as files, and only
the processes that open the file see them.

boxoffice reads `BOXOFFICE_MANAGER_TOKEN`, `BOXOFFICE_DOOR_TOKEN` and `DATABASE_URL` from the variable or
from the file `…_FILE` names. Section 08 moves the tokens out of `~/.profile` and into files.

## What not to do with one

- **Never commit one.** A secret in a repository is in its history after it is deleted, and in every clone.
  Files that hold secrets, such as `.env` files, go in `.gitignore`.
- **Never log one.** Section 07 gives boxoffice a type whose log output is `[hidden]`, the same idea as
  lesson 12's `email`.
- **Make them easy to replace.** A token read from a file at start-up is replaced by writing the file and
  restarting, which nobody needs to put off.

Your local `DATABASE_URL` connects through a socket with no password, which is why lesson 6 could put it in
`~/.profile`. A production database URL carries a password and gets a file.
