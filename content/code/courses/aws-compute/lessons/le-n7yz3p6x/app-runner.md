---
title: App Runner, taught from the documentation
version: 1
---

**Nothing in this section was run.** moto has no App Runner, and AWS does not offer it in São Paulo,
so this course can neither imitate it nor price it in `sa-east-1`. What follows is App Runner as
AWS's own documentation describes it, the prices it carries in `us-east-1`, and one command that
shows what moto does when asked:

```
ana@laptop:~/aws$ aws apprunner list-services --region us-east-1

aws: [ERROR]: An error occurred (500) when calling the ListServices operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

A 500 from moto means the service is not implemented. It is not an AWS error, and AWS would never
send an HTML page to the command line.

## The state of the service, with its date

**AWS closed App Runner to new customers on 30 April 2026.** Its release notes gave that date in
advance, and its developer guide carries a page called *AWS App Runner availability change*. On
16 October 2026 that page said three things: the service is no longer open to new customers,
existing customers can continue to use it as normal, and the recommended way to migrate is Amazon
ECS Express Mode. This lesson makes no claim beyond those sentences: not about new features, and not
about what happens to existing services later. If you are reading this after that date, check the
same page before you trust a word of this paragraph.

So the practical reading is short. **An account that never used App Runner cannot start now**, and
yours, if you open one for this course, is such an account. The reason to learn it anyway is that
plenty of companies run services on it, and the model it uses is the clearest example AWS has of a
platform that takes a container and gives back an address. Elastic Beanstalk, in the next section,
is the older and still open example of the same promise.

## Source in, address out

The wrong picture is that App Runner is a smaller Fargate. Fargate, from lesson 9, runs a task you
described, inside a network and behind a load balancer you built. **App Runner asks for less and
decides more.** You give it one of two sources, and the command line's own model of the API lists
them:

```
ana@laptop:~/aws$ aws apprunner create-service --generate-cli-skeleton | jq '{ServiceName, SourceConfiguration: (.SourceConfiguration | keys), InstanceConfiguration: (.InstanceConfiguration | del(.InstanceRoleArn))}'
{
  "ServiceName": "",
  "SourceConfiguration": [
    "AuthenticationConfiguration",
    "AutoDeploymentsEnabled",
    "CodeRepository",
    "ImageRepository"
  ],
  "InstanceConfiguration": {
    "Cpu": "",
    "Memory": ""
  }
}
```

The skeleton is printed by the command line on your laptop, from the API description it ships with,
and reaches nobody. `ImageRepository` is an image in ECR, the registry of lesson 10.
`CodeRepository` is a Git repository, which App Runner builds into an image itself, using a managed
runtime for Python, Node.js, Java and several other languages. `AutoDeploymentsEnabled` makes every new image
or every new commit a deployment, with no pipeline of yours in between.

What comes back is an HTTPS address on `awsapprunner.com`. There is no load balancer to create, no
target group, no security group in front of the service and no subnet to choose. App Runner owns
all of that, which is the point of it and also the first limit you meet: by default the service
reaches the internet and nothing else, and reaching a private database means adding a *VPC
connector*, a resource of its own.

## How it scales, and what is billed

The instance is sized from a short menu. The API documentation gives 0.25 to 4 vCPU and 0.5 to
12 GB of memory, with **1 vCPU and 2 GB as the default**. Scaling is by concurrent requests rather
than by CPU, set in an *auto scaling configuration* with three numbers whose defaults the same
documentation states:

| setting | default | what it decides |
| --- | --- | --- |
| `MaxConcurrency` | 100 | requests one instance takes at a time before App Runner adds another |
| `MinSize` | 1 | instances kept provisioned at all times |
| `MaxSize` | 25 | the most instances that ever serve traffic |

**A provisioned instance is not the same as an active one**, and the bill is built on the
difference. App Runner keeps at least `MinSize` instances provisioned, with your code loaded and
ready, and activates them when requests arrive. You pay for the memory of every provisioned
instance and for the processor of the active ones only. The documentation adds that during a
deployment App Runner temporarily doubles the provisioned instances, so the old and the new code
run side by side.

```
ana@laptop:~/aws$ python3 prices.py containers | tail -n 3
App Runner, us-east-1 (not offered in sa-east-1)
  vCPU, while serving                              0.064  per hour
  memory, provisioned or serving                   0.007  per GB-hour
```

Those are the two lines lesson 1's sheet prints, as published on 16 October 2026. The file behind
them carries three more, and they are worth reading once, straight from the cache:

```
ana@laptop:~/aws$ jq -r '.terms.OnDemand[][].priceDimensions[] | "\(.pricePerUnit.USD)\t\(.unit)\t\(.description)"' ~/.cache/aws-prices/AWSAppRunner-*.json | sort
0.0050000000	Mins	AWS App Runner - Build-mins- US East (N. Virginia)
0.0070000000	hours	AWS App Runner - GB-hours - US East (N. Virginia)
0.0070000000	hours	AWS App Runner - Provisioned - GB-hours - US East (N. Virginia)
0.0640000000	vCPU-hour	AWS App Runner - vCPU - US East (N. Virginia)
1.0000000000	pipelines	AWS App Runner - AutomaticDeployment - US East (N. Virginia)
```

The two memory lines, provisioned and serving, are the same 0.007, which is why the sheet prints them
as one. A build from source costs 0.005 USD a minute of building, and automatic deployment is 1 USD
per *pipeline*, the file's own unit, which AWS's pricing page charges monthly for each service that
has it switched on.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A day of one App Runner service with the default instance of 1 vCPU and 2 GB, on three rows over a 24-hour axis. Row one: a provisioned instance, whose memory is billed every hour of the day whether anybody visits or not. Row two: the same instance active from 08:00 to 18:00, when its vCPU is billed as well. Row three: the service paused from 19:00 to 07:00, when nothing is billed, and billed as above in between.\"><text x=\"20\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">provisioned instance</text><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">memory: 2 GB × 0.007 USD an hour</text><rect x=\"190.0\" y=\"40\" width=\"492.0\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"20\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">active instance</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">vCPU: 1 × 0.064 USD an hour</text><rect x=\"190.0\" y=\"110\" width=\"492.0\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"20\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">paused at night</text><text x=\"20\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">PauseService from 19:00 to 07:00</text><rect x=\"190.0\" y=\"180\" width=\"492.0\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"190.0\" y=\"40\" width=\"492.0\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"436.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">memory billed every hour, visitors or not</text><rect x=\"354.0\" y=\"110\" width=\"205.0\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"456.5\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">vCPU billed while serving</text><rect x=\"333.5\" y=\"180\" width=\"246.0\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"456.5\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">memory and vCPU as above</text><text x=\"261.75\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nothing billed</text><text x=\"630.75\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nothing billed</text><path d=\"M190.0 228 L190.0 234\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"190.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">00:00</text><path d=\"M313.0 228 L313.0 234\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"313.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">06:00</text><path d=\"M436.0 228 L436.0 234\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"436.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">12:00</text><path d=\"M559.0 228 L559.0 234\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"559.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">18:00</text><path d=\"M682.0 228 L682.0 234\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"682.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">24:00</text><path d=\"M190.0 228 L682.0 228\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path></svg>", "caption": "Two meters on one instance. Memory runs whenever the instance is provisioned; the processor runs only while it serves. Only a pause stops both."}
```

Put numbers on the default instance, 1 vCPU and 2 GB, over a month of 730 hours:

- provisioned and idle all month: 2 GB × 0.007 × 730 = **10.22 USD**, memory only;
- active all month: (0.064 + 2 × 0.007) × 730 = 0.078 × 730 = **56.94 USD**;
- active 240 hours and idle the other 490: 240 × 0.078 + 490 × 0.014 = 18.72 + 6.86 = **25.58 USD**.

**It never scales to zero on its own.** `MinSize` cannot go below one, which the API's own model
enforces, so a service nobody visits still pays for its memory. The one way to stop the meter is `PauseService`, which the documentation says
reduces compute capacity to zero and loses state, ephemeral storage included; a paused service
answers nobody until it is resumed. That is a manual act, which makes App Runner cheap for a
service that is busy in office hours and paused at night only if somebody, or a schedule, does the
pausing.
