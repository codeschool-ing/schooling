---
title: How soon, to whom, and the way back
version: 1
---

"Update everything immediately" and "never touch a working machine" are both wrong. The answer depends
on what the update changes:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 180\" role=\"img\" aria-label=\"How quickly each kind of update should reach an office&#x27;s machines. Security fixes within days, to every machine, automatically. Ordinary updates within a week or two, to a pilot group first and then the rest. Feature updates within months, after the pilot group has used them for weeks.\"><defs><marker id=\"rg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"30\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">kind</text><text x=\"240\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">how soon</text><text x=\"410\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">to whom</text><rect x=\"20\" y=\"30\" width=\"680\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">security fixes</text><text x=\"240\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">within days</text><text x=\"410\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">every machine, automatically</text><rect x=\"20\" y=\"76\" width=\"680\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ordinary updates</text><text x=\"240\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">within a week or two</text><text x=\"410\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a pilot group first, then the rest</text><rect x=\"20\" y=\"122\" width=\"680\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">feature updates</text><text x=\"240\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">within months</text><text x=\"410\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">after the pilot group has used it for weeks</text></svg>", "caption": "The more an update changes, the longer it waits and the smaller the group that meets it first. Security fixes are the exception that does not wait."}
```

The **pilot group** is a few machines whose users are told they are first, often Ana's own. If a
feature update breaks the scanner, it breaks one desk, and the rest of the office waits while the maker
is asked for a driver.

## Holding one package back

Sometimes one program must not change, for a while: the accounting software is certified on an exact
version of a library until the vendor catches up. Linux can **hold** one package while everything else
updates:

```
ana@server:~$ sudo apt-mark hold cron
cron set on hold.
ana@server:~$ apt-mark showhold
cron
ana@server:~$ sudo apt-mark unhold cron
Canceled hold on cron.
```

A hold is a **debt with no date on it**. Write down why and until when, or the package stays behind
for years and becomes the next CVE nobody fixed.

## Restarting

Most Linux updates take effect when the program restarts; a new **kernel** needs the whole machine to
restart, lesson 3's point. Ubuntu leaves a marker file when that is needed:

```
ana@server:~$ ls /var/run/reboot-required
ls: cannot access '/var/run/reboot-required': No such file or directory
```

No such file, so no restart is owed. On Windows the equivalent is *Restart required* in Windows Update,
and it is why active hours exist.

## The way back

- *Windows*: *Settings > Windows Update > Update history > Uninstall updates*, or `wusa` from section
  02; a feature update can be rolled back within ten days, in *System > Recovery > Go back*.
- *Linux*: `apt install package=version` puts back an older version while the archive still has it,
  and a server's disk snapshot or backup is the bigger way back.
- *Anything*: the backup taken before, which lesson 17 relies on.
