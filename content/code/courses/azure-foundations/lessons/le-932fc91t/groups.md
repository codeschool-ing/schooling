---
title: Groups, and the rule that keeps one up to date
version: 1
---

**Give access to groups, never to people.** It is the oldest rule in the trade, and it is a rule
about leaving rather than joining. A permission given to `bia` stays with `bia` until somebody
remembers to take it away; a permission given to the engineering group leaves her the day she leaves
the group, and nobody has to remember anything. Lesson 9 assigns every Azure role in this course to a
group for that reason.

Entra ID has two kinds of group, and only one of them is for access:

| kind | what it is for | holds |
|---|---|---|
| **security** | access: to Azure resources, applications, and the directory's own roles | users, devices, service principals, other groups |
| **Microsoft 365** | collaboration: a shared mailbox, calendar, files and a Teams team | users only |

A Microsoft 365 group can be given access too, and companies do it, but its members are whoever
joined a team to share a calendar. **The shop keeps access in security groups**, named so that the
name says it: `grp-shop-engineering`, `grp-shop-prod-readers`.

## Assigned, or computed

A group's members are either **assigned**, added and removed one by one, or **dynamic**, computed by
Entra ID from a rule over the users' own attributes:

```
user.department -eq "Engineering"
```

Every user whose `department` is `Engineering` is a member, and only those. Hire somebody into
engineering and the HR system that fills in her department has also given her the group; move her
to marketing and she leaves it, in minutes, with nobody touching the group. **A dynamic group turns
a fact the company already keeps into access**, which is the strongest argument for it and also the
risk: whoever can edit a user's department can now move that user into a group with access to
production. Choose attributes that only the HR system writes.

Two limits come with dynamic groups. They need a **Microsoft Entra ID P1** licence, the paid tier,
for the users they apply to, so a new tenant on the free tier cannot have them. And a dynamic group
cannot have members added by hand: the rule is the whole membership, which is the point.

## Groups inside groups

A security group may contain another group, and **whether the members of the inner group count
depends on the feature**. Azure's role-based access follows the nesting: a role given to
`grp-shop-all` reaches members of `grp-shop-engineering` if that group is inside it. Several other
features read only direct members; Microsoft's documentation states it per feature, and assigning an
application to a group is one where the nested members are left out. **Keep the nesting shallow**,
one level at most, and read the documentation of the feature that will consume the group before
relying on it.

## Who owns a group

Every group can have **owners**, users allowed to change its membership without being directory
administrators. That is useful for a team that manages its own people, and it is also a door: an
owner of a group with access to production can add anybody to it. **A group that grants access to
production has owners from the platform team only**, and the next section narrows the
administrators the same way.
