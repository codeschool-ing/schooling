---
title: A deploy is a command
version: 2
---

A deploy that lives in somebody's head, or in a wiki page of twelve steps, is a deploy that goes
differently every time. **A deploy should be one command that takes an artifact and an environment
and either succeeds completely or says it failed.** `shipquote`'s is one script. Save it as `ops/deploy.sh`:

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

`deploy.sh` hands two jobs to scripts of their own. Stopping the old process and starting the new
one is `restart.sh`. Save it as `ops/restart.sh`:

```sh
#!/usr/bin/env bash
# Stop the environment's running process, if any, and start `current` with
# the environment's own configuration.
set -euo pipefail
env=$1
root=${SHIPQUOTE_ENVS:-$HOME/envs}/$env
if [ -f "$root/pid" ] && kill -0 "$(cat "$root/pid")" 2>/dev/null; then
  kill "$(cat "$root/pid")"
  while kill -0 "$(cat "$root/pid")" 2>/dev/null; do sleep 0.1; done
fi
set -a; . "$root/config.env"; set +a
export SHIPQUOTE_ENV=$env
cd "$root/current"
setsid python3 -m shipquote.app >> "$root/app.log" 2>&1 < /dev/null &
echo $! > "$root/pid"
for _ in $(seq 50); do
  curl -s --max-time 1 "http://127.0.0.1:$SHIPQUOTE_PORT/health" > /dev/null && exit 0
  sleep 0.1
done
echo "restart: $env did not answer on port $SHIPQUOTE_PORT" >&2
exit 1
```

It keeps the process's id in the environment's `pid` file, starts the program detached from the
terminal with `setsid`, its output appended to `app.log`, and waits up to five seconds for `/health`
to answer. The other, `rollback.sh`, points `current` back at `previous`, and lesson 11 is about
when to use it. It belongs to this release, so save it now too. Save it as `ops/rollback.sh`:

```sh
#!/usr/bin/env bash
# Point the environment back at the release it ran before, restart, smoke.
set -euo pipefail
env=$1
root=${SHIPQUOTE_ENVS:-$HOME/envs}/$env
[ -L "$root/previous" ] || { echo "rollback: $env has no previous release" >&2; exit 1; }
before=$(readlink "$root/previous")
ln -sfn "$(readlink "$root/current")" "$root/previous"
ln -sfn "$before" "$root/current"
"$(dirname "$0")/restart.sh" "$env"
set -a; . "$root/config.env"; set +a
"$(dirname "$0")/smoke.sh" "http://127.0.0.1:$SHIPQUOTE_PORT" "${before#releases/shipquote-}"
```

An environment is a directory you make, with a configuration of one line:

```sh
mkdir -p ~/envs/staging ~/envs/production
echo SHIPQUOTE_PORT=8200 > ~/envs/staging/config.env
echo SHIPQUOTE_PORT=8300 > ~/envs/production/config.env
```

The staging environment's whole configuration is that line, and the deploy to it prints one line:

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
