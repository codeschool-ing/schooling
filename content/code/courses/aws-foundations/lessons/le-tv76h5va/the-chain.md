---
title: The credential chain, and where a program finds its keys
version: 1
---

**A program that calls AWS never has to carry a key; it has to find credentials, and the SDK knows
where to look.** Every AWS SDK, and the command line built on one, walks an ordered list of places
called the **credential provider chain** and stops at the first place that answers. The top of the
list is a key somebody typed. The bottom is a credential the platform hands to a machine for a few
hours at a time, and this lesson is about the bottom.

The common wrong picture is that `aws` reads `AWS_ACCESS_KEY_ID` and that is the whole story. It is
the first place the command line looks, which is why `env.sh` has worked since lesson 1, and it is
one place out of a dozen.

Restart moto in the first terminal (Ctrl+C, then `moto_server -p 4567`) so this lesson starts from an
empty AWS. **Nothing in this lesson turns on moto's permission checking.** The credentials moto hands out at
the bottom of the chain are placeholders its checking would refuse, and the last section measures a
call that breaks the checking outright.

```
ana@laptop:~/aws$ aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : <not set>                : None             : None
access_key : ****************test     : env              : 
secret_key : ****************test     : env              : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
```

`aws configure list` says which credentials the command line would use and where it found them. The
`TYPE` column is the provider: `env`, the environment `env.sh` filled. The last four characters of
the key are shown and the rest is hidden, which makes it safe to paste into a ticket.

## The order, as the command line reports it

`--debug` makes the command line narrate what it does, including every provider it tries. Take the
keys out of the environment and point the metadata provider at moto, which serves an imitation of
EC2's metadata service on its own port:

```
ana@laptop:~/aws$ unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
ana@laptop:~/aws$ export AWS_EC2_METADATA_SERVICE_ENDPOINT=http://localhost:4567/
ana@laptop:~/aws$ aws sts get-caller-identity --debug 2>&1 | grep -oE "Looking for credentials via: .*|Found credentials .*|(PUT|GET) /latest[^ ]*"
Looking for credentials via: env
Looking for credentials via: assume-role
Looking for credentials via: assume-role-with-web-identity
Looking for credentials via: sso
Looking for credentials via: shared-credentials-file
Looking for credentials via: login
Looking for credentials via: custom-process
Looking for credentials via: config-file
Looking for credentials via: ec2-credentials-file
Looking for credentials via: boto-config
Looking for credentials via: container-role
Looking for credentials via: iam-role
PUT /latest/api/token
GET /latest/meta-data/iam/security-credentials/
GET /latest/meta-data/iam/security-credentials/default-role
Found credentials from IAM Role: default-role
```

The `grep` keeps three kinds of line from a few hundred: the providers tried, the one that answered,
and the requests sent to the metadata service. **Twelve providers were asked, in this order, and
the twelfth answered.** The names are the ones `botocore`, the library inside the command line,
gives them:

| provider | where it looks | who puts credentials there |
|---|---|---|
| `env` | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` | you, or a CI system |
| `assume-role` | a profile with `role_arn` | you, in `~/.aws/config` (lesson 25) |
| `assume-role-with-web-identity` | `AWS_ROLE_ARN` and `AWS_WEB_IDENTITY_TOKEN_FILE` | Kubernetes on EKS, or a CI system (this lesson) |
| `sso` | a profile with `sso_session` | IAM Identity Center (lesson 11) |
| `shared-credentials-file` | `~/.aws/credentials` | you |
| `login` | what `aws login` left behind | your console sign-in, through a browser |
| `custom-process` | a profile with `credential_process` | a program you name (lesson 25) |
| `config-file` | keys written into `~/.aws/config` | you |
| `ec2-credentials-file`, `boto-config` | two files from an older Python SDK | nobody, today |
| `container-role` | `AWS_CONTAINER_CREDENTIALS_RELATIVE_URI` or `_FULL_URI` | ECS, and EKS Pod Identity |
| `iam-role` | the instance metadata service | EC2, through an instance profile |

Two consequences follow from **first answer wins**. A key left in the environment of a machine that
has a role beats the role, silently, and the machine runs as whoever owns the key. And the
providers near the top cost nothing to check, while the last one makes network requests, which is
why a laptop with no credentials at all pauses for a moment before it says so. Other SDKs keep the
same idea and differ in small ways in the order; each SDK's documentation lists its own.

## Asking the metadata service yourself

On an EC2 instance the metadata service lives at **`http://169.254.169.254/`**, a link-local
address that only the instance itself can reach, and nothing is installed to make it answer. moto
answers the same paths on `localhost:4567`. The service has two versions, and the difference is the
first request:

```
ana@laptop:~/aws$ curl -s http://localhost:4567/latest/meta-data/iam/security-credentials/; echo
default-role
```

That is **IMDSv1**: a plain `GET`, answered with the name of the role whose credentials the instance
holds. moto always answers `default-role`. **IMDSv2** asks for a session token first, with a `PUT`
and a header saying how many seconds it should last, and then sends that token on every read:

```
ana@laptop:~/aws$ TOKEN=$(curl -s -X PUT -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" http://localhost:4567/latest/api/token)
ana@laptop:~/aws$ echo $TOKEN
fake-imdsv2-token
ana@laptop:~/aws$ curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://localhost:4567/latest/meta-data/iam/security-credentials/default-role; echo
{"AccessKeyId": "test-key", "SecretAccessKey": "test-secret-key", "Token": "test-session-token", "Expiration": "2026-10-17T19:00:28Z"}
```

The answer is a whole set of credentials: a key id, a secret, a session token and an expiry. On AWS
the key id starts with `ASIA`, the prefix of a temporary key, and the answer carries three more
fields, `Code`, `LastUpdated` and `Type`. AWS's documentation promises **new credentials at least five
minutes before the old ones expire**, so a program that asks again when its copy runs out never
holds a dead key. moto's are fixed placeholders, `test-key` with the session token `test-session-token`, its IMDSv2
token is always `fake-imdsv2-token`, and the expiry is a day after the request.

## The bottom of the chain, from the command line

With the keys still out of the environment and the metadata address exported, ask again which
credentials the command line would use:

```
ana@laptop:~/aws$ aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : <not set>                : None             : None
access_key : ****************-key     : iam-role         : 
secret_key : ****************-key     : iam-role         : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
```

**`iam-role` is the instance metadata provider**, and the location is empty because there is no
file: the credentials came over HTTP. `get-caller-identity` answers as moto's default user, because
moto does not know a key called `test-key` and falls back to it. On an instance AWS would answer
with the role, `arn:aws:sts::123456789012:assumed-role/shop-app/i-…`, where **the session name is the
instance id**, so a line in CloudTrail says which machine made the call.

Now read `env.sh` again. It puts the keys back, and leaves the metadata address where it was:

```
ana@laptop:~/aws$ source ~/aws/env.sh
ana@laptop:~/aws$ aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : <not set>                : None             : None
access_key : ****************test     : env              : 
secret_key : ****************test     : env              : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
```

`env` wins again, with the metadata service still one variable away, because the chain never got
that far. Keep this terminal as it is now, with `env.sh` read; the next section uses it.
