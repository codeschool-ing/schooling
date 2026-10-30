---
title: A pipeline that deploys without a stored secret
version: 1
---

**The shop's deployments run in GitHub Actions, and the old way to let them reach Azure was a client
secret stored in the repository's settings.** It worked, it was copied into three other repositories,
and nobody knew which of them still used it when it expired. Workload identity federation replaces it
with an exchange of tokens:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l07-federation\" aria-label=\"The token exchange in four steps between three parties. 1: GitHub issues the job a token for repository shop-example/storefront on branch main. 2: the job sends that token and the client id of shop-deploy to Entra ID's token endpoint. 3: Entra ID compares issuer, subject and audience with the federated credential on the registration. 4: Entra ID returns an access token, which the job uses with Resource Manager.\"><defs><marker id=\"l07-federation-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l07-federation-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"16.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">GitHub</text><path d=\"M110.0 51.0 L110.0 280.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"280.0\" y=\"16.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the job</text><path d=\"M360.0 51.0 L360.0 280.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"530.0\" y=\"16.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Entra ID</text><path d=\"M610.0 51.0 L610.0 280.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M114.0 89.0 L356.0 89.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07-federation-af-ah-phosphor)\"></path><text x=\"235.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1  a token for repo and branch</text><path d=\"M364.0 144.0 L606.0 144.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07-federation-af-ah-phosphor)\"></path><text x=\"485.0\" y=\"131.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2  that token, with the client id</text><circle cx=\"610.0\" cy=\"185.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"596.0\" y=\"185.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">3  issuer, subject, audience match?</text><path d=\"M606.0 249.0 L364.0 249.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07-federation-af-ah-amber)\"></path><text x=\"485.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4  an access token, about an hour</text></svg>", "caption": "Nothing in the exchange is stored anywhere, so nothing in it can leak later."}
```

1. **GitHub issues the job a token** of its own, signed by `https://token.actions.githubusercontent.com`,
   saying which repository and which branch the job runs for;
2. the job sends that token to Entra ID's token endpoint, **in place of a secret**, together with the
   client id of `shop-deploy`;
3. **Entra ID compares it with the federated credential** on the registration: the issuer, the
   subject and the audience must match exactly;
4. if they match, Entra ID returns an access token for `shop-deploy`, valid for about an hour, and the
   job uses it with Resource Manager like any other.

The credential in `main.tf` is that comparison, written down:

| field | value | it says |
|---|---|---|
| `issuer` | `https://token.actions.githubusercontent.com` | the token must come from GitHub's issuer, which Entra ID checks against that issuer's public keys |
| `subject` | `repo:shop-example/storefront:ref:refs/heads/main` | only jobs of that repository, on the `main` branch |
| `audiences` | `api://AzureADTokenExchange` | the token must have been made for Entra ID, and for nothing else |

**The subject is where the security is.** A subject of `repo:shop-example/storefront:ref:refs/heads/main`
lets the main branch deploy and refuses a job on any other branch, a pull request from a fork, or
another repository of the same owner. Widen it carelessly and a pull request can deploy to production.
A separate credential with the subject `repo:shop-example/storefront:environment:production` ties the
deployment to a GitHub environment instead, which can demand an approval before the job starts.

**Nothing is stored that can leak.** There is no secret in GitHub, no expiry date to remember, and the
token GitHub issued is valid for minutes and only for that job. What remains to protect is the
registration itself, and who may change its federated credentials, which is a directory permission,
the kind lesson 6 set apart from Azure's roles.

## What the lab checked, and the rest

```
ana@laptop:~/azure/deploy$ terraform plan -input=false

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: unable to build authorizer: could not configure AzureCli Authorizer: obtaining subscription ID: obtaining account details: running Azure CLI: exit status 1: ERROR: Please run 'az login' to setup account.
│ 
│   with provider["registry.terraform.io/hashicorp/azuread"],
│   on main.tf line 10, in provider "azuread":
│   10: provider "azuread" {
│ 
╵
```

`validate` had already accepted the credential's three fields, and `plan` stopped at the sign-in,
like every plan here. **No token exchange was run**: it needs a GitHub job, a real tenant and a real
registration, and the course has none of the three. The steps above are Microsoft's and GitHub's
documented flow. The workflow file on GitHub's side asks for the token with
`permissions: id-token: write` and uses Microsoft's `azure/login` action, given the client id, the
tenant id and the subscription id, none of which is a secret.
