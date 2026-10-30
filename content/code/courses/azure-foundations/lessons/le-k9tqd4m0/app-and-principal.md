---
title: An application, and its service principal
version: 1
---

**A program that calls Azure needs an identity of its own, and in Entra ID that identity comes in two
halves.** People expect one object, called something like "the app's account". There are two, and
confusing them is the reason half the questions about this subject exist:

- **the application object**, or **app registration**, is the program's definition: its name, who
  may sign in to it, what credentials it accepts, what it asks permission for. It lives in one
  tenant, its **home tenant**, and it is the same whoever uses it;
- **the service principal** is the program's identity **inside one tenant**: the object that signs
  in, that roles are given to, that appears in the logs. The portal lists them as *Enterprise
  applications*.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l07-app-and-sp\" aria-label=\"One application registered in its home tenant, with one client id, and a service principal for it in each tenant that uses it: one in the home tenant and one in a customer's tenant. Each service principal has its own object id and receives its own roles; the client id is the same everywhere.\"><defs><marker id=\"l07-app-and-sp-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"330.0\" height=\"250.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"36.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">home tenant</text><rect x=\"50.0\" y=\"60.0\" width=\"270.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">application (registration)</text><text x=\"185.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">client id 00001111-…</text><text x=\"185.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one, wherever it is used</text><rect x=\"50.0\" y=\"170.0\" width=\"270.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">service principal</text><text x=\"185.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its own object id</text><text x=\"185.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">roles in this tenant</text><path d=\"M185.0 131.0 L185.0 169.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-app-and-sp-af-ah-paper-dim)\"></path><rect x=\"370.0\" y=\"20.0\" width=\"330.0\" height=\"250.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"386.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">a customer's tenant</text><rect x=\"400.0\" y=\"170.0\" width=\"270.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">service principal</text><text x=\"535.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">another object id</text><text x=\"535.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">roles the customer gives</text><path d=\"M321.0 95.0 L535.0 95.0 L535.0 169.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l07-app-and-sp-af-ah-paper-dim)\"></path><text x=\"535.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">instantiated on consent</text></svg>", "caption": "The registration says what the program is; each service principal says what it may do in one tenant."}
```

For the shop's own deployment program, `shop-deploy`, the distinction looks like pedantry: one
registration in the shop's tenant, one service principal beside it. It stops being pedantry the day
an application is used by more than one tenant. A product sold to other companies is registered once,
in the vendor's tenant, and each customer that agrees to use it gets **a service principal of its
own**, in its own directory, which its own administrators give roles to and can delete. The
registration says what the program is; each service principal says what it may do in one place.

Two ids follow from this, and both appear in every error message about applications:

| id | names | where it is the same |
|---|---|---|
| **application (client) id** | the registration, and so the program | in every tenant: it is what the program sends to sign in |
| **object id** | one object in one directory | nowhere else: the registration has one, and each service principal has its own |

**A role is given to the service principal's object id**, never to the client id. A script that
gives a role to the client id is refused, or, worse, finds an unrelated object.

## Who may sign in to it

A registration declares its **audience**: whose accounts may use it. The shop's deployment program
is for the shop only. Make the lesson's directory:

```sh
mkdir -p ~/azure/deploy && cd ~/azure/deploy
```

and save this as `main.tf`:

```hcl
terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.10.0"
    }
  }
}

provider "azuread" {
  tenant_id = "aaaabbbb-0000-cccc-1111-dddd2222eeee"
}

resource "azuread_application" "deploy" {
  display_name     = "shop-deploy"
  sign_in_audience = "AzureADMyOrg"
}

resource "azuread_service_principal" "deploy" {
  client_id = azuread_application.deploy.client_id
}

resource "azuread_application_federated_identity_credential" "main" {
  application_id = azuread_application.deploy.id
  display_name   = "github-main"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:shop-example/storefront:ref:refs/heads/main"
}
```

The registration, its service principal built from the registration's client id, and a federated
credential the third section of this lesson explains. Check it, and then try the audience somebody
guessed rather than looked up:

```
ana@laptop:~/azure/deploy$ terraform init -input=false
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/azuread versions matching "3.10.0"...
- Installing hashicorp/azuread v3.10.0...
- Installed hashicorp/azuread v3.10.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
ana@laptop:~/azure/deploy$ terraform validate
Success! The configuration is valid.

ana@laptop:~/azure/deploy$ sed -i 's/AzureADMyOrg/AzureADMyTenant/' main.tf && terraform validate
╷
│ Error: expected sign_in_audience to be one of ["AzureADMyOrg" "AzureADMultipleOrgs" "AzureADandPersonalMicrosoftAccount" "PersonalMicrosoftAccount"], got AzureADMyTenant
│ 
│   with azuread_application.deploy,
│   on main.tf line 16, in resource "azuread_application" "deploy":
│   16:   sign_in_audience = "AzureADMyTenant"
│ 
╵
ana@laptop:~/azure/deploy$ sed -i 's/AzureADMyTenant/AzureADMyOrg/' main.tf
```

`init` downloaded the provider again, although lesson 6 left it in the cache `env.sh` set up.
**Terraform takes a provider from the cache only for a directory that already has a lock file**,
`.terraform.lock.hcl`, which records the exact provider a configuration was checked with and which
`init` has just written. A second `init` in the same directory uses the cache:

```
ana@laptop:~/azure/deploy$ rm -rf .terraform && terraform init -input=false | grep -E 'Reusing|Using'
- Reusing version 3.10.0 of hashicorp/azuread from the dependency lock file
- Using hashicorp/azuread v3.10.0 from the shared cache directory
```

Back to the first transcript. The second `validate` names the four audiences there are: `AzureADMyOrg`, this tenant only;
`AzureADMultipleOrgs`, any work or school tenant; and the two that add personal Microsoft accounts.
**A company's own tools take the first**, and anything wider is a product decision, not a default.
The last command puts the file back as it was.
