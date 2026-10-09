---
title: Recovery, in steps
version: 1
---

**Recovery** is returning the systems to normal service, and confirming that they are working normally. The
second half is the one that takes the time.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Recovery as five steps, each with a gate before the next: restore from a known-good source; verify that the fix is in and the hole is closed; return to service, one system at a time; monitor more closely, for a set period; close, when the criteria written at the start are met.\"><rect x=\"10\" y=\"50\" width=\"124\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"72.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">restore</text><text x=\"72.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">known-good source</text><path d=\"M134 82 L154 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M154 82 L146.0 78.0 L146.0 86.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"154\" y=\"50\" width=\"124\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"216.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">verify</text><text x=\"216.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fix in, hole closed</text><path d=\"M278 82 L298 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M298 82 L290.0 78.0 L290.0 86.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"298\" y=\"50\" width=\"124\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">return</text><text x=\"360.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one system at a time</text><path d=\"M422 82 L442 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M442 82 L434.0 78.0 L434.0 86.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"442\" y=\"50\" width=\"124\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"504.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">monitor</text><text x=\"504.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">for a set period</text><path d=\"M566 82 L586 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M586 82 L578.0 78.0 L578.0 86.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"586\" y=\"50\" width=\"124\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"648.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">close</text><text x=\"648.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">criteria met</text></svg>", "caption": "Each step has a gate: the next one starts when this one is checked, not when it is done."}
```

Every step has a **gate**: the next one starts when this one has been checked, not when it has been done. For
`gw`, after the rebuild, the gate before returning it to service is three questions with evidence: is the
hole closed, does the legitimate way in still work, and is it being recorded?

```
root@soc:~# ip netns exec outside ssh -o BatchMode=yes -o PreferredAuthentications=password -o StrictHostKeyChecking=accept-new ana@198.51.100.22 true
ana@198.51.100.22: Permission denied (publickey).
root@soc:~# ip netns exec outside runuser -u ana -- ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new ana@198.51.100.22 hostname
gw
root@soc:~# tail -n 4 /var/log/soclab/gw-auth.log
2026-10-07T20:48:18-0300 gw sshd: Connection closed by authenticating user ana 203.0.113.66 port 55460 [preauth]
2026-10-07T20:48:18-0300 gw sshd: Accepted publickey for ana from 203.0.113.66 port 55466 ssh2: ED25519 SHA256:QJsKkPtqEBuAn+lfcyMGgnotN3pJ16nFW1AbcdPz8bo
2026-10-07T20:48:18-0300 gw sshd: Received disconnect from 203.0.113.66 port 55466:11: disconnected by user
2026-10-07T20:48:18-0300 gw sshd: Disconnected from user ana 203.0.113.66 port 55466
```

The first command asks only for a password and is refused: `Permission denied (publickey)`, the server
offering keys and nothing else. The second logs in with ana's key and runs `hostname`: `gw`. The log has both:
a connection closed before authentication, and an accepted key, with its fingerprint, the same one the
inventory holds. **That fingerprint in the log is what the audit and the monitoring meet on**: a login by a
key that is not in the inventory is lesson 4's kind of rule, waiting to be written.

**Return one system at a time.** `gw` first, watched for a day; then bruno's account, with its new key; then
the egress rule's exceptions reviewed with the file server's owner. If something goes wrong, it is clear which
step did it.

**The end of recovery is written at the start.** For Thursday, the incident record says recovery is complete
when: `gw` is rebuilt and passes the three checks; every key on both hosts is in the inventory; passwords are
off on `gw`; the egress rule is in the firewall's source; and two weeks of daily login reviews have found
nothing. Without criteria like these, an incident is never closed, or it is closed on the day everybody is
tired of it, which is not the same thing.

Then the incident goes to its last phase, and the one that makes the next one cheaper: lesson 15.
