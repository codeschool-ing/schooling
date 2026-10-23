---
title: Updates nobody has to type
version: 1
---

**On most machines, the right number of people involved in a security update is zero.** Ubuntu
installs `unattended-upgrades` by default, and it runs once a day: it refreshes the package lists,
picks the upgrades that come from origins it is allowed to trust, and installs them. For a
workstation or a server where a security fix is more urgent than any risk the fix brings, that is the
patching process, and the rings are what it does across the firm's machines because each one runs at
a slightly different moment.

Two files decide what it does. `20auto-upgrades` switches it on; `50unattended-upgrades` lists the
**origins** it may install from, and on Ubuntu that list holds the release and its security updates
and nothing else. The firm's own repository is not on it, so add it, matching the `Origin` the
`Release` file was given. First `web` goes back to `1.0`, so there is something to upgrade:

```
root@web:~# apt-get install -y -q --allow-downgrades jatoba-health=1.0 >/dev/null 2>&1; dpkg-query -W jatoba-health
jatoba-health	1.0
root@web:~# printf 'Unattended-Upgrade::Origins-Pattern { "origin=Jatoba"; };\n' > /etc/apt/apt.conf.d/51jatoba; cat /etc/apt/apt.conf.d/51jatoba /etc/apt/apt.conf.d/20auto-upgrades
Unattended-Upgrade::Origins-Pattern { "origin=Jatoba"; };
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
root@web:~# unattended-upgrade --dry-run --debug 2>&1 | grep -E "^(Allowed origins|Packages that will be upgraded|All upgrades)"
Allowed origins are: o=Ubuntu,a=noble, o=Ubuntu,a=noble-security, o=UbuntuESMApps,a=noble-apps-security, o=UbuntuESM,a=noble-infra-security, origin=Jatoba
Packages that will be upgraded: jatoba-health
All upgrades installed
```

`--dry-run --debug` reports what a real run would do without doing it. **Allowed origins** lists
Ubuntu's four and the firm's own, and the line after it names `jatoba-health` as the package it would
upgrade. The last line says `All upgrades installed`; in a dry run that only means the simulated
installation succeeded, and `dpkg-query` would still report `1.0`.

## What it should not touch

Automatic updates fit packages whose updates are routine and whose failure is cheap. They fit badly
where an update changes behaviour, restarts something with users connected, or needs a step a person
must take. The settings in `50unattended-upgrades` cover the common cases:

| setting | what it does |
|---|---|
| `Unattended-Upgrade::Package-Blacklist` | packages it must never upgrade on its own, by name or pattern |
| `Unattended-Upgrade::Automatic-Reboot` | whether it may reboot when an update asks for it, and `Automatic-Reboot-Time` for when |
| `Unattended-Upgrade::Mail` | an address that receives a report of each run |

**A machine that updates itself still needs somebody to read what it did.** The log is in
`/var/log/unattended-upgrades/`, and lesson 18's inventory, which reads installed versions from every
machine, is what tells you whether every machine actually did it. A laptop that has been switched off
for a month has not.
