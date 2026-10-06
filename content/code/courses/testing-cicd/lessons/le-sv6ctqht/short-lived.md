---
title: Credentials that expire on their own
version: 1
---

Every secret so far is **long-lived**: it works until somebody revokes it. A long-lived credential in
a pipeline is a liability with no end date. It has to be stored, it can be copied, and the day it
leaks it works for the attacker exactly as it works for you, until somebody notices.

The alternative is to hold **no durable credential at all**. The pipeline proves who it is at the
moment it needs access, and receives a credential that expires on its own, minutes or an hour later.
On hosted CI the mechanism is **OpenID Connect (OIDC) federation**:

1. the job asks the CI service for a signed token that says which repository, which workflow and
   which branch or tag is running;
2. the job presents that token to the cloud provider;
3. the provider checks the signature and **a condition its owner wrote**, and hands back a short-lived
   access credential;
4. the credential expires on its own.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"A sequence between three parties: the deploy job, GitHub, and the cloud provider. 1, the job asks GitHub for a token about this run. 2, GitHub returns a signed token naming the repository, workflow and ref. 3, the job presents the token to the cloud provider, which checks the signature and the repository condition. 4, the provider returns a credential that expires within the hour.\"><rect x=\"50\" y=\"14\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"130\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">deploy job</text><path d=\"M130 48 L130 262\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></path><rect x=\"280\" y=\"14\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">GitHub</text><path d=\"M360 48 L360 262\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></path><rect x=\"510\" y=\"14\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">cloud provider</text><path d=\"M590 48 L590 262\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></path><path d=\"M130 82 L353 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M352 78 L360 82 L352 86 z\" fill=\"var(--paper-dim)\"></path><text x=\"245.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1. token about this run?</text><path d=\"M360 124 L137 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M138 120 L130 124 L138 128 z\" fill=\"var(--paper-dim)\"></path><text x=\"245.0\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2. signed: repository, workflow, ref</text><path d=\"M130 166 L583 166\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M582 162 L590 166 L582 170 z\" fill=\"var(--phosphor)\"></path><text x=\"360.0\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">3. this token, checked against the condition</text><path d=\"M590 208 L137 208\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M138 204 L130 208 L138 212 z\" fill=\"var(--amber)\"></path><text x=\"360.0\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">4. a credential for one hour</text><text x=\"360\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nothing is stored before step 1 or kept after the hour</text></svg>", "caption": "The exchange described above, in time order. The only secret involved is GitHub's signing key, which never leaves GitHub."}
```

## This repository's deploy works that way

The release workflow's deploy job holds no cloud key. The step that obtains credentials is named
after what it does:

```yaml
      - name: An hour of credentials, in exchange for a token about this repository
        uses: google-github-actions/auth@7c6bc770dae815cd3e89ee6cdf493a5fab2cc093 # v3.0.0
        with:
          workload_identity_provider: ${{ env.WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ env.DEPLOY_ACCOUNT }}
```

On the cloud side, the repository's Terraform declares which tokens to believe, and its comment
calls one line *the single most consequential line in this directory*:

```hcl
  // Read the block comment above before touching this line.
  attribute_condition = "assertion.repository == \"${var.github_repository}\""
```

Without that condition the provider would trust **any** repository on GitHub, since any of them can
obtain a validly signed token. With it, only tokens about this repository are exchanged, and the
binding on the deploy account narrows it again. The comment at the top of the file puts the benefit
in one sentence: *nothing durable exists to leak*.

## What it changes

| | long-lived key in a secret | federation |
|---|---|---|
| what is stored in CI | the key | nothing |
| what a leaked log could expose | a key that works until revoked | a credential that expires within the hour |
| rotation | a task somebody must remember | not needed |
| what decides access | possession of the key | the identity of the running workflow, checked every time |

Federation does not remove the need for least privilege: the account the pipeline becomes should
still be able to do only the deploy. It removes the secret, which removes the commonest way access
is stolen. Most cloud providers support it for GitHub Actions and GitLab CI, and it is the first
thing to set up before a pipeline is given any cloud access at all.
