---
title: Groups gather users; a role is worn
version: 1
---

**A group is a list of users that policies can be attached to, and nothing more.** A role is the
opposite kind of thing: an identity with permissions and **no credentials of its own**, which a
principal puts on for a while and takes off again. The two are often confused because both carry
permissions for somebody else, so this section builds both for the shop and then reads the names
AWS gave them.

## Three groups

The shop's people fall into three teams, and the permissions follow the team, not the person.
Lesson 7 attaches the policies; here the groups only gather the users:

```
ana@laptop:~/aws$ for g in developers data finance; do aws iam create-group --group-name $g --query Group.Arn --output text; done
arn:aws:iam::123456789012:group/developers
arn:aws:iam::123456789012:group/data
arn:aws:iam::123456789012:group/finance
ana@laptop:~/aws$ aws iam add-user-to-group --group-name developers --user-name bia
ana@laptop:~/aws$ aws iam add-user-to-group --group-name data --user-name caio
ana@laptop:~/aws$ aws iam add-user-to-group --group-name finance --user-name dani
ana@laptop:~/aws$ aws iam get-group --group-name developers --query "Users[].UserName"
[
    "bia"
]
ana@laptop:~/aws$ aws iam list-groups-for-user --user-name caio --query "Groups[].GroupName"
[
    "data"
]
```

`list-groups-for-user` answers the question from the other side, and it is the one to run when
somebody asks why a user can do something: the answer is often a group nobody remembered.

**The wrong picture is a group as a shared account for the team.** A group has no password, no
access key and no way to sign anything, so it never makes a request. It follows that a group
**cannot be named as the principal** of a policy, cannot assume a role, and cannot contain another
group. A user may be in up to ten groups, which is the `GroupsPerUserQuota` the previous section
printed and AWS's own limit.

moto is more lenient than AWS here, and it is worth seeing once:

```
ana@laptop:~/aws$ aws iam create-role --role-name grouptest --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::123456789012:group/developers"},"Action":"sts:AssumeRole"}]}' --query Role.Arn
"arn:aws:iam::123456789012:role/grouptest"
ana@laptop:~/aws$ aws iam delete-role --role-name grouptest
```

**moto stored a trust policy naming a group. AWS refuses that document** as malformed, because a
group is not a principal and the policy names one in the principal's place. That refusal was not
run here, since it needs an account; it is AWS's documented behaviour, and the reason the
`developers` team reaches a role through each member's own permissions instead.

## A role, and the policy that says who may wear it

The shop's continuous delivery runs as a role called `deployer`. **A role carries two policies of
different kinds**: a **trust policy**, which names who may assume it, and permission policies,
which say what the session may then do. Lesson 7 writes the second kind. The trust policy comes
first, because a role cannot be created without one. For now it trusts bia; the next section hands
the role to GitHub instead. Save it as `~/aws/deployer-trust.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::123456789012:user/bia"},
      "Action": "sts:AssumeRole"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam create-role --role-name deployer --assume-role-policy-document file://deployer-trust.json
{
    "Role": {
        "Path": "/",
        "RoleName": "deployer",
        "RoleId": "AROARZPUZDIKPPMZN5TQR",
        "Arn": "arn:aws:iam::123456789012:role/deployer",
        "CreateDate": "2026-10-16T16:06:31.226904+00:00",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": "arn:aws:iam::123456789012:user/bia"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        },
        "MaxSessionDuration": 3600,
        "RoleLastUsed": {}
    }
}
```

The `RoleId` begins with `AROA`, AWS's prefix for a role, and moto gets this one right.
`MaxSessionDuration` is 3600 seconds, the default length of a session; lesson 9 changes it.

**A role has no key to create.** `create-access-key` takes a user's name, and a role is not one:

```
ana@laptop:~/aws$ aws iam create-access-key --user-name deployer

aws: [ERROR]: An error occurred (NoSuchEntity) when calling the CreateAccessKey operation: The user with name deployer cannot be found.
```

What a role gives instead is a session. `sts assume-role` asks for one and receives three
values that work together, and an expiry:

```
ana@laptop:~/aws$ aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy --query "{User:AssumedRoleUser,Key:Credentials.AccessKeyId,Expires:Credentials.Expiration}"
{
    "User": {
        "AssumedRoleId": "AROARZPUZDIKPPMZN5TQR:bia-deploy",
        "Arn": "arn:aws:sts::123456789012:assumed-role/deployer/bia-deploy"
    },
    "Key": "ASIARZPUZDIKNJGDRMLO",
    "Expires": "2026-10-16T17:06:32.463668+00:00"
}
```

**The key id begins with `ASIA`, the prefix of a temporary key**, against `AKIA` for a user's
permanent one. Beside it, which the `--query` left out, come a secret and a session token, and
the three are refused together an hour later. Nobody has to rotate or delete them, and a leaked
one is worth an hour at most. Note also what moto did not ask: whether the caller was bia. With
checking off it hands a session to anybody, and lesson 9 repeats this with checking on to show the
trust policy refusing a principal it does not name.

## Reading the names

Every principal so far has two names: an **ARN**, which is the address policies use, and a
**unique id**, which AWS assigns and never reuses.

| what | ARN in the shop | id begins with |
|---|---|---|
| root user | `arn:aws:iam::123456789012:root` | the account number |
| IAM user | `arn:aws:iam::123456789012:user/bia` | `AIDA` (moto: random lowercase) |
| group | `arn:aws:iam::123456789012:group/developers` | `AGPA` (moto: random lowercase) |
| role | `arn:aws:iam::123456789012:role/deployer` | `AROA` |
| role session | `arn:aws:sts::123456789012:assumed-role/deployer/bia-deploy` | the role's id, a colon, the session name |
| access key | not an ARN | `AKIA` long-term, `ASIA` temporary |

**The session's ARN belongs to `sts`, not `iam`**, and it ends in the session name the caller
chose. That is the name a log shows when something was done through a role, which is why
`bia-deploy` beats `session1`; lesson 9 shows how AWS's audit log, CloudTrail, uses it.

**The id is what makes a recreated user a different user.** If bia's user is deleted and created
again, the ARN is the same and the id is new. AWS's documentation describes what that does to a
trust policy that names her: the stored policy turns the ARN into the old id when the user is
deleted, so the new bia is not trusted until somebody writes the policy again. That was not run
here, and it is a deliberate protection: a name reused by somebody else does not inherit an old
permission.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l06-principals\" aria-label=\"The principals of the shop and what each signs its requests with. The root user signs with the e-mail address, password and MFA, and holds every permission. The IAM user bia sits inside the group developers; she signs with a password or an AKIA access key, which lasts until somebody deletes it. The group itself signs nothing. bia, and GitHub Actions with an OIDC token, can assume the role deployer, which has no credentials of its own; the session it gives signs with an ASIA key and a token that expire after an hour.\"><defs><marker id=\"l06-principals-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l06-principals-af-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l06-principals-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l06-principals-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"580.0\" y=\"36.0\" width=\"120.0\" height=\"278.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">AWS API</text><rect x=\"45.0\" y=\"36.0\" width=\"180.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">root user</text><text x=\"135.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e-mail, password, MFA</text><path d=\"M227.0 60.0 L577.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l06-principals-af-ah-paper-dim)\"></path><text x=\"408.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every permission, always</text><rect x=\"30.0\" y=\"104.0\" width=\"210.0\" height=\"122.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"135.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">group/developers</text><rect x=\"45.0\" y=\"130.0\" width=\"180.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">IAM user bia</text><text x=\"135.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">password, AKIA key</text><text x=\"135.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the group signs nothing</text><path d=\"M227.0 150.0 L240.0 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M240.0 150.0 L577.0 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l06-principals-af-ah-amber)\"></path><text x=\"408.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">AKIA key: until somebody deletes it</text><path d=\"M227.0 178.0 L240.0 187.9\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M240.0 187.9 L298.0 232.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l06-principals-af-ah-paper)\"></path><text x=\"300.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sts:AssumeRole</text><rect x=\"45.0\" y=\"262.0\" width=\"180.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">GitHub Actions</text><text x=\"135.0\" y=\"298.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">OIDC token</text><path d=\"M227.0 286.0 L298.0 262.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l06-principals-af-ah-paper)\"></path><text x=\"300.0\" y=\"300.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">AssumeRoleWithWebIdentity</text><rect x=\"300.0\" y=\"214.0\" width=\"160.0\" height=\"64.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"380.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">role deployer</text><text x=\"380.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no credentials of its own</text><path d=\"M462.0 246.0 L577.0 246.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l06-principals-af-ah-phosphor)\"></path><text x=\"520.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">ASIA key + token</text><text x=\"520.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">expires in an hour</text></svg>", "caption": "Four ways a request gets signed, and a group that signs none. Only the role session expires on its own."}
```
