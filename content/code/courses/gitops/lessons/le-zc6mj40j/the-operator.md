---
title: An operator that copies from a store
version: 1
---

**Lesson 9 ended with a token that Vault hands to a pod that proves who it is.** Applications rarely
speak Vault, though, and most of them read secrets the ordinary Kubernetes way: from a Secret,
mounted as a file or put in an environment variable. The **External Secrets Operator** joins the
two. It runs in the cluster, logs in to a secret store, reads the entries you name, and writes them
into ordinary Secrets, then keeps reading them on a schedule so the Secrets follow the store.

It adds two kinds of object, and only the second one is about a particular secret:

- a **SecretStore** says where a store is and how to log in to it: Vault at this address with this
  role, AWS Secrets Manager in this region with this identity. A `ClusterSecretStore` is the same for
  every namespace;
- an **ExternalSecret** says which entries to read from a store, and which Secret to write them into.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"How the External Secrets Operator works. Git holds a SecretStore and an ExternalSecret, and Flux applies them to the cluster. The operator reads the ExternalSecret, logs in to the store named by the SecretStore, reads the entry, and writes an ordinary Secret, which the pod mounts. The operator repeats the read on a schedule, so the Secret follows the store. The value never passes through Git.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"300\" fill=\"var(--ink)\"/><rect x=\"20\" y=\"40\" width=\"150\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"95.0\" y=\"70.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Git</text><text x=\"95.0\" y=\"88.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">SecretStore, ExternalSecret</text><line x1=\"170\" y1=\"75\" x2=\"220.0\" y2=\"75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"228,75 220.0,70.5 220.0,79.5\" fill=\"var(--paper-dim)\"/><text x=\"199\" y=\"66\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"11\" fill=\"var(--paper-dim)\">Flux</text><rect x=\"230\" y=\"20\" width=\"470\" height=\"260\" rx=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-dasharray=\"4 4\"/><text x=\"245\" y=\"40\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">the cluster</text><rect x=\"250\" y=\"50\" width=\"170\" height=\"60\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"335.0\" y=\"75.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">External Secrets</text><text x=\"335.0\" y=\"93.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Operator</text><rect x=\"510\" y=\"50\" width=\"170\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"595.0\" y=\"75.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">store</text><text x=\"595.0\" y=\"93.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">Vault, or a cloud service</text><line x1=\"420\" y1=\"72\" x2=\"500.0\" y2=\"72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"508,72 500.0,67.5 500.0,76.5\" fill=\"var(--paper-dim)\"/><text x=\"464\" y=\"64\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"11\" fill=\"var(--paper-dim)\">logs in, reads</text><line x1=\"508\" y1=\"92\" x2=\"430.0\" y2=\"92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"/><polygon points=\"422,92 430.0,96.5 430.0,87.5\" fill=\"var(--paper-dim)\"/><text x=\"464\" y=\"108\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"11\" fill=\"var(--paper-dim)\">the value</text><rect x=\"250\" y=\"180\" width=\"170\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"335.0\" y=\"205.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Secret</text><text x=\"335.0\" y=\"223.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">an ordinary one</text><line x1=\"335\" y1=\"110\" x2=\"335.0\" y2=\"170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"335,178 339.5,170.0 330.5,170.0\" fill=\"var(--paper-dim)\"/><text x=\"345\" y=\"150\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"11\" fill=\"var(--paper-dim)\">writes, and again</text><text x=\"345\" y=\"164\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"11\" fill=\"var(--paper-dim)\">on every refresh</text><rect x=\"510\" y=\"180\" width=\"170\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"595.0\" y=\"205.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">pod</text><text x=\"595.0\" y=\"223.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">mounts the Secret</text><line x1=\"420\" y1=\"210\" x2=\"500.0\" y2=\"210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"508,210 500.0,205.5 500.0,214.5\" fill=\"var(--paper-dim)\"/></svg>", "caption": "Git holds which secret and from where; the store holds the value. The operator is the only thing that reads the store, and it writes an ordinary Secret the pod already knows how to use."}
```

**What goes into Git is the ExternalSecret, which holds no secret at all.** It says "production's
token is the `token` field of `bulletin/production`", and the store says what that is today. A
reviewer reads which secret a workload gets and from where; the value never appears in a pull
request, a diff or a clone. And because the operator keeps reading, **changing the value in the
store changes the cluster without a commit**, which is exactly what lesson 11 needs for rotation,
and exactly what a GitOps purist will object to: the Secret's content is now state that Git does not
describe. The answer is that Git describes *which* secret and *who may read it*, and the store
describes the value and keeps its own history and audit log. Lesson 12 reads both.

The operator works the same against any store it has a provider for: Vault, the three big clouds'
secret services, and a few dozen others. This lesson runs it against the Vault of lesson 9, and then
shows what changes, which is very little, when the store is a cloud's.
