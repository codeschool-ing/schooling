---
title: Deny policies, and how the tree resolves a request
version: 1
---

**Allow policies add up down the tree, and nothing lower down can take a grant away.** A role on the
organisation is held on every project; a project's policy cannot remove it, because a project's policy
can only add bindings. That is lesson 2's inheritance, applied to IAM, and it is the reason a second kind
of policy exists.

A **deny policy** names principals and permissions that are refused, whatever any allow policy says.
It is attached to the organisation, a folder or a project, it is inherited like an allow policy, and it is
**evaluated first**. The order Google evaluates a request in, simplified to the two kinds this lesson
covers:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l07-evaluation\" aria-label=\"How a request is judged, top to bottom. First, deny policies from the organisation down to the resource: if any denies the permission to the principal, the request is refused and nothing else is read. Then allow policies from the organisation down to the resource: if any binding on the path grants a role holding the permission, the request is allowed. If neither, the request is refused: no grant is a refusal.\"><defs><marker id=\"l07-evaluation-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l07-evaluation-af-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l07-evaluation-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"250.0\" y=\"14.0\" width=\"220.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"31.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a request arrives</text><path d=\"M360.0 48.0 L360.0 70.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07-evaluation-af-ah-paper)\"></path><rect x=\"190.0\" y=\"72.0\" width=\"340.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1. deny policies, organisation to resource</text><text x=\"360.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">does any deny this principal this permission?</text><path d=\"M532.0 97.0 L596.0 97.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l07-evaluation-af-ah-amber)\"></path><text x=\"564.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">yes</text><rect x=\"600.0\" y=\"78.0\" width=\"104.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"652.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">refused</text><path d=\"M360.0 122.0 L360.0 156.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07-evaluation-af-ah-paper)\"></path><text x=\"372.0\" y=\"139.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no</text><rect x=\"190.0\" y=\"158.0\" width=\"340.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2. allow policies, organisation to resource</text><text x=\"360.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">does any binding grant a role holding it?</text><path d=\"M532.0 183.0 L596.0 183.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l07-evaluation-af-ah-phosphor)\"></path><text x=\"564.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">yes</text><rect x=\"600.0\" y=\"164.0\" width=\"104.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"652.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">allowed</text><path d=\"M360.0 208.0 L360.0 242.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07-evaluation-af-ah-paper)\"></path><text x=\"372.0\" y=\"225.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no</text><rect x=\"260.0\" y=\"244.0\" width=\"200.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">refused: no grant at all</text><text x=\"20.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a deny is read first,</text><text x=\"20.0\" y=\"156.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">so no allow can undo it</text></svg>", "caption": "Deny first, then allow, then refuse."}
```

1. **Deny policies**, from the organisation down to the resource. If any one of them denies the
   permission to the principal, the request is refused, and nothing else is read.
2. **Allow policies**, from the organisation down to the resource. If any binding anywhere on the path
   grants a role holding the permission, the request is allowed.
3. Otherwise, refused. **No grant at all is a refusal**: IAM allows nothing by default.

There are other layers on top in Google's full model, principal access boundaries and the organisation
policies of lesson 4 among them, and they can refuse too. The two above are the ones every request meets.

## A deny for planner

Two things should never happen in production, however a role ends up granted: deleting the project, and
deleting a topic. Add a deny policy to `~/gcp/policy`, saved as `deny.tf`:

```hcl
resource "google_iam_deny_policy" "production_guard" {
  parent       = urlencode("cloudresourcemanager.googleapis.com/projects/planner-prod")
  name         = "production-guard"
  display_name = "Nobody deletes the project or a topic"
  rules {
    description = "Only the break-glass group may delete."
    deny_rule {
      denied_principals = ["principalSet://goog/public:all"]
      exception_principals = [
        "principalSet://goog/group/break-glass@example.com",
      ]
      denied_permissions = [
        "cloudresourcemanager.googleapis.com/projects.delete",
        "pubsub.googleapis.com/topics.delete",
      ]
    }
  }
}
```

Three things in it differ from an allow policy. **Principals are written in the `principalSet://` form**:
`principalSet://goog/public:all` is everybody, and `principalSet://goog/group/...` a Google group.
**Permissions are written with the service's address in front**, `pubsub.googleapis.com/topics.delete`
rather than `pubsub.topics.delete`. And **`exception_principals`** carve out who the deny does not apply
to, which is how a break-glass group keeps the one door a real emergency needs.

```
ana@laptop:~/gcp/policy$ terraform plan -input=false -no-color | sed -n '/# google_iam_deny_policy/,/^    }/p'
  # google_iam_deny_policy.production_guard will be created
  + resource "google_iam_deny_policy" "production_guard" {
      + deletion_policy = (known after apply)
      + display_name    = "Nobody deletes the project or a topic"
      + etag            = (known after apply)
      + id              = (known after apply)
      + name            = "production-guard"
      + parent          = "cloudresourcemanager.googleapis.com%2Fprojects%2Fplanner-prod"

      + rules {
          + description = "Only the break-glass group may delete."

          + deny_rule {
              + denied_permissions   = [
                  + "cloudresourcemanager.googleapis.com/projects.delete",
                  + "pubsub.googleapis.com/topics.delete",
                ]
              + denied_principals    = [
                  + "principalSet://goog/public:all",
                ]
              + exception_principals = [
                  + "principalSet://goog/group/break-glass@example.com",
                ]
            }
        }
    }
```

The `parent` came out as `cloudresourcemanager.googleapis.com%2Fprojects%2Fplanner-prod`: the full
resource name of lesson 2 without its leading `//`, with every `/` written as `%2F`, because the deny
policy API takes the parent as one piece of its own address. That is what `urlencode` in the file did.

**Not every permission can be denied.** Deny policies support a list of permissions that grows with each
service, and a permission outside it is refused when the policy is created: one more thing a plan cannot
see. The role to manage them, `roles/iam.denyAdmin`, is held on the organisation, for the same reason as
the policy administrator of lesson 4: the people a deny is aimed at must not be the people who can lift
it. None of this ran against Google.
