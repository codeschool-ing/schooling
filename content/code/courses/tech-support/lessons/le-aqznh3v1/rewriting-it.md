---
title: Rewriting it
version: 1
---

The rewritten article, compared line by line with the old one:

```
ana@host:~$ diff -u kb/intranet-on-a-new-computer.md kb/intranet-new.md
--- kb/intranet-on-a-new-computer.md    2026-09-26 01:29:02.284627093 -0300
+++ kb/intranet-new.md  2026-09-26 01:29:12.190095166 -0300
@@ -1,9 +1,17 @@
-# Intranet on a new computer
+# The intranet does not open on a new computer
 
-Add the intranet to the hosts file:
+Symptom: the browser cannot reach http://intranet/, or curl says
+"Could not resolve host: intranet" or "Couldn't connect to server".
+Applies to: an office computer set up by hand. Needs: sudo on it.
 
-    echo "10.30.0.200 intranet" | sudo tee -a /etc/hosts
+1. On the computer: getent hosts intranet
+   Expected: nothing, or an old address to replace.
+2. On your own computer, srv1's current address: getent hosts srv1
+3. On the computer, put the line "<that address> intranet" in /etc/hosts,
+   replacing any intranet line already there.
+4. On the computer: curl -sS http://intranet/
+   Expected: intranet: welcome
 
-Then open http://intranet/ in the browser.
+If step 4 fails, escalate to level 2 with the output of steps 1, 2 and 4.
 
-Last reviewed: 2024-03-11
+Owner: service desk. Last reviewed: 2026-09-26, followed on pc2.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The parts of a knowledge base article, top to bottom. Title: the problem, as someone would search for it. Symptom: the exact message, so a search finds it. Applies to and needs: when it is the right article, and what access. Steps: each with what it should show. If it fails: where to go next. Owner and reviewed: who keeps it true, and when it was last followed.\"><defs><marker id=\"ar-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"200\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">title</text><text x=\"236\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the problem, as someone would search for it</text><rect x=\"20\" y=\"62\" width=\"200\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">symptom</text><text x=\"236\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the exact message, so a search finds it</text><rect x=\"20\" y=\"108\" width=\"200\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">applies to, needs</text><text x=\"236\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">when it is the right article, and what access</text><rect x=\"20\" y=\"154\" width=\"200\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">steps</text><text x=\"236\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">each with what it should show</text><rect x=\"20\" y=\"200\" width=\"200\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"223\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">if it fails</text><text x=\"236\" y=\"223\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">where to go next</text><rect x=\"20\" y=\"246\" width=\"200\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"269\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">owner, reviewed</text><text x=\"236\" y=\"269\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">who keeps it true, and when it was last followed</text></svg>", "caption": "Close to a runbook's shape, lesson 8, with one difference at the top: an article has to be found before it can be followed, so its title and symptom are written in the words people search with."}
```

Every problem of the previous section has a line that answers it: a title in the words of the symptom,
the error messages quoted exactly, **a step that looks the address up instead of giving it**, an
expected result after the steps that matter, where to go if it fails, and an owner. Then the new article
is followed, step by step, on `pc2`, before it replaces the old one:

```
ana@pc2:~$ getent hosts intranet
10.30.0.200     intranet
ana@host:~$ getent hosts srv1
10.30.0.29      srv1
ana@pc2:~$ sudo sed -i 's/^.* intranet$/10.30.0.29 intranet/' /etc/hosts && grep intranet /etc/hosts
10.30.0.29 intranet
ana@pc2:~$ curl -sS -m 10 http://intranet/
intranet: welcome
```

Step 1 finds the old line the first attempt left behind, step 2 gives `10.30.0.29`, step 3 replaces the line
and step 4 prints the expected page. *Followed on pc2* in the last line is true, and it is the phrase
that makes *last reviewed* worth reading.
