---
title: Permissions, roles, and the three roles that are too big
version: 1
---

**A permission is one thing an API lets you do; a role is a named set of permissions; and only a role
can be granted.** That last part is the rule people try to break first. There is no way to grant
`pubsub.topics.publish` on its own to anybody; it has to arrive inside a role, and the choice of which
role is the whole craft of IAM.

A permission is written `service.resource.verb`, and reading one aloud says what it does:

| permission | what it allows |
|---|---|
| `pubsub.topics.publish` | publish a message to a topic |
| `pubsub.topics.create` | create a topic |
| `resourcemanager.projects.delete` | delete a project |
| `iam.serviceAccounts.actAs` | run something as a service account, lesson 8 |

A role is written `roles/NAME`, and a grant joins three things: **a principal, a role, and the resource
it is granted on**. `group:planner-devs` with `roles/pubsub.publisher` on the topic `orders` may publish
to `orders` and to no other topic.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l06-chain\" aria-label=\"How a grant is put together, left to right. Permissions, such as pubsub.topics.publish, are collected into a role, roles/pubsub.publisher. A grant joins that role to a principal, group:planner-devs, and to the resource it is granted on, the topic orders. Below, a note: a permission can never be granted on its own, only inside a role.\"><defs><marker id=\"l06-chain-af-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"190.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">permissions</text><rect x=\"32.0\" y=\"64.0\" width=\"166.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">pubsub.topics.publish</text><rect x=\"32.0\" y=\"104.0\" width=\"166.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">pubsub.topics.get</text><path d=\"M212.0 95.0 L256.0 95.0\" stroke=\"var(--paper)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l06-chain-af-ah-paper)\"></path><rect x=\"260.0\" y=\"66.0\" width=\"180.0\" height=\"58.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"350.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a role</text><text x=\"350.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">roles/pubsub.publisher</text><path d=\"M442.0 95.0 L486.0 95.0\" stroke=\"var(--paper)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l06-chain-af-ah-paper)\"></path><rect x=\"490.0\" y=\"20.0\" width=\"210.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"595.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">a grant</text><text x=\"595.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">who</text><text x=\"595.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">group:planner-devs</text><text x=\"595.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">which role</text><text x=\"595.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">roles/pubsub.publisher</text><text x=\"595.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">on what</text><text x=\"595.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">topics/orders</text><text x=\"360.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a permission is never granted on its own, only inside a role</text></svg>", "caption": "Permissions make a role; a grant joins the role to a principal, on a resource."}
```

## Owner, Editor and Viewer

Three roles predate everything else in Google Cloud and are still the first ones people meet. Google
calls them **basic roles**:

- **Viewer**, `roles/viewer`, reads almost everything in the project;
- **Editor**, `roles/editor`, changes almost everything: creates and deletes machines, networks,
  databases, topics, across every service the project has enabled;
- **Owner**, `roles/owner`, is Editor plus managing IAM itself: it may grant any role to anybody,
  including Owner.

**All three are too big for almost every job**, and Google's own documentation says to avoid them in
production. The reason is what they contain. Editor holds the permissions of thousands of actions in
hundreds of services, and it grows: every new service Google launches adds its permissions to Editor.
A role granted for "deploying the website" that also lets its holder delete the database is a role
somebody will one day use for the second thing by accident. Viewer has a quieter version of the same
problem: it can read things that are not meant for everybody who may look at a project, such as the
configuration of every service in it.

Owner deserves a sentence of its own. **Whoever holds Owner can make themselves anything**, because
granting roles is part of it. The number of owners of a production project is the number of people who
can take it over, and a good answer is two, held through a group, used rarely.

## What to grant instead

The answer is the **predefined roles** of the next section: roles Google defines per service, sized for
one job. Basic roles keep two honest uses: Viewer for a person exploring a sandbox project, and Owner on
a project that exists to be thrown away. Everything that runs in production is granted predefined roles,
or custom ones built from the same permissions.
