---
title: Breaking it, and going back
version: 1
---

Now the change that goes wrong. The file is deleted, and a program the system needs goes missing:

```
ana@vm1:~$ rm notes.txt; sudo mv /usr/bin/ls /usr/bin/ls.gone; ls
bash: line 1: ls: command not found
```

A minute later, one command on the host:

```
ana@host:~$ virsh snapshot-revert vm1 clean
Domain snapshot clean reverted

ana@vm1:~$ cat notes.txt; ls -d /etc; date +%T
checked, all fine
/etc
20:27:08
ana@host:~$ date +%T
20:28:14
```

`notes.txt` is back, `ls` is back, and the guest never noticed anything happened, because to the guest
nothing did: it was put back into the memory and disk of the moment the snapshot was taken.

**Including its clock.** The guest says 20:27:08, the host says 20:28:14: the guest is 66 seconds behind,
because it resumed at the snapshot's moment and has no idea time passed. A guest with a network time
service corrects itself within minutes. Until then, and on a snapshot from last week, the wrong time
causes very real faults:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A timeline. The snapshot is taken at 20:26:55. The guest is then broken, and a minute passes. At the revert, the guest goes back to the moment of the snapshot, memory and clock included, so a few seconds later its clock says 20:27:08 while the host&#x27;s says 20:28:14: 66 seconds behind.\"><defs><marker id=\"ck-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M20 70 L700 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ck-ah)\"></path><circle cx=\"40\" cy=\"70\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"34\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">snapshot taken</text><text x=\"34\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20:26:55</text><circle cx=\"240\" cy=\"70\" r=\"6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"234\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the guest is broken</text><circle cx=\"480\" cy=\"70\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"474\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">reverted</text><path d=\"M 474 62 C 330 10, 170 10, 48 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ck-ah)\" stroke-dasharray=\"4 3\"></path><text x=\"480\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the guest’s clock</text><text x=\"640\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">20:27:08</text><text x=\"480\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the host’s clock</text><text x=\"640\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20:28:14</text><text x=\"480\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">66 seconds behind</text></svg>", "caption": "Reverting a running snapshot takes the guest back in time, clock and all. The files come back as they were, and so does a time that is no longer true."}
```

- **Logins that check the time**, such as Kerberos in a Windows domain, refuse a clock more than a few
  minutes off.
- **Certificates** look not yet valid, or expired, lesson 6 of the networks course.
- **A Windows machine in a domain can lose its trust with the domain** if it is reverted past a change
  of its machine password, which the domain makes every month. The message says the trust relationship
  failed, and the fix is to join it again.

So a snapshot is for going back **a short way**: minutes or days, while you test something. Going back
months is restoring an old machine into a present that has moved on.
