---
title: The root user, and the IAM users beside it
version: 1
---

**A principal is whatever signs a request that AWS then judges.** Every call to AWS carries a
signature, the signature names an identity, and IAM decides what that identity may do. The common
wrong picture is that an IAM user is a person. **A user is a name with long-term credentials**,
and the two do not line up: a person can work in AWS for years with no IAM user at all, signing in
through single sign-on as lesson 11 shows, and a program on somebody's laptop can sign every
request with a user's key.

This lesson creates the four kinds of principal AWS has, in the order an account meets them: the
root user, IAM users, role sessions and federated identities. Groups come in the middle, and they
are the one thing in IAM's list of identities that is **not** a principal.

## Before anything: an empty AWS

Restart moto in the first terminal (Ctrl+C, then `moto_server -p 4567`) so this lesson starts from
an empty AWS, and read `env.sh` into the second, as lesson 1 showed. **moto's permission checking
stays off in this lesson**, which is its default: every call below succeeds whoever makes it.
Lesson 7 turns the checking on. Until then, a command that works here proves the command is right,
not that anybody was allowed to run it.

## The root user

Opening an AWS account creates one identity, from the e-mail address and password typed into the
form. That identity is the **root user**, and its ARN has no name in it, only the account:
`arn:aws:iam::123456789012:root`. It holds every permission in the account, and **no IAM policy in
the account can take one away from it**. Only a service control policy, set from outside by the
organisation, limits the root user of a member account, and lesson 4 shows how.

A short list of tasks needs root and nothing else, according to AWS's documentation: changing the
account's name, e-mail address or root password, changing or cancelling the support plan, and
closing the account. **Everything else is done by some other principal**, so the root password is
kept somewhere safe, protected with MFA, and taken out for those tasks alone. Lesson 1's section on
a real account gives the order to do that in. An organisation can go further and remove the root
password of its member accounts altogether, which IAM's documentation calls centralised root
access.

moto has no root user to sign in as: lesson 1's `get-caller-identity` answered with a user called
`moto`. What it does keep is the account summary, and two of its lines are the first thing an
audit of a real account reads:

```
ana@laptop:~/aws$ aws iam get-account-summary --query "SummaryMap.{AccountMFAEnabled:AccountMFAEnabled,AccountAccessKeysPresent:AccountAccessKeysPresent,Users:Users,GroupsPerUserQuota:GroupsPerUserQuota}"
{
    "AccountMFAEnabled": 0,
    "AccountAccessKeysPresent": 0,
    "Users": 0,
    "GroupsPerUserQuota": 10
}
```

**Both `Account…` lines describe the root user, not the account.** `AccountMFAEnabled` is 1 when
root has a second factor, and `AccountAccessKeysPresent` is 1 when root has an access key. A real
account wants 1 and 0. moto prints 0 for both because there is no root behind it, which is the
one case where 0 MFA is not a finding.

## IAM users

The shop has three people besides ana: bia the developer, caio the analyst and dani from finance.
Each gets an IAM user here, because that is the principal this lesson is about. Lesson 11 moves
people onto IAM Identity Center, which is where a person belongs in a real organisation.

```
ana@laptop:~/aws$ aws iam create-user --user-name bia
{
    "User": {
        "Path": "/",
        "UserName": "bia",
        "UserId": "js9pb6447kryw6le9a1i",
        "Arn": "arn:aws:iam::123456789012:user/bia",
        "CreateDate": "2026-10-16T16:06:21.871983+00:00"
    }
}
```

The ARN is the user's address in every policy: the service `iam`, no region because IAM is global,
the account, then `user/` and the name. `UserId` is the user's **unique id**, and it is a different
thing from the name, which the next section comes back to. **moto's ids do not have AWS's shape.**
AWS's user ids are 21 characters starting with `AIDA`; moto's are 20 random lowercase letters and
digits, as above. The other two users:

```
ana@laptop:~/aws$ aws iam create-user --user-name caio --query "User.[UserName,UserId,Arn]" --output text
caio	uamtq0s7tvnse8tqk0us	arn:aws:iam::123456789012:user/caio
ana@laptop:~/aws$ aws iam create-user --user-name dani --query "User.[UserName,UserId,Arn]" --output text
dani	c9jkpficj8fz3num8nga	arn:aws:iam::123456789012:user/dani
```

A user can hold two kinds of long-term credential, and long-term means exactly that: they last
until somebody deletes them.

- **A password**, for the console, made by `create-login-profile`. AWS calls it a login profile.
- **An access key**, for the command line and the SDKs: an id and a secret that sign requests.

```
ana@laptop:~/aws$ aws iam create-login-profile --user-name bia --password 'Lab-only-pass-2026' --password-reset-required
{
    "LoginProfile": {
        "UserName": "bia",
        "CreateDate": "2026-10-16T16:06:21.871983+00:00",
        "PasswordResetRequired": false
    }
}
ana@laptop:~/aws$ aws iam create-access-key --user-name bia --query "AccessKey.[AccessKeyId,Status]" --output text
AKIARZPUZDIKEBQA4QAN	Active
```

**An access key id begins with `AKIA`**, in moto and in AWS: four letters that mean "long-term key
of an IAM user". The `--query` printed the id and the status and kept the secret off the screen,
which is a habit worth having even with moto's keys, which open nothing outside moto. moto also
recorded `PasswordResetRequired` as false although the command asked for true; AWS keeps the flag
and makes bia choose a new password at her first sign-in.

The password and the key have the same weakness: **they work from anywhere, for anyone holding
them, until somebody notices.** That is why lesson 12 calls an access key the last resort, and why
the next section's roles exist.
