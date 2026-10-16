---
title: "The exchange: a token in, credentials out"
version: 1
---

Everything in the last section was preparation for one API call. **A pod with the annotated service
account holds a token Kubernetes signed; the AWS SDK inside it sends that token to STS's
`AssumeRoleWithWebIdentity`, and STS answers with credentials for the role, valid for an hour.**
The SDK signs every later call with them, and asks again before they run out. No key is stored
anywhere, and the token itself expires within a day.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"A sequence in five steps between four parties: the pod, STS, the cluster's issuer and S3. 1, the pod sends STS the token and the role it wants. 2, STS fetches the issuer's public keys. 3, STS checks the signature, issuer, audience and expiry, then the trust policy's subject. 4, STS returns credentials that last an hour. 5, the pod calls S3 GetObject signed with them. A note says moto skips steps 2 and 3 and reads no token at all.\"><defs><marker id=\"ex-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"ex-ah-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M90 62 L90 320\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\" fill=\"none\"></path><rect x=\"15\" y=\"14\" width=\"150\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">the pod</text><text x=\"90\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">SDK and token file</text><path d=\"M310 62 L310 188\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\" fill=\"none\"></path><path d=\"M310 234 L310 320\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\" fill=\"none\"></path><rect x=\"245\" y=\"14\" width=\"130\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">STS</text><text x=\"310\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">security tokens</text><path d=\"M520 62 L520 190\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\" fill=\"none\"></path><rect x=\"440\" y=\"14\" width=\"160\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">the cluster's issuer</text><text x=\"520\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">discovery and keys</text><path d=\"M660 62 L660 200\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\" fill=\"none\"></path><path d=\"M660 244 L660 320\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\" fill=\"none\"></path><rect x=\"615\" y=\"14\" width=\"90\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"660\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">S3</text><text x=\"660\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the bucket</text><text x=\"200\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1 · the token and the role ARN</text><path d=\"M92 98 L306 98\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ex-ah)\"></path><text x=\"415\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2 · fetch the issuer's keys</text><path d=\"M312 134 L516 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ex-ah-dim)\"></path><text x=\"415\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the keys, as a JWKS</text><path d=\"M518 170 L314 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ex-ah-dim)\"></path><rect x=\"176\" y=\"188\" width=\"268\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3 · signature, issuer, audience, expiry,</text><text x=\"310\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">then the trust policy's sub</text><text x=\"200\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4 · credentials for one hour</text><path d=\"M308 264 L94 264\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ex-ah)\"></path><text x=\"375\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">5 · GetObject, signed with those credentials</text><path d=\"M92 302 L656 302\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ex-ah)\"></path><rect x=\"452\" y=\"200\" width=\"250\" height=\"44\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"577\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">moto skips steps 2 and 3:</text><text x=\"577\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">it reads no token at all</text></svg>", "caption": "The exchange at the heart of IRSA. The pod proves who it is with a token Kubernetes signed, and STS believes it only after checking that signature against the issuer's published keys. On your laptop moto plays STS and does steps 1 and 4 alone."}
```

## What the pod is given

The service account's annotation is read by a mutating webhook EKS runs in the control plane, the
pod identity webhook. When a pod using that service account is created, the webhook adds three
things to its spec, which AWS documents and `kubectl get pod -o yaml` shows on a real cluster:

- a **projected volume** with a service account token for the audience `sts.amazonaws.com`, valid
  for 86,400 seconds, mounted at `/var/run/secrets/eks.amazonaws.com/serviceaccount/token`. The
  kubelet writes a fresh token before the old one runs out;
- **`AWS_ROLE_ARN`**, the role from the annotation;
- **`AWS_WEB_IDENTITY_TOKEN_FILE`**, the path of the token.

That is all. There is no AWS code in the pod beyond the SDK the application already uses, and it is
those two variables that switch it from looking for keys to doing the exchange. Every current AWS
SDK and the command line read them, so **the exchange can be run on your laptop exactly as a pod
runs it**, with moto playing STS.

## A token, made by hand

A real token is a JSON Web Token: three parts separated by dots, a header, the claims and a
signature, the first two base64url-encoded JSON. This program makes one of the same shape, with the
claims IRSA cares about. Save it as `~/aws/mktoken.py`:

```python
# mktoken.py: an UNSIGNED token shaped like the one Kubernetes puts in a pod
import base64
import json
import sys
import time


def part(data):
    return base64.urlsafe_b64encode(json.dumps(data).encode()).rstrip(b'=').decode()


issuer = sys.argv[1]
audience = sys.argv[2] if len(sys.argv) > 2 else 'sts.amazonaws.com'
claims = {
    'iss': issuer,
    'sub': 'system:serviceaccount:shop:photos',
    'aud': [audience],
    'exp': int(time.time()) + 86400,
}
print(part({'alg': 'none'}) + '.' + part(claims) + '.', end='')
```

`iss`, `sub` and `aud` are the three the trust policy and the provider test, and `exp` is a day
from now, as the kubelet's would be. A real token also carries the pod's name and uid and a key id
in its header. **The difference that matters is the last part: here it is empty, and the header says
`none`.** Nobody signed this token, and no real STS would take it. It ends without a newline,
because the SDK sends the file's contents as they are and a line break is not allowed in them.

## Running the exchange

In the terminal where `ISSUER` is set, write a token and give the command line the two variables
the webhook gives a pod. The test keys have to go: **the SDK looks for keys in the environment
before it looks for a token**, so with them present it would never try the exchange. A real pod has
no keys in its environment, which is the point.

```
ana@laptop:~/aws$ python3 mktoken.py "$ISSUER" > token
ana@laptop:~/aws$ export AWS_ROLE_ARN=arn:aws:iam::123456789012:role/photos-reader
ana@laptop:~/aws$ export AWS_WEB_IDENTITY_TOKEN_FILE=~/aws/token AWS_ROLE_SESSION_NAME=photos-pod
ana@laptop:~/aws$ unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "AROARZPUZDIKCYCGLBJ3Q:photos-pod",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/photos-reader/photos-pod"
}
```

The caller is no longer moto's user. It is the role `photos-reader`, in a session called
`photos-pod`, and every call this terminal makes from now on is signed with that role's temporary
credentials. `AWS_ROLE_SESSION_NAME` is optional; without it the SDK invents a name with a
timestamp in it, and naming the session is what lets CloudTrail say which workload it was.

## What moto believed, and AWS would not

Now replace the token with a word and ask again. The command line keeps the credentials of a role it
assumed in `~/.aws/cli/cache` until they expire, so the cache goes first, or the answer would come
from there rather than from moto:

```
ana@laptop:~/aws$ echo not-a-token > token
ana@laptop:~/aws$ rm -rf ~/.aws/cli/cache
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn
"arn:aws:sts::123456789012:assumed-role/photos-reader/photos-pod"
ana@laptop:~/aws$ AWS_ROLE_ARN=arn:aws:iam::123456789012:role/no-such-role aws sts get-caller-identity --query Arn
"arn:aws:sts::123456789012:assumed-role/no-such-role/photos-pod"
```

**moto gave out credentials for `not-a-token`, and then for a role that does not exist.** It reads
neither the token nor the role, and it does not open the trust policy at all. That is not a bug to
work around; it is the line between what this lab can show and what it cannot. On AWS, STS refuses
each of these:

- a token whose signature does not check against the issuer's keys, or whose issuer has no IAM OIDC
  provider in the account, with `InvalidIdentityToken`;
- a token past its `exp`, with `ExpiredToken`;
- a valid token whose `sub` or `aud` does not match the trust policy, say one for
  `system:serviceaccount:shop:default`, with `AccessDenied` on `sts:AssumeRoleWithWebIdentity`.

None of those three refusals was run here, and none is shown as output, because moto cannot produce
them. They are in STS's API reference, which is where to read the wording.

Put the test keys back before going on:

```
ana@laptop:~/aws$ unset AWS_ROLE_ARN AWS_WEB_IDENTITY_TOKEN_FILE AWS_ROLE_SESSION_NAME
ana@laptop:~/aws$ export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
```

## The role's permissions are the pod's permissions

What moto can check, when asked, is the other half: what the credentials may do once issued.
`moto_server` reads `INITIAL_NO_AUTH_ACTION_COUNT` from its environment, lets that many requests
through unchecked, and evaluates IAM policies for every request after them. Stop moto with Ctrl+C
and start it again in its terminal with checks on after five requests:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=5 ~/aws/venv/bin/moto_server -p 4567
```

It is empty again, so the five unchecked requests set the scene: the bucket, a photo in it, the role
and its permission, and the exchange itself, done explicitly this time and kept in three variables.
**The exchange has to be inside the five for a reason of moto's**: with checks on it cannot answer a
request that carries no signature, and `AssumeRoleWithWebIdentity` is unsigned by design, since the
whole point is that the caller has no credentials yet.

```
ana@laptop:~/aws$ printf "hi\n" > photo.jpg
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-photos-123456789012 --create-bucket-configuration LocationConstraint=sa-east-1 --query Location
"/shop-photos-123456789012"
ana@laptop:~/aws$ aws s3api put-object --bucket shop-photos-123456789012 --key cat.jpg --body photo.jpg --query ETag
"\"764efa883dda1e11db47671c4a3bbd9e\""
ana@laptop:~/aws$ aws iam create-role --role-name photos-reader --assume-role-policy-document file://trust.json --query Role.Arn
"arn:aws:iam::123456789012:role/photos-reader"
ana@laptop:~/aws$ aws iam put-role-policy --role-name photos-reader --policy-name read-photos --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::shop-photos-123456789012/*"}]}'
ana@laptop:~/aws$ read AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN < <(aws sts assume-role-with-web-identity --role-arn arn:aws:iam::123456789012:role/photos-reader --role-session-name photos-pod --web-identity-token file://token --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" --output text)
ana@laptop:~/aws$ export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn
"arn:aws:sts::123456789012:assumed-role/photos-reader/photos-pod"
ana@laptop:~/aws$ aws s3api get-object --bucket shop-photos-123456789012 --key cat.jpg cat.jpg --query ContentLength
3
ana@laptop:~/aws$ aws s3api put-object --bucket shop-photos-123456789012 --key dog.jpg --body photo.jpg

aws: [ERROR]: An error occurred (AccessDenied) when calling the PutObject operation: Access Denied
```

The role may read the photo and may not write one, exactly as `read-photos` says. **On AWS that
refusal is the everyday case, not a lab trick**: a pod gets the role's permissions and nothing
more, so the policy, not the pod's code, decides what a compromised resizer could do.

Before the next section, stop this moto and start it the ordinary way, with no variable in front.
