---
title: Holding a package back on purpose
version: 1
---

**Sometimes an update must not be installed on one machine yet.** Lesson 16 called this an
exception: the update breaks something the firm depends on, the vendor is working on it, and the
machine has to stay on the old version until then. apt's word for it is a **hold**:

```
root@web:~# apt-mark hold jatoba-health; apt-mark showhold
jatoba-health set on hold.
jatoba-health
root@web:~# apt-get -s upgrade 2>&1 | grep -A1 "kept back"
The following packages have been kept back:
  jatoba-health
root@web:~# unattended-upgrade --dry-run --debug 2>&1 | grep -E "^(Packages that will be upgraded|No packages found)"
No packages found that can be upgraded unattended and no pending auto-removals
```

`apt-mark hold` marks the package, and `showhold` lists what is held. A simulated upgrade now keeps
it back, and unattended upgrades leave it alone: the package that the previous section's dry run would
have upgraded is now not a candidate at all. A hold is respected by every apt command that upgrades,
which is what makes it the right tool and also what makes it dangerous.

## A hold is invisible unless somebody looks

Nothing complains about a held package. It does not expire, it does not appear in the morning's
mail, and six months later nobody remembers why it is there. **A hold is lesson 16's exception
without the record**, unless the record is kept somewhere else:

| field | for this hold |
|---|---|
| machine and package | `web`, `jatoba-health` held at `1.0` |
| reason | `1.1` breaks the monitoring job that parses its output; vendor ticket open |
| compensating control | the monitoring job checks the portal directly until the fix |
| owner | the person responsible for `web`, by name |
| expires | a date; on that date the hold is removed or the exception renewed by the same owner |

The check that keeps holds honest is cheap: `apt-mark showhold` on every machine, compared with the
list of exceptions. Anything held without an exception is a finding, and lesson 18's inventory is
where that comparison is made once for the whole firm.

## Holding is not the only way

A hold freezes a package at whatever is installed. apt also has **pinning**, a file in
`/etc/apt/preferences.d/` that sets priorities per package or per origin, which can say "never above
1.0" or "prefer the internal mirror". Pinning is more precise and more easily forgotten, and for the
case in this section, one package on one machine for a few weeks, a hold with a record beside it is
enough.
