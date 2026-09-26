---
title: Asking as the user
version: 1
---

The same two questions, asked as Bruno with `sudo -u bruno`:

```
ana@pc1:~$ sudo -u bruno lpstat -d
system default destination: pdf
ana@pc1:~$ sudo -u bruno bash -c "cd ~ && lp report.txt"
request id is pdf-4 (1 file(s))
```

**For Bruno, the default is `pdf`**, and his document went to the `pdf` queue, which writes a file and
never touches paper. Nothing is broken: the printer works, the queue works, and his documents are going
exactly where his settings send them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Two defaults, and which one each person gets. The system&#x27;s default is office, the printer. Bruno has a default of his own, pdf, in his lpoptions file, and it wins for him. So when ana prints, the job goes to office; when bruno prints, it goes to pdf, which makes a file and no paper.\"><defs><marker id=\"df-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ana prints</text><rect x=\"20\" y=\"120\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">bruno prints</text><rect x=\"250\" y=\"30\" width=\"220\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the system&#x27;s default: office</text><rect x=\"250\" y=\"120\" width=\"220\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">bruno&#x27;s own default: pdf</text><rect x=\"530\" y=\"30\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"542\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">office: the printer</text><rect x=\"530\" y=\"120\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"542\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pdf: a file, not paper</text><path d=\"M192 50 L248 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#df-ah)\"></path><path d=\"M472 50 L528 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#df-ah)\"></path><path d=\"M192 140 L248 140\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#df-ah)\"></path><path d=\"M472 140 L528 140\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#df-ah)\"></path></svg>", "caption": "A user's own default wins over the system's, for that user only. That is why the technician's test page came out and Bruno's documents did not: they were never sent to the same place."}
```

This is the kind of cause the user's explanation hides. "The printer is broken" named the last thing he
could see, the printer that stayed silent. The fault was one step before it, in a choice he made in a
dialog box. In the lab, what that choice did was done with `lpoptions -d pdf`, run as Bruno, and the
capture's header says so: the lab's computers have no desktop to show the window on.
