---
title: Three copies, two kinds, one somewhere else
version: 1
---

Every backup in this course so far has lived on the same machine as the database it protects. Lesson
3 said it of the virtual machine's snapshot, and it is just as true of lesson 5's repository in
`/var/lib/pgbackrest`: a disk that fails, a machine that is deleted, a data centre that floods, or a
person with the server's password takes the database and every copy of it in one go. **A backup on
the same machine is a convenience for small mistakes, not a backup.**

The rule people have used for decades fits on one line:

| | |
|---|---|
| **3** | three copies of the data: the live one and two backups |
| **2** | on two different kinds of storage, so one kind of failure cannot take both |
| **1** | one of them somewhere else: another building, another region, another provider |

Ransomware added two digits to it, which lesson 10 is about: **1** copy that cannot be changed or
deleted for a set time, whatever credentials somebody holds, and **0** errors when that copy is
restored, which is lesson 7's drill pointed at it.

## What "somewhere else" has to mean

Somewhere else is measured by what can fail together, not by distance:

- **Another disk in the same server** survives a disk failure and nothing else.
- **Another server in the same rack** survives a server failure, and not a fire, a flood or the
  network switch above them.
- **Another region of the same cloud account** survives a region failing, and not the account being
  closed, compromised or locked for an unpaid bill.
- **Another provider, or the same provider under another account with other credentials**, survives
  all of those.

The question to ask of each copy is what single event would destroy it **together with** the live
database, and the copy that answers "nothing I can think of" is the one that counts as offsite.

By the end of this lesson the shop's copies will sit like this:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Two boxes. The database server holds the live database and repo1, the local repository for fast restores; a note says one event takes both. Somewhere else holds repo2, encrypted, kept longer and immutable until a date; every segment and backup reaches both repositories, and repo2 survives the event that takes the server.\"><defs><marker id=\"l9p-pa\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"330\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"185\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the database server</text><rect x=\"40\" y=\"56\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">live database</text><rect x=\"200\" y=\"56\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"265\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">repo1</text><text x=\"265\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">fast restores</text><path d=\"M170 81 L198 81\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9p-pa)\"></path><text x=\"185\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">one event takes both</text><rect x=\"420\" y=\"20\" width=\"280\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"560\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">somewhere else</text><rect x=\"450\" y=\"56\" width=\"220\" height=\"74\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">repo2</text><text x=\"560\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">encrypted, kept longer,</text><text x=\"560\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">immutable until a date</text><text x=\"560\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">survives that event</text><path d=\"M350 81 L448 81\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9p-pa)\"></path><text x=\"385\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">segments,</text><text x=\"385\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">backups</text></svg>", "caption": "Where the copies of the shop live after this lesson. The local repository is for speed; only the one somewhere else, readable with the passphrase and deletable by nobody before its date, counts against the events that take a whole server."}
```

The next sections give the shop a second repository, encrypt it, lose the first one on purpose and
restore from the second, and then ask the harder question: who can delete the copy that is supposed
to survive everything.
