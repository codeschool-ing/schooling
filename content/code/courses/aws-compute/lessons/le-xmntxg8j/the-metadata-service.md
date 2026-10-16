---
title: "The metadata service: an instance asking about itself"
version: 1
---

The script in the last section asked a question with `curl` and got its Availability Zone back,
with no key, no signature and no region. **That is because it was not calling the EC2 API.** It
was calling the instance metadata service, an HTTP server at `169.254.169.254` that every instance
reaches without leaving its host, and that answers each instance about itself and about nothing
else.

The wrong picture is that this is one more AWS endpoint, like `ec2.sa-east-1.amazonaws.com` with
fewer features. An AWS endpoint is on the internet, takes signed requests and answers whoever
holds the right key. **The metadata service takes no credentials at all, because the identity of
the caller is where the request came from.** `169.254.169.254` is a link-local address, which no
router forwards: a request to it from the instance is answered by the host underneath, and the
same request from anywhere else goes nowhere.

## What it answers

The service is a tree of paths under `/latest/`, and a path ending in `/` lists what is under it.
AWS documents a long list; these are the ones a script reaches for:

| path | what AWS answers on an instance |
|---|---|
| `/latest/meta-data/instance-id` | the instance's own id, `i-` and 17 characters |
| `/latest/meta-data/instance-type` | `t3.micro`, `m7g.large`, … |
| `/latest/meta-data/placement/availability-zone` | the zone, such as `sa-east-1a` |
| `/latest/meta-data/local-ipv4` | its private address in the VPC |
| `/latest/meta-data/iam/security-credentials/` | the name of the role attached, if any |
| `/latest/user-data` | the user data, decoded |
| `/latest/dynamic/instance-identity/document` | a JSON summary of the above, signed by AWS |

The last row is how an instance proves who it is to a third party: the document comes with a
signature AWS publishes the means to check. The row above it is the previous section's warning
made concrete, since any process on the instance can read the user data back.

**The path that matters most is the credentials one.** An instance launched with an instance
profile, as `aws-foundations` lesson 10 set up, has a role, and under
`iam/security-credentials/<role>` the service hands out a temporary access key, secret key and
session token for that role. AWS rotates them and has the next set ready before the current one
expires. Every AWS SDK and the CLI look there when nothing closer gives them credentials. The
environment variables and the files in `~/.aws` come first; the metadata service is the last
place in the chain, and on an instance it is the one meant to answer.

## What moto answers, and what it does not

moto has no instances and no hosts, so nothing in this lab can call `169.254.169.254`. What it
does have is a handful of these paths served on its own port, so that a program under test can
find credentials the way it would on an instance:

```
ana@laptop:~/aws$ curl -s localhost:4567/latest/meta-data/; echo
iam
ana@laptop:~/aws$ curl -s localhost:4567/latest/meta-data/instance-id; echo
i-fake
ana@laptop:~/aws$ curl -s localhost:4567/latest/meta-data/placement/availability-zone; echo
us-east-1a
ana@laptop:~/aws$ curl -s localhost:4567/latest/meta-data/iam/security-credentials/; echo
default-role
ana@laptop:~/aws$ curl -s localhost:4567/latest/meta-data/iam/security-credentials/default-role; echo
{"AccessKeyId": "test-key", "SecretAccessKey": "test-secret-key", "Token": "test-session-token", "Expiration": "2026-10-17T16:06:37Z"}
```

**Read those as placeholders, not as an instance.** The id is `i-fake`, which is no instance moto
launched. The zone is `us-east-1a`, while every instance this lab has launched sits in
`sa-east-1a`. There is a role called `default-role` although no instance profile was attached to
anything, and its keys are the words `test-key` and `test-secret-key`. The same answers come back
whatever has been launched, and `instance-type`, `local-ipv4` and `/latest/user-data` are not there
at all. On AWS every one of those paths answers with that instance's own value, and differently on
the next instance.

What the placeholders do show for real is the client side. Remove the two credential variables
from the environment and tell the CLI where the metadata service is, which on an instance it
knows without being told. The CLI then goes looking for a role:

```
ana@laptop:~/aws$ env -u AWS_ACCESS_KEY_ID -u AWS_SECRET_ACCESS_KEY AWS_EC2_METADATA_SERVICE_ENDPOINT=http://localhost:4567/ aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : <not set>                : None             : None
access_key : ****************-key     : iam-role         : 
secret_key : ****************-key     : iam-role         : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
ana@laptop:~/aws$ env -u AWS_ACCESS_KEY_ID -u AWS_SECRET_ACCESS_KEY AWS_EC2_METADATA_SERVICE_ENDPOINT=http://localhost:4567/ aws sts get-caller-identity --debug 2>&1 | grep -E "\"(PUT|GET) /latest|Found credentials" | sed "s/^.* - //"
http://localhost:4567 "PUT /latest/api/token HTTP/1.1" 200 17
http://localhost:4567 "GET /latest/meta-data/iam/security-credentials/ HTTP/1.1" 200 12
http://localhost:4567 "GET /latest/meta-data/iam/security-credentials/default-role HTTP/1.1" 200 134
Found credentials from IAM Role: default-role
```

`aws configure list` reports the keys as coming from `iam-role`, which is the chain falling
through to the metadata service. The `--debug` lines, filtered to the requests that went to it,
show the CLI's three steps: **a `PUT` to `/latest/api/token` first**, then a `GET` that lists the
role, then a `GET` of that role's credentials. The token request in the first line is IMDSv2, and
the CLI makes it without being asked. Why there is a `PUT` at all is the next section.
