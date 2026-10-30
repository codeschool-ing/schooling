---
title: Federation: trusting a token instead of holding a secret
version: 1
---

**Workload identity federation replaces the stored secret with a rule about whom to believe.** GitHub
runs an OpenID Connect token service. Any workflow run that asks for it, and is allowed to, gets a
short-lived token **signed by GitHub** that says, in standard fields, which repository, branch,
environment and run it belongs to. Microsoft Entra ID can be told to accept such a token in exchange
for an Azure token, but only one whose fields match a **federated credential** you attached to the app
registration in advance.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A sequence between three parties. One: the workflow run asks GitHub&#x27;s token service for an OIDC token. Two: GitHub returns a token signed by GitHub, valid for minutes, naming the repository and environment in its subject. Three: the run sends that token to Microsoft Entra ID. Four: Entra ID checks the issuer, subject and audience against the federated credential on the app registration. Five: Entra ID returns an Azure access token for the service principal, valid for about an hour.\"><defs><marker id=\"ah-exchange\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"180\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">GitHub token service</text><rect x=\"270\" y=\"20\" width=\"180\" height=\"50\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">the workflow run</text><rect x=\"520\" y=\"20\" width=\"180\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Microsoft Entra ID</text><path d=\"M110 70 L110 280\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M360 70 L360 280\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M610 70 L610 280\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M355 100 L116 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-exchange)\"></path><text x=\"235\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 ask for an OIDC token</text><path d=\"M116 135 L355 135\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-exchange)\"></path><text x=\"235\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 signed token, minutes</text><path d=\"M366 170 L604 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-exchange)\"></path><text x=\"485\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3 present it</text><rect x=\"470\" y=\"185\" width=\"230\" height=\"40\" rx=\"6\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"585\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">4 issuer, subject, audience?</text><path d=\"M604 250 L366 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-exchange)\"></path><text x=\"485\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5 Azure token, about an hour</text></svg>", "caption": "Nothing in the exchange was stored in advance except the trust: which issuer, which subject, which audience."}
```

The federated credential is three facts:

```json
{
  "name": "shop-production",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:example-shop/shop-api:environment:production",
  "audiences": ["api://AzureADTokenExchange"]
}
```

The `issuer` is GitHub's token service, and Entra ID fetches its public keys from there to check the
signature. The `audiences` value is the one Azure's documentation fixes for this exchange, and the
login action asks GitHub for a token with that audience. The `subject` is the part you design, and the
next section is about nothing else.

It is created with the command line or with Bicep and Terraform; this is the command line's form,
**not run**, because it needs a real tenant:

```sh
az ad app federated-credential create --id "$APP_ID" --parameters @shop-production.json
```

What has changed is where the risk sits. **There is nothing to leak**: the GitHub token is valid for
minutes and only for the audience it was issued to, and the Azure token it buys lasts about an hour.
There is nothing to rotate. And revocation is exact: delete the federated credential, and that one
repository and environment can no longer sign in, with nothing else affected.

Azure Pipelines' service connections use the same mechanism with Azure DevOps as the issuer, which is
why lesson 1 could say the connection holds no secret.
