---
title: Automatic security updates
version: 1
---

A standard Ubuntu Server installs **unattended-upgrades** and turns it on. Lesson 3's minimal server
left it out, so it is installed here, with lesson 11's tool:

```
ana@server:~$ sudo apt install -y unattended-upgrades > uu.log 2>&1; grep "^Setting up" uu.log
Setting up python-apt-common (2.7.7ubuntu5.3) ...
Setting up python3-distro-info (1.7build1) ...
Setting up iso-codes (4.16.0-1) ...
Setting up python3-apt (2.7.7ubuntu5.3) ...
Setting up unattended-upgrades (2.9.1+nmu4ubuntu1) ...
ana@server:~$ cat /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
ana@server:~$ grep -A2 '^Unattended-Upgrade::Allowed-Origins' /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
        "${distro_id}:${distro_codename}";
        "${distro_id}:${distro_codename}-security";
ana@server:~$ systemctl list-timers apt-daily-upgrade.timer --no-pager
NEXT                        LEFT LAST                        PASSED UNIT                    ACTIVATES
Sat 2026-09-26 03:29:33 -03  15h Fri 2026-09-25 10:11:25 -03      - apt-daily-upgrade.timer apt-daily-upgrade.service

1 timers listed.
Pass --all to see loaded but inactive timers, too.
```

- Five packages were set up: the tool and four it needs.
- `20auto-upgrades` is two switches: refresh the package lists daily (`"1"`), and apply upgrades
  daily.
- `50unattended-upgrades` decides **which** upgrades: by default the release and its `-security`
  suite. Ordinary updates from `-updates` are not in the list, so they wait for a person.
- `apt-daily-upgrade.timer`, a lesson 14 timer, is what runs it: at a randomised time each morning,
  so that thousands of servers do not all ask the archive at once.

## Windows and macOS

**Windows Update** downloads and installs security and quality updates on its own on Home and Pro.
What an office controls is *when*: *active hours*, during which it will not restart, and *pause*,
up to five weeks. On Pro, Group Policy can delay feature updates for months, which is lesson 5's point
about Home and Pro again.

```sh
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5   # the latest updates
wusa /uninstall /kb:<number>                   # remove one update, by the number Get-HotFix showed
```

**Not run for this lesson.** Each Windows update has a **KB** number, the Knowledge Base article that
describes it, and `Get-HotFix` lists them.

On a Mac, *System Settings > General > Software Update > Automatic updates* has separate switches for
downloading, installing macOS updates, and installing **Security Responses and system files**, the
small urgent fixes. The last one should always be on.
