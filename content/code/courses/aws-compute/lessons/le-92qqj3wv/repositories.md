---
title: A repository, and the address that names it
version: 1
---

The picture most people bring to ECR is Docker Hub with AWS's logo on it: one big registry that
everybody pushes to, where your images sit beside everyone else's. **ECR is the opposite shape.
Every AWS account has a private registry of its own in every region**, and a repository inside
that registry holds the versions of one image. Nobody outside the account can read it unless a
policy says so, and an image pushed in São Paulo does not exist in Virginia.

The address of an image says all of that, piece by piece:

| piece | in this lesson | what it says |
|---|---|---|
| `123456789012` | the account | whose registry it is: moto's account here |
| `dkr.ecr` | the service | ECR's registry endpoint, the one Docker talks to |
| `sa-east-1` | the region | where the layers are stored |
| `amazonaws.com` | the domain | AWS's, the same in every commercial region |
| `shop/web` | the repository | the versions of one image |
| `1.0.0` | the tag | one version, named by you |

Written out, that is `123456789012.dkr.ecr.sa-east-1.amazonaws.com/shop/web:1.0.0`. **Docker
reads the part before the first slash as the registry to talk to**, which is why an image has to
be tagged with this long name before it can be pushed: the name is the destination.

## Creating one

A repository is created before anything is pushed to it. ECR creates one on a push only when a
repository creation template allows it, and this lesson uses none:

```
ana@laptop:~/aws$ aws ecr create-repository --repository-name shop/web
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:sa-east-1:123456789012:repository/shop/web",
        "registryId": "123456789012",
        "repositoryName": "shop/web",
        "repositoryUri": "123456789012.dkr.ecr.sa-east-1.amazonaws.com/shop/web",
        "createdAt": "2026-10-16T13:25:46.504000-03:00",
        "imageTagMutability": "MUTABLE",
        "imageScanningConfiguration": {
            "scanOnPush": false
        },
        "encryptionConfiguration": {
            "encryptionType": "AES256"
        }
    }
}
```

Four things in that answer are decisions the defaults made for you:

- **`imageTagMutability` is `MUTABLE`**: a push may move a tag that already exists onto a
  different image. The section on tags shows what that costs and turns it off.
- **`scanOnPush` is `false`**: nothing looks inside the image when it arrives. The section on
  scanning turns it on and says what it finds.
- **`encryptionType` is `AES256`**: the layers are encrypted at rest with a key ECR manages.
  `--encryption-configuration encryptionType=KMS` uses a KMS key of your own instead, and AWS
  only lets you choose at creation: a repository's encryption cannot be changed afterwards.
- **`repositoryUri` is the address above**, without a tag, and it is what a task definition or a
  Kubernetes manifest names.

The slash in `shop/web` is part of the name and not a folder. There is no repository called
`shop`, and `aws ecr delete-repository --repository-name shop` would find nothing. The prefix is
useful all the same, because an IAM policy can name `repository/shop/*` and cover every image of
one team at once.

The name has a format, and AWS enforces it. Capitals are the mistake people make:

```
ana@laptop:~/aws$ aws ecr create-repository --repository-name Shop/Web

aws: [ERROR]: An error occurred (InvalidParameterException) when calling the CreateRepository operation: Invalid parameter at 'repositoryName' failed to satisfy constraint: 'must satisfy regular expression '(?:[a-z0-9]+(?:[._-][a-z0-9]+)*/)*[a-z0-9]+(?:[._-][a-z0-9]+)*'
```

moto carries the same regular expression AWS publishes, so this refusal is one of the places where
the imitation and the service agree exactly.

## Who may pull from it

**Inside the account, pulling is an IAM question.** Whoever pulls needs permission for three
actions: `ecr:GetAuthorizationToken` to log in, and `ecr:BatchGetImage` and
`ecr:GetDownloadUrlForLayer` to read the manifest and the layers. That is what the execution role
of lesson 8 carries, and `aws-foundations` lessons 7 and 8 are where those policies are written
and evaluated.

**From another account, it takes a repository policy as well**, a resource-based policy attached
to the repository, in the same way a bucket policy is attached to a bucket. A production account
that pulls images built in a tools account is the usual case. `444455556666` below is the second
example account in AWS's own documentation:

```
ana@laptop:~/aws$ aws ecr set-repository-policy --repository-name shop/web --policy-text '{"Version":"2012-10-17","Statement":[{"Sid":"ProductionPulls","Effect":"Allow","Principal":{"AWS":"arn:aws:iam::444455556666:root"},"Action":["ecr:BatchGetImage","ecr:GetDownloadUrlForLayer"]}]}' --query policyText --output text
{"Version":"2012-10-17","Statement":[{"Sid":"ProductionPulls","Effect":"Allow","Principal":{"AWS":"arn:aws:iam::444455556666:root"},"Action":["ecr:BatchGetImage","ecr:GetDownloadUrlForLayer"]}]}
```

moto stores the policy and returns it, and that is all it does with it. It evaluates no policy by
default, so a pull it would have refused cannot be shown here. On AWS both halves have to agree:
the repository has to allow the other account, and an IAM policy in the other account has to
allow its role to make the two calls.

## One region, and the ways out of it

A repository lives in one region, and so do its layers. A cluster in `us-east-1` can pull from
`sa-east-1`, but every pull crosses the continent: it is slower, and AWS charges for data that
leaves a region, which it does not for a pull that stays inside one. Teams that run in several
regions configure **replication** on the registry, which copies each image to the other regions
or accounts as it is pushed, so every cluster pulls from its own region.

Two more kinds of registry are worth recognising by name, though this lesson does not use them:

- **ECR Public**, at `public.ecr.aws`, is where AWS and others publish images anybody can pull
  without an account. The Lambda base image that lesson 14 runs, `public.ecr.aws/lambda/python`,
  comes from there.
- **A pull through cache rule** makes your private registry fetch an image from an upstream
  registry, such as ECR Public or Docker Hub, the first time it is asked for, and keep a copy.
  Production then pulls from your own account rather than from the internet, and keeps running
  on the day the upstream registry is slow or limits how often you may pull.

Neither was run here. moto implements the private registry's API and nothing on `public.ecr.aws`.
