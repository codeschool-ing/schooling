---
title: Cost allocation tags, and what they cannot do afterwards
version: 1
---

A bill arrives as a total and a list of services. Neither says **whose** the money was, and that is the
question a bill has to answer before anybody can act on it: a team that cannot see its own spend cannot
reduce it, and a cost nobody owns grows until somebody finds it, which lesson 23's idle resources show.
The answer on AWS is **tags**, and three rules make them work for cost.

**A short list of keys, written down.** The shop's is three: `owner`, the team that answers for the
resource; `environment`, `prod`, `staging` or `dev`; and `service`, what it is part of. More keys are
more ways to be inconsistent; three that every resource has beat ten that some resources have.
`Owner`, `owner` and `team` are three keys to the billing system, so the spelling is part of the list.

**Tags are applied where resources are created.** Lesson 6's Terraform put `default_tags` on the provider,
and every resource it created carried them; a resource made by hand in the console carries what the
person remembered. A **tag policy** in AWS Organizations can enforce the spelling of keys and values, and
a service control policy can refuse to create a resource without them; both are organisation features
the lab does not have.

**A tag counts for cost only after it is activated, and only from then on.** In the billing console, or
with `update-cost-allocation-tags-status`, a key is made a cost allocation tag, and from that moment
the bill and Cost Explorer can group by it. **Activation is not retroactive**: last month's costs were
recorded without the tag and stay that way. A team that activates `owner` in March sees owners from March,
which is the reason to activate the keys on the day the list is written, not the day somebody asks.

```
ana@laptop:~/aws/owners$ aws ce update-cost-allocation-tags-status --cost-allocation-tags-status TagKey=owner,Status=Active 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the UpdateCostAllocationTagsStatus operation (reached max retries: 2): <!doctype html>
```

moto has no billing data, so activation is a 500 here; on AWS it takes up to a day to appear in Cost
Explorer. AWS also creates a few tags itself, `aws:createdBy` among them, which can be activated the same
way and say which identity created a resource, useful when the `owner` tag is missing.
