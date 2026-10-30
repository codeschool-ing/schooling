---
title: The workflow, line by line
version: 1
---

This is the shop's deploy workflow with federation. It was **not run**: it needs GitHub's runners and a
real tenant. Read it for what each line contributes to the exchange in the figure above.

```yaml
# .github/workflows/deploy.yml
name: deploy
on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-24.04
    environment: production
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      - run: |
          az webapp config container set \
            --resource-group rg-shop --name app-shop-api --slot staging \
            --container-image-name crshop.azurecr.io/shop/api:${{ github.sha }}
```

**`permissions: id-token: write`** is what lets the job ask GitHub for an OIDC token at all. Without it,
the login action fails before Azure is ever involved. Granting it at the job rather than the workflow
level is tighter still, when a workflow has jobs that do not deploy. `contents: read` is there because
setting any permission explicitly turns the others off, and checkout still needs to read the code.

**`environment: production`** does two things at once. It puts the job behind the GitHub environment's
protections, and it changes the subject to `...:environment:production`, which is the one subject the
`shop-production` credential trusts.

**`client-id`, `tenant-id` and `subscription-id` are not secrets.** They name an identity; they do not
prove one. They are kept in `vars` rather than `secrets` to say so plainly, and leaking them lets nobody
sign in. Compare that with the `creds` blob of the old way, where the same three ids travelled beside
the one string that did prove the identity.

**`azure/login@v2`** asks GitHub for the token with the `api://AzureADTokenExchange` audience, sends it
to Entra ID, and leaves the command line signed in for the rest of the job. The step after it is an
ordinary `az` command, run as `shop-production`, with whatever the role on `rg-shop` allows and nothing
more.

Two habits finish it. **Pin actions to a commit** rather than a tag when the workflow can reach
production, because a tag is somebody else's repository deciding what runs with your identity; the
shop writes tags here for legibility. And **keep the role small**: federation removes the secret, not
the permissions, and a workflow that can deploy the app should not be able to assign roles.
