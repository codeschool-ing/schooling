---
title: "User data: a script handed over at launch"
version: 1
---

A common first picture of user data is a setting that configures the instance, the way a launch
template sets its type. **It is nothing of the sort: user data is a piece of text that EC2 stores
beside the instance and hands back to it on request.** EC2 never reads it and never runs it.
What runs it is a program inside the image, **cloud-init** on Amazon Linux, Ubuntu and nearly
every other published Linux AMI, which fetches the text early in the first boot and acts on it.

That division decides everything else in this section. The limits are EC2's, because EC2 stores
the text. The behaviour is cloud-init's, because cloud-init runs it. And who can read it is
whoever can ask EC2 or the instance, which is more people than most authors of user data assume.

## A script for the first boot

If the text begins with `#!`, cloud-init runs it as a script, as root, once. Here is one for a
small web server on Amazon Linux 2023. Copy it with the button on the block and save it as
`~/aws/first-boot.sh`:

```schooling-example
{"language": "sh", "file": "first-boot.sh", "parts": [{"code": "#!/bin/bash\nset -euo pipefail\n\n", "note": "The first two characters are what tell cloud-init this is a script to run rather than a configuration to read. `set -euo pipefail` stops it at the first command that fails, so a broken install does not carry on into a half-configured server."}, {"code": "dnf install -y nginx\n\n", "note": "User data runs as root, so there is no `sudo`. `dnf` is Amazon Linux 2023's package manager; on an Ubuntu image this line would be `apt-get`."}, {"code": "TOKEN=$(curl -sS -X PUT http://169.254.169.254/latest/api/token \\\n  -H 'X-aws-ec2-metadata-token-ttl-seconds: 300')\n", "note": "A session token from the instance's metadata service, valid for 300 seconds. Section 04 says why a `PUT` comes before every read."}, {"code": "ZONE=$(curl -sS -H \"X-aws-ec2-metadata-token: $TOKEN\" \\\n  http://169.254.169.254/latest/meta-data/placement/availability-zone)\n\n", "note": "The instance asks which Availability Zone it is in, with the token in a header. Nothing about the zone was written into the script: every instance launched from it finds out its own."}, {"code": "echo \"<h1>served from $ZONE</h1>\" > /usr/share/nginx/html/index.html\nsystemctl enable --now nginx\n", "note": "The page names the zone, so when a load balancer spreads requests over several instances you can see which one answered. `enable --now` starts nginx now and at every later boot, which matters because this script will not run again."}]}
```

Two lines in it read the instance's own metadata, which is the subject of the next two sections.
They are here because they are the usual reason user data exists at all: **one script, launched
on many instances, each of which works out its own facts at boot** rather than having them typed
in. A script with the zone written into it would be right on one instance and wrong on the rest.

cloud-init also reads a second format, a YAML file that starts with `#cloud-config` and declares
packages, users and files instead of running commands. It is the better choice for anything
longer than this script, and the format is cloud-init's own rather than AWS's, documented on
cloud-init's site. Everything below about how EC2 stores and hands out the text applies to both.

## Handing it over

The image is an Amazon Linux 2023 AMI from moto's catalogue; lesson 2 says what that catalogue
is and how to find the one AWS publishes today. The script goes in with `--user-data`:

```
ana@laptop:~/aws$ AMI=$(aws ec2 describe-images --owners amazon --filters Name=name,Values=al2023-ami-2023.12.20260727.0-kernel-6.12-x86_64 --query "Images[0].ImageId" --output text)
ana@laptop:~/aws$ echo "$AMI"
ami-0629d059c178d0eac
ana@laptop:~/aws$ ID=$(aws ec2 run-instances --image-id "$AMI" --instance-type t3.micro --user-data file://first-boot.sh --query "Instances[0].InstanceId" --output text)
ana@laptop:~/aws$ echo "$ID"
i-667121efeb55d85d5
```

**EC2 stores user data base64-encoded**, and the AWS CLI did the encoding: `file://` reads the
file and the CLI encodes it on the way. Asking for it back shows the stored form, and decoding it
shows the script:

```
ana@laptop:~/aws$ aws ec2 describe-instance-attribute --instance-id "$ID" --attribute userData --query UserData.Value --output text | cut -c1-60
IyEvYmluL2Jhc2gKc2V0IC1ldW8gcGlwZWZhaWwKCmRuZiBpbnN0YWxsIC15
ana@laptop:~/aws$ aws ec2 describe-instance-attribute --instance-id "$ID" --attribute userData --query UserData.Value --output text | base64 -d | head -4
#!/bin/bash
set -euo pipefail

dnf install -y nginx
ana@laptop:~/aws$ wc -c < first-boot.sh
395
ana@laptop:~/aws$ base64 -w0 first-boot.sh | wc -c
528
```

The 395 bytes of the script became 528 characters of base64, which is the four-for-three that
base64 always costs. **The limit AWS documents is 16 KB of user data in its raw form, before it is
encoded**, so the 528 characters are not what counts against it. moto does not hold you to the
limit at all, and launches with a script of 20,000 bytes:

```
ana@laptop:~/aws$ yes "echo padding" | head -c 20000 > big.sh
ana@laptop:~/aws$ aws ec2 run-instances --image-id "$AMI" --instance-type t3.micro --user-data file://big.sh --query "Instances[0].State.Name" --output text
pending
```

AWS refuses that launch. A script that needs more than 16 KB is telling you to bake the software into an image, which
is what lesson 2 does, or to have a small script download the rest.

## It runs once

**cloud-init runs a user-data script on the first boot of each instance, and not on a reboot or a
stop and start.** It records that the instance has done it, so a reboot skips the script. That is
the right behaviour for installing packages, and the wrong place for anything that has to happen
at every start: that belongs in a service the script installs, which is why the example enables
nginx rather than only starting it.

It also means **changing the user data of a running instance changes nothing that has happened.**
AWS lets you replace it only while the instance is stopped. Even then cloud-init will not run the
new script on the next start, because the instance has already had its first boot. moto
checks neither part. It accepted a replacement on an instance in the `running` state:

```
ana@laptop:~/aws$ printf "#!/bin/bash\necho changed\n" > second.sh
ana@laptop:~/aws$ aws ec2 modify-instance-attribute --instance-id "$ID" --attribute userData --value "$(base64 -w0 second.sh)"
ana@laptop:~/aws$ aws ec2 describe-instances --instance-ids "$ID" --query "Reservations[0].Instances[0].State.Name" --output text
running
ana@laptop:~/aws$ aws ec2 describe-instance-attribute --instance-id "$ID" --attribute userData --query UserData.Value --output text | base64 -d
#!/bin/bash
echo changed
```

On AWS that call is refused until the instance stops. The way to give a fleet a new script is not
to edit the old instances but to launch new ones with it, which is what a launch template version
and an instance refresh do in lesson 4.

When a first boot goes wrong, the instance's own log is where to look. cloud-init writes what the
script printed to `/var/log/cloud-init-output.log`, and `cloud-init status --wait` waits for
the first boot to finish and says whether it failed. moto runs nothing, so neither exists here.

## It is not a secret

The decoding above needed nothing but permission to describe the instance. **Anybody allowed
`ec2:DescribeInstanceAttribute` in the account reads the user data in full**, and on the instance
any process that can reach the metadata service reads it too, at `/latest/user-data`. A database
password or an API key written into user data is written into a place many things can read, and it
stays there for the life of the instance.

The script above carries no secret, and that is the pattern to keep. What an instance needs to
authenticate comes from the role attached to it, which `aws-foundations` lesson 10 attached as an
instance profile, and a secret proper is fetched at boot from Secrets Manager with that role's
permission, which `aws-operations` lesson 17 teaches. Both of those go through the metadata
service, which is where the next section starts.
