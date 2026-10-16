---
title: Scanning, and the gate that reads it
version: 1
---

An image carries an operating system's packages and a language's libraries, and some of them have
published vulnerabilities. **ECR can look**, and it does it two ways. **Basic scanning** checks the
operating system's packages against public vulnerability databases, when the image is pushed or when
asked, and costs nothing. **Enhanced scanning** hands the repository to Amazon Inspector, which also
reads the language packages (the Python wheels, the npm modules) and, more importantly, **scans
again whenever a new vulnerability is published**, so an image that was clean on Monday can have a
finding on Thursday without anybody pushing anything.

## Scan, and read the result

```
ana@laptop:~/aws/ecr$ aws ecr put-image-scanning-configuration --repository-name shop/api --image-scanning-configuration scanOnPush=true --query imageScanningConfiguration
{
    "scanOnPush": true
}
ana@laptop:~/aws/ecr$ aws ecr start-image-scan --repository-name shop/api --image-id imageTag=1.4.1 --query imageScanStatus
{
    "status": "IN_PROGRESS"
}
ana@laptop:~/aws/ecr$ aws ecr describe-image-scan-findings --repository-name shop/api --image-id imageTag=1.4.1 --query 'imageScanFindings.findings[].[name,severity,attributes[?key==`package_name`].value|[0]]' --output text
CVE-9999-9999	HIGH	moto_fake
```

`scanOnPush` makes every later push start a scan by itself; `start-image-scan` asks for one now. The
finding is worth a second look before anything else: `CVE-9999-9999`, in a package called
`moto_fake`, at version 9.9.9. **moto returns this one invented finding for every image it is asked
about.** It does not read the image, and it has no image to read. What it gives the lab is a finding
with the shape of a real one, which is all the next part needs.

## A gate that refuses

A scan that nobody reads protects nothing. The useful version is a step in the pipeline, after the
push and before the deployment, that **fails the run when the image has a finding above a line the
team chose**. This one refuses anything critical or high:

```sh
# scan-gate.sh REPOSITORY TAG: refuse an image with a critical or high finding
set -eu
repo=$1 tag=$2
aws ecr wait image-scan-complete --repository-name "$repo" --image-id imageTag="$tag"
counts=$(aws ecr describe-image-scan-findings --repository-name "$repo" \
  --image-id imageTag="$tag" --query imageScanFindings.findingSeverityCounts)
echo "findings: $counts"
blocking=$(echo "$counts" | jq '(.CRITICAL // 0) + (.HIGH // 0)')
if [ "$blocking" -gt 0 ]; then
  echo "refusing $repo:$tag: $blocking critical or high finding(s)"
  exit 1
fi
echo "$repo:$tag may be deployed"
```

`wait image-scan-complete` polls until the scan finishes, because a scan takes time on ECR.
`findingSeverityCounts` is a small object of counts by severity, so the script adds two of them,
treating a missing severity as zero, and exits with status 1 when the sum is above zero. In the
buildspec of lesson 1 it would be one line in `post_build`, after the push: a failed `post_build`
fails the build, and the deploy stage never starts.

Against moto's placeholder finding:

```
ana@laptop:~/aws/ecr$ bash scan-gate.sh shop/api 1.4.1; echo "exit status $?"
findings: {
    "HIGH": 1
}
refusing shop/api:1.4.1: 1 critical or high finding(s)
exit status 1
```

**The gate fired on a finding that does not exist**, which is as much as a lab can show: the logic
works, and the input is fake. On a real image the same script reads real counts.

## Where to draw the line

A gate on every finding of every severity blocks every deployment within a week, because a base
image always has something; the team then turns the gate off, and protection drops to nothing.
Three habits keep a gate on:

- **refuse on critical and high**, and report medium and low somewhere a person reads them;
- **rebuild on a fresh base image regularly**, because most findings are fixed upstream, and an
  image rebuilt from `python:3.12-slim` this week inherits the fixes;
- **allow a named exception with an end date**, when a finding is in a package the service never
  calls, rather than lowering the line for everybody.

Enhanced scanning's continuous rescans also mean a finding can arrive on an image already running in
production. That finding goes to Security Hub, which is lesson 19, where deciding what to fix first
is the whole subject.

## What it costs

```
ana@laptop:~/aws/ecr$ python3 price.py AmazonECR data storage
AmazonECR, sa-east-1, published 2026-09-11
  SAE1-TimedStorage-ByteHrs                0.100000 USD per GB-Mo      $0.10 per GB-month of data storage
ana@laptop:~/aws/ecr$ python3 price.py AmazonInspectorV2 SAE1-container-image
AmazonInspectorV2, sa-east-1, published 2026-10-15
  SAE1-container-image-initial-scan        0.110000 USD per Resource-assessment $0.11 per Resource-assessment for container-image-initial-scan in South America (Sao Paulo)
  SAE1-container-image-initial-scan-free-trial     0.000000 USD per Resource-assessment $0.0 per Resource-assessment for container-image-initial-scan-free-trial in South America (Sao Paulo)
  SAE1-container-image-re-scan             0.010000 USD per Resource-assessment $0.01 per Resource-assessment for container-image-re-scan in South America (Sao Paulo)
  SAE1-container-image-re-scan-free-trial     0.000000 USD per Resource-assessment $0.0 per Resource-assessment for container-image-re-scan-free-trial in South America (Sao Paulo)
```

Storage is ten cents per gigabyte a month. Enhanced scanning is billed by Inspector: eleven cents
for an image's first scan and one cent for each rescan, so a repository receiving 400 images a month
pays 44 USD in first scans before any rescan. The list carries a free trial line too, which applies
to an account's first days with Inspector and is not a price.
