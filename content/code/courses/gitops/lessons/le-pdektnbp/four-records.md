---
title: Four records of one change
version: 1
---

**An audit answers four questions about a change: who, what, when and why.** In a GitOps setup no
single system can answer all four, and that is by design: each step of a change happens in a
different place, and each place keeps its own record.

| the record | it says | it cannot say |
|---|---|---|
| **Git and the pull request** | who wrote the change, who approved it, why, as text | whether it ever reached a cluster |
| **Flux's events** | which revision was applied, when, and whether it worked | who wrote it |
| **the API server's audit log** | every request to the cluster: who, which object, what verb | which commit a request came from |
| **Vault's audit log** | every request for a secret: which identity, which path | what the secret was used for |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"Four records of one change, joined by identifiers. A pull request in Git records the author, the reviewer and the reason, and produces a commit hash. Flux&#x27;s events record that the commit&#x27;s revision was applied, when, and the result. The API server&#x27;s audit log records each request Flux&#x27;s controller made, under the controller&#x27;s ServiceAccount. Vault&#x27;s audit log records each read by a pod&#x27;s ServiceAccount. The commit hash joins the first two, the controller&#x27;s identity joins the second and third, and the pod&#x27;s ServiceAccount joins the cluster to Vault.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"250\" fill=\"var(--ink)\"/><rect x=\"20\" y=\"40\" width=\"140\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"90.0\" y=\"70.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Git</text><text x=\"90.0\" y=\"88.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">author, review, why</text><rect x=\"200\" y=\"40\" width=\"140\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"270.0\" y=\"70.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Flux events</text><text x=\"270.0\" y=\"88.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">revision applied</text><rect x=\"380\" y=\"40\" width=\"140\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"450.0\" y=\"70.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">API server audit</text><text x=\"450.0\" y=\"88.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">every request</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"630.0\" y=\"70.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Vault audit</text><text x=\"630.0\" y=\"88.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">every read</text><line x1=\"160\" y1=\"75\" x2=\"190.0\" y2=\"75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"198,75 190.0,70.5 190.0,79.5\" fill=\"var(--paper-dim)\"/><line x1=\"340\" y1=\"75\" x2=\"370.0\" y2=\"75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"378,75 370.0,70.5 370.0,79.5\" fill=\"var(--paper-dim)\"/><line x1=\"520\" y1=\"75\" x2=\"550.0\" y2=\"75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"558,75 550.0,70.5 550.0,79.5\" fill=\"var(--paper-dim)\"/><text x=\"180\" y=\"150\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"11\" fill=\"var(--paper-dim)\">joined by the commit hash</text><text x=\"360\" y=\"180\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"11\" fill=\"var(--paper-dim)\">joined by the controller's ServiceAccount</text><text x=\"540\" y=\"210\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"11\" fill=\"var(--paper-dim)\">joined by a pod's ServiceAccount</text><line x1=\"180\" y1=\"138\" x2=\"180\" y2=\"112\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"/><line x1=\"360\" y1=\"168\" x2=\"360\" y2=\"112\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"/><line x1=\"540\" y1=\"198\" x2=\"540\" y2=\"112\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"/></svg>", "caption": "No record answers who, what, when and why on its own. Each carries an identifier the next one also carries, and the audit is following them."}
```

**The thread through them is an identifier each one carries for the next.** The commit hash is in
the pull request and in Flux's revision. Flux's controller is the user in the API server's audit log
for everything it applied, and the ServiceAccount of a pod is the identity in Vault's log for
everything it read. Following the thread is how "who changed production's token on Tuesday" gets an
answer rather than a guess.

Two things are not in this table because they do not deserve to be. **A change made with `kubectl`
by a person** shows up in the API server's log and in nothing else: there is no pull request, no
reason, no review. Lessons 1 and 4 showed Flux undoing such changes; this lesson shows how to find
who made them. And **a secret's value** is in none of these, on purpose: every record here says that
something was read or written, never what.
