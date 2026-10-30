---
title: Authoritative or additive: three Terraform resources for one policy
version: 1
---

Because a policy is replaced whole, a tool that manages it has to decide **how much of the policy it
owns**. Terraform's Google provider offers three answers, with three resources, and choosing the wrong
one is the commonest way a Terraform run removes somebody's access:

| resource | owns | what it does to everything else |
|---|---|---|
| `google_project_iam_policy` | the **whole policy** | removes every binding the file does not name, the owners' included |
| `google_project_iam_binding` | **one role** | sets that role's member list exactly; removes anybody else holding it |
| `google_project_iam_member` | **one principal in one role** | adds it, and touches nothing else |

The first two are **authoritative**: what the file says is the whole truth for what they own. The third
is **additive**: it only promises that one grant exists. The same three exist for folders, organisations,
service accounts, topics and most resources, with the same names after the resource's own.

## Seeing the difference in a plan

Make a directory with lesson 2's provider file:

```sh
mkdir -p ~/gcp/policy && cd ~/gcp/policy
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Save this as `iam.tf`. It grants Viewer twice, once authoritatively and once additively, on two projects
that exist only on paper:

```hcl
# Authoritative for one role on planner-staging: after an apply, these two
# are the only Viewers, whoever else held the role before.
resource "google_project_iam_binding" "staging_viewers" {
  project = "planner-staging"
  role    = "roles/viewer"
  members = [
    "group:planner-devs@example.com",
    "group:planner-oncall@example.com",
  ]
}

# Additive on planner-dev: Ana holds Viewer, and every other Viewer stays.
resource "google_project_iam_member" "dev_viewer_ana" {
  project = "planner-dev"
  role    = "roles/viewer"
  member  = "user:ana@example.com"
}
```

```
ana@laptop:~/gcp/policy$ terraform plan -input=false -no-color | sed -n '/# google/,/^    }/p'
  # google_project_iam_binding.staging_viewers will be created
  + resource "google_project_iam_binding" "staging_viewers" {
      + etag    = (known after apply)
      + id      = (known after apply)
      + members = [
          + "group:planner-devs@example.com",
          + "group:planner-oncall@example.com",
        ]
      + project = "planner-staging"
      + role    = "roles/viewer"
    }
  # google_project_iam_member.dev_viewer_ana will be created
  + resource "google_project_iam_member" "dev_viewer_ana" {
      + etag    = (known after apply)
      + id      = (known after apply)
      + member  = "user:ana@example.com"
      + project = "planner-dev"
      + role    = "roles/viewer"
    }
```

**The two plans look alike, and that is the danger.** Both say `will be created`, both list members.
Nothing in the plan says that the binding, on apply, would remove a third Viewer that somebody granted by
hand last month, because Terraform does not know that Viewer exists until it reads the policy from
Google. The difference is in the resource's name, and the name is the thing to read. Both carry an
`etag` that is `(known after apply)`: the provider reads the policy, and its etag, at the moment it
writes, which is the read-modify-write of the previous section done for you.

## The rules that keep a team safe

- **Never mix the authoritative and additive resources for the same role on the same resource.** A
  `google_project_iam_binding` for Viewer and a `google_project_iam_member` for Viewer on one project
  fight on every apply: one adds Ana, the other removes her, and the plan never settles.
- **Use `google_project_iam_policy` almost never.** It owns the owners. A file that forgets to list them
  removes them, and with them the people who could put them back. Google's provider documentation says
  the same, in capital letters.
- **Prefer `_member` where people also grant by hand, and `_binding` where Terraform is the only author.**
  A role whose members should be exactly what the file says, such as Owner on production, is the case
  for `_binding`: anything added by hand is removed on the next apply, which is the point.

The plan is the provider's, run on the laptop. What the apply would remove depends on the policy Google
holds today, and only an apply against a real project can show it.
