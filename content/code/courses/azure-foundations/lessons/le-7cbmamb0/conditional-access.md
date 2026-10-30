---
title: Conditional access, a rule evaluated at every sign-in
version: 1
---

**Conditional access is a set of if-then rules that Entra ID evaluates every time somebody signs
in.** If these users, reaching these applications, under these conditions, then grant access only
with these controls, or block it. Security defaults are one fixed rule; conditional access is the
rules you write, and it needs a licence, Microsoft Entra ID P1 or above, for the users it covers.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l11-policy\" aria-label=\"A conditional access policy as an if-then rule evaluated at sign-in. On the left, the assignments: users, including directory roles and exclusions, and target resources. In the middle, the conditions: risk, device platform, location and client app. On the right, the access controls: block, or grant with a second factor, an authentication strength or a managed device. Underneath, a note that every policy that applies is enforced together, with no order.\"><defs><marker id=\"l11-policy-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30.0\" y=\"24.0\" width=\"190.0\" height=\"186.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">if: who and what</text><rect x=\"44.0\" y=\"62.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">users and groups</text><rect x=\"44.0\" y=\"98.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">directory roles</text><rect x=\"44.0\" y=\"134.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">exclusions</text><rect x=\"44.0\" y=\"170.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">target resources</text><rect x=\"265.0\" y=\"24.0\" width=\"190.0\" height=\"186.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">and: under which conditions</text><rect x=\"279.0\" y=\"62.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">sign-in risk</text><rect x=\"279.0\" y=\"98.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">device platform</text><rect x=\"279.0\" y=\"134.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">location</text><rect x=\"279.0\" y=\"170.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">client app</text><rect x=\"500.0\" y=\"24.0\" width=\"190.0\" height=\"186.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">then: what happens</text><rect x=\"514.0\" y=\"62.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">block</text><rect x=\"514.0\" y=\"98.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">grant with a second factor</text><rect x=\"514.0\" y=\"134.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">authentication strength</text><rect x=\"514.0\" y=\"170.0\" width=\"162.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">managed device</text><path d=\"M221.0 117.0 L264.0 117.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-policy-af-ah-paper-dim)\"></path><path d=\"M456.0 117.0 L499.0 117.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-policy-af-ah-paper-dim)\"></path><text x=\"360.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">every policy that applies is enforced, together: no order, no first match</text><text x=\"360.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">report-only evaluates and logs, and enforces nothing</text></svg>", "caption": "One policy: if these, under these conditions, then this."}
```

## The parts of a policy

**Assignments** say whom and what the policy is about:

- **users**: all users, chosen users or groups, or the holders of chosen **directory roles**, and
  the exclusions, which matter as much as the inclusions;
- **target resources**: the applications being signed in to. *Windows Azure Service Management API*
  is the one that matters in this course: Microsoft's documentation says a policy aimed at it covers
  Resource Manager and the Azure portal, and through them the CLI and PowerShell.

**Conditions** narrow when it applies: the sign-in's risk, the device's platform, the **location**,
named by country or by the company's own address ranges, and the **client app**, which is how
legacy authentication is singled out.

**Access controls** say what happens: **block**, or **grant** on condition of one or more controls,
such as multifactor authentication, an **authentication strength** that requires a phishing-resistant
method, or a device the company manages. **Session controls** shape what happens after, such as how
often a sign-in must be repeated.

**Every policy that applies is enforced, all together.** There is no priority and no "first match".
If one policy demands a second factor and another demands a managed device, the person needs both;
if any applicable policy blocks, the sign-in is blocked. That is why a block is the policy to write
last and test longest.

## Report-only first

A policy has three states: **on**, **off**, and **report-only**. In report-only, Entra ID evaluates
the policy at every sign-in and writes into the sign-in log what it *would* have done, without doing
it. A week of report-only on a new policy shows exactly who it would have stopped, including the
nightly job everybody forgot signs in as a person. Microsoft's documentation adds that emergency
accounts need no exclusion from a report-only policy, since nothing is enforced.

## The shop's first policy, in Terraform

Conditional access lives in Entra ID rather than in Resource Manager, so its Terraform resource comes
from the provider for Entra ID, which lesson 6 introduced. Make the lesson's directory and save this
as `main.tf`:

```sh
mkdir -p ~/azure/access && cd ~/azure/access
```

```hcl
terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.10.0"
    }
  }
}

provider "azuread" {}

resource "azuread_conditional_access_policy" "admins_mfa" {
  display_name = "Require MFA for administrators"
  state        = "enabledForReportingButNotEnforced"

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_roles = [
        "62e90394-69f5-4237-9190-012177145e10",
        "e8611ab8-c189-46e8-94e1-60213ab1f814",
      ]
      excluded_groups = ["aaaaaaaa-1111-2222-3333-cccccccccccc"]
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }
}
```

The policy covers the holders of two directory roles, named by the ids Microsoft's documentation
lists for them: **Global Administrator** and **Privileged Role Administrator**, the two that can hand
out every other power. It applies to every application and every kind of client, demands a second
factor, and excludes one group: the emergency accounts of the next section, by a made-up object id.
Its state is `enabledForReportingButNotEnforced`, the API's spelling of report-only.

Run `terraform init`, then check the file, then make the most likely mistake, spelling the state the
way people say it:

```
ana@laptop:~/azure/access$ terraform validate
Success! The configuration is valid.

ana@laptop:~/azure/access$ sed -i 's/"enabledForReportingButNotEnforced"/"reportOnly"/' main.tf
ana@laptop:~/azure/access$ terraform validate
╷
│ Error: expected state to be one of ["disabled" "enabled" "enabledForReportingButNotEnforced"], got reportOnly
│ 
│   with azuread_conditional_access_policy.admins_mfa,
│   on main.tf line 14, in resource "azuread_conditional_access_policy" "admins_mfa":
│   14:   state        = "reportOnly"
│ 
╵
```

**The provider lists the three states it accepts**, and the portal's word is not one of them. The
refusal happened on your computer, which is the cheapest place for it. Put the long spelling back
with `sed -i 's/"reportOnly"/"enabledForReportingButNotEnforced"/' main.tf`.

```
ana@laptop:~/azure/access$ terraform plan -input=false

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: unable to build authorizer: could not configure AzureCli Authorizer: tenant ID was not specified and the default tenant ID could not be determined: obtaining tenant ID: obtaining account details: running Azure CLI: exit status 1: ERROR: Please run 'az login' to setup account.
│ 
│   with provider["registry.terraform.io/hashicorp/azuread"],
│   on main.tf line 10, in provider "azuread":
│   10: provider "azuread" {}
│ 
╵
```

`plan` stopped at the same place as every other `plan` in this course: it needs a signed-in identity
before it can ask Entra ID what policies exist. **The policy was not created**, and its report-only
week, which is the part that would teach you something about a real tenant, could not happen here.
