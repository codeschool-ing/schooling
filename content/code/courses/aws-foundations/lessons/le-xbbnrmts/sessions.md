---
title: Temporary credentials: how long, how chained, how named
version: 1
---

**A session's credentials carry their own end.** `Expiration` is in the answer to `assume-role`,
and after it AWS refuses the key, the secret and the token together, with nothing for anybody to
revoke. How long that is depends on two numbers: the `--duration-seconds` the caller asks for, and
the role's `MaxSessionDuration`, which caps it.

## How long a session lasts

**The default is one hour, the shortest allowed is fifteen minutes, and a role may allow up to
twelve hours.** The command line itself refuses anything under 900 seconds before sending the
request. Above that, AWS refuses a request for more than the role's maximum, and the maximum is
raised on the role, not by the caller:

```
ana@laptop:~/aws$ with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy --duration-seconds 600

aws: [ERROR]: An error occurred (ParamValidation): Parameter validation failed:
Invalid value for parameter DurationSeconds, value: 600, valid min value: 900
ana@laptop:~/aws$ with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy --duration-seconds 900 --query Credentials.Expiration --output text
2026-10-16T17:08:26.777090+00:00
ana@laptop:~/aws$ with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy --duration-seconds 7200 --query Credentials.Expiration --output text
2026-10-16T18:53:27.279140+00:00
ana@laptop:~/aws$ aws iam update-role --role-name deployer --max-session-duration 7200
ana@laptop:~/aws$ aws iam get-role --role-name deployer --query Role.MaxSessionDuration
7200
```

**moto does not enforce the maximum.** Two hours were granted on a role whose maximum was still
one, and AWS would have refused that request. That refusal was not run here. Raising the maximum to
7200 with `update-role` is what makes the same request valid in AWS. The expiry times above are in
UTC, three hours ahead of São Paulo, and they are moto's answer for this run. Yours will be the time
of yours.

Which length to choose is a trade the role's owner makes once. **A short session limits what a
leaked one is worth; a long one spares a person signing in again in the middle of the afternoon.**
A deployment pipeline needs minutes; a person at the console, a working day at most.

## Role chaining

A session can itself assume another role, which AWS calls **role chaining**: bia becomes
`deployer`, and `deployer`'s session becomes `auditor`. AWS's documentation sets one rule on it
that surprises people: **a chained session lasts one hour at most**, whatever the second role's
maximum, and asking for more is refused. Chaining is also how a trail of identities gets long
enough that nobody can say who started it, which the next part of this section is about.

In moto the chain breaks earlier, for the reason the previous section gave. A trust policy that
names `role/deployer` is compared, as a string, with the session's ARN, `assumed-role/deployer/...`,
and they differ:

```
ana@laptop:~/aws$ aws iam create-role --role-name auditor --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::123456789012:role/deployer"},"Action":"sts:AssumeRole"}]}' --query Role.Arn --output text
arn:aws:iam::123456789012:role/auditor
ana@laptop:~/aws$ aws iam put-role-policy --role-name deployer --policy-name chain-to-auditor --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"sts:AssumeRole","Resource":"arn:aws:iam::123456789012:role/auditor*"}]}'
ana@laptop:~/aws$ s=$(with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy)
ana@laptop:~/aws$ with_session "$s" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/auditor --role-session-name chained

aws: [ERROR]: An error occurred (AccessDenied) when calling the AssumeRole operation: User: arn:aws:sts::123456789012:assumed-role/deployer/bia-deploy is not authorized to perform: sts:AssumeRole
ana@laptop:~/aws$ aws iam create-role --role-name auditor-session --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:sts::123456789012:assumed-role/deployer/bia-deploy"},"Action":"sts:AssumeRole"}]}' --query Role.Arn --output text
arn:aws:iam::123456789012:role/auditor-session
ana@laptop:~/aws$ with_session "$s" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/auditor-session --role-session-name chained --duration-seconds 7200 --query "[AssumedRoleUser.Arn,Credentials.Expiration]" --output text
arn:aws:sts::123456789012:assumed-role/auditor-session/chained	2026-10-16T18:53:31.618451+00:00
```

AWS accepts a role's ARN in a trust policy as meaning its sessions, so the first attempt would
have succeeded there, and lasted an hour. **moto accepted only the trust policy that names the
exact session**, which nobody writes in a real account, because the session name changes with
every caller. The one-hour limit on chaining was not measured here. moto granted the chained
session the two hours it was asked for.

## Who did it: session names and source identity

**Everything done through a role is logged under the session, not under the person.** CloudTrail,
AWS's audit log of API calls, records the caller of each call as the session's ARN,
`arn:aws:sts::123456789012:assumed-role/deployer/bia-deploy`. It records the `AssumeRole` call that
made the session as a separate event naming bia. Joining the two is possible and tedious. The
session name is the cheap part of the answer: **a name that says who, such as `bia-deploy`, makes
every later line readable**, where `session1` makes each one a search.

The session name is the caller's choice, though, so it proves nothing. **Source identity** is the
stronger form. `--source-identity bia` sets a value that CloudTrail records for every call of the
session, which the caller cannot change afterwards, and which **carries over to every role chained
from it**. A role can demand it: its trust policy allows `sts:SetSourceIdentity` beside
`sts:AssumeRole`, with a condition on `sts:SourceIdentity`. moto accepts the parameter and returns
no source identity:

```
ana@laptop:~/aws$ with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy --source-identity bia --query "{User:AssumedRoleUser.Arn,SourceIdentity:SourceIdentity}"
{
    "User": "arn:aws:sts::123456789012:assumed-role/deployer/bia-deploy",
    "SourceIdentity": null
}
```

AWS returns `SourceIdentity` in the answer and in the session's log lines. **moto keeps no
CloudTrail record of the calls it answers**, and answers `cloudtrail lookup-events` with HTTP 500,
so none of the logging in this part was run. Lesson 26 opens one of moto's own requests instead, and
lesson 20 of `aws-operations` is about CloudTrail itself.
