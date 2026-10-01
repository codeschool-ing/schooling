---
title: Users and groups, the identities for people
version: 1
---

A **user** is a long-lived identity for one person. It has a name, and it can have two kinds of
credential: a password for signing in to the console, and one or more access keys for the command
line and for programs. Long-lived means it exists until somebody deletes it, and so does every
credential it holds. An access key created in March works in December unless somebody did something
about it in between.

One user per person, and never a shared one. A user called `dev` that four people sign in as is the
root problem again at a smaller size: the log records `dev`, and nobody can say which of the four
made a call.

## Permissions go on the group, not on the person

The habit that goes wrong is attaching permissions to each person as they arrive. Take a team of
eight, where everybody needs the same three policies: read the reports bucket, manage the team's
virtual machines, read the logs. Attached one person at a time, that is 24 attachments. The ninth
person to join gets "the same as Bruno", and somebody copies Bruno's list, including the policy he
kept from the project he left last year. Nobody decided the ninth person should have it; it arrived
by resemblance.

**A group is a set of users that policies are attached to.** The team becomes one group with three
policies on it, and a person's access is the groups they belong to:

| | per person | with a group |
|---|---|---|
| attachments for eight people | 24 | 3 |
| somebody joins | copy another person's list | add them to the group |
| the team loses a permission | remove it eight times | remove it once |
| somebody moves team | find what was theirs and what was the team's | change their groups |

A group is a way to hand out permissions and nothing more. At AWS it cannot sign in, it has no
credentials of its own, and a policy cannot name a group as the principal it is talking about; groups
also cannot contain other groups. If a policy needs to say "the analysts", it says so by being
attached to the analysts' group.

## A person leaving should be one change

The test of the arrangement is the day somebody leaves. With groups, their permissions leave with
their memberships, and deleting the user takes the rest. Without groups, somebody has to find every
attachment, and the one that is missed is the one nobody remembers giving.

There is a trap inside the user itself. **The console password and the access keys are separate
credentials, and removing one leaves the other working.** Disabling somebody's console sign-in on
their last day does nothing to the access key on their laptop; a script that used it on Friday still
works on Monday. The complete change is to deactivate and delete the keys as well, or to delete the
user, which takes everything it holds.

The next step past this is to have no long-lived users for people at all. Sign-in happens once, at
the organisation's own identity provider, with a second factor, and the cloud account hands out
temporary credentials; leaving is then one change in one place for every account the person could
reach. Two more pieces are needed before that works, a role and a trust between systems, and they
are the next section and the one on federation.
