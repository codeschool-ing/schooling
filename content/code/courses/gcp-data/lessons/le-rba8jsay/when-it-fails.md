---
title: When the lab does not answer
version: 1
---

These are the failures met while this lesson was recorded, in the order a student meets them, with
what each one says and what it means. Most of them are one forgotten line.

**`gcloud` is not found.** A new terminal starts without `~/gcp/google-cloud-sdk/bin` on its path:

```
ana@laptop:~/gcp$ PATH=/usr/bin:/bin; gcloud version
bash: line 1: gcloud: command not found
```

The second line under "Every time you open a terminal" puts it back. `fake-gcs-server` disappears
the same way, from the other terminal, when its `export PATH` line was skipped.

**No credentials, and nothing saying not to use any.** The terminal has the path and the endpoint,
and not `CLOUDSDK_AUTH_DISABLE_CREDENTIALS`, so `gcloud` looks for an account to sign with, finds
none and stops before sending anything:

```
ana@laptop:~/gcp$ env -u CLOUDSDK_AUTH_DISABLE_CREDENTIALS gcloud storage buckets list
ERROR: (gcloud.storage.buckets.list) You do not currently have an active account selected.
Please run:

  $ gcloud auth login

to obtain new credentials.

If you have already logged in with a different account, run:

  $ gcloud config set account ACCOUNT

to select an already authenticated account to use.
```

**Do not follow its advice.** `gcloud auth login` signs this command line in to a real Google
account, and from then on a terminal that has lost its endpoint line would be talking to Google as
you. The fix is the third line of the block, typed again.

**No project.** Every request to Cloud Storage names a project, and without
`CLOUDSDK_CORE_PROJECT` there is none to name:

```
ana@laptop:~/gcp$ env -u CLOUDSDK_CORE_PROJECT gcloud storage buckets list
ERROR: (gcloud.storage.buckets.list) The required property [project] is not currently set.
It can be set on a per-command basis by re-running your command with the [--project] flag.

You may set it for your current workspace by running:

  $ gcloud config set project VALUE

or it can be set temporarily by the environment variable [CLOUDSDK_CORE_PROJECT]
```

The last of its three suggestions is the one this course uses, and the third line of the block is
where it is.

**The emulator is not running.** The variables are set and nothing is listening on the port, because
the other terminal was closed, or `Ctrl+C` stopped the server:

```
ana@laptop:~/gcp$ gcloud storage buckets list
ERROR: gcloud crashed (ConnectionError): HTTPConnectionPool(host='localhost', port=4443): Max retries exceeded with url: /storage/v1/b?alt=json&maxResults=1000&project=planner-dev&projection=full (Caused by NewConnectionError("HTTPConnection(host='localhost', port=4443): Failed to establish a new connection: [Errno 111] Connection refused"))

If you would like to report this issue, please run the following command:
  gcloud feedback

To check gcloud for common problems, please run the following command:
  gcloud info --run-diagnostics
```

**`gcloud crashed` sounds worse than it is.** The two words that matter are `port=4443` and
`Connection refused`: the request went where it should, and nobody was there. Start the emulator
again in its own terminal. It comes back empty, and the lesson you were on rebuilds what it needs
from its first command. The same error with `port=8085`, `9020` or another number names the
emulator of a later lesson.

**The port is taken.** A second `fake-gcs-server`, in a third terminal, or one left behind by a
terminal that was closed without stopping it:

```
ana@laptop:~/gcp$ timeout 10 fake-gcs-server -scheme http -port 4443 -backend memory -location southamerica-east1 2>&1 | tail -3
time=2026-10-30T15:06:30.251-03:00 level=ERROR msg="listen tcp 0.0.0.0:4443: bind: address already in use"
```

`address already in use` means an emulator is already answering, so there is nothing to fix unless
you wanted an empty one. To stop the old one, find its process and end it: `pgrep -af
fake-gcs-server` prints its number, and `kill` followed by that number stops it.

## When the installation itself fails

**`gcloud components install` stops with a network error.** It downloads each component from
`dl.google.com`, so it needs the network the first time and never again. Run the same line again;
it skips what is already there.

**It asks to update the command line first.** The `fixed_sdk_version` line was skipped. Answer no,
run that line, and run the install again.

**A Java emulator will not start**, in lessons 10 and 19, with `java: command not found` or a
version error. The `openjdk-21-jre-headless` package of the first block is missing, and `java
-version` says so in one line.

**Disk.** The lab wants 1.6 GB, and `pip` needs some room of its own while it unpacks. On a virtual
machine with a small disk, `df -h ~` before the installation saves an hour of reading half-written
errors.

**Starting again is cheap.** Everything this section installs lives under `~/gcp` and
`~/.config/gcloud`, so `rm -rf ~/gcp ~/.config/gcloud` and the blocks above, in order, give you a
lab in the state these transcripts were recorded in. Nothing outside those two directories was
touched, apart from the packages of the first block.
