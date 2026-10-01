---
title: A policy, line by line
version: 1
---

A **policy** is a JSON document that lists what may or may not be done. The same format serves every
place a policy is attached — a user, a group, a role, and some resources — so learning to read one
is learning to read all of them. It has a small, fixed anatomy:

- `Version`, the version of the policy language;
- `Statement`, a list of statements, each deciding something on its own;
- in each statement, `Effect`, which is `Allow` or `Deny`;
- `Action`, the operations it covers, written `service:Operation`;
- `Resource`, the things it covers, written as ARNs;
- optionally `Condition`, the circumstances in which it applies, and `Sid`, a label for people.

A statement means: for these actions, on these resources, in these circumstances, the effect is
this. **Every part narrows**; a statement with more actions or a wider resource says yes to more.

## One policy, read part by part

Here is a policy for somebody who has to read this year's reports and nothing else: the objects
under `2026/` in the bucket `example-reports`, and a listing of what is there. It is written for this
lesson and applied nowhere, because there is no account in this course; it is the document you would
attach to a user, a group or a role.

```schooling-example
{"language": "json", "file": "read-reports-2026.json", "parts": [{"code": "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [", "note": "`Version` is the version of the policy **language**, not a date to keep current. `2012-10-17` is the current one and the value to write. Leave the line out and AWS reads the policy in the older 2008 version, where policy variables such as `${aws:username}` do not work. `Statement` opens the list."}, {"code": "    {\n      \"Sid\": \"ReadReports2026\",\n      \"Effect\": \"Allow\",\n      \"Action\": \"s3:GetObject\",\n      \"Resource\": \"arn:aws:s3:::example-reports/2026/*\"\n    },", "note": "The first statement reads objects. `s3:GetObject` fetches one object, and the resource is every object whose key begins with `2026/` in this bucket: the `*` at the end of the ARN matches the rest of the key, slashes included. `Sid` is only a label, for the person reading."}, {"code": "    {\n      \"Sid\": \"ListReports2026\",\n      \"Effect\": \"Allow\",\n      \"Action\": \"s3:ListBucket\",\n      \"Resource\": \"arn:aws:s3:::example-reports\",", "note": "The second statement lists. `s3:ListBucket` is an action on the **bucket**, so its resource is the bucket's ARN with no `/*` after it. Allowed on its own, it would list every key in the bucket, including the years this person may not read."}, {"code": "      \"Condition\": {\n        \"StringLike\": { \"s3:prefix\": \"2026/*\" }\n      }\n    }\n  ]\n}", "note": "So the condition narrows it. `StringLike` compares with wildcards, and `s3:prefix` is the prefix the request asked to list. A listing of `2026/` or anything under it is allowed; a listing of the whole bucket, with no prefix, matches nothing and is refused."}]}
```

Two statements, and not one, because the two actions work on two different kinds of resource. That
is the detail people get wrong most often in S3 policies: `s3:ListBucket` put on
`arn:aws:s3:::example-reports/*` matches nothing, because a listing is not an operation on any
object. The request to list is refused, the policy looks right, and somebody spends an afternoon on
it.

## Things a policy does not contain

There is no `Principal` in that document, and that is right. **A policy attached to an identity is
about that identity**, so it does not need to name it; the user, group or role it is attached to is
the principal. `Principal` appears in the two kinds of policy that sit somewhere else and have to say
whom they are talking about: a trust policy, as in the previous section, and a resource-based policy,
such as a bucket policy attached to the bucket itself.

There is also no ordering. Statements are not read top to bottom with the first match winning, the
way firewall rules often are; the next section shows that every statement that applies is weighed
together.

And a statement's lists multiply. One statement with three actions and two resources covers every
action on every resource, six pairs in all, not three matched pairs. If the pairs have to be
matched — reads here, writes there — they have to be separate statements.

## Actions have names you can look up

Each provider publishes the list of actions per service, with the resource each action works on and
the condition keys it understands. At AWS that is the *Service Authorization Reference*. The list is
long: S3 alone has well over a hundred actions. Nobody memorises it; the habit to build is to look up
the action you think you need, check what resource it expects, and write exactly that, which is the
subject of the section after next.
