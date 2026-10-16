---
title: Across accounts, and with a third party
version: 1
---

**A role is how one account lets in a principal of another, and it is the only way that leaves no
long-term credential behind.** The role lives in the account being entered, and its trust policy names
the other account, or a principal in it. The other account's own policies decide which of its
principals may use the door. Both sides grant, as lesson 8's cross-account rule said, and here the
trust policy is the resource's half.

## From the management account into shop-prod

Lesson 3 built the shop's organisation. Here one member account is enough:

```
ana@laptop:~/aws$ aws organizations create-organization --feature-set ALL --query Organization.MasterAccountId --output text
123456789012
ana@laptop:~/aws$ aws organizations create-account --account-name shop-prod --email aws+shop-prod@example.com --query "CreateAccountStatus.[AccountName,State,AccountId]" --output text
shop-prod	SUCCEEDED	855386161245
```

Every account `create-account` makes comes with a role called `OrganizationAccountAccessRole`, whose
trust policy names the management account, `arn:aws:iam::123456789012:root`. **That principal is
the account, not its root user**: inside the management account, an identity policy decides who
may use the role. admin's `AdministratorAccess` allows it, and bia's policy names only `deployer`.
The new account's number goes into a variable, `prod`, because yours will differ from the one here:

```
ana@laptop:~/aws$ prod=$(aws organizations list-accounts --query "Accounts[?Name==\`shop-prod\`].Id" --output text)
ana@laptop:~/aws$ s=$(aws sts assume-role --role-arn arn:aws:iam::$prod:role/OrganizationAccountAccessRole --role-session-name ana-admin)
ana@laptop:~/aws$ with_session "$s" aws sts get-caller-identity
{
    "UserId": "AROA4OKH5ABOZYSBAWRQ4:ana-admin",
    "Account": "855386161245",
    "Arn": "arn:aws:sts::855386161245:assumed-role/OrganizationAccountAccessRole/ana-admin"
}
ana@laptop:~/aws$ with_session "$s" aws ec2 describe-vpcs

aws: [ERROR]: An error occurred (AccessDenied) when calling the DescribeVpcs operation: User: arn:aws:sts::855386161245:assumed-role/OrganizationAccountAccessRole/ana-admin is not authorized to perform: ec2:DescribeVpcs
ana@laptop:~/aws$ with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::$prod:role/OrganizationAccountAccessRole --role-session-name bia-try

aws: [ERROR]: An error occurred (AccessDenied) when calling the AssumeRole operation: User: arn:aws:iam::123456789012:user/bia is not authorized to perform: sts:AssumeRole
```

**The session's ARN carries the other account's number**, and everything it does happens there. In
AWS that session would be an administrator of `shop-prod`, because AWS attaches
`AdministratorAccess` to the role it creates. moto creates the role with no policy at all, so the
session is refused even a list of VPCs. AWS would have answered it. bia was refused on her own side,
before the trust policy was read, and moto judges that half as AWS does.

**The other half, moto does not judge across accounts.** Asked for a role in an account that does
not exist, it handed out a session all the same:

```
ana@laptop:~/aws$ aws sts assume-role --role-arn arn:aws:iam::111122223333:role/OrganizationAccountAccessRole --role-session-name nowhere --query AssumedRoleUser.Arn --output text
arn:aws:sts::111122223333:assumed-role/OrganizationAccountAccessRole/nowhere
```

So a cross-account session in the lab proves that the caller's side allowed the call, and nothing
about the trust policy on the other side. AWS would have answered that request with an error; it was
not run against AWS.

**Trusting a whole account is wide.** Anyone whose identity policies allow `sts:AssumeRole` on the
role gets in, so the role is only as narrow as the widest policy in the management account. The
tighter form names one role there, `arn:aws:iam::123456789012:role/platform-admin`, so that only
sessions of that role can come through. That form was not run here.

## A third party, and the confused deputy

A monitoring company reads the shop's metrics from its own AWS account, `444455556666`, through a
role in the shop's account. **The danger is not the company; it is the company's other customers.**
The company assumes roles in hundreds of accounts, on its customers' instructions. If another
customer learns the ARN of the shop's role and types it into the company's console as their own,
the company assumes the shop's role on that customer's behalf. The company is the **confused
deputy**: it has the permission, and somebody else chose how to use it.

**The external id is the fix**: a value the company generates for each customer and sends with
every `AssumeRole` it makes for that customer. The shop's trust policy accepts the company only
when the value is the shop's own. Another customer cannot make the company send the shop's id,
because the company sends the id of whoever is configuring it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l09-confused-deputy\" aria-label=\"The confused deputy, and the external id that stops it. On the left, another customer of the monitoring company. In the middle, the monitoring company's account 444455556666. On the right, the shop's account 123456789012 with the role monitoring, which accepts the company only with the external id shop-7f3k92. Step 1: the other customer gives the company the shop's role ARN as if it were theirs. Step 2: the company assumes that role sending the other customer's own external id, and is refused. Step 3: when the shop is the one configured, the company sends shop-7f3k92 and is allowed.\"><defs><marker id=\"l09-confused-deputy-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l09-confused-deputy-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"150.0\" height=\"110.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">another customer</text><text x=\"95.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">types in the</text><text x=\"95.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop's role ARN</text><rect x=\"290.0\" y=\"40.0\" width=\"130.0\" height=\"230.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">monitoring</text><text x=\"355.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">company</text><text x=\"355.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">444455556666</text><rect x=\"560.0\" y=\"40.0\" width=\"140.0\" height=\"230.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the shop</text><text x=\"630.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">123456789012</text><rect x=\"572.0\" y=\"100.0\" width=\"116.0\" height=\"64.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">role/monitoring</text><text x=\"630.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">needs the id</text><text x=\"630.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">shop-7f3k92</text><path d=\"M172.0 100.0 L288.0 100.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-confused-deputy-af-ah-amber)\"></path><text x=\"230.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">1 · the shop's ARN</text><path d=\"M422.0 125.0 L570.0 125.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-confused-deputy-af-ah-amber)\"></path><text x=\"496.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">2 · their own id</text><text x=\"496.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">refused</text><path d=\"M422.0 220.0 L560.0 187.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M560.0 187.0 L600.0 166.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-confused-deputy-af-ah-phosphor)\"></path><text x=\"491.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">3 · shop-7f3k92</text><text x=\"491.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">when the shop set it up</text></svg>", "caption": "The company has the permission. The external id makes sure the shop is the one choosing how it is used."}
```

In a real arrangement the principal is the company's account, `arn:aws:iam::444455556666:root`,
and the lab has no such account with anybody in it to sign. So the lab plays the company with a
user called `vendor` in the shop's own account, and the trust policy names that user. Save it as `~/aws/monitoring-trust.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::123456789012:user/vendor"},
      "Action": "sts:AssumeRole",
      "Condition": {"StringEquals": {"sts:ExternalId": "shop-7f3k92"}}
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam create-role --role-name monitoring --assume-role-policy-document file://monitoring-trust.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/monitoring
ana@laptop:~/aws$ aws iam create-user --user-name vendor --query User.Arn --output text
arn:aws:iam::123456789012:user/vendor
ana@laptop:~/aws$ aws iam put-user-policy --user-name vendor --policy-name assume-monitoring --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"sts:AssumeRole","Resource":"arn:aws:iam::123456789012:role/monitoring"}]}'
ana@laptop:~/aws$ vendor=$(aws iam create-access-key --user-name vendor)
ana@laptop:~/aws$ with_key "$vendor" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/monitoring --role-session-name for-another-customer --external-id other-9q2m11 --query AssumedRoleUser.Arn --output text

aws: [ERROR]: An error occurred (AccessDenied) when calling the AssumeRole operation: User: arn:aws:iam::123456789012:user/vendor is not authorized to perform: sts:AssumeRole
ana@laptop:~/aws$ with_key "$vendor" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/monitoring --role-session-name for-the-shop --external-id shop-7f3k92 --query AssumedRoleUser.Arn --output text
arn:aws:sts::123456789012:assumed-role/monitoring/for-the-shop
ana@laptop:~/aws$ with_key "$vendor" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/monitoring --role-session-name no-id --query AssumedRoleUser.Arn --output text
arn:aws:sts::123456789012:assumed-role/monitoring/no-id
```

**This is the one condition moto compares, and it compares it only halfway.** A wrong external id
is refused and the right one accepted, as AWS does. A request with **no** external id is accepted,
and AWS would refuse it, because a `StringEquals` on a key the request does not carry does not
match. That last refusal was not run here.

## A profile that assumes the role for you

Typing `assume-role` and carrying the answer around is what a profile does for you. A profile in
`~/.aws/config` names the role. The command line assumes it before each command, keeps the
session in `~/.aws/cli/cache` until it expires, and assumes it again after. Lesson 25 is about
profiles, and this is the one line of it that belongs to roles. If lessons 2 to 4 left a
`~/.aws/config` behind, this replaces it:

```sh
mkdir -p ~/.aws
cat > ~/.aws/config <<EOF
[profile shop-prod]
role_arn = arn:aws:iam::$prod:role/OrganizationAccountAccessRole
credential_source = Environment
role_session_name = ana-admin
EOF
```

`credential_source = Environment` makes the command line sign the `AssumeRole` call with the keys
in the environment, admin's here, so no key is written to any file. The usual form,
`source_profile`, names another profile whose credentials sign the call, and lesson 25 is where
profiles are set up properly.

```
ana@laptop:~/aws$ aws sts get-caller-identity --profile shop-prod
{
    "UserId": "AROA4OKH5ABOZYSBAWRQ4:ana-admin",
    "Account": "855386161245",
    "Arn": "arn:aws:sts::855386161245:assumed-role/OrganizationAccountAccessRole/ana-admin"
}
ana@laptop:~/aws$ aws configure list --profile shop-prod
NAME       : VALUE                    : TYPE             : LOCATION
profile    : shop-prod                : manual           : --profile
access_key : ****************BKSM     : assume-role      : 
secret_key : ****************jHAO     : assume-role      : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn --output text
arn:aws:iam::123456789012:user/admin
```

**`--profile shop-prod` is the whole cross-account step**, done for every command. Remove the file
when you finish, `rm ~/.aws/config`, so the next lessons start from the lab as lesson 1 left it.
