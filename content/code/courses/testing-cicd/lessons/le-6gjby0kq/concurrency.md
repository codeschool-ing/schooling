---
title: Runs that overlap
version: 1
---

Push three commits to a branch in ten minutes and three runs start. The first two are already out of
date: nobody will merge those commits, only the last. Running them to the end spends runners and,
worse, can report a red that no longer matters after a green that does. A **concurrency group**
tells the service that runs in the same group should not overlap.

This repository's workflow declares one:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

The group is the workflow and the branch, so runs on different branches never interfere, and
`cancel-in-progress` cancels the older run when a newer one starts in the same group. Here are the
runs of one branch on 19 September 2026, newest first:

```
ana@laptop:~$ curl -s "$A/workflows/ci.yml/runs?branch=claude/wonderful-cray-nrgjb2&created=2026-09-19&per_page=8" | jq -r ".workflow_runs[] | [.id, .conclusion, .run_started_at, .updated_at] | @tsv"
35432460022	success	2026-09-19T08:36:39Z	2026-09-19T08:43:22Z
35430039994	success	2026-09-19T07:42:08Z	2026-09-19T07:48:29Z
35426262104	success	2026-09-19T06:18:49Z	2026-09-19T06:25:29Z
35425738735	failure	2026-09-19T06:06:59Z	2026-09-19T06:10:43Z
35422745554	success	2026-09-19T04:59:39Z	2026-09-19T05:06:02Z
35422536691	cancelled	2026-09-19T04:54:33Z	2026-09-19T04:59:55Z
35422344961	cancelled	2026-09-19T04:50:03Z	2026-09-19T04:54:52Z
35415431885	success	2026-09-19T02:21:56Z	2026-09-19T02:28:06Z
```

Read from the bottom. Run `35422344961` started at 04:50:03. Another push started `35422536691` at
04:54:33, and the first run ended **cancelled** at 04:54:52, nineteen seconds later. Five minutes on,
the same thing happened to the second: run `35422745554` started at 04:59:39 and the second ended
cancelled at 04:59:55. Then the third run was allowed to finish, and it succeeded. Further up, a
run failed and the next push fixed it; nothing cancelled it, because nothing newer arrived while it
ran.

## When cancelling is wrong

Cancelling suits checks: an old check is worthless once there is a newer commit. It is the wrong
behaviour for anything that **changes the world**, such as a deployment. A deploy cancelled halfway
can leave a database migrated and a service on the old version. This repository's release workflow
puts its deploy job in a group of its own with `cancel-in-progress: false`, so a second release
waits for the first instead of interrupting it, and its comment says what it accepts in exchange:
when three releases queue, the middle one is dropped before it starts, which is the right loss,
because it was never going to be the one serving.

`shipquote`'s workflow cancels, because it only checks. Lesson 7 adds jobs that deliver, and they
will need the other setting.
