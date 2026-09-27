---
title: What sudo reaches
version: 1
---

Elisa uses pc1. Her folder is closed to other users, and the technician's own account is refused like
anyone else's:

```
ana@pc1:~$ ls /home/elisa
ls: cannot open directory '/home/elisa': Permission denied
ana@pc1:~$ sudo ls /home/elisa
letter-to-doctor.txt
```

With `sudo`, the refusal is gone. That is the point of an administrator's account: the next ticket may be
a folder whose permissions are broken, and the technician has to be able to reach it. It also means **the
permissions protect Elisa from everyone except support**.

And the command above already showed something that was none of the technician's business. Nobody opened
the file, and its name alone says something about Elisa's health. Under the LGPD, data about health is
*sensitive personal data*, with stricter rules than the rest.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A large box, what sudo reaches: every home folder, every printed copy, every mailbox on a mail server, every log. Inside it a small box, what the ticket needs: the one folder, the one queue.\"><defs><marker id=\"rc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">what sudo reaches</text><text x=\"36\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every home folder</text><text x=\"36\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every printed copy</text><text x=\"36\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every mailbox on a mail server</text><text x=\"36\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every log</text><rect x=\"430\" y=\"70\" width=\"240\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">what the ticket needs</text><text x=\"446\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the one folder, the one queue</text></svg>", "caption": "The permission is the large box and the job is the small one. Nothing on the computer keeps a technician inside the small box: only the technician does."}
```

The rule that follows is called **need to know**: look at what the ticket needs, and only that. A ticket
about a full disk needs sizes, `du`, lesson 3, not file names. A ticket about one folder's permissions
needs that folder. If the job can be done without listing a person's files, it is done without listing
them.
