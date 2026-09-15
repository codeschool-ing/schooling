---
title: `crontab`, and the flag that deletes everything
version: 1
---

Every user can have one crontab. It is a file, it is not in your home directory,
and you never edit it where it lives.

| | |
|---|---|
| `crontab -l` | list yours |
| `crontab -e` | edit yours, in `$EDITOR` — lesson 12's chain |
| `crontab -r` | **delete** yours. No confirmation |
| `crontab file` | replace yours with the contents of `file` |
| `crontab -u ana -l` | somebody else's, as root |

```
ana@vm:~/work/cron$ crontab -l
* * * * * /home/ana/work/cron/heartbeat.sh
* * * * * report.sh
* * * * * echo "ran at $(date +%H:%M)" >> /home/ana/work/cron/pct.log
```

Three jobs, every minute. Two of them are broken in ways the next three sections
are about, and this section is about the two commands, not the lines.

## `crontab -e` and the editor you did not choose

`crontab -e` opens **an editor on a temporary copy**, and installs it when the
editor exits — the `sudoedit` shape from lesson 12, applied to a file you are not
allowed to write directly.

```
ana@vm:~/work/cron$ EDITOR=/bin/true crontab -e
No modification made
```

That is the whole mechanism in one line: `/bin/true` is an editor that exits
immediately and changes nothing, so `crontab` compares the copy with the original
and installs nothing. Which means:

**If you make a syntax error, `crontab -e` catches it before installing**, and
offers to put you back in the editor. A crontab written straight to the spool
directory gets no such check.

And the editor is the one from section 205 — `$VISUAL`, then `$EDITOR`, then
whatever the distribution's fallback is. `EDITOR=nano crontab -e` is the spelling
worth knowing on a machine that is not yours.

## `-r` is next to `-e`

```sh
crontab -r          # deletes your entire crontab, immediately, with no prompt
```

**There is no confirmation and no undo.** `-r` and `-e` are one key apart on the
keyboard, and the mistake is common enough that some distributions ship
`crontab -i`, which asks first — and many do not.

The habit that costs nothing, and what it buys:

```
ana@vm:~/work/cron$ crontab -l > ~/crontab.backup; wc -l ~/crontab.backup
4 /home/ana/crontab.backup
ana@vm:~/work/cron$ crontab -r
ana@vm:~/work/cron$ crontab -l; echo "exit $?"
no crontab for ana
exit 1
ana@vm:~/work/cron$ crontab ~/crontab.backup && crontab -l | tail -2
* * * * * echo "CRON_TZ=[$CRON_TZ]  ran at $(date -u +\%H:\%M) UTC" >> /home/ana/work/cron/tzenv2.log
30 8 * * * echo "08:30 New York?" >> /home/ana/work/cron/tz830.log
```

**`crontab -r` printed nothing at all** — no prompt, no summary, no "are you
sure". The next line is how you find out, and the line after it is the thirty
seconds that the backup cost.

Better than the habit: **keep the crontab in a file in version control** and
install it with `crontab jobs.cron`. Then `-r` costs you thirty seconds rather
than a schedule nobody remembers.

And note the `exit 1` in that transcript: **`crontab -l` fails when there is no
crontab**, rather than printing nothing and succeeding, which is a thing a script
can check.

## Where it actually lives

```
/var/spool/cron/crontabs/ana        # Debian and Ubuntu
/var/spool/cron/ana                 # Red Hat and SUSE
```

The directory is mode `1730` and owned by `root:crontab`, so you cannot read
anybody else's and you cannot write your own by hand — which is why `crontab -e`
exists rather than being a convenience.

**Do not edit the spool file directly even as root.** Cron notices a changed
crontab by the directory's modification time, and an editor that writes in place
can leave the file changed and the directory untouched.

## Two things that are not obvious

**The crontab has no `SHELL` and no path unless you say so.** Section 215 is the
whole subject and it is the commonest way a job that works in your terminal does
nothing at all at three in the morning.

**A crontab file needs a final newline**, and a generated one often does not have
it:

```
ana@vm:~/work/cron$ od -c nonl.cron | tail -2
0000040   c   h   o       g   o   o   d   b   y   e
0000053
ana@vm:~/work/cron$ crontab nonl.cron; echo "exit $?"
new crontab file is missing newline before EOF, can't install.
exit 1
```

**It refuses, loudly, and installs nothing** — the old crontab is still there,
untouched. That is the good case and it is worth knowing which case it is: a
deploy script that pipes a here-document into `crontab -` and ignores the exit
status will report success and change nothing at all.
