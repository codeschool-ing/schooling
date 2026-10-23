---
title: A token instead of a key
version: 1
---

**The cure for a key that crosses the seam is to stop sending a key across it. The job proves who it
is with a short-lived token its own provider signs, and AWS trades that token for credentials that
expire within the hour.** Nothing is stored on either side that would still work next week. The
mechanism is called **workload identity federation**, and every large provider offers it in both
directions.

The `cloud` course's lesson 7 met federation for people, who sign in once and receive temporary
credentials. This is the same idea for a program.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" data-fig=\"l04-exchange\" aria-label=\"Workload identity federation, step by step, with four participants: the job in Google Cloud, Google, AWS STS and the S3 bucket. One: the job asks Google for an identity token, and Google returns one it has signed. Two: the job sends the token to AWS STS, calling AssumeRoleWithWebIdentity. Three: STS checks the signature against the keys Google publishes, the expiry, and the trust policy's condition naming one service account; moto checks none of this. Four: STS returns a temporary key starting ASIA, with a session token, that expires in one hour. Five: the job reads the bucket with it. No secret is stored on either side.\"><defs><marker id=\"l04-exchange-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l04-exchange-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the job</text><text x=\"90.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">in Google Cloud</text><path d=\"M90.0 66.0 L90.0 360.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"200.0\" y=\"20.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Google</text><text x=\"270.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">signs tokens</text><path d=\"M270.0 66.0 L270.0 360.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"380.0\" y=\"20.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">AWS STS</text><text x=\"450.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">trades tokens</text><path d=\"M450.0 66.0 L450.0 212.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M450.0 270.0 L450.0 360.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"560.0\" y=\"20.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">S3</text><text x=\"630.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">clinic-exports</text><path d=\"M630.0 66.0 L630.0 360.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M94.0 100.0 L266.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-exchange-af-ah-paper-dim)\"></path><text x=\"180.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1  ask for an identity token</text><path d=\"M266.0 140.0 L94.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-exchange-af-ah-paper-dim)\"></path><text x=\"180.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a token Google signed</text><path d=\"M94.0 190.0 L446.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-exchange-af-ah-paper-dim)\"></path><text x=\"270.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2  AssumeRoleWithWebIdentity</text><path d=\"M446.0 290.0 L94.0 290.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-exchange-af-ah-phosphor)\"></path><text x=\"270.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4  ASIA key + session token, 1 hour</text><path d=\"M94.0 340.0 L626.0 340.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-exchange-af-ah-phosphor)\"></path><text x=\"360.0\" y=\"330.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">5  read the bucket</text><rect x=\"330.0\" y=\"214.0\" width=\"240.0\" height=\"54.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3  check the signature, the expiry</text><text x=\"450.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">and the condition naming one account</text><text x=\"450.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">moto checks none of this</text></svg>", "caption": "A token proves who the job is; the credentials it buys expire on their own. Nothing copied from one side would still work tomorrow."}
```

## moto, without its count this time

Stop moto in the first terminal and start it again **without** `INITIAL_NO_AUTH_ACTION_COUNT`:

```sh
moto_server -p 4567
```

The reason is a defect of the imitation, not of AWS. With its checking on, moto expects every request
to carry a signature, and the call at the centre of this section carries a token instead; moto
answers it with an internal error, HTTP 500. Without the count, moto accepts the call, and the
`test` key in `env.sh` is back in charge of this terminal. Open a new terminal, or run
`source ~/aws/env.sh` again, so that the administrator's key from the previous section is gone.

## The role the job will assume

On AWS's side, the user becomes a **role**, and the role's trust policy says who may assume it. Here
that is not an AWS principal but a token issuer: Google, which signs identity tokens for the
service accounts its workloads run as. Save the trust policy as `trust-google.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Federated": "accounts.google.com" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": { "accounts.google.com:aud": "104857600012345678901" }
      }
    }
  ]
}
```

**The condition is what makes it safe.** `Principal` alone would admit a token from any Google
service account in the world, since Google signs them all with the same keys. The condition pins it
to one: the value is the numeric unique ID of the service account the clinic's job runs as, which
Google assigns when the account is created. This one is made up for the lab. AWS documents three
condition keys it reads from a Google token, `accounts.google.com:aud`, `accounts.google.com:oaud`
and `accounts.google.com:sub`, and a trust policy for a workload should pin at least one of them to
that single identity.

The restart emptied the account, so make the bucket and its export again, then create the role and
give it the same narrow permission the user had:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-exports --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-exports
ana@laptop:~/aws$ aws s3api put-object --bucket clinic-exports --key 2026-10-23.csv --query ETag --output text
"d41d8cd98f00b204e9800998ecf8427e"
```

```
ana@laptop:~/aws$ aws iam create-role --role-name reports-sync --assume-role-policy-document file://trust-google.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/reports-sync
ana@laptop:~/aws$ aws iam put-role-policy --role-name reports-sync --policy-name read-exports --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:GetObject","s3:ListBucket"],"Resource":["arn:aws:s3:::clinic-exports","arn:aws:s3:::clinic-exports/*"]}]}'
```

## The exchange

In Google Cloud, the job asks its own metadata server for an identity token and sends it to AWS's
security token service. That half was **not run**: there is no Google Cloud in this lab. What can be
run is AWS's half, with `--no-sign-request`, because this call carries a token instead of a key and
is not signed:

```
ana@laptop:~/aws$ s=$(aws sts assume-role-with-web-identity --no-sign-request --role-arn arn:aws:iam::123456789012:role/reports-sync --role-session-name nightly-export --web-identity-token not-a-real-token)
ana@laptop:~/aws$ echo "$s" | jq '.Credentials | {AccessKeyId, Expiration}'
{
  "AccessKeyId": "ASIARZPUZDIKKGLSAFXR",
  "Expiration": "2026-10-23T04:47:31.815017+00:00"
}
```

**moto handed out a session for a token that is plainly not one, and AWS would refuse it.** AWS
checks the token's signature against the keys Google publishes, its expiry, and then the trust
policy's condition; moto checks none of that, and ignores conditions altogether. What the run does
show is the shape of the answer, which is AWS's: an access key starting `ASIA`, the prefix of a
temporary key, and an `Expiration` one hour after the session began. An `AKIA` key, like the user's,
has no expiration at all.

Type the session's version of `with_key`, which carries the session token as well, and make the
nightly read as the role:

```sh
with_session() {
  local c=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$c" | jq -r .Credentials.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$c" | jq -r .Credentials.SecretAccessKey) \
  AWS_SESSION_TOKEN=$(echo "$c" | jq -r .Credentials.SessionToken) "$@"
}
```

```
ana@laptop:~/aws$ with_session "$s" aws sts get-caller-identity --query Arn --output text
arn:aws:sts::123456789012:assumed-role/reports-sync/nightly-export
ana@laptop:~/aws$ with_session "$s" aws s3api list-objects-v2 --bucket clinic-exports --query "Contents[].Key" --output text
2026-10-23.csv
```

The caller is now `assumed-role/reports-sync/nightly-export`. **The session name is chosen by the
job**, and a good one names the run, so a record of what it did can be traced to the job that did it.

## Retiring the key

With the job moved to the role, the user's key has no reason to exist, and the previous section
already tried the two levers. In a real account the order is: watch the key's last use stop
advancing after the job's first night on the role; **deactivate** the key; wait long enough for
anything you did not know about to complain; then **delete** the key, its policy and the user. A key
that is still being used after "we moved the job" means something else holds a copy, and its last
use says which service and which region to start looking in.

## The other directions

The same pattern runs every way, and each provider documents its half. **None of this was run here.**

| the job runs in | it acts on | what it uses |
|---|---|---|
| Google Cloud | AWS | a Google identity token, a role trusting `accounts.google.com`, as above |
| Azure | AWS | a token from Microsoft Entra ID for the workload's managed identity, and an IAM OIDC provider for the tenant's issuer |
| AWS | Google Cloud | Google Cloud's **Workload Identity Federation**, with a pool whose provider is the AWS account |
| AWS or Google Cloud | Azure | Microsoft Entra **workload identity federation**, a federated credential on an app registration or a managed identity |

In every row the property is the same: **no secret is copied from one provider into the other**,
the credential expires on its own, and each side's trust rule names exactly one identity of the
other's.
