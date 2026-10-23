---
title: When a key leaks
version: 1
---

**A leaked access key is not discovered by the person who leaked it. It is discovered by a program,
often within minutes, and the question is only whose program gets there first.** Public
repositories are read continuously by automated scanners, some run to protect key owners and some
run to use what they find. A key pushed by mistake has to be treated as known to everybody from the
moment of the push.

The wrong picture is that deleting the file fixes it. A commit that removes a key leaves it in the
commit before, in every clone and fork made in between, and in any cache that copied the page. **The
only fix for a leaked key is to make the key worthless**, which means rotating it, and the rest of
this lesson is about doing that without breaking the application that used it.

## Where keys end up

The usual routes are ordinary, and none of them looks like a mistake while it is happening:

- a configuration file committed with the code, the case below;
- a value pasted into a ticket, a chat or a support case, to show somebody the error;
- a screenshot of a terminal, posted to explain something else;
- a container image built with the key copied in, where it stays in a layer even after a later
  layer deletes the file;
- a CI log that printed the environment while debugging.

caio set the booking application up the quick way: a file beside the code with his key in it. Make
a directory that stands for the application's repository, and write the same file there from the key
in the variable `caio`:

```sh
mkdir -p booking
printf 'AWS_ACCESS_KEY_ID=%s\nAWS_SECRET_ACCESS_KEY=%s\n' \
  "$(echo "$caio" | jq -r .AccessKey.AccessKeyId)" \
  "$(echo "$caio" | jq -r .AccessKey.SecretAccessKey)" > booking/booking.env
```

## Finding one

**Key ids have a shape, and the shape is what scanners look for.** `AKIA` or `ASIA`, then sixteen
capital letters and digits. One `grep` over a directory is the smallest scanner there is:

```
ana@laptop:~/aws$ grep -rnoE 'A(KI|SI)A[A-Z0-9]{16}' booking
booking/booking.env:1:AKIARZPUZDIKKKVVGHFV
```

It found the id in `booking/booking.env`, line 1. A real scanner adds the secret's shape, which has no
prefix and is harder to tell from random text, and checks history as well as the files of today.
Gitleaks and TruffleHog are two widely used ones, and the `secure-code` course's lesson 16 argued
where the value should have gone instead.

::: track devsecops
Running one on every push, over the history too, is what the `secure-pipeline` course's lesson 6 set
up in the pipeline you built before this course.
:::

::: track *
Running one on every push, over the history too, belongs in the pipeline; the `secure-pipeline`
course's lesson 6 builds exactly that.
:::

**GitHub runs the same search on public repositories**, through its secret scanning partner
programme: when it finds something shaped like an AWS key, it tells AWS. None of that was run here,
since nothing in this lab is public.

## What AWS does, and what it does not

When AWS learns that a key is exposed, by GitHub's report or its own, it contacts the account and
may attach a managed policy to the user, the **compromised-key quarantine policy** that lesson 6 read
for its list of IAM actions. Here you attach it by hand, standing in for AWS, and ask what caio's key
can still do:

```
ana@laptop:~/aws$ aws iam attach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3
ana@laptop:~/aws$ with_key "$caio" aws s3 ls

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListBuckets operation: Access Denied
ana@laptop:~/aws$ with_key "$caio" aws iam create-access-key --user-name caio

aws: [ERROR]: An error occurred (AccessDenied) when calling the CreateAccessKey operation: User: arn:aws:iam::123456789012:user/caio is not authorized to perform: iam:CreateAccessKey
ana@laptop:~/aws$ with_key "$caio" aws secretsmanager list-secrets --query "length(SecretList)"
0
```

The listing of buckets and the creation of a new key were refused: an explicit `Deny` beats the
`PowerUserAccess` that allows them. **The request to Secrets Manager went through.** The quarantine
denies the actions most often abused, the ones that cost money or create new ways in, and not
everything. It is a brake applied by somebody else, and it buys time for the owner to act.

So the owner's steps, in AWS's documented order, are the next section's: replace the key with a new
one, delete the exposed one, then read what the old key did while it was out, from the records lesson
15 is about, before removing the quarantine.
