---
title: Tags, or who is spending it
version: 1
---

A bill grouped by service answers what is being bought: so much for EC2, so much for the NAT gateway, so
much for S3. It does not answer **who is buying it**, and that is the question every cost conversation
turns into. Three teams share one account; the bill went up by a third; each team is sure it was not
them. **A cost you cannot attribute to somebody is a cost nobody can manage**, because nobody can decide
to change it.

## Tags are the attribution

A tag is a key and a value attached to a resource: a machine, a volume, a bucket, a load balancer. The
providers all have them; Google Cloud calls them labels. A small, fixed set on every resource is enough
to answer most questions:

| key | example value | what it answers |
| --- | --- | --- |
| `team` | `payments` | who to ask, and whose budget it comes out of |
| `project` | `shop` | which product the spending belongs to |
| `environment` | `production`, `staging`, `test` | whether it serves customers or can be switched off |

With those three, the 298.64 of the estimate stops being one number. The same bill grouped by
`environment` might show that staging costs almost as much as production, which is a finding; grouped
by `team`, it shows whom to talk to about it.

**A tag has to be activated before it appears in the bill.** In AWS, a tag you put on resources is not a
cost allocation tag until somebody activates it in the billing settings. Until then, the resources carry
it and the cost reports ignore it. And a tag only attributes the cost incurred while it was on the
resource. A machine tagged in March says nothing about who paid for it in February.

## Some lines cannot be tagged

Not every line of a bill belongs to a resource. Tax, a support plan and some traffic charges arrive as
account-wide amounts. Rather than leaving them unattributed, agree a rule once, such as splitting them in
proportion to each team's tagged spending, and apply it every month the same way. **A rule people
dislike but understand beats a number nobody can explain.**

## Resources nobody owns

The most useful report tags produce is the one that lists **what has no tags at all**. An untagged
resource is one nobody claimed when it was created: the test machine from a workshop, the volume left
behind by a deleted instance, the address reserved and never used. These are where the surprise lines
from earlier in this lesson live. Reviewing the untagged spend every week, and deleting or claiming each
item, is the cheapest cost saving there is.

## A tag policy, in outline

Tags only work if they are consistent. `Team`, `team` and `teem` are three different keys to a billing
report, and `prod`, `production` and `Production` are three different environments. A tag policy writes
the convention down and lets the provider check it:

- which keys are required on which kinds of resource;
- how each key is spelled, including its case;
- which values are allowed, where the list is closed, as it is for `environment`;
- whether a resource without the required tags may be created at all.

AWS Organizations has tag policies and Azure has Azure Policy, which can refuse or flag a resource;
`aws-foundations` and `azure-foundations` show the syntax. The strongest
enforcement is the one nobody has to remember: when infrastructure is written as code, as in the `iac`
course, the tags are set once as a default and every resource carries them.
