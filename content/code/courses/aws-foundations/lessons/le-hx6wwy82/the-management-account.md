---
title: The management account, and accounts that already exist
version: 1
---

**The management account is the most powerful account in the organisation, so it should do the
least.** The tempting picture is the opposite: it is the first account, it already exists, somebody
has the password, so the shop's first machines go there. Three facts make that the worst place in
the tree for them.

- **It can reach into every member.** Each account it created carries a role it may take on, which
  the next transcript shows. Whoever controls the management account controls all of them.
- **No rule of the organisation applies to it.** Lesson 4's guardrails restrict every member account
  and never the management account, by design. A workload there runs outside all of them.
- **It holds the bill and the tree.** From it somebody can create accounts, move them between
  branches, remove them and change the payment method.

So the shop's management account runs nothing, very few people may sign in to it, and they do so
for two jobs: the organisation and the bill. **Work that has to be done for the whole tree is
handed to a member.** Organizations lets the management account name a member as the
**delegated administrator** of a service, such as the security tooling that lesson 5 places in the
`security` account, so that even those jobs leave the management account alone.

## The role in every account it created

```
ana@laptop:~/aws$ aws configure set profile.shop-prod.role_arn arn:aws:iam::$(account shop-prod):role/OrganizationAccountAccessRole
ana@laptop:~/aws$ aws configure set profile.shop-prod.credential_source Environment
ana@laptop:~/aws$ aws configure set profile.shop-prod.role_session_name ana
ana@laptop:~/aws$ aws --profile shop-prod iam get-role --role-name OrganizationAccountAccessRole --query "Role.AssumeRolePolicyDocument"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::123456789012:root"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
ana@laptop:~/aws$ aws --profile shop-prod iam list-attached-role-policies --role-name OrganizationAccountAccessRole
{
    "AttachedPolicies": []
}
```

These are lesson 2's three lines again, with the account number looked up rather than typed, since
this moto's `shop-prod` is a different account. The role's **trust policy** names who may take it
on: `arn:aws:iam::123456789012:root`, which means the management account as a whole, whichever of
its own identities its IAM lets through, and not its root user. Lesson 9 reads trust policies
properly.

**The second answer is where moto and AWS part.** In AWS, `OrganizationAccountAccessRole` arrives
with the managed policy `AdministratorAccess` attached, so taking it on gives full control of the
member account. In moto the role arrives with **no policy at all**. Nothing in this lesson notices,
because moto checks no permission until lesson 7 turns that on; from then on, a member account's
role in moto is allowed nothing until a policy is attached to it. `create-account` also takes a
`--role-name`, for a company that wants the role called something else.

## An account that already exists

**An existing account joins by invitation, and the invitation has to be accepted from inside it.**
The management account sends it with `invite-account-to-organization`; AWS e-mails the other
account's owner; somebody signed in to that account accepts it with `accept-handshake`, and only
then is it a member. The exchange is called a **handshake**, and it exists because joining hands an
account's bill and its limits to somebody else: nobody may do that to an account but the account
itself.

moto has none of it:

```
ana@laptop:~/aws$ aws organizations invite-account-to-organization --target Id=111122223333,Type=ACCOUNT

aws: [ERROR]: An error occurred (500) when calling the InviteAccountToOrganization operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

`500` is moto saying the operation is not implemented, not AWS refusing anything, and
`111122223333` is the placeholder AWS's own documentation uses for "some other account". **The
invitation, the e-mail and the acceptance were not run here**; what this section says about them is
AWS's documented behaviour.

Two differences follow an invited account for the rest of its life. **It has no
`OrganizationAccountAccessRole`**, because the organisation did not create it: if the management
account is to reach in, an administrator of the invited account creates that role by hand, with the
same trust policy and the same `AdministratorAccess`. And `describe-account` reports its
`JoinedMethod` as `INVITED` rather than `CREATED`, which is how a list of accounts says which ones
came with their own history.

## Leaving

A member leaves with `leave-organization`, run from inside it, or is removed from the management
account with `remove-account-from-organization`. Either way it becomes a standalone account again,
with a bill of its own, so **AWS will not let it go until it has what a standalone account needs**:
a payment method, contact details and a support plan. An account created inside the organisation
has none of those, which makes leaving harder than joining on purpose. Lesson 4 writes the
guardrail that forbids leaving altogether, since an account that walks out of the tree walks out of
every rule attached to it.
