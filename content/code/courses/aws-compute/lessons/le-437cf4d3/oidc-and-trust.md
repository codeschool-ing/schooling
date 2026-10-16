---
title: The cluster's issuer, and a role that trusts it
version: 1
---

IRSA is three pieces, and only one of them is new. **The cluster already has an identity provider
of its own; you tell IAM to believe it; and you write a role whose trust policy accepts one service
account and nobody else.** A fourth step, outside AWS, points the service account at the role. This
section builds the three pieces in moto and shows the fourth as the file it is.

The picture people often bring is that the cluster logs in to IAM on the pod's behalf, or that
IRSA quietly creates an IAM user per pod. **Neither happens.** The pod calls STS itself, carrying a
token that Kubernetes signed, and AWS gives it credentials because IAM was told in advance whose
signature to accept. Nothing in AWS holds a secret for the pod, which is the property the last
section asked for.

## The issuer every cluster has

Kubernetes already signs a token for every service account, so that a pod can prove to the API
server who it is. On EKS the signer is published as an **OpenID Connect issuer**: a URL, unique to
the cluster, where anybody can fetch a discovery document and the public keys that check the
signatures. Lesson 11 saw the field when it created a cluster. Create one again, and ask for it:

```
ana@laptop:~/aws$ aws eks create-cluster --name shop --role-arn arn:aws:iam::123456789012:role/shop-cluster --resources-vpc-config subnetIds=subnet-0a1,subnet-0b2 --query cluster.identity
{
    "oidc": {
        "issuer": "https://oidc.eks.sa-east-1.amazonaws.com/id/lOAQdZ7XP0"
    }
}
ana@laptop:~/aws$ ISSUER=$(aws eks describe-cluster --name shop --query cluster.identity.oidc.issuer --output text)
ana@laptop:~/aws$ aws iam create-open-id-connect-provider --url "$ISSUER" --client-id-list sts.amazonaws.com
{
    "OpenIDConnectProviderArn": "arn:aws:iam::123456789012:oidc-provider/oidc.eks.sa-east-1.amazonaws.com/id/lOAQdZ7XP0"
}
```

Two things in that answer are moto's rather than AWS's. On AWS the last part of the issuer is
32 hexadecimal characters, where moto makes up ten mixed-case ones, and moto's cluster reports
Kubernetes 1.19, a version AWS retired long ago. More important for this lesson, **nothing answers
at that URL on your laptop.** On AWS it serves
`/.well-known/openid-configuration` and a key set, and STS fetches the keys from there; here no
server holds keys and no token is ever signed, so the next section has to be careful about what
the exchange proves.

The third command is the step that matters. **An IAM OIDC provider is an entry in your account
saying: tokens signed by this issuer, for this audience, are worth believing.** The audience,
`--client-id-list`, is `sts.amazonaws.com`, which is what the EKS tokens meant for IRSA carry.

There is no `--thumbprint-list`, and on AWS none is needed. The API reference the command line
carries says the field is optional. AWS checks the TLS certificate of the issuer's key endpoint
against its own library of trusted certificate authorities, and consults a thumbprint only when that
certificate is not signed by one of them. An EKS issuer's is.

One provider is needed **per cluster**, because every cluster has its own issuer. A team that runs a
cluster per environment and replaces clusters during upgrades creates and deletes providers as
often as clusters, and IAM limits how many an account may hold, 100 by default. Section 05 comes
back to that cost.

## The trust policy

`aws-foundations` lesson 9 split a role in two: the permission policy says what the role may do,
and the trust policy says who may become it. IRSA lives in the trust policy. Paste this into the
terminal where `ISSUER` was set; it writes `trust.json` for your own cluster:

```schooling-example
{"language": "sh", "parts": [{"code": "OIDC=${ISSUER#https://}\ncat > trust.json <<EOF\n{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Effect\": \"Allow\",\n", "note": "`OIDC` is the issuer with `https://` cut off, because that is how IAM names the provider and the keys of its conditions. The heredoc's `EOF` is not quoted, so the shell puts the value of `$OIDC` into the file wherever it appears."}, {"code": "      \"Principal\": {\n        \"Federated\": \"arn:aws:iam::123456789012:oidc-provider/$OIDC\"\n      },\n", "note": "**Who may assume the role: whoever holds a token from this one issuer.** `Federated` names the IAM OIDC provider created above. A token signed by another cluster's issuer matches nothing here."}, {"code": "      \"Action\": \"sts:AssumeRoleWithWebIdentity\",\n", "note": "The one way in. This is the call that trades a token for credentials, and it is the only action the statement allows."}, {"code": "      \"Condition\": {\n        \"StringEquals\": {\n          \"$OIDC:sub\": \"system:serviceaccount:shop:photos\",\n", "note": "`sub` is the token's subject: the namespace `shop` and the service account `photos`. **Without this line every pod in the cluster could assume the role**, because every pod's token comes from the same issuer."}, {"code": "          \"$OIDC:aud\": \"sts.amazonaws.com\"\n        }\n      }\n    }\n  ]\n}\nEOF\n", "note": "`aud` is the audience the token was minted for. A token Kubernetes issued for some other purpose, with another audience, is refused even when its subject matches."}]}
```

What it wrote, with this cluster's issuer in the three places the variable was:

```
ana@laptop:~/aws$ cat trust.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/oidc.eks.sa-east-1.amazonaws.com/id/lOAQdZ7XP0"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.sa-east-1.amazonaws.com/id/lOAQdZ7XP0:sub": "system:serviceaccount:shop:photos",
          "oidc.eks.sa-east-1.amazonaws.com/id/lOAQdZ7XP0:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

The two conditions are the part to read slowly. A token from this issuer can only be used for this
role if its `sub` names the service account `photos` in the namespace `shop` and its `aud` says
STS. **Remove the `sub` line and the role trusts every pod in the cluster**, including the debugging
pod from the last section, because all of their tokens come from the same issuer. The same mistake
in a milder form is `StringLike` with `system:serviceaccount:shop:*`, which hands the role to every
service account in the namespace, including ones created next year.

Then the role itself, and the one thing it may do:

```
ana@laptop:~/aws$ aws iam create-role --role-name photos-reader --assume-role-policy-document file://trust.json --query Role.Arn
"arn:aws:iam::123456789012:role/photos-reader"
ana@laptop:~/aws$ aws iam put-role-policy --role-name photos-reader --policy-name read-photos --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::shop-photos-123456789012/*"}]}'
```

`read-photos` allows `s3:GetObject` on the shop's bucket and nothing else. That permission policy is
an ordinary one; what makes this an IRSA role is only the trust policy above it.

## The fourth piece, in Kubernetes

The role exists, and the cluster still has to know which service account it belongs to. That is an
annotation on the service account, and the pod names the service account in its spec:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: photos
  namespace: shop
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/photos-reader
```

**This file is not applied anywhere in this course, because moto runs no Kubernetes** and there is
no API server for `kubectl` to talk to. On a real cluster, `kubectl apply -f` creates it, and a pod
with `serviceAccountName: photos` in its spec picks up the role. Only a pod created after the annotation does: the role is wired into a pod
when the pod is made, so one that was already running carries on without it, which is the most
common reason an annotation "does not work".

The annotation grants nothing by itself. A service account annotated with a role whose trust
policy names a different subject gets a token STS will refuse, and the pod's first AWS call fails.
**The trust policy is the lock, and the annotation is only the address on the envelope.**

`eksctl create iamserviceaccount` does all four steps in one command, and most teams use it or
Terraform's EKS module. Doing them by hand once is how you learn to read what those tools leave in
the account.
