---
title: A timer is two files, and one of them you already know
version: 2
---

A systemd timer is a **service that already exists**, plus a file that says when
to start it. That split is the whole design: what to run and when to run it are
separate units, and the first one is lesson 5's `.service`.

## The service

Both files are written in a directory of their own, and installed later:

```sh
mkdir -p ~/work/cron/units && cd ~/work/cron/units
cat > report.service <<'END'
[Unit]
Description=Nightly report

[Service]
Type=oneshot
ExecStart=/home/ana/bin/report.sh
User=ana
END
```

**`Type=oneshot`** is the difference from lesson 5's services: it runs, it
finishes, and systemd does not consider that a failure. A `.service` for a timer
is a job, not a daemon.

There is no schedule in it. You can run it by hand with
`systemctl start report.service`, which is worth doing before you trust the
timer — **the timer is not what is broken, nine times out of ten.**

## The timer

```sh
cd ~/work/cron/units
cat > report.timer <<'END'
[Unit]
Description=Run the nightly report at 03:00

[Timer]
OnCalendar=*-*-* 03:00:00
RandomizedDelaySec=15m
Persistent=true

[Install]
WantedBy=timers.target
END
```

Same base name, different extension. **`report.timer` starts `report.service`**,
by that convention alone — and `Unit=` overrides it when the names differ.

| | |
|---|---|
| `OnCalendar=` | a wall-clock schedule — section 11 |
| `RandomizedDelaySec=15m` | spread the herd: a random delay up to fifteen minutes |
| `Persistent=true` | if the machine was off, run it at the next boot — section 12 |
| `WantedBy=timers.target` | enable it and it starts with the system |

## Check it before you install it

```
ana@vm:~/work/cron/units$ systemd-analyze verify ./report.timer ./report.service && echo "both ok"
both ok
```

Now the same timer with one letter wrong — `OnCalender` instead of `OnCalendar`.
`sed` makes the copy, and the service is copied as it is so that the names pair:

```sh
cd ~/work/cron/units
sed 's/OnCalendar/OnCalender/' report.timer > report-typo.timer
cp report.service report-typo.service
```

```
ana@vm:~/work/cron/units$ systemd-analyze verify ./report-typo.timer ./report-typo.service
/home/ana/work/cron/units/report-typo.timer:5: Unknown key name 'OnCalender' in section 'Timer', ignoring.
report-typo.timer: Timer unit lacks value setting. Refusing.
Unit report-typo.timer has a bad unit file setting.
```

**Three lines, and the second is the one that matters.** `Unknown key name` is a
warning — systemd ignores keys it does not recognise, which is how a misspelt
`OnCalendar` becomes *a timer with no schedule* rather than an error. And a timer
with no schedule is refused: `Timer unit lacks value setting.`

That is the failure mode to remember. **A typo in a unit file is usually ignored,
not reported**, and `systemd-analyze verify` before `daemon-reload` is how you
find out which kind you have. It reads files by path and needs no root.

## Installing one

```sh
cd ~/work/cron/units
sudo cp report.service report.timer /etc/systemd/system/
sudo systemctl daemon-reload            # systemd re-reads the unit files
sudo systemctl enable --now report.timer
```

And it is there, waiting for three in the morning:

```
ana@vm:~$ systemctl list-timers report.timer
NEXT                        LEFT LAST PASSED UNIT         ACTIVATES
Thu 2026-10-08 03:01:02 UTC  12h -         - report.timer report.service

1 timers listed.
Pass --all to see loaded but inactive timers, too.
```

**`NEXT` is 03:01:02, not 03:00:00** — `RandomizedDelaySec=15m` has already
picked this machine's delay, a minute and two seconds. **`LAST` is a dash**,
because it has never run.

**`daemon-reload` is the step people forget.** Without it systemd is still
running the version it read at boot, and your edit has no effect at all.

**Enable the `.timer`, not the `.service`.** Enabling the service would start the
job at boot, which is not what you asked for.

For a job that is yours rather than the machine's, the same files go in
`~/.config/systemd/user/` and every command takes `--user` — and that needs
`loginctl enable-linger ana` for the timers to run while you are not logged in.

## What the two files buy you over a crontab line

| | |
|---|---|
| the journal | `journalctl -u report.service` — every run, with output, timestamped |
| the environment | `Environment=`, `EnvironmentFile=`, and a `PATH` you control |
| the identity | `User=`, `Group=`, and the sandboxing of lesson 5 |
| dependencies | `After=network-online.target` — a thing cron cannot express |
| one run at a time | a `.service` that is already running is not started again |
| catching up | `Persistent=`, which cron has no answer to |

That last pair is the honest reason to prefer a timer for anything that matters:
**overlap and missed runs are solved in the file rather than in your script** —
which is sections 14 and 12, and about half of what section 16 is about.

## What it costs

Two files instead of one line. A `daemon-reload` you will forget once. And a unit
file syntax with about forty settings, where cron has five fields.

**On a machine where the job is one line, cron is still the right answer.** On a
machine where the job belongs to a service you already wrote a unit for, the
timer is fifteen lines and everything above.
