---
title: Copying, sharing and retiring an image
version: 1
---

An image looks finished once it launches. **An image has a life after it is built**: it is copied
to the regions that need it, shared with the accounts that launch it, marked old when a newer one
replaces it, and finally deregistered. The last step is the one people get half right, because
deregistering an image does not delete what you were paying for.

## Copying to another region

An AMI id means something in one region only, so a machine in N. Virginia cannot launch the image
built in São Paulo. It has to be copied:

```
ana@laptop:~/aws$ aws ec2 copy-image --source-region sa-east-1 --source-image-id "$IMG" --region us-east-1 --name web-2026-10-16
{
    "ImageId": "ami-fafccb322fa427951"
}
ana@laptop:~/aws$ aws ec2 describe-images --owners self --region us-east-1 --query "Images[].[ImageId,Name,State]" --output text
ami-fafccb322fa427951	web-2026-10-16	available
```

The copy has an id of its own, and it is a separate image with **separate snapshots, stored and
billed in the second region**. Nothing links the two afterwards: deregistering the original leaves
the copy, and a fix to one is not a fix to the other. A copy is also the moment to encrypt an image
that was not, by naming a KMS key with `--encrypted --kms-key-id`; the copy's snapshots are then
encrypted with that key.

## Sharing with another account

An organisation commonly builds images in one account and launches them in others: development,
staging, production. An image is private to its owner until a **launch permission** names another
account:

```
ana@laptop:~/aws$ aws ec2 modify-image-attribute --image-id "$IMG" --launch-permission "Add=[{UserId=111122223333}]"
ana@laptop:~/aws$ aws ec2 describe-image-attribute --image-id "$IMG" --attribute launchPermission
{
    "ImageId": "ami-a9a13e442ffd8c0ff",
    "LaunchPermissions": [
        {
            "UserId": "111122223333"
        }
    ]
}
```

`111122223333` is the example account id AWS uses in its documentation. Once named, that account can
launch the image by its id, and it does not become the owner: it cannot change the image's
permissions or deregister it, and if you deregister it, its next launch fails, although instances
it already runs carry on. To keep a copy of its own, the
other account copies the image, which makes it the owner of the copy.

Three things go wrong here on AWS, and moto checks none of them:

- **An image encrypted with the default AWS-managed key cannot be shared.** That key is private to
  its account. Images meant to be shared are encrypted with a customer-managed KMS key, and the key
  policy grants the other account the use of it, which is `aws-foundations` lesson 7's policy
  grammar applied to a key.
- **Sharing with everybody** is the same command with `Group=all`, and it publishes every byte of
  the image, including any secret somebody baked into it. AWS has an account-level setting, *block
  public access for AMIs*, that refuses it; check that it is on in every account that builds images.
- **Sharing with an organisation** names an AWS Organizations ARN instead of an account, so a new
  account in it can launch the image the day it is created.

## Marking it old

When a newer image replaces this one, nothing tells the people still launching the old id. AWS's
answer is a **deprecation date**:

```
ana@laptop:~/aws$ aws ec2 enable-image-deprecation --image-id "$IMG" --deprecate-at 2027-04-16T00:00:00Z

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

moto does not implement it and fails with an error of its own, so what follows is AWS's documented
behaviour, not run here. After the date, the image no longer appears when other accounts list or
search for images, unless they ask for deprecated ones as well. It **still launches** for anybody
who has its id, so nothing that depends on it breaks on the day. That is the purpose: new users
stop finding it, existing users keep working, and somebody reading a template has a date to argue
from.

## Retiring it

An image is removed by deregistering it. Try to delete its snapshot first, and AWS and moto agree:

```
ana@laptop:~/aws$ aws ec2 delete-snapshot --snapshot-id "$SNAP"

aws: [ERROR]: An error occurred (InvalidSnapshot.InUse) when calling the DeleteSnapshot operation: The snapshot snap-ea6b97d76b42a5e1a is currently in use by ami-a9a13e442ffd8c0ff
```

The snapshot belongs to a registered image, so it cannot go first. Deregistering the image is the
next step, and the image is gone at once:

```
ana@laptop:~/aws$ aws ec2 deregister-image --image-id "$IMG"
{
    "Return": true
}
ana@laptop:~/aws$ aws ec2 describe-images --image-ids "$IMG"
{
    "Images": []
}
ana@laptop:~/aws$ aws ec2 describe-snapshots --snapshot-ids "$SNAP" --query "Snapshots[].[SnapshotId,VolumeSize,Description]" --output text
snap-ea6b97d76b42a5e1a	15	Created by CreateImage(i-52f3615249060ee52) for ami-a9a13e442ffd8c0ff
```

**The snapshot is still there, and still billed.** Deregistering removes the record and leaves the
blocks, because AWS cannot know whether you meant to keep them. An account where images were
deregistered for a year and their snapshots never deleted pays for every one of them; at 0.068 USD
per GB-month on the price sheet of 16 October 2026, 365 nightly images of 15 GB each, if every
snapshot were stored whole, would be 372.30 USD a month for nothing anybody can launch.

moto then shows one more leniency:

```
ana@laptop:~/aws$ aws ec2 run-instances --image-id "$IMG" --instance-type t3.micro --query "Instances[0].[InstanceId,ImageId]" --output text
i-e34f66e3291d7cc0a	ami-a9a13e442ffd8c0ff
```

It launched an instance from an image that no longer exists. **AWS refuses a launch from a
deregistered image.** Then the snapshot, which can go now:

```
ana@laptop:~/aws$ aws ec2 delete-snapshot --snapshot-id "$SNAP"
ana@laptop:~/aws$ aws ec2 describe-snapshots --snapshot-ids "$SNAP"

aws: [ERROR]: An error occurred (InvalidSnapshot.NotFound) when calling the DescribeSnapshots operation: None
```

The order is therefore fixed: deregister the image, then delete the snapshots its mapping named,
which is why it is worth reading the mapping before deregistering, as the previous section did.
Image Builder and most image pipelines can do both on a schedule, keeping the last few images and
removing the rest. Lesson 4 is where you find out which images are still in use, because a launch
template that names a deregistered image fails at the next scale-out, not at the moment the image
was removed.
