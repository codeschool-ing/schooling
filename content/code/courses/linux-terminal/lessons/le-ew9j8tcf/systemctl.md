---
title: Seven verbs, and `enable` is not `start`
version: 2
---

`systemctl` is the front end to all of systemd, and you need seven of its verbs. They divide into
two groups, and the division is the single most important thing in this lesson.

| **now** | | **at the next boot** |
|---|---|---|
| `start` | | `enable` |
| `stop` | | `disable` |
| `restart` | | |
| `reload` | | |
| `status` | | `is-enabled` |

```
sudo systemctl start nginx        # run it, this second
sudo systemctl enable nginx       # run it every boot from now on
sudo systemctl enable --now nginx # both
```

**`enable` does not start anything. `start` does not survive a reboot.** Every one of us has set up
a service, checked that it works, rebooted, and found it absent — and this is why.

## What `enable` actually does

Here it is, run against a filesystem tree rather than a running system, which is why it works on
this machine:

```
root@vm:/srv/machines/ubuntu24# systemctl --root=/srv/machines/ubuntu24 is-enabled hello.service
disabled
root@vm:/srv/machines/ubuntu24# systemctl --root=/srv/machines/ubuntu24 enable hello.service
Created symlink /srv/machines/ubuntu24/etc/systemd/system/multi-user.target.wants/hello.service → /etc/systemd/system/hello.service.
root@vm:/srv/machines/ubuntu24# systemctl --root=/srv/machines/ubuntu24 is-enabled hello.service
enabled
```

**`enable` made a symlink.** That is the whole of it.

Read the path it made: `multi-user.target.wants/`. Section 13 is about targets; for now, the
directory is a list of *things this target wants running*, and enabling a service is putting it in
that list. At boot, systemd reaches `multi-user.target`, reads the directory, and starts what is in
it.

Nothing about creating a symlink starts a program. **That is not a quirk — it is the correct
design**, and once you have seen the symlink the rule stops needing to be memorised.

`disable` removes it again:

```
root@vm:/srv/machines/ubuntu24# ls -l /srv/machines/ubuntu24/etc/systemd/system/multi-user.target.wants/
total 0
lrwxrwxrwx 1 root root 40 Sep 14 23:14 e2scrub_reap.service -> /lib/systemd/system/e2scrub_reap.service
lrwxrwxrwx 1 root root 33 Sep 14 23:23 hello.service -> /etc/systemd/system/hello.service
lrwxrwxrwx 1 root root 40 Sep 14 23:14 remote-fs.target -> /usr/lib/systemd/system/remote-fs.target
root@vm:/srv/machines/ubuntu24# systemctl --root=/srv/machines/ubuntu24 disable hello.service
Removed "/srv/machines/ubuntu24/etc/systemd/system/multi-user.target.wants/hello.service".
root@vm:/srv/machines/ubuntu24# systemctl --root=/srv/machines/ubuntu24 is-enabled hello.service
disabled
```

Three entries in that listing, and two of them were not put there by you — that is what an enabled
service looks like on any machine. Lesson 3 section 11 taught you to read `->`; this is that
reading, cashed in.

## `restart` and `reload` are not the same

| | does |
|---|---|
| `restart` | stop it, start it. **Connections drop, state is lost** |
| `reload` | tell it to re-read its configuration **while it keeps running** |
| `reload-or-restart` | reload if it supports it, restart if it does not |

**Prefer `reload` on anything serving traffic.** Nginx, Apache, Postgres and sshd all support it,
and a reload is invisible to whoever is connected.

Not every service implements it — the unit file has to say `ExecReload=`, and section 11 shows
where. `systemctl reload` on a service without one fails and tells you so, which is better than
silently restarting.

**And the one worth knowing about sshd**: reloading it does not disconnect you, and restarting it
does not either — the running session is already established. What a broken configuration *does*
kill is your next login, which is why you test with a second terminal you have not closed.

## `status` and `is-*`

```
systemctl status nginx        # the human answer — section 79
systemctl is-active nginx     # active / inactive / failed
systemctl is-enabled nginx    # enabled / disabled / static / masked
systemctl is-failed nginx     # for a script
```

The `is-*` family prints one word and sets an exit status, which makes them the ones to use in a
script. `status` is for reading, and section 10 takes it apart.

`systemctl is-enabled` has four answers and two of them need a word:

| | |
|---|---|
| `static` | it has no `[Install]` section, so it cannot be enabled — something else pulls it in |
| `masked` | deliberately disabled *hard*: linked to `/dev/null` so it cannot even be started by accident |

`mask` is the sledgehammer, and it exists for a real case: a package you cannot remove keeps
starting something you do not want. `unmask` undoes it. A service you cannot start for no apparent
reason is often a masked one, and `is-enabled` is how you find out in one word.

## Seeing what is there

```
systemctl list-units --type=service              # what is loaded and running
systemctl list-units --type=service --all        # including the inactive
systemctl --failed                               # the short list that matters
systemctl list-unit-files --type=service         # every unit file, enabled or not
```

**`systemctl --failed` is the first command to run on a machine somebody says is broken.** It
prints the services that tried and did not make it, and it is usually one line and usually the
answer.

The difference between the first and the last is worth keeping: `list-units` is about what is
**loaded right now**; `list-unit-files` is about what **exists on disk**. A service that is
installed and never started appears in one and not the other.

## The name, and the suffix you can usually omit

`nginx.service` is the full name. `systemctl start nginx` works because `.service` is assumed when
you leave the suffix off. Other kinds need it:

| suffix | is |
|---|---|
| `.service` | a program to run — the default |
| `.timer` | a schedule — lesson 13 |
| `.socket` | a port or socket that starts the service on first connection |
| `.mount` | a filesystem — lesson 3 section 12, generated from `/etc/fstab` |
| `.target` | a group of the above — section 13 |

So `systemctl start backup.timer` needs the suffix, and `systemctl start nginx` does not.

## Two more you will want

```
sudo systemctl daemon-reload      # after editing a unit file by hand
systemctl cat nginx               # print the unit file, and any overrides
```

**`daemon-reload` is the one people forget.** Edit a `.service` file and systemd carries on with
the version it read at boot until you tell it to re-read. The symptom is a change that has no
effect and a service that restarts happily into its old behaviour. `systemctl edit` — section 11 —
does the reload for you, which is one of several reasons to prefer it.
