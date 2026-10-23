---
title: The mask, which chmod rewrites
version: 1
---

**The mask is the most that any named user, named group or the owning group may have.** An entry
grants what it says *and* what the mask allows; whatever the mask does not allow is not granted,
whatever the entry says. The owner and others are outside it. It exists so that the old tools, which
know only nine bits, can still narrow a file that carries an ACL.

The trap is what those old tools do to it. Give `portal` write access on the file, then do what any
administrator has done a thousand times, `chmod 640`, meaning "owner reads and writes, group reads":

```
ana@web:~$ sudo setfacl -m u:portal:rw /srv/clientes/silva.txt && sudo getfacl -p --omit-header /srv/clientes/silva.txt
user::rw-
user:portal:rw-
user:auditoria:r--
group::rw-
mask::rw-
other::---

ana@web:~$ sudo chmod 640 /srv/clientes/silva.txt && sudo getfacl -p --omit-header /srv/clientes/silva.txt
user::rw-
user:portal:rw-	#effective:r--
user:auditoria:r--
group::rw-	#effective:r--
mask::r--
other::---

ana@web:~$ echo "edited" | sudo -u joao tee -a /srv/clientes/silva.txt; sudo ls -l /srv/clientes/silva.txt
tee: /srv/clientes/silva.txt: Permission denied
edited
-rw-r-----+ 1 maria contabil 37 Oct 23 09:35 /srv/clientes/silva.txt
```

Before the `chmod`, the mask was `rw-` and nothing was hidden. After it, `ls` shows `rw-r-----`, as
asked, but look at what changed. **On a file with an ACL, the middle three bits that `ls` shows are
the mask, not the owning group.** `chmod g-w`, or `chmod 640`, rewrote the mask to `r--`, and every
entry under it lost write: `getfacl` marks `portal` and the group with `#effective:r--`. João, an
accountant whose group entry still reads `rw-`, is refused.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l06-mask\" aria-label=\"The mask as a ceiling. Before chmod 640, the entries for portal and for the group say rw and the mask is rw, so each gets rw. After chmod 640, the mask is r, so portal and the group each get only r, although their own entries still say rw. The owner and other are outside the mask and are unchanged.\"><text x=\"180.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">before chmod 640</text><rect x=\"20.0\" y=\"40.0\" width=\"320.0\" height=\"34.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">mask::rw-</text><text x=\"328.0\" y=\"57.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ceiling</text><rect x=\"20.0\" y=\"100.0\" width=\"320.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"117.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">user:portal:rw-</text><text x=\"328.0\" y=\"117.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">effective rw-</text><rect x=\"20.0\" y=\"146.0\" width=\"320.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">group::rw-</text><text x=\"328.0\" y=\"163.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">effective rw-</text><text x=\"540.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">after chmod 640</text><rect x=\"380.0\" y=\"40.0\" width=\"320.0\" height=\"34.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"392.0\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">mask::r--</text><text x=\"688.0\" y=\"57.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ceiling</text><rect x=\"380.0\" y=\"100.0\" width=\"320.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"392.0\" y=\"117.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">user:portal:rw-</text><text x=\"688.0\" y=\"117.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">effective r--</text><rect x=\"380.0\" y=\"146.0\" width=\"320.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"392.0\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">group::rw-</text><text x=\"688.0\" y=\"163.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">effective r--</text><text x=\"360.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the owner and other are outside the mask</text></svg>", "caption": "chmod on a file with an ACL rewrites the mask, and every entry under it shrinks."}
```

Nobody meant to take the accountants' write access away. The command did exactly what it does on a
file without an ACL, and on this file it means something else. Two consequences:

- **Read `getfacl` rather than `ls`** on any file marked `+`. The `#effective` column is the access
  people actually have.
- **Change an ACL file's access with `setfacl`**, and set the mask explicitly when you mean to:

```
ana@web:~$ sudo setfacl -m u:portal:r,m::rw /srv/clientes/silva.txt && sudo getfacl -p --omit-header /srv/clientes/silva.txt | grep -E "portal|group::|mask"
user:portal:r--
group::rw-
mask::rw-
```

`m::rw` puts the mask back, and `portal` returns to read-only, which is all it ever needed. The
accountants can write again, through the group entry the mask no longer narrows.

## Why it works this way

The mask lets a program that knows nothing about ACLs, such as a backup tool that restores files
with `chmod`, narrow a file safely: whatever it sets on the group bits limits every extra entry at
once, so a restored file is never more open than its bits say. The price is the trap above, paid by
the administrator who forgot the file had an ACL. That is why the `+` in `ls -l` is worth noticing
every time.
