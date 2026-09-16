---
title: Unit files, and which copy wins
version: 1
---

A unit file is how a service describes itself. It is an ini file — sections in square brackets,
`Key=Value` lines — and it replaced the shell script section 08 was about.

Here is a complete one, and it is doing everything a small service needs:

```
root@vm:~# cat /etc/systemd/system/hello.service
[Unit]
Description=A tiny service that says hello
Documentation=https://example.com/hello
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/hello.sh
Restart=on-failure
RestartSec=5
User=ana

[Install]
WantedBy=multi-user.target
```

Twelve lines. Under SysV that was a hundred lines of shell, most of it PID-file handling that
systemd now does itself.

## `[Unit]` — what it is and what it needs

| | |
|---|---|
| `Description=` | the text after the name in `systemctl status` |
| `Documentation=` | a URL or a `man:` page. `systemctl status` prints it |
| `After=` | start **after** this, if this is being started at all |
| `Requires=` | and **fail** if that one fails |
| `Wants=` | prefer it started first, and carry on if it is not |

**`After=` is about order, `Requires=` is about dependency, and they are not the same.** `After=`
without `Requires=` means *if you are starting both, do that one first* — and says nothing about
whether the other one has to exist. Almost everything you write wants `After=` alone.

`Requires=` is strong: if the required unit stops or fails, yours is stopped too. Use it when the
service genuinely cannot work without the other, and `Wants=` when it would merely prefer to.

## `[Service]` — how to run it

**`Type=` is the field that goes wrong.**

| | means | when |
|---|---|---|
| `simple` | the process you start **is** the service | the default, and almost always right |
| `exec` | like simple, but wait until it has actually started | slightly safer than simple |
| `forking` | the program daemonises itself and the **parent exits** | an old-style daemon |
| `oneshot` | it runs, it finishes, and that is success | a setup job — section 10's `active (exited)` |
| `notify` | the program tells systemd when it is ready | services written for systemd |

**A modern program should not daemonise**, and if it does not, `Type=simple` is correct. Telling
systemd `forking` about a program that stays in the foreground produces a start that hangs and then
times out — one of the more confusing failures there is, because nothing is actually broken.

The rest of what you will write:

| | |
|---|---|
| `ExecStart=` | the command. **An absolute path**, and no shell — no `&&`, no `>`, no `$VAR` expansion |
| `ExecReload=` | what `systemctl reload` runs. Absent means reload is refused |
| `Restart=` | `no`, `on-failure`, `always`, `on-abnormal` |
| `RestartSec=` | how long to wait first. Without it, a crash loop is a tight one |
| `User=`, `Group=` | the account to run as — section 07's third property, in one line |
| `WorkingDirectory=` | lesson 3 section 03's point: a service starts in `/` unless told |
| `Environment=` | one variable; `EnvironmentFile=` for a file of them |
| `UMask=` | lesson 4 section 09 said your dotfile does not reach here. This does |

**`ExecStart=` is not a shell command.** That is the mistake everybody makes once: `ExecStart=/usr/bin/foo > /var/log/foo.log`
does not redirect — it passes `>` and the path as two arguments to `foo`. If you need a shell, say
so: `ExecStart=/bin/sh -c 'foo > /var/log/foo.log'`. Usually you do not, because section 12's
journal already collects the output.

## `[Install]` — what `enable` should do

```
[Install]
WantedBy=multi-user.target
```

This section is **only** read by `systemctl enable`, and it says which `.wants` directory the
symlink goes in. Section 09 showed the symlink being made; this is the line that decided where.

**A unit with no `[Install]` section cannot be enabled**, and `systemctl is-enabled` calls it
`static`. That is intentional for units that something else pulls in.

## Where they live, and which one wins

```
root@vm:~# systemd-analyze unit-paths
/etc/systemd/system.control
/run/systemd/system.control
/run/systemd/transient
/run/systemd/generator.early
/etc/systemd/system
/etc/systemd/system.attached
/run/systemd/system
/run/systemd/system.attached
/run/systemd/generator
/usr/local/lib/systemd/system
/usr/lib/systemd/system
/run/systemd/generator.late
```

**That list is in priority order, highest first.** Three of the entries matter to you:

| | |
|---|---|
| `/usr/lib/systemd/system` | **the package's copy.** An upgrade overwrites it |
| `/usr/local/lib/systemd/system` | software you installed by hand — lesson 3 section 02's `/usr/local` |
| `/etc/systemd/system` | **yours.** Higher priority, and nothing overwrites it |

So a file you put in `/etc/systemd/system/nginx.service` completely replaces the packaged one, and
survives upgrades. That is the mechanism, and it has a trap: **your copy stops receiving the
package's improvements**, silently, for as long as it exists. A fix upstream makes to the unit is a
fix you do not get.

## `systemctl edit` is the better answer

```
sudo systemctl edit nginx
```

This opens an empty file and writes what you type to
`/etc/systemd/system/nginx.service.d/override.conf` — a **drop-in**. Those are merged on top of the
packaged unit rather than replacing it, so you change one line and inherit every other:

```
[Service]
Restart=always
RestartSec=10
```

Four lines instead of forty, and the package's unit keeps updating underneath.

`systemctl edit --full` gives you the whole file to override instead, when a drop-in will not do.
And `systemctl edit` runs `daemon-reload` for you afterwards, which is the step section 09 said
people forget.

`systemctl cat nginx` prints the unit and every drop-in applied to it, in order — which is how you
find out what somebody else did to a machine.

## Check it before you start it

This is the command from the demonstration at the end of the lesson, and it runs on a **file**
rather than on a running system:

```
root@vm:~# systemd-analyze verify /etc/systemd/system/broken.service
/etc/systemd/system/broken.service:2: Unknown key name 'Descriptoin' in section 'Unit', ignoring.
/etc/systemd/system/broken.service:8: Failed to parse service restart specifier, ignoring: maybe
Binding to IPv6 address not available since kernel does not support IPv6.
broken.service: Command /usr/local/bin/does-not-exist.sh is not executable: No such file or directory
root@vm:~# echo $?
1
```

Ignore the IPv6 line — that is this machine's kernel, not your unit, and it appears whatever you
verify. The other three are the findings, and **read the last word of the first two: `ignoring`.**

A misspelled key name is not an error. systemd drops the line and carries on, so a service with
`Descriptoin=` has no description and no complaint, and a service with `Restart=maybe` does not
restart and never said so. **That silence is the characteristic systemd bug**, and `verify` is the
only thing that will tell you.

The third finding would have failed loudly at start. It is the least dangerous of the three and the
only one most people ever catch.

On a valid file the same command has nothing to say, which is lesson 1's silence-is-success
arriving in a new place:

```
root@vm:~# systemd-analyze verify /etc/systemd/system/hello.service
Binding to IPv6 address not available since kernel does not support IPv6.
root@vm:~# echo $?
0
```

The one line is the same machine noise as before, and the exit status is `0`. **That is the
answer** — and it is why a script checks `$?` rather than whether anything was printed.

**Run it on every unit you write, before you start it.** It costs a second.
