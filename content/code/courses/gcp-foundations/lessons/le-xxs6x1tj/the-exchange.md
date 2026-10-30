---
title: Trading somebody else's token for one of Google's
version: 1
---

**A program outside Google Cloud usually already holds a signed statement of who it is.** A GitHub
Actions job can ask GitHub for a token that says *this job runs in the repository `example/planner`, on
the branch `main`*. A workload in another cloud has its own provider's token. A server joined to Active
Directory can get one from the company's identity provider. Workload Identity Federation is Google Cloud
agreeing to **trust that statement**, under conditions you write, and handing back a Google token in
exchange. No key is created, stored or rotated, because nothing long-lived ever crosses.

The exchange has three parties and four steps:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l09-exchange\" aria-label=\"The exchange, in four steps between three parties. On the left, a GitHub Actions job. At the top, GitHub's identity provider, which signs an OIDC token for the job, step 1. In the middle, Google's Security Token Service, which receives the token with the pool and provider named, checks the signature, the attribute mapping and the condition, and returns a federated token, step 2. To the right, IAM Credentials, which trades the federated token for a token of the deployer service account, step 3. Last, the job calls Google APIs with that token, step 4. A note: no key crosses at any step.\"><defs><marker id=\"l09-exchange-af-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l09-exchange-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"120.0\" width=\"140.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"143.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a GitHub</text><text x=\"90.0\" y=\"156.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Actions job</text><rect x=\"20.0\" y=\"14.0\" width=\"140.0\" height=\"54.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"90.0\" y=\"34.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">GitHub's identity</text><text x=\"90.0\" y=\"47.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">provider</text><path d=\"M90.0 70.0 L90.0 116.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l09-exchange-af-ah-paper)\"></path><text x=\"98.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1. a signed OIDC token</text><rect x=\"250.0\" y=\"110.0\" width=\"180.0\" height=\"80.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"340.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sts.googleapis.com</text><text x=\"340.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">signature, mapping,</text><text x=\"340.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">condition</text><path d=\"M162.0 140.0 L246.0 140.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l09-exchange-af-ah-paper)\"></path><text x=\"204.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">2</text><path d=\"M246.0 162.0 L162.0 162.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l09-exchange-af-ah-phosphor)\"></path><text x=\"204.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">federated</text><rect x=\"520.0\" y=\"110.0\" width=\"180.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"610.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">iamcredentials</text><text x=\"610.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">federated token for</text><text x=\"610.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the deployer's</text><path d=\"M90 182 C 90 240, 610 240, 610 192\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l09-exchange-af-ah-paper)\"></path><text x=\"350.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3. trade it for the deployer's token, then 4. call Google APIs</text><text x=\"360.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">no key crosses at any step</text></svg>", "caption": "An outside token in, a Google token out, and nothing long-lived in between."}
```

1. **The outside identity provider signs a token.** For GitHub it is an OIDC token, a JWT, valid for
   minutes, carrying claims: `repository`, `ref`, `actor`, `workflow` and others.
2. **The workload sends it to Google's Security Token Service**, `sts.googleapis.com`, naming the
   **pool** and **provider** it is presenting it to. STS checks the signature against the issuer's
   published keys, applies the provider's **attribute mapping** and **condition**, and, if they pass,
   returns a short-lived **federated token**.
3. **The federated token is either used directly**, on resources where the pool's principals were
   granted roles, **or traded once more** with the IAM Credentials API of lesson 8 for a token of a service
   account the pool is allowed to impersonate.
4. **The workload calls Google APIs** with the result, which lasts an hour.

## Pools, providers and the condition

A **workload identity pool** is a container for outside identities, in a project: `ci-pool`. A
**provider** inside it says whom to trust: the issuer's address, `https://token.actions.githubusercontent.com`
for GitHub, and how to read its claims. Two pieces of the provider do the real security work:

- **attribute mapping** turns the token's claims into attributes Google understands. `google.subject` is
  the one required: the identity of this particular workload. Others, such as
  `attribute.repository = assertion.repository`, become names lesson 5's `principalSet://` can select by.
- **attribute condition** is a CEL expression every token must satisfy, or the exchange is refused before
  any role is considered: `assertion.repository_owner == 'example'`.

**The condition is the lock on the door.** GitHub signs tokens for every repository on GitHub, millions of
them, with the same issuer. A provider that trusts the issuer and has no condition accepts a token from
anybody's repository, and the only thing between a stranger's workflow and your project is whether some
role happens to be granted to a principal it matches. Google's documentation insists on a condition for
any provider whose issuer is shared like this, for exactly that reason. Writing one that names the
organisation, and a grant that names the repository, is two locks rather than one.

Nothing in this section ran: the exchange needs a real pool, a real provider and a real token from GitHub.
The next two sections write the pool and plan it, then build the credential file a workload uses, and send
Google an exchange that is refused for a reason worth reading.
