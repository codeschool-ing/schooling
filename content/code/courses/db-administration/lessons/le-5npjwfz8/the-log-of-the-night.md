---
title: The log of the night
version: 1
---

While you work through a runbook, **write down what you see and what you do, as you do it**, one
line at a time with the time in front. Not afterwards: the account written the next morning is a
story, tidied by a tired memory into the order things should have happened in. The lines written
during the night are evidence, and three people need them — whoever takes over if you hand the
incident on, whoever writes the review afterwards (db-reliability lesson 22), and whoever keeps
the runbook true (the next section).

It needs no tool, but a small one removes every excuse. Save this as `~/bin/note` and make it
executable:

```bash
#!/usr/bin/env bash
# note: add one line, with the time, to today's incident log.
#   note "df says 91%, pg_wal is 40G"
mkdir -p ~/incidents
printf '%s  %s\n' "$(date '+%H:%M:%S')" "$*" >> ~/incidents/"$(date +%F)".log
```

```sh
mkdir -p ~/bin
nano ~/bin/note
chmod +x ~/bin/note
```

Ubuntu's `~/.profile` puts `~/bin` on your `PATH` when it exists at login, so log out and in again
once (or run `source ~/.profile`), and `note` works from anywhere. Each call appends one line to a
file named for the day, under `~/incidents`.

## What goes in a line

**What you saw, with the number.** "df 91%" can be compared with the next reading; "disk quite
full" cannot. **What you did**, as the command or the act's letter in the runbook. **What you
decided and why**, especially a decision not to act, because the reason is the first thing
forgotten. **Whom you asked, and what they said**, since an answer given on the phone exists
nowhere else.

This is the log written while running the previous section's runbook, one `note` after each
check:

```
ana@db:~$ cat incidents/$(date +%F).log
16:42:37  Alert: disk under PostgreSQL filling on db. Opened runbook disk-filling.
16:42:37  df: 54% used. Not 100%, writes still working.
16:42:38  pg_wal 657M, base 467M. Looking at slots.
16:42:38  slot standby1: inactive, retaining 649 MB. Asked its owner whether a replica still uses it.
16:42:38  log: no errors, checkpoints started by WAL volume.
16:42:38  table filler in db ana, 313 MB, created tonight. Not ours to delete: ticket for its owner.
16:42:39  standby1: owner confirms no replica uses it. Dropping it.
16:42:40  dropped standby1, ran CHECKPOINT.
16:42:40  verify: no slots. pg_wal 673M, recycled for reuse rather than removed, as expected. df 54%. Watching 15 min.
16:42:40  Closed. Follow-up: max_slot_wal_keep_size, and a check on slots in monitoring.
```

On the recording machine the whole runbook ran in about three seconds, because nobody had to wait
for an answer. On a real night the gaps between these lines are the story: twenty minutes between
"Asked its owner" and "owner confirms" is twenty minutes of a filling disk, and a review needs to
see it. The last line is the one people leave out, and it is the reason the next incident of this
kind might not happen; the next section says what becomes of it.

## When a line is not enough

`script` records a whole terminal session, every command and everything it printed, into a file:

```sh
script -a ~/incidents/"$(date +%F)".typescript
```

Type `exit` to stop it. It was not run here. It is complete where `note` is selective, which cuts
both ways: it holds the exact output of every command for the review, and nothing in it says which
of the two hundred commands mattered. The two together are the useful pair — the recording for
what happened, the notes for what you thought it meant.
