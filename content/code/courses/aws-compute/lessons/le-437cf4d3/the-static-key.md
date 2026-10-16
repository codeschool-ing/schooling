---
title: The static key, and why it is the wrong answer
version: 1
---

A pod in the shop's EKS cluster resizes product photos, and it has to read them from an S3 bucket.
So it needs AWS credentials. The answer most teams reach for first is quick: create an IAM user,
give it an access key, put the key in a Kubernetes Secret, and hand the Secret to the pod as two
environment variables. **It works on the first afternoon, and everything wrong with it happens on
the days after.** This section is about those days, seen from the side of whoever has to keep the
account safe.

## A key that never ends

Create the user and its key the way that answer does. The `--query` keeps the secret half off the
screen, which is a habit worth having even with moto:

```
ana@laptop:~/aws$ aws iam create-user --user-name shop-app --query User.Arn
"arn:aws:iam::123456789012:user/shop-app"
ana@laptop:~/aws$ aws iam create-access-key --user-name shop-app --query "AccessKey.[Status,CreateDate]" --output text
Active	2026-10-16T16:29:03.368272+00:00
ana@laptop:~/aws$ aws iam list-access-keys --user-name shop-app --query "AccessKeyMetadata[0]" | grep -v AccessKeyId
{
    "UserName": "shop-app",
    "Status": "Active",
    "CreateDate": "2026-10-16T16:29:03.368272+00:00"
}
ana@laptop:~/aws$ aws sts get-session-token --query "Credentials.Expiration"
"2026-10-17T04:29:04.409027+00:00"
```

The key's own record has a status and a date of birth, and nothing else. **There is no field for
when it stops working, because it does not stop.** It is valid until a person deactivates or
deletes it, which in practice means until somebody remembers. The last command asks STS for a
temporary credential instead, and that one carries an `Expiration` twelve hours ahead. Every
credential the rest of this lesson produces is of the second kind, and most of what follows is
about how a pod gets one without anybody storing a key at all.

## A Secret is an envelope, not a safe

The Secret the quick answer writes looks like this. The two values are the word `test`, the
credentials moto accepts and AWS refuses:

```yaml
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: photos-aws
  namespace: shop
data:
  AWS_ACCESS_KEY_ID: dGVzdA==
  AWS_SECRET_ACCESS_KEY: dGVzdA==
```

The strings under `data` look scrambled, and that is the whole of their protection:

```
ana@laptop:~/aws$ grep SECRET secret.yaml
  AWS_SECRET_ACCESS_KEY: dGVzdA==
ana@laptop:~/aws$ grep SECRET secret.yaml | awk '{print $2}' | base64 -d; echo
test
```

**Base64 is an encoding, and anybody can reverse it with a command every Linux machine has.** A
Kubernetes Secret is kept in the cluster's database and handed to the pods that mount it. Who can
read it is decided by Kubernetes permissions, and AWS encrypts the disks underneath; neither stops
the key from leaving through the people and programs that are allowed to see it. Count where this
one ends up:

- **in the manifest**, if `secret.yaml` was ever committed to the repository, and then in every
  clone and every fork of it;
- **in the cluster**, readable by anyone allowed to `get secrets` in the namespace, and by every pod
  that mounts it;
- **in the places a key leaks to by accident**: a CI log that printed the environment, a laptop's
  shell history, a support ticket with a pasted error.

Each copy is as good as the original, for as long as the key lives, which the capture above says is
forever.

## One user for every pod

Three replicas of the resizer, a debugging pod somebody started last month and a developer's laptop
all present the same key. In CloudTrail every one of their calls is made by `user/shop-app`, so the
record of who read a bucket cannot tell a pod from a laptop. And rotating the key, because it leaked
or because a policy says ninety days, is a small project. It takes a second key, a new Secret and a
rollout of every deployment that reads it, then deleting the old key and hoping nothing else had a
copy.

## The other wrong answer: the node's role

The second answer people reach for is to give the permission to the node. `aws-foundations` lesson
10 showed how an instance profile hands a role to an EC2 instance, and an EKS node is an EC2
instance with one already: the node role, which lets the kubelet join the cluster and pull images
from ECR. Add `s3:GetObject` to it and the resizer can read the bucket, with no key anywhere.

**So can every other pod scheduled on that node**, whatever it is and whoever wrote it, because
the node's credentials come from the instance metadata service and any process on the machine can
ask. The permission is granted to a machine, while the need belongs to one workload. Lesson 7 is
where the defence lives: with IMDSv2 required and a hop limit of 1, the answer to the token request
cannot travel the extra hop into a container on its own network, so pods cannot reach the node's
role at all. EKS's own guidance is to block it that way and give each workload its own role.

## What the replacement has to do

Put the failures side by side and the requirements write themselves. The credential should belong
to **one workload**, named by its Kubernetes service account, and not to a node or a user. It
should **expire** on its own, in hours. It should be **stored nowhere** a person can copy it from.
And CloudTrail should be able to say **which workload** made the call.

`aws-foundations` lesson 10 named the mechanism that does all four: **IAM roles for service
accounts**, IRSA. The next three sections build it piece by piece and run the exchange at its heart
on your laptop. The last one shows EKS Pod Identity, the newer way to reach the same result.

If your cluster already has keys like `shop-app`'s, they are findable: `aws iam list-access-keys`
for each user, as above, and `aws iam get-access-key-last-used`, which says when a key was last
used and for which service. A key that is old, active and used from a pod is the first one to
replace.
