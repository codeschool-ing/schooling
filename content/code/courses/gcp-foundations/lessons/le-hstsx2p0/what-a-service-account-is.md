---
title: An identity that is also a resource
version: 1
---

**A service account is two things at once: a principal that holds roles, and a resource that others
hold roles on.** Lesson 5 met the first half: `serviceAccount:reports@planner-dev.iam.gserviceaccount.com`
can be granted `roles/pubsub.subscriber` like any person. This lesson is about the second half, which is
where service accounts become dangerous: **who may act as it?**

Holding a role on a service account is how somebody, or something, gets to use the roles the account
holds. Two roles on the account decide it:

| role on the service account | what its holder may do |
|---|---|
| `roles/iam.serviceAccountUser` | **attach** the account to something they create: a virtual machine, a function, a Cloud Run service, which then runs as the account |
| `roles/iam.serviceAccountTokenCreator` | **impersonate** the account: ask Google for a short-lived token in its name, and make requests as it |

**Either one is, in effect, every role the account holds.** A developer with no role on production, but
`serviceAccountUser` on a production service account that holds Editor, can create a machine that runs as
that account and do anything Editor does. This is the most common way a carefully narrow IAM design leaks,
and it is why a review of who holds what has to read the policies on service accounts, not only on
projects.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l08-act-as\" aria-label=\"How a narrow grant leaks. On the left, a developer with no role on production. In the middle, the service account prod-runner, which holds Editor on planner-prod. The developer holds serviceAccountUser on that account, drawn as an arrow to it. So the developer can create a machine that runs as prod-runner, and through it do anything Editor allows in production, drawn as a dashed arrow from the developer, through the account, to the project.\"><defs><marker id=\"l08-act-as-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-act-as-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"80.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a developer</text><text x=\"100.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no role on production</text><rect x=\"270.0\" y=\"80.0\" width=\"180.0\" height=\"70.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">prod-runner@</text><text x=\"360.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a service account</text><rect x=\"540.0\" y=\"70.0\" width=\"160.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"620.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">planner-prod</text><text x=\"620.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">everything Editor</text><text x=\"620.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">may do</text><path d=\"M182.0 115.0 L266.0 115.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#l08-act-as-af-ah-amber)\"></path><text x=\"224.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--amber)\">serviceAccountUser</text><path d=\"M452.0 115.0 L536.0 115.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#l08-act-as-af-ah-phosphor)\"></path><text x=\"494.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">roles/editor</text><path d=\"M100 152 C 100 220, 620 220, 620 164\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l08-act-as-af-ah-amber)\"></path><text x=\"360.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">acting as the account is holding every role it holds</text><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read the policies on service accounts, not only on projects</text></svg>", "caption": "A role on a service account is a path to every role the account holds."}
```

## Grant on the account, not on the project

Both roles can be granted on a project, where they apply to **every** service account in it, or on one
service account. The project-wide grant is the one that leaks: somebody given `serviceAccountUser` on
the project to deploy one function can now run anything as any account the project has, the default
Compute Engine account with Editor included. The grant belongs on the account the job needs, which lesson
7's authoritative or additive resources write as `google_service_account_iam_member`.

## Attached accounts and where the token comes from

When a machine or a Cloud Run service runs as an attached account, **no key exists anywhere**. The code on
the machine asks the **metadata server**, an address only the machine can reach, `169.254.169.254`, for a
token, and Google hands back one that lasts about an hour and is renewed on demand. The client libraries of
lesson 24 do that on their own; the application never sees a credential to leak, store or rotate. That is
the arrangement to aim for wherever code runs inside Google Cloud, and `gcp-compute` uses it on every
machine it builds.

Nothing in this section ran: attaching an account needs Compute Engine or Cloud Run, which the lab cannot
answer. The next section can show impersonation, because the first thing impersonation does is ask Google
for a token, and Google answers.
