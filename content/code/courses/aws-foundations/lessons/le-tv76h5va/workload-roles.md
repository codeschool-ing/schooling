---
title: A role per pod and per task: IRSA, Pod Identity and ECS
version: 1
---

**An instance profile gives one role to a whole machine; a cluster needs a role per workload.** A
Kubernetes node on EKS runs pods from several teams, and the shop's checkout and its reporting job
should not share permissions because they happen to land on the same node. AWS has three answers,
and each lands on one of two providers in the chain: **a token file traded for a role**, or a
local address that hands out credentials.

| | what the workload is given | provider in the chain |
|---|---|---|
| **IRSA**, IAM roles for service accounts (EKS) | a token file and a role ARN | `assume-role-with-web-identity` |
| **EKS Pod Identity** | a local address and a token file | `container-role` |
| **ECS task role** | a local address | `container-role` |

## IRSA: a token from the cluster, traded at STS

An EKS cluster is an **OpenID Connect issuer**. It signs a short-lived token for each pod that says
which service account the pod runs as, and publishes the keys that verify the signature at a public
address. IRSA makes IAM trust that issuer:

1. the account registers the cluster's issuer as an OIDC identity provider in IAM;
2. a role's trust policy names that provider and says which service account may assume it;
3. the pod receives the token in a file, and two environment variables naming the file and the role;
4. the SDK calls `sts:AssumeRoleWithWebIdentity` with the token, and STS answers with temporary
   credentials for the role.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" data-fig=\"l10-irsa\" aria-label=\"IRSA as a sequence, between four parties: the EKS cluster, the pod, STS and S3. One: the cluster gives the pod a signed token in a file. Two: the pod sends AssumeRoleWithWebIdentity to STS with the token and no signature. Three: STS fetches the keys the cluster publishes and verifies the signature. Four: STS evaluates the trust policy, where sub and aud must match. Five: STS returns credentials for an hour. Six: the pod calls S3, signed with them. moto skips steps three and four.\"><defs><marker id=\"l10-irsa-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10-irsa-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"24.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the cluster</text><text x=\"90.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">EKS</text><path d=\"M90.0 70.0 L90.0 360.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"200.0\" y=\"24.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the pod</text><text x=\"270.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">checkout</text><path d=\"M270.0 70.0 L270.0 360.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"380.0\" y=\"24.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">STS</text><path d=\"M450.0 70.0 L450.0 360.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"560.0\" y=\"24.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">S3</text><path d=\"M630.0 70.0 L630.0 360.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M92.0 100.0 L268.0 100.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-irsa-af-ah-phosphor)\"></path><text x=\"179.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">1  a signed token, in a file</text><path d=\"M272.0 150.0 L448.0 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-irsa-af-ah-phosphor)\"></path><text x=\"359.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">2  token, no signature</text><path d=\"M448.0 200.0 L92.0 200.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-irsa-af-ah-amber)\"></path><text x=\"271.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">3  fetch its keys, verify the signature</text><path d=\"M448.0 290.0 L272.0 290.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-irsa-af-ah-phosphor)\"></path><text x=\"361.0\" y=\"279.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">5  credentials for an hour</text><path d=\"M272.0 340.0 L628.0 340.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-irsa-af-ah-phosphor)\"></path><text x=\"449.0\" y=\"329.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">6  a call signed with them</text><text x=\"460.0\" y=\"245.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">4  trust policy: sub, aud</text><text x=\"160.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" font-style=\"italic\" fill=\"var(--amber)\">moto skips 3 and 4</text></svg>", "caption": "The pod needs no AWS credential to get its first one: the token is the proof, and STS is the one that checks it."}
```

The call to STS, step 2 in the figure, is **not signed**. The token is the proof, and that is the
point: the pod needs no AWS credential at all to get its first one. Register the provider. The issuer address is
the shape EKS gives a cluster in `sa-east-1`, with an id from AWS's documentation:

```
ana@laptop:~/aws$ aws iam create-open-id-connect-provider --url https://oidc.eks.sa-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE --client-id-list sts.amazonaws.com
{
    "OpenIDConnectProviderArn": "arn:aws:iam::123456789012:oidc-provider/oidc.eks.sa-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
}
```

The trust policy carries the conditions that make it a role for one workload. **`sub` is the
service account, as `system:serviceaccount:<namespace>:<name>`; `aud` is who the token is for**,
which for IRSA is STS. Without the `sub` condition, every pod in the cluster with a token could
become this role. Save this as `~/aws/trust-checkout.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/oidc.eks.sa-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.sa-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE:sub": "system:serviceaccount:shop:checkout",
          "oidc.eks.sa-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam create-role --role-name shop-checkout --assume-role-policy-document file://trust-checkout.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/shop-checkout
ana@laptop:~/aws$ aws iam attach-role-policy --role-name shop-checkout --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
```

On the cluster side, the service account carries the role's ARN in an annotation, and EKS puts the
token and the two variables into every pod that runs as it. **This was not run**, since there is no
cluster in the lab; it is the shape EKS documents:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: checkout
  namespace: shop
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/shop-checkout
```

## A token, made by hand

A pod's token is a JWT: three base64 pieces joined by dots, a header, a set of claims and a
signature. This program writes one with the claims an EKS token carries, and a third piece that is
**not a signature at all**. It is enough to drive the chain, and the section after it measures what
that says about moto. Save it as `~/aws/make-token.py`; a file called `token.py` in `~/aws` would
hide Python's own `token` module from every program run there, boto3 included:

```schooling-example
{"language": "python", "file": "make-token.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Prints a token shaped like the one EKS gives a pod. It is NOT signed.\n\n    python3 make-token.py SERVICE-ACCOUNT > token\n\"\"\"\nimport base64\nimport json\nimport sys\nimport time\n\n", "note": "Only Python's own library. The service account comes from the command line, so the same program can write a token for the right workload and for the wrong one."}, {"code": "ISSUER = 'https://oidc.eks.sa-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE'\n\n\ndef piece(d):\n    raw = json.dumps(d, separators=(',', ':')).encode()\n    return base64.urlsafe_b64encode(raw).rstrip(b'=').decode()\n\n\n", "note": "A JWT encodes each piece as base64 in its URL-safe form, with the `=` padding removed. `ISSUER` is the address registered as the OIDC provider."}, {"code": "now = int(time.time())\nclaims = {'iss': ISSUER, 'sub': sys.argv[1], 'aud': ['sts.amazonaws.com'],\n          'iat': now, 'exp': now + 3600}\n", "note": "The claims STS compares with the trust policy: who issued the token, which service account it names, who it is for. `exp` makes it worthless an hour after it was made. A real pod's token expires too, and the kubelet replaces it before it does."}, {"code": "print(piece({'alg': 'RS256', 'kid': 'lab'}) + '.' + piece(claims) + '.not-a-signature')\n", "note": "The header says RS256, an RSA signature, and the third piece is a placeholder. AWS would fetch the issuer's published keys, find none that verifies it, and refuse the token."}]}
```

Write a token for the checkout's service account, take the keys out of the environment, and give
the chain the two variables a pod would get. `AWS_ROLE_SESSION_NAME` is optional; it fixes the name
the session would otherwise take from the clock:

```
ana@laptop:~/aws$ python3 make-token.py system:serviceaccount:shop:checkout > token
ana@laptop:~/aws$ unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
ana@laptop:~/aws$ export AWS_ROLE_ARN=arn:aws:iam::123456789012:role/shop-checkout AWS_WEB_IDENTITY_TOKEN_FILE=~/aws/token AWS_ROLE_SESSION_NAME=checkout-pod
ana@laptop:~/aws$ aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : <not set>                : None             : None
access_key : ****************QGVI     : assume-role-with-web-identity : 
secret_key : ****************B/rN     : assume-role-with-web-identity : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "AROARZPUZDIKGSK3B22RF:checkout-pod",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/shop-checkout/checkout-pod"
}
```

**`assume-role-with-web-identity` answered**, the third provider in the chain, and the identity is
the role with the session name the variable gave it.

## What moto checks, measured

Now the same chain with a token for a service account the trust policy does not name, and then
with a role that does not exist:

```
ana@laptop:~/aws$ python3 make-token.py system:serviceaccount:other:intruder > token
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn --output text
arn:aws:sts::123456789012:assumed-role/shop-checkout/checkout-pod
ana@laptop:~/aws$ AWS_ROLE_ARN=arn:aws:iam::123456789012:role/no-such-role aws sts get-caller-identity --query Arn --output text
arn:aws:sts::123456789012:assumed-role/no-such-role/checkout-pod
```

**moto verified nothing.** Not the signature, which is not one; not the issuer; not `sub` or `aud`
against the conditions; not even that the role exists. It returned credentials every time. Asking
STS directly, with `--no-sign-request` because the call needs no key, shows one more gap:

```
ana@laptop:~/aws$ aws sts assume-role-with-web-identity --role-arn arn:aws:iam::123456789012:role/shop-checkout --role-session-name checkout-pod --web-identity-token file://token --no-sign-request --query "keys(@)" --output text
Credentials	AssumedRoleUser	PackedPolicySize
```

AWS's answer also carries `SubjectFromWebIdentityToken`, `Audience` and `Provider`, which say whose
token was accepted, and moto's has none of them.

And with moto's permission checking turned on, as lesson 7 starts it
(`INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567`, then an `admin` user bootstrapped in three
requests), the call does not get that far. moto's checking expects every request to carry a
signature, this one carries none, and moto answers with an internal error, HTTP 500. That was
measured while recording this lesson, and it is why the lesson leaves the checking off.

So the lab shows **how the credentials travel**, and AWS's documentation is the only source for
what STS refuses. It verifies the token's signature against the keys the issuer publishes, checks
that the issuer is a registered provider and that the token has not expired, and then evaluates the
trust policy, where `sub` and `aud` must match. A token for `other:intruder` is refused there with
`AccessDenied`.

## EKS Pod Identity, the newer way

**EKS Pod Identity** removes the OIDC provider from the arrangement. An agent runs on every node and
answers on a link-local address, `169.254.170.23`, and the cluster maps a service account to a role
with an association, `aws eks create-pod-identity-association`. The role's trust policy names one
service principal, the same in every cluster:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Service": "pods.eks.amazonaws.com"},
      "Action": ["sts:AssumeRole", "sts:TagSession"]
    }
  ]
}
```

That is the difference that matters in practice: **with IRSA every cluster is a provider to
register and a condition to write in each trust policy, and with Pod Identity a role can be reused
by any cluster in the account** without editing it. AWS's documentation presents Pod Identity as
the simpler choice on EKS, and IRSA stays where Pod Identity does not reach, such as pods on Fargate.
Neither was run here.

## ECS task roles, and the container provider

On ECS, a task role is declared in the task definition, and the ECS agent serves its credentials
at `169.254.170.2`. The container gets a variable, `AWS_CONTAINER_CREDENTIALS_RELATIVE_URI`, holding
the path to ask for, and the chain's `container-role` provider asks it. The role's trust policy
names `ecs-tasks.amazonaws.com`.

The answer has the same JSON shape as the metadata service's, so the provider can be shown working
by pointing its other variable, `AWS_CONTAINER_CREDENTIALS_FULL_URI`, at moto's metadata answer.
That is the provider reading moto's placeholder credentials, not an ECS agent. Take the web
identity variables out first, since that provider comes earlier in the chain:

```
ana@laptop:~/aws$ unset AWS_ROLE_ARN AWS_WEB_IDENTITY_TOKEN_FILE AWS_ROLE_SESSION_NAME
ana@laptop:~/aws$ AWS_CONTAINER_CREDENTIALS_FULL_URI=http://localhost:4567/latest/meta-data/iam/security-credentials/default-role aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : <not set>                : None             : None
access_key : ****************-key     : container-role   : 
secret_key : ****************-key     : container-role   : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
```

**`container-role` answered**, ahead of `iam-role` in the chain. Every workload in this section,
pod or task, ended with credentials that expire within hours, and no key was written anywhere.
Read `env.sh` again to put the test keys back before the drill.
