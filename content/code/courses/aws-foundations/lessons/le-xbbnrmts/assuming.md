---
title: Assuming a role, and the two policies that must agree
version: 1
---

**Assuming a role is a request like any other, and it is judged from both ends.** The caller's
own policies have to allow `sts:AssumeRole` on that role, and the role's trust policy has to name
the caller. If both agree, STS hands back a session: temporary credentials that act with the
**role's** permissions, not the caller's. The wrong picture is that a role adds its permissions to
yours. **A session has the role's permissions and nothing else**; whatever the caller could do
before stays outside the session.

Lesson 6 made a session with moto's checking off, and moto handed it to a caller the trust policy
did not name. This lesson turns the checking on and shows the refusal.

## The start, as in lesson 7

Restart moto in the first terminal with the count, so this lesson starts from an empty AWS that
judges every request:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567
```

In the second terminal, the three requests that make `admin`, the `export` onto admin's key, and
lesson 8's two functions, `with_key` and `with_session`, typed again:

```
ana@laptop:~/aws$ aws iam create-user --user-name admin --query User.Arn --output text
arn:aws:iam::123456789012:user/admin
ana@laptop:~/aws$ aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ key=$(aws iam create-access-key --user-name admin)
ana@laptop:~/aws$ aws iam list-users

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the ListUsers operation: The security token included in the request is invalid.
ana@laptop:~/aws$ export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn --output text
arn:aws:iam::123456789012:user/admin
```

```sh
with_key() {
  local k=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$k" | jq -r .AccessKey.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$k" | jq -r .AccessKey.SecretAccessKey) "$@"
}
with_session() {
  local c=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$c" | jq -r .Credentials.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$c" | jq -r .Credentials.SecretAccessKey) \
  AWS_SESSION_TOKEN=$(echo "$c" | jq -r .Credentials.SessionToken) "$@"
}
```

## A role, its trust and its permissions

`deployer` again, trusting bia as it did at first in lesson 6. Save the trust policy as
`~/aws/deployer-trust.json`:

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

The role gets AWS's `AmazonS3FullAccess` as its permissions policy, and the shop's two people get
what they need from their own side. **bia's own policy allows her to assume `deployer` and nothing
else; caio holds `AdministratorAccess`**, which allows every action, `sts:AssumeRole` included:

```
ana@laptop:~/aws$ aws iam create-role --role-name deployer --assume-role-policy-document file://deployer-trust.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/deployer
ana@laptop:~/aws$ aws iam attach-role-policy --role-name deployer --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/shop-assets
ana@laptop:~/aws$ aws iam create-user --user-name bia --query User.Arn --output text
arn:aws:iam::123456789012:user/bia
ana@laptop:~/aws$ aws iam put-user-policy --user-name bia --policy-name assume-deployer --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"sts:AssumeRole","Resource":"arn:aws:iam::123456789012:role/deployer"}]}'
ana@laptop:~/aws$ bia=$(aws iam create-access-key --user-name bia)
ana@laptop:~/aws$ aws iam create-user --user-name caio --query User.Arn --output text
arn:aws:iam::123456789012:user/caio
ana@laptop:~/aws$ aws iam attach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ caio=$(aws iam create-access-key --user-name caio)
```

**caio is refused although his own policy allows everything.** The trust policy is the role's half
of the agreement and it names bia alone, so an administrator of the same account cannot wear the
role. moto judges this exactly as AWS does. bia, named on both sides, gets a session:

```
ana@laptop:~/aws$ with_key "$caio" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name caio-try

aws: [ERROR]: An error occurred (AccessDenied) when calling the AssumeRole operation: User: arn:aws:iam::123456789012:user/caio is not authorized to perform: sts:AssumeRole
ana@laptop:~/aws$ s=$(with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy)
ana@laptop:~/aws$ with_session "$s" aws sts get-caller-identity --query Arn --output text
arn:aws:sts::123456789012:assumed-role/deployer/bia-deploy
ana@laptop:~/aws$ with_session "$s" aws s3 ls
2026-10-16 13:53:17 shop-assets
ana@laptop:~/aws$ with_session "$s" aws iam list-users

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListUsers operation: User: arn:aws:sts::123456789012:assumed-role/deployer/bia-deploy is not authorized to perform: iam:ListUsers
```

The session is `assumed-role/deployer/bia-deploy`, and it carries the role's permissions: S3, which
`AmazonS3FullAccess` gives, and not IAM, which nothing in the role gives. **bia's own policy plays
no part inside the session**: it allowed her to assume the role, and that was all it did.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l09-two-sides\" aria-label=\"An AssumeRole request judged from both ends. On the left, the user bia, whose own policy allows her to assume deployer, and the user caio, whose AdministratorAccess allows everything. In the middle, STS. On the right, the role deployer, with a trust policy naming bia only and the permissions policy AmazonS3FullAccess. bia's request passes both checks and returns the session assumed-role/deployer/bia-deploy, which can use S3 and not IAM. caio's request is refused, because the trust policy does not name him.\"><defs><marker id=\"l09-two-sides-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l09-two-sides-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l09-two-sides-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"200.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">user/bia</text><text x=\"120.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">her policy: may assume deployer</text><rect x=\"20.0\" y=\"170.0\" width=\"200.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">user/caio</text><text x=\"120.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">his policy: allows everything</text><rect x=\"290.0\" y=\"95.0\" width=\"140.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">STS</text><text x=\"360.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">AssumeRole</text><rect x=\"500.0\" y=\"30.0\" width=\"200.0\" height=\"124.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">role/deployer</text><rect x=\"515.0\" y=\"62.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">trust: names bia only</text><rect x=\"515.0\" y=\"106.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">AmazonS3FullAccess</text><rect x=\"500.0\" y=\"196.0\" width=\"200.0\" height=\"74.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">assumed-role/deployer/</text><text x=\"600.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">bia-deploy</text><text x=\"600.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">S3 yes, IAM no</text><path d=\"M222.0 80.0 L288.0 118.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-two-sides-af-ah-phosphor)\"></path><path d=\"M222.0 202.0 L288.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-two-sides-af-ah-amber)\"></path><text x=\"300.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">caio: refused,</text><text x=\"300.0\" y=\"230.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">not in the trust</text><path d=\"M432.0 118.0 L498.0 92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l09-two-sides-af-ah-paper-dim)\"></path><path d=\"M432.0 165.0 L498.0 222.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-two-sides-af-ah-phosphor)\"></path></svg>", "caption": "The caller's policy lets them ask; the role's trust policy decides who is answered."}
```

## The account as a principal, and where moto differs

A trust policy often names a whole account rather than a person: `"AWS":
"arn:aws:iam::123456789012:root"`. **In AWS that does not mean the root user.** It means any
principal of that account whose own policies allow `sts:AssumeRole` on the role. The account's
administrators decide, through their identity policies, who may wear it. It is the usual way to
trust another account, as the last section of this lesson shows.

**moto does not read it that way.** It compares the caller's ARN with the principal as two strings.
`user/admin` does not match `root`, so admin is refused a role whose trust policy names its own
account:

```
ana@laptop:~/aws$ aws iam create-role --role-name readonly --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::123456789012:root"},"Action":"sts:AssumeRole"}]}' --query Role.Arn --output text
arn:aws:iam::123456789012:role/readonly
ana@laptop:~/aws$ aws sts assume-role --role-arn arn:aws:iam::123456789012:role/readonly --role-session-name admin-try

aws: [ERROR]: An error occurred (AccessDenied) when calling the AssumeRole operation: User: arn:aws:iam::123456789012:user/admin is not authorized to perform: sts:AssumeRole
```

AWS would have given admin that session, since `AdministratorAccess` allows the call. The same
string comparison means **a trust policy naming a role does not match that role's sessions** in moto,
which the next section meets when it chains two roles. In the lab, name the exact user or session
ARN in a trust policy when you want moto to say yes.
