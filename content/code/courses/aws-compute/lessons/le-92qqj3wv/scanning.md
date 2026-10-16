---
title: Scanning, and what a clean result does not say
version: 1
---

A scanned image with no findings reads as a certificate: this image is safe. **A scan compares the
packages it can identify inside the image with published vulnerabilities, and that is all it
does.** It cannot see a bug in your own code, a password somebody copied into a layer, or a
vulnerability that is published tomorrow. It is worth having for what it does find, which is a
lot: an old base image is usually full of known problems, and the scan names them by package and
version.

## Basic and enhanced

ECR offers two kinds, chosen for the whole registry:

| | basic | enhanced |
|---|---|---|
| run by | ECR itself | Amazon Inspector |
| what it reads | the operating system's packages | the operating system's and the language packages: pip, npm, Maven and others |
| when | on push, or when asked: once per image every 24 hours | on push, and again whenever a vulnerability is published that affects a package inside |
| price | no charge | Inspector's price per image scanned, not on the course's price sheet |

The difference that matters most is the third row. **Basic scanning looks at an image at one
moment.** An image clean on Monday can be vulnerable on Thursday without a byte changing, because a
vulnerability in one of its packages became known on Wednesday. Enhanced scanning keeps looking;
basic scanning only sees it if somebody scans again.

## Scanning in moto

Turning on scan on push for the repository, and asking for a scan of `1.0.1`:

```
ana@laptop:~/aws$ aws ecr put-image-scanning-configuration --repository-name shop/web --image-scanning-configuration scanOnPush=true --query imageScanningConfiguration
{
    "scanOnPush": true
}
ana@laptop:~/aws$ aws ecr start-image-scan --repository-name shop/web --image-id imageTag=1.0.1 --query imageScanStatus
{
    "status": "IN_PROGRESS"
}
ana@laptop:~/aws$ aws ecr describe-image-scan-findings --repository-name shop/web --image-id imageTag=1.0.1 --query 'imageScanFindings.findings[].[name,severity,attributes[?key==`package_name`].value|[0]]' --output text
CVE-9999-9999	HIGH	moto_fake
ana@laptop:~/aws$ aws ecr get-registry-scanning-configuration
{
    "registryId": "123456789012",
    "scanningConfiguration": {
        "scanType": "BASIC",
        "rules": []
    }
}
```

**That finding is a placeholder.** `CVE-9999-9999` is no published vulnerability, and `moto_fake`
is no package: moto answers every scan with the same invented entry, whatever the image contains,
and it could not do otherwise, because it never received a layer to look inside. The shape of the
answer is AWS's: a list of findings, each with a name, a severity and attributes naming the
package and its version, which is what a pipeline reads to decide whether to stop. The registry's
configuration is `BASIC`; enhanced scanning is turned on for the registry with
`aws ecr put-registry-scanning-configuration --scan-type ENHANCED`, and from then on Inspector does
the work and sends the bill.

What to do with a finding is the pipeline's business: `aws-operations` lesson 2 puts the build,
the push and the scan into a pipeline, and that is where a finding becomes a decision. **This lesson's point is narrower: the scan reads packages, and a clean scan describes
the packages it recognised, on the day it ran.**

## What storage costs

The last price that belongs to the registry is storage, from the sheet of lesson 1, as published
on 16 October 2026:

```
ana@laptop:~/aws$ python3 prices.py containers | grep -A3 "EKS and ECR"
EKS and ECR
  EKS cluster, standard support                      0.1  per hour
  EKS cluster, extended support                      0.5  per hour
  ECR storage                                        0.1  per GB-month
```

**ECR charges 0.10 USD per GB-month for what it stores**, and the image of this lesson is about
26 MB. Those numbers make a case for the lifecycle policy that a sentence cannot:

- A pipeline that pushes ten releases of 26 MB every working day and never deletes one stores
  65 GB after 250 working days, 6.50 USD a month, and the number only goes up.
- With the policy of the previous section, the repository keeps the 30 most recent releases:
  0.78 GB, about 0.08 USD a month.

Neither number is large for one image, and that is how a registry becomes a line on the bill
nobody can explain: a hundred repositories nobody cleans are 650 USD a month. A pull to a task or a
node in the same region carries no transfer charge; a pull from another region, or from outside
AWS, is charged as data transfer, which is not on the sheet.

## Cleaning up

A repository with images in it refuses to be deleted, which protects you from a typo:

```
ana@laptop:~/aws$ aws ecr delete-repository --repository-name shop/web

aws: [ERROR]: An error occurred (RepositoryNotEmptyException) when calling the DeleteRepository operation: The repository with name 'shop/web' in registry with id '123456789012' cannot be deleted because it still contains images
ana@laptop:~/aws$ aws ecr delete-repository --repository-name shop/web --force --query repository.repositoryName
"shop/web"
```

`--force` deletes the images with it. On AWS that cannot be undone, and anything that pulls from
the repository fails from that moment.
