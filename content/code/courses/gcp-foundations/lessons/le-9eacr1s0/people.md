---
title: People, groups and the two words that mean everybody
version: 1
---

**A principal is whoever a role is granted to.** IAM in Google Cloud never grants anything to a
password, a laptop or an address; it grants a role to a principal, on a resource, and the principal is
written as a prefix and an identifier. The prefix is the part people forget, and it is the part that
says what kind of thing is being trusted.

| written as | what it is |
|---|---|
| `user:ana@example.com` | one Google account: a person, signed in |
| `group:planner-devs@example.com` | a Google group, and everybody in it at the moment of the request |
| `domain:example.com` | every account in a Cloud Identity or Workspace domain |
| `allAuthenticatedUsers` | anybody signed in to any Google account, anywhere |
| `allUsers` | anybody at all, signed in or not |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l05-principals\" aria-label=\"Where each kind of principal comes from, in three columns. From the company's Google directory, Cloud Identity or Workspace: user, group and domain. Made in Google Cloud: service accounts you create, default service accounts and service agents. From somebody else's directory, through federation: principal and principalSet, from a workforce pool for people or a workload pool for programs. Below all three, one rule: a role is granted to any of them the same way, on a resource. Apart, the two that mean everybody: allAuthenticatedUsers and allUsers.\"><defs><marker id=\"l05-principals-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"200.0\" height=\"160.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the Google directory</text><rect x=\"40.0\" y=\"60.0\" width=\"160.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">user:</text><rect x=\"40.0\" y=\"98.0\" width=\"160.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">group:</text><rect x=\"40.0\" y=\"136.0\" width=\"160.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">domain:</text><rect x=\"260.0\" y=\"20.0\" width=\"200.0\" height=\"160.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">made in Google Cloud</text><rect x=\"280.0\" y=\"60.0\" width=\"160.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">serviceAccount:</text><rect x=\"280.0\" y=\"98.0\" width=\"160.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">default accounts</text><rect x=\"280.0\" y=\"136.0\" width=\"160.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">service agents</text><rect x=\"500.0\" y=\"20.0\" width=\"200.0\" height=\"160.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">another directory</text><rect x=\"520.0\" y=\"60.0\" width=\"160.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">principal://</text><rect x=\"520.0\" y=\"98.0\" width=\"160.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">principalSet://</text><rect x=\"520.0\" y=\"136.0\" width=\"160.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">workforce / workload</text><path d=\"M120.0 182.0 L120.0 206.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-principals-af-ah-paper-dim)\"></path><path d=\"M360.0 182.0 L360.0 206.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-principals-af-ah-paper-dim)\"></path><path d=\"M600.0 182.0 L600.0 206.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-principals-af-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"208.0\" width=\"680.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a role is granted to any of them the same way, on a resource</text><text x=\"360.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">apart: allAuthenticatedUsers and allUsers, which mean everybody</text></svg>", "caption": "Three origins, one way of granting."}
```

## A person is an account, and an account belongs to somebody else

`user:` names a **Google account**, and Google Cloud does not own it. The account lives in Cloud
Identity or Google Workspace for a company's own people, lesson 10's subject, or is a personal Gmail
address for everybody else. Google Cloud only trusts that whoever signs in as `ana@example.com` is the
person the directory says; if the directory suspends the account, every role granted to it stops
working at once, without anybody touching IAM.

That makes **the directory part of the security of every project**, and it is why a company grants
roles to its own domain's accounts and nobody else's. A policy from lesson 4, `iam.allowedPolicyMemberDomains`,
refuses a grant to any account outside the domains it lists, so that `user:ana.personal@gmail.com`
cannot be added to production by a hurried colleague.

## Groups are the unit of grants

**Grant to groups, not to people.** A role granted to `group:planner-devs@example.com` is held by
everybody in the group, and joining or leaving the group is a change in the directory, made by
whoever runs the directory, with no change to any IAM policy at all. The difference shows up on the
day somebody leaves: with groups, removing them from three groups ends every role; with direct grants,
somebody has to find every project, folder and bucket where `user:` named them, and the one that is
missed is the one that matters.

Groups also make policies readable. A project whose policy says `planner-devs` may deploy and
`planner-oncall` may restart says what the team is; a policy listing forty addresses says who happened
to ask.

## The two words that mean everybody

`allAuthenticatedUsers` sounds restrictive and is not: **it means every Google account in the world**,
including a Gmail account created five minutes ago. `allUsers` adds people who are not signed in at
all. Both have a legitimate use, a public bucket of images for a website, and both are the most common
cause of data that should not have been public becoming so. The domain-restriction policy above
refuses both, and an estate that needs one public bucket exempts that one project rather than lifting
the policy for everybody.

Nothing in this section ran in the lab: there is no directory and no IAM to ask. The last section of
this lesson writes every kind of principal into a Terraform file and has the provider check how each
is written.
