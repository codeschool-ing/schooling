---
title: Elastic Beanstalk, and the stack it builds for you
version: 1
---

Elastic Beanstalk dates from 2011, three years before ECS and Lambda, and it is still open to
anybody. **It is not a place your code runs.** It is a builder: you hand it an
application and the name of a platform, and it creates the EC2 instances, the auto scaling group
and the load balancer of lessons 1 to 5, wires them together, puts your code on the instances and
keeps them running. Everything it creates is an ordinary resource in your account, which you can
list, read and, unwisely, change by hand.

That is the difference from App Runner, and it decides almost everything later in this lesson.
App Runner hides the machines; Beanstalk builds them where you can see them.

## Four words

Beanstalk's vocabulary is small, and each word is a thing the API keeps:

- an **application** is a name and a folder for everything else. It runs nothing;
- an **application version** is one build of your code, a zip file in S3 with a label such as `v2`;
- an **environment** is one running copy of one version, with its own address: `shop-prod` and
  `shop-staging` are two environments of the application `shop`;
- a **platform** is what the instances run underneath your code: an operating system, a language
  runtime and a web server, maintained by AWS and named with a version of its own.

**The platform is the part that ages.** Its name carries two versions, the platform's and the
language's, and moto ships a list of them, taken from AWS at some point in the past:

```
ana@laptop:~/aws$ aws elasticbeanstalk list-available-solution-stacks --query "length(SolutionStacks)"
54
ana@laptop:~/aws$ aws elasticbeanstalk list-available-solution-stacks --query "SolutionStacks[?contains(@, \`Python\`)]"
[
    "64bit Amazon Linux 2023 v4.6.0 running Python 3.11",
    "64bit Amazon Linux 2023 v4.6.0 running Python 3.9",
    "64bit Amazon Linux 2023 v4.6.0 running Python 3.12",
    "64bit Amazon Linux 2023 v4.6.0 running Python 3.13",
    "64bit Amazon Linux 2 v3.3.14 running Python 3.8"
]
```

Five of them run Python: four on Amazon Linux 2023 at platform version 4.6.0, and one on Amazon
Linux 2 at 3.3.14. Those 54 names are moto's copy and not today's catalogue; on AWS the same call
answers with the platforms current in your region, and the version numbers move every few weeks. What that movement
asks of you is the subject of the next section.

## An application and an environment, in moto

The application is a name and a description:

```
ana@laptop:~/aws$ aws elasticbeanstalk create-application --application-name shop --description "the shop web app"
{
    "Application": {
        "ApplicationArn": "arn:aws:elasticbeanstalk:sa-east-1:123456789012:application/shop",
        "ApplicationName": "shop"
    }
}
```

The environment names the application and the platform:

```
ana@laptop:~/aws$ aws elasticbeanstalk create-environment --application-name shop --environment-name shop-prod --solution-stack-name "64bit Amazon Linux 2023 v4.6.0 running Python 3.12"
{
    "EnvironmentName": "shop-prod",
    "EnvironmentId": "",
    "ApplicationName": "shop",
    "VersionLabel": "1",
    "SolutionStackName": "None",
    "PlatformArn": "TODO",
    "EndpointURL": "",
    "CNAME": "",
    "DateCreated": "2026-10-16T16:20:05.417494+00:00",
    "DateUpdated": "2026-10-16T16:20:05.417505+00:00",
    "Status": "Ready",
    "AbortableOperationInProgress": false,
    "Health": "Grey",
    "HealthStatus": "No Data",
    "Tier": {
        "Name": "WebServer",
        "Type": "Standard",
        "Version": "1.0"
    },
    "EnvironmentLinks": [],
    "EnvironmentArn": "arn:aws:elasticbeanstalk:sa-east-1:123456789012:environment/shop/shop-prod"
}
```

**Read this answer as moto's, field by field.** `EnvironmentId` is empty where AWS returns an id
such as `e-` followed by ten characters. `SolutionStackName` says `None` although the request named
one, and `PlatformArn` says `TODO`, which is a note moto's authors left for themselves. `CNAME` is
empty where AWS fills in the environment's address, a name under `elasticbeanstalk.com` that
carries the region. And `Status` is `Ready` at once, where AWS answers `Launching` and spends
several minutes building before it says anything else.

Then ask for the machines that environment should have:

```
ana@laptop:~/aws$ aws ec2 describe-instances --query "Reservations[].Instances[].InstanceId"
[]
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[].AutoScalingGroupName"
[]
ana@laptop:~/aws$ aws elbv2 describe-load-balancers --query "LoadBalancers[].LoadBalancerName"
[]
ana@laptop:~/aws$ aws cloudformation list-stacks --query "StackSummaries[].StackName"
[]
```

**Four empty lists.** moto kept two records and created nothing behind them. That is the honest
limit of this section: everything below about what Beanstalk builds is AWS's documented behaviour,
and none of it happened here.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"On the left, the application shop, holding two application versions in S3, v1 and v2, and two environments, shop-staging and shop-prod. An arrow leads from shop-prod to what AWS builds for it: one CloudFormation stack holding a load balancer with its target group, an auto scaling group of two EC2 instances each running the platform and version v2, and security groups. Below, two notes: moto keeps the application and the environment as two records, and builds nothing behind them.\"><defs><marker id=\"l22s-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"290\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"35\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">application</text><text x=\"110\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">shop</text><rect x=\"40\" y=\"60\" width=\"250\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"55\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">application versions, in S3</text><rect x=\"55\" y=\"90\" width=\"95\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"102\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v1</text><rect x=\"165\" y=\"90\" width=\"95\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"212\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v2</text><rect x=\"40\" y=\"150\" width=\"250\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"55\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">environments</text><rect x=\"55\" y=\"182\" width=\"110\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-staging</text><rect x=\"175\" y=\"182\" width=\"105\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"227\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-prod</text><path d=\"M282 199 L366 199\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l22s-amber)\"></path><rect x=\"370\" y=\"20\" width=\"330\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"385\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">on AWS: one CloudFormation stack</text><rect x=\"390\" y=\"55\" width=\"290\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">load balancer and target group</text><rect x=\"390\" y=\"110\" width=\"290\" height=\"85\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"405\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">auto scaling group</text><rect x=\"405\" y=\"140\" width=\"125\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"467\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">EC2 instance</text><text x=\"467\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">platform + v2</text><rect x=\"540\" y=\"140\" width=\"125\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"602\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">EC2 instance</text><text x=\"602\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">platform + v2</text><rect x=\"390\" y=\"205\" width=\"290\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">security groups</text><text x=\"20\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">what moto keeps: the application and the environment, as two records</text><text x=\"370\" y=\"290\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">what moto builds behind them: nothing, four empty lists</text></svg>", "caption": "An application holds versions and environments; on AWS each environment is a stack of ordinary resources. In moto it is a record and nothing more."}
```

## What AWS would have built

On AWS, creating that environment starts a **CloudFormation stack** whose name carries the
environment's id, and the stack creates the rest. For a load-balanced web server environment that
means a launch template and an auto scaling group as in lesson 4, with the instances it keeps. In
front of them goes a load balancer with its listener and target group, as in `aws-foundations`
lesson 22, and security groups guard both; the console and the EB command line choose an
Application Load Balancer. Your versions
go into an S3 bucket Beanstalk creates for the region. A *single-instance* environment
skips the load balancer and the group's spare capacity, which is cheaper and is fine for a staging
copy that nobody depends on.

**Beanstalk itself costs nothing**; you pay for those resources at the prices of lesson 1's sheet.
A small production environment of two `t4g.medium` behind a load balancer is two instances at
0.0536 an hour each before the balancer is counted, which is 2 × 0.0536 × 730 = 78.26 USD a month.
The load balancer's own price is not on this course's sheet, and `aws-foundations` lesson 22 is
where it is priced.

Deploying a new version is the step moto does not reach at all:

```
ana@laptop:~/aws$ aws elasticbeanstalk create-application-version --application-name shop --version-label v2

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

On AWS that call names a zip in S3 (`--source-bundle S3Bucket=…,S3Key=…`), and
`update-environment --version-label v2` then rolls it onto the instances. How it rolls is a choice,
and it is where the next section starts.
