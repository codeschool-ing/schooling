---
title: Rolling back, and when not to
version: 1
---

**An update that goes wrong has to come out faster than it went in.** That is the other half of
patching quickly: a team that can undo a bad update in minutes can afford to install updates early,
and one that cannot will wait. On `desk`, version `1.1` is installed; going back to `1.0` is an
install with the version named:

```
ana@admin:~$ ssh desk "sudo apt-get install -y -q --allow-downgrades jatoba-health=1.0 2>&1 | grep -E \"^(Unpacking|Setting)|downgrad\"; jatoba-health"
0 upgraded, 0 newly installed, 1 downgraded, 0 to remove and 0 not upgraded.
dpkg: warning: downgrading jatoba-health from 1.1 to 1.0
Unpacking jatoba-health (1.0) over (1.1) ...
Setting up jatoba-health (1.0) ...
jatoba-health 1.0
portal 200
ana@admin:~$ ssh desk "grep jatoba-health /var/log/dpkg.log | grep -E \" (install|upgrade) \""
2026-10-23 09:29:20 install jatoba-health:all <none> 1.0
2026-10-23 09:29:22 upgrade jatoba-health:all 1.0 1.1
2026-10-23 09:29:24 upgrade jatoba-health:all 1.1 1.0
```

apt asks for `--allow-downgrades` because installing an older version is not something it does by
default; dpkg warns that it is downgrading, unpacks `1.0` over `1.1` and sets it up. The program runs
and the portal answers. dpkg's log keeps the whole history, one line per change, and a downgrade
appears there as an `upgrade` from the newer version to the older one.

The rollback worked because the old version was still in the repository. **A repository that keeps
only the latest version is one you cannot roll back from**, which is a reason to keep older versions
in the firm's mirror for as long as any machine might need one.

## When rolling back is the wrong move

A package can be rolled back. What the update did while it was installed sometimes cannot:

- **a database migration**: the new version changed a schema or converted stored data, and the old
  version cannot read it;
- **a changed configuration format**: the new version rewrote its configuration file, and the old one
  refuses it;
- **a security fix**: rolling back reopens the flaw the update closed, so the rollback is an
  exception in lesson 16's sense, with a reason, a compensating control and a date.

For the first two, the protection is a snapshot taken before the update: of the virtual machine, of
the database, of the configuration directory. Lesson 1 recommended building the lab in a virtual
machine partly for this, and Multipass can snapshot a stopped machine. **Rolling forward**, installing
a fixed newer version rather than the old one, is often the better answer, and the rings exist so
that a bad update reaches few enough machines for either choice to be quick.
