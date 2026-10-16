---
title: "Requiring IMDSv2: per instance, per template, per account"
version: 1
---

IMDSv2 protects nothing while IMDSv1 still answers beside it. **An instance with `HttpTokens` set
to `optional` accepts both, so the forged `GET` of the last section still works on it**, and
`optional` is what an instance gets when nobody says otherwise and its image does not either. The
work of this section is making `required` the state nobody has to remember, at four levels, from
one instance up to the whole organisation.

## One instance, at launch

`--metadata-options` takes the three settings that matter, and the answer shows them applied:

```
ana@laptop:~/aws$ aws ec2 run-instances --image-id "$AMI" --instance-type t3.micro --metadata-options HttpTokens=required,HttpPutResponseHopLimit=1,HttpEndpoint=enabled --query "Instances[0].[InstanceId,MetadataOptions]"
[
    "i-1ec13ad5f7dd6ffd8",
    {
        "State": "applied",
        "HttpTokens": "required",
        "HttpPutResponseHopLimit": 1,
        "HttpEndpoint": "enabled",
        "HttpProtocolIpv6": "disabled",
        "InstanceMetadataTags": "disabled"
    }
]
```

`HttpTokens=required` refuses any read without a token. `HttpPutResponseHopLimit=1` keeps the
token on the instance, as the last section drew. `HttpEndpoint=enabled` keeps the service on at
all; `disabled` turns it off, which is right for an instance that has no role and no use for its
own metadata, and wrong for nearly everything else, since the SDKs fall silent without it.

## One instance, while it runs

An instance launched without the options says `optional`, and can be changed without a stop or a
reboot:

```
ana@laptop:~/aws$ OLD=$(aws ec2 run-instances --image-id "$AMI" --instance-type t3.micro --query "Instances[0].InstanceId" --output text)
ana@laptop:~/aws$ aws ec2 describe-instances --instance-ids "$OLD" --query "Reservations[0].Instances[0].MetadataOptions.HttpTokens" --output text
optional
ana@laptop:~/aws$ aws ec2 modify-instance-metadata-options --instance-id "$OLD" --http-tokens required --http-endpoint enabled
{
    "InstanceId": "i-51e1cd95bf0fae843",
    "InstanceMetadataOptions": {
        "State": "applied",
        "HttpTokens": "required",
        "HttpPutResponseHopLimit": 1,
        "HttpEndpoint": "enabled"
    }
}
```

On AWS the `State` reads `pending` until the change has reached the instance and `applied` after;
moto applies it at once. **Do this to a running fleet only once you know nothing on it still
speaks IMDSv1**, because the call takes effect for every program on the instance at the same
moment. AWS SDKs have spoken IMDSv2 since it was released in 2019, so the programs that break are
old ones: an SDK from before then, a monitoring agent nobody has updated, a shell script with a
bare `curl`. EC2 counts them for you. Every instance publishes a CloudWatch metric,
`MetadataNoToken`, of the metadata reads it answered without a token, and a fleet whose metric has
read zero for a couple of weeks is one where `required` breaks nothing. Reading and alarming on
that metric is `aws-operations` lesson 8; moto keeps no metrics, so it is not shown here.

## Every instance from a template

Setting it per instance is how a fleet ends up with one instance nobody set. **The place for it is
the launch template**, so that every instance launched from it, by a person or by an auto scaling
group, starts with tokens required:

```
ana@laptop:~/aws$ aws ec2 create-launch-template --launch-template-name web --launch-template-data "{\"ImageId\":\"$AMI\",\"InstanceType\":\"t3.micro\",\"MetadataOptions\":{\"HttpTokens\":\"required\",\"HttpPutResponseHopLimit\":1}}" --query LaunchTemplate.LatestVersionNumber
1
ana@laptop:~/aws$ aws ec2 describe-launch-template-versions --launch-template-name web --query "LaunchTemplateVersions[0].LaunchTemplateData.MetadataOptions"
{
    "HttpTokens": "required",
    "HttpPutResponseHopLimit": 1
}
```

Lesson 4 built launch templates and the groups that use them. A new template version with these
options, rolled out by an instance refresh, is also how an existing group moves to IMDSv2 without
anybody touching an instance.

The image can carry the same demand. An AMI registered with `--imds-support v2.0` gives every
instance launched from it `HttpTokens` set to `required`, and **Amazon Linux 2023's images are
published that way**. moto's catalogue copies the names of AWS's images and not that flag:

```
ana@laptop:~/aws$ aws ec2 describe-images --image-ids "$AMI" --query "Images[0].[Name,ImdsSupport]" --output text
al2023-ami-2023.12.20260727.0-kernel-6.12-x86_64	None
```

`None` is moto having no value for the field. It is also why `$OLD`, launched from this same image
a few commands ago, said `optional`; on AWS it would have said `required`.

## Every instance in a Region, and every account

Two levels sit above the template. **The account default** sets the metadata options for every
instance launched in a Region of the account that does not set them itself:
`aws ec2 modify-instance-metadata-defaults --http-tokens required`. It changes nothing already
running, and a launch that names its own options still wins. moto 5.2.3 does not implement it,
and the call fails inside moto rather than with an AWS error:

```
ana@laptop:~/aws$ aws ec2 modify-instance-metadata-defaults --http-tokens required 2>&1 | head -3 | cut -c1-100

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Furth
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Err
```

That `500 Internal Server Error` is moto's, and the command is AWS's documented one; on AWS it
answers with `"Return": true`.

**A policy is the level nobody can forget.** IAM can refuse the launch itself when the request
does not ask for tokens, through the condition key `ec2:MetadataHttpTokens`. This is the shape
AWS documents. It is attached to the people and roles that launch instances, or written as a
service control policy over every account of an organisation:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "RequireImdsV2",
      "Effect": "Deny",
      "Action": "ec2:RunInstances",
      "Resource": "arn:aws:ec2:*:*:instance/*",
      "Condition": {
        "StringNotEquals": { "ec2:MetadataHttpTokens": "required" }
      }
    }
  ]
}
```

A `Deny` wins over any `Allow`, as `aws-foundations` lesson 8 worked through, so a launch that
leaves the tokens optional is refused whoever asks. A second statement denying
`ec2:ModifyInstanceMetadataOptions` to everyone but administrators stops somebody turning it back
afterwards. This policy was not run: moto does not evaluate IAM policies by default, and the
condition key is not one it knows.

## What moto lets through

moto stores what it is given, and that includes values AWS refuses:

```
ana@laptop:~/aws$ aws ec2 modify-instance-metadata-options --instance-id "$OLD" --http-put-response-hop-limit 65 --http-tokens sometimes
{
    "InstanceId": "i-51e1cd95bf0fae843",
    "InstanceMetadataOptions": {
        "State": "applied",
        "HttpTokens": "sometimes",
        "HttpPutResponseHopLimit": 65
    }
}
```

**AWS accepts `optional` or `required` for `HttpTokens`, and a hop limit from 1 to 64.** moto took
`sometimes` and 65 and reported them `applied`. A template or a script that works against moto
has been checked for its shape, not for its values, and the first launch on AWS is where a typo in
one of these is found.
