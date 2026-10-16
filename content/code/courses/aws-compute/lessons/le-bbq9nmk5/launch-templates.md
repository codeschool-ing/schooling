---
title: The launch template, and its versions
version: 1
---

A launch template looks like a saved form: the answers to `run-instances`, kept under a name so
nobody has to type them again. That picture is right about what it holds and wrong about how it
changes. **A launch template is a numbered series of versions, and a version never changes.** You
do not edit a template; you add a version to it, and a pointer says which version the name means
when somebody uses it without a number. Everything in this lesson, and most of the next, depends
on that pointer.

## What one version holds

A version holds what one instance is: the image, the instance type, the disks, the metadata
settings, the tags, and optionally the security groups, the instance profile, a key pair and the
user data. It does not hold how many instances there are, or which subnets they go into. Those
belong to whatever launches from it, and in this lesson that is an auto scaling group.

Here is the first version Ana writes, as a file the command line reads. **Copy it with the button
on the block and save it as `~/aws/template.json`**; the notes beside it are not copied.

```schooling-example
{"language": "json", "file": "template.json", "parts": [{"code": "{\n  \"ImageId\": \"ami-0629d059c178d0eac\",\n  \"InstanceType\": \"t3.micro\",\n", "note": "The image and the type, the two things every launch needs. The image id is one of the Amazon Linux 2023 images in moto's catalogue, which lesson 2 explains; on AWS the same image has a different id in every region, so a template is written per region."}, {"code": "  \"BlockDeviceMappings\": [\n    {\n      \"DeviceName\": \"/dev/xvda\",\n      \"Ebs\": {\"VolumeSize\": 20, \"VolumeType\": \"gp3\", \"DeleteOnTermination\": true}\n    }\n  ],\n", "note": "The root volume: 20 GB of gp3, the volume type lesson 3 prices, deleted when the instance is. In a group that matters, because the group terminates instances on its own and a volume left behind for each one is a bill nobody asked for."}, {"code": "  \"MetadataOptions\": {\"HttpTokens\": \"required\", \"HttpEndpoint\": \"enabled\"},\n", "note": "Instance metadata only through a session token, which is IMDSv2. Lesson 7 says what the token stops; the template is where it is enforced, once, for every instance the group will ever launch."}, {"code": "  \"TagSpecifications\": [\n    {\"ResourceType\": \"instance\", \"Tags\": [{\"Key\": \"app\", \"Value\": \"shop\"}]}\n  ]\n}\n", "note": "A tag put on every instance launched from this version. Instances in a group come and go with ids nobody chose, so a tag is how a person, a bill or a filter finds them."}]}
```

It names no security group. On AWS an instance launched into a VPC with no group named gets the
VPC's default security group, which is rarely what you want; a real template names the group that
`aws-foundations` lesson 18 builds, in `SecurityGroupIds`.

The image is moto's, and the command line can say which one it is before anything uses it:

```
ana@laptop:~/aws$ aws ec2 describe-images --image-ids ami-0629d059c178d0eac --query "Images[].[Name,Architecture]" --output text
al2023-ami-2023.12.20260727.0-kernel-6.12-x86_64	x86_64
ana@laptop:~/aws$ aws ec2 create-launch-template --launch-template-name web --version-description "t3.micro, first" --launch-template-data file://template.json
{
    "LaunchTemplate": {
        "LaunchTemplateId": "lt-420bf22b86d1ab21b",
        "LaunchTemplateName": "web",
        "CreateTime": "2026-10-16T16:25:46+00:00",
        "CreatedBy": "arn:aws:iam::123456789012:root",
        "DefaultVersionNumber": 1,
        "LatestVersionNumber": 1,
        "Tags": []
    }
}
```

The answer carries two numbers that are the whole subject of this section: `DefaultVersionNumber`
and `LatestVersionNumber`. With one version both are 1.

## A new version, and what moto leaves out of it

The shop needs a bigger machine. On AWS the short way is to base a new version on an old one and
send only what changes: `--source-version 1` copies everything version 1 holds, and the
`--launch-template-data` given beside it overrides the instance type. Here is that command, and
what moto made of it:

```
ana@laptop:~/aws$ aws ec2 create-launch-template-version --launch-template-name web --source-version 1 --version-description t3.medium --launch-template-data '{"InstanceType": "t3.medium"}' --query LaunchTemplateVersion.VersionNumber
2
ana@laptop:~/aws$ aws ec2 describe-launch-template-versions --launch-template-name web --versions 2 --query "LaunchTemplateVersions[].LaunchTemplateData"
[
    {
        "InstanceType": "t3.medium"
    }
]
```

**That answer is moto's, not AWS's.** AWS would show version 2 with the image, the disk, the
metadata options and the tags of version 1, and `t3.medium` in place of `t3.micro`. moto 5.2.3
ignores `--source-version` and stores only what was sent, so its version 2 has no image at all,
and an instance launched from it in this lab comes back with an empty `ImageId`.

Version 2 cannot be fixed, which is the other half of the lesson. A version is immutable on AWS
as well: it can be deleted with `delete-launch-template-versions`, but never edited. So the way
on is a version 3, written whole. `jq` makes the file from the first one, changing one field, and
this is the form that behaves the same on moto and on AWS:

```
ana@laptop:~/aws$ jq '.InstanceType = "t3.medium"' template.json > template-medium.json
ana@laptop:~/aws$ aws ec2 create-launch-template-version --launch-template-name web --version-description "t3.medium, whole" --launch-template-data file://template-medium.json --query LaunchTemplateVersion.VersionNumber
3
ana@laptop:~/aws$ aws ec2 describe-launch-templates --launch-template-names web --query "LaunchTemplates[].[DefaultVersionNumber,LatestVersionNumber]" --output text
1	3
```

Default 1, latest 3. Nothing launched from version 3 yet, and nothing will until somebody either
asks for it by number or moves the default.

## Two names that are not numbers

Anything that launches from a template can name a version by number, or by one of two names.

- **`$Latest` is the highest number.** It moves by itself, every time anybody adds a version.
- **`$Default` is whichever version the template says.** It moves only when somebody runs
  `modify-launch-template --default-version`, which is a decision with a name in the log beside it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A launch template named web holding versions 1, 2 and 3, with a dashed slot for a version 4 that somebody may add. Version 1 is t3.micro, versions 2 and 3 are t3.medium. The name $Latest points at version 3 and, dashed, at the slot for version 4, because it moves by itself. The name $Default points at version 1, and an auto scaling group that says Version=$Default points at that name.\"><defs><marker id=\"lt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"16\" width=\"300\" height=\"268\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"46\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">launch template web</text><rect x=\"46\" y=\"50\" width=\"268\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"60\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">version 4</text><text x=\"300\" y=\"72\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">whoever adds it</text><rect x=\"46\" y=\"106\" width=\"268\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">version 3</text><text x=\"300\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">t3.medium</text><rect x=\"46\" y=\"162\" width=\"268\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">version 2</text><text x=\"300\" y=\"184\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">t3.medium</text><rect x=\"46\" y=\"218\" width=\"268\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">version 1</text><text x=\"300\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">t3.micro</text><rect x=\"410\" y=\"106\" width=\"110\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"465\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">$Latest</text><path d=\"M410 128 L320 128\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lt-ah)\"></path><path d=\"M440 106 L440 72 L320 72\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#lt-ah)\"></path><text x=\"410\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">moves when anybody adds a version</text><rect x=\"410\" y=\"218\" width=\"110\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"465\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">$Default</text><path d=\"M410 240 L320 240\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lt-ah)\"></path><text x=\"410\" y=\"278\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">moves only when somebody sets it</text><rect x=\"560\" y=\"196\" width=\"144\" height=\"66\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"632\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">auto scaling group</text><text x=\"632\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Version=$Default</text><path d=\"M560 240 L526 240\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lt-ah)\"></path></svg>", "caption": "Three versions and two names. $Latest follows the highest number by itself, so a group that names it launches from whatever was added last; $Default stays where somebody put it. A version, once written, is never edited."}
```

The difference is invisible on the day you write it and decisive on the day somebody adds a
version to try something. **A group that says `$Latest` launches from that experiment at its next
launch**, whether that is a scale-out at three in the morning or a replacement for an instance
that failed, while a group that says `$Default` keeps launching from the version somebody chose.
Either way nothing changes on the instances already running, which is the subject of the last
section of this lesson. The group in the next section uses `$Default`.

## Launch configurations, which you will still meet

Before launch templates there were **launch configurations**: one set of answers, no versions,
usable only by a group. Changing one meant creating a copy under a new name and pointing the
group at it. AWS has been retiring them. They do not offer the instance types released since the
start of 2023, and accounts created after 1 October 2024 cannot create them. You will still find
them in older accounts and older Terraform, and the move is always the same: a launch template
with the same answers, and the group switched to it.
