---
title: A deploy is a command
version: 1
---

A deploy that lives in somebody's head, or in a wiki page of twelve steps, is a deploy that goes
differently every time. **A deploy should be one command that takes an artifact and an environment
and either succeeds completely or says it failed.** `shipquote`'s is `ops/deploy.sh`:

```schooling-example
{
  "language": "sh",
  "file": "ops/deploy.sh",
  "parts": [
    {
      "code": "#!/usr/bin/env bash\n# Deploy one built artifact to one environment, then smoke-test it.\n#   ops/deploy.sh staging dist/shipquote-1.4.0.tar.gz\n# An environment is a directory under ~/envs holding its own config.env;\n# every release is unpacked beside the others, and `current` points at one.\nset -euo pipefail\nenv=$1 artifact=$2\nroot=${SHIPQUOTE_ENVS:-$HOME/envs}/$env\n[ -f \"$root/config.env\" ] || { echo \"deploy: $root/config.env does not exist\" >&2; exit 1; }",
      "note": "An environment is a directory under `~/envs` with its own `config.env`. A deploy to an environment that has none stops here: no defaults, no guessing which port production uses."
    },
    {
      "code": "(cd \"$(dirname \"$artifact\")\" && sha256sum --check --quiet \"$(basename \"$artifact\").sha256\")",
      "note": "The hash written by the build is checked **before anything is unpacked**. Section 08 shows this line refusing an artifact."
    },
    {
      "code": "name=$(basename \"$artifact\" .tar.gz)\nversion=${name#shipquote-}\nmkdir -p \"$root/releases\"\ntar -xzf \"$artifact\" -C \"$root/releases\"\n[ -L \"$root/current\" ] && ln -sfn \"$(readlink \"$root/current\")\" \"$root/previous\"\nln -sfn \"releases/$name\" \"$root/current\"",
      "note": "Each release is unpacked beside the others, and `current` is a link to one of them. The link that was there before is kept as `previous`, which is what lesson 11's rollback uses."
    },
    {
      "code": "\"$(dirname \"$0\")/restart.sh\" \"$env\"\nset -a; . \"$root/config.env\"; set +a\n\"$(dirname \"$0\")/smoke.sh\" \"http://127.0.0.1:$SHIPQUOTE_PORT\" \"$version\"",
      "note": "Restart the environment's process on the new release, then run the smoke test against it, with the version the artifact's name promised."
    }
  ]
}
```

The staging environment's whole configuration is one line, and the deploy to it prints one line:

```
ana@laptop:~/shipquote$ cat ~/envs/staging/config.env
SHIPQUOTE_PORT=8200
ana@laptop:~/shipquote$ ops/deploy.sh staging dist/shipquote-1.4.0.tar.gz
smoke: http://127.0.0.1:8200 is up and running 1.4.0
ana@laptop:~/shipquote$ ls -F ~/envs/staging ~/envs/staging/releases
/home/ana/envs/staging:
app.log
config.env
current@
pid
releases/

/home/ana/envs/staging/releases:
shipquote-1.4.0/
ana@laptop:~/shipquote$ readlink ~/envs/staging/current
releases/shipquote-1.4.0
ana@laptop:~/shipquote$ curl -s http://127.0.0.1:8200/version; echo
{"version": "1.4.0", "env": "staging"}
```

The smoke test, the next section's subject, found the program answering on port 8200 and running
1.4.0. The directory shows the layout: the configuration, the process's id and log, the releases,
and `current` pointing at `releases/shipquote-1.4.0`. The program itself confirms it: version
`1.4.0`, environment `staging`.

## Why releases sit side by side

Unpacking each release into its own directory and switching a link means the switch is **one atomic
operation**: there is no moment when half the files are new and half are old. It also means the
previous release is still on disk, complete, so going back is another switch rather than another
build. Container platforms do the same with images: every revision stays in the registry, and
deploying is pointing the service at one of them.

## What the lab leaves out

A real deploy also has to drain connections from the old process before stopping it, run database
migrations in the right order, and spread the change over many machines. `restart.sh` simply stops
the old process and starts the new one, so for a moment nothing answers on the port. Lesson 10
measures that moment, and shows two ways to make it disappear.
