---
title: How Linux decides, entry by entry
version: 1
---

**The kernel does not add up a user's entries. It finds the first class that applies and stops.** The
common belief is that access is the sum of everything that applies to you, your user entry plus every
group you are in. On Linux it is not, and the difference can lock out the person it was meant to help
or, less often, keep in somebody it was meant to restrict.

The order is fixed, and it is checked from the top:

1. **Owner.** If you own the file, the owner bits decide, and nothing else is looked at.
2. **Named user.** If there is an entry for your user, it decides, limited by the mask.
3. **Groups.** If the owning group or any named group you belong to is in the list, you get the
   access of any one of them that grants what you asked, limited by the mask; if they all refuse,
   you are refused.
4. **Other.** Only if none of the above applied.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l06-resolve\" aria-label=\"How Linux resolves a POSIX ACL, as four questions asked in order, stopping at the first yes. One: does the user own the file? Then the owner entry decides. Two: is there a named entry for the user? Then that entry, limited by the mask, decides. Three: is the owning group or a named group one of the user's groups? Then access is granted if any matching group entry, limited by the mask, allows it, and refused otherwise. Four: otherwise the other entry decides. The example: the auditor, in the writing group but with a named entry for read, stops at question two and gets read only.\"><defs><marker id=\"l06-resolve-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l06-resolve-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"250.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1  owner?</text><text x=\"300.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">user::</text><path d=\"M145.0 74.0 L145.0 92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-resolve-dh-ah-paper-dim)\"></path><text x=\"155.0\" y=\"83.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no</text><rect x=\"20.0\" y=\"92.0\" width=\"250.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36.0\" y=\"114.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2  named user?</text><text x=\"300.0\" y=\"114.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">user:auditoria:r--</text><path d=\"M145.0 136.0 L145.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-resolve-dh-ah-paper-dim)\"></path><text x=\"155.0\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no</text><rect x=\"20.0\" y=\"154.0\" width=\"250.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3  one of my groups?</text><text x=\"300.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">group::rw-</text><path d=\"M145.0 198.0 L145.0 216.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-resolve-dh-ah-paper-dim)\"></path><text x=\"155.0\" y=\"207.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no</text><rect x=\"20.0\" y=\"216.0\" width=\"250.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36.0\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4  everybody else</text><text x=\"300.0\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">other::---</text><rect x=\"470.0\" y=\"80.0\" width=\"230.0\" height=\"70.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the auditor asks to write</text><text x=\"585.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">stops at 2: read only</text><text x=\"585.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">step 3 is never asked</text><path d=\"M470.0 115.0 L440.0 115.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-resolve-dh-ah-phosphor)\"></path><text x=\"360.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">steps 2 and 3 are limited by the mask</text></svg>", "caption": "The first class that applies decides. Entries are never added up."}
```

The step that surprises people is the second. Put the auditor into `contabil`, the group that may
write, and ask her to write to a file where she also has a named entry for read only:

```
ana@web:~$ sudo usermod -aG contabil auditoria && id auditoria
uid=1004(auditoria) gid=1005(auditoria) groups=1005(auditoria),1002(contabil)
ana@web:~$ echo "edited" | sudo -u auditoria tee -a /srv/clientes/souza.txt
tee: /srv/clientes/souza.txt: Permission denied
edited
ana@web:~$ sudo setfacl -x u:auditoria /srv/clientes/souza.txt && echo "edited" | sudo -u auditoria tee -a /srv/clientes/souza.txt
edited
```

Refused. She is in the writing group, but the kernel found her named entry first, at step 2, and
stopped there: `r--`. Remove the named entry with `setfacl -x`, and the same request reaches step 3,
where the group grants write, and succeeds. **A named user entry can take access away from somebody
whose group would give it.** That makes it a precise tool, the way to say "this one person, read
only, whatever groups she joins", and a confusing one, when somebody adds a user to a group and
nothing changes.

Step 4 is where everybody else lands, and on this directory it is empty:

```
ana@web:~$ sudo -u estagio ls /srv/clientes
ls: cannot open directory '/srv/clientes': Permission denied
```

The intern's account, which lesson 1 locked and which is back in this fresh lab, cannot even list the
directory. That is the bits and the ACL working together: `other::---` on the directory and on every
file in it, and no entry for anybody who does not need one.

## Reading a list correctly

When the question is "can this person do this", answer it in the kernel's order, with `getfacl` and
`id` side by side: is the person the owner, is there an entry with their name, which of their groups
appear, and what does the mask allow. When in doubt, ask the system, as this lesson has done
throughout: `sudo -u <user> test -r <file>` answers for reading without changing anything, and
`-w` for writing.
