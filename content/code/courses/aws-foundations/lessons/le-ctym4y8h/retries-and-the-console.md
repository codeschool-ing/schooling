---
title: Retries, the console as a client, and where the course goes next
version: 1
---

**A client that calls AWS has to expect some calls to fail and succeed a moment later, and every
SDK retries them for you.** The same layer that signs and paginates also counts attempts, waits a
little longer each time, and gives up after a limit. This section measures the command line doing
it, places the console among the clients, and closes the course.

## Retries, measured on a call that always fails

moto answers every `rolesanywhere` call with an internal error, as lesson 12 found, which makes it a
reliable failure to watch. The `grep` keeps the attempt header and the retry lines:

```
ana@laptop:~/aws$ aws rolesanywhere list-trust-anchors --debug 2>&1 | grep -oE "'amz-sdk-request': b'[^']*'|Retry needed, retrying request after delay of: [0-9.]*|reached max retries: [0-9]*" | head -6
'amz-sdk-request': b'attempt=1'
Retry needed, retrying request after delay of: 0.5274532777405271
'amz-sdk-request': b'ttl=20261016T190257Z; attempt=2; max=3'
Retry needed, retrying request after delay of: 1.4379720271632055
'amz-sdk-request': b'ttl=20261016T190257Z; attempt=3; max=3'
reached max retries: 2
```

**Three attempts, then the error**, which says it reached two retries. Each request tells the
service which attempt it is with `amz-sdk-request`. The delays before the second and third are
random and short, because the waiting doubles from a small base and a random part keeps a thousand
clients that failed together from retrying together. The limit is a setting:

```
ana@laptop:~/aws$ AWS_MAX_ATTEMPTS=1 aws rolesanywhere list-trust-anchors --debug 2>&1 | grep -c "Sending http request"
1
```

**One request, no retry.** The same pair of settings exists in every SDK and in `~/.aws/config`,
as `max_attempts` and `retry_mode`; the program in the previous section wrote them in its `Config`.

AWS's documentation describes three retry modes, and the default of AWS CLI 2 is the second:

| mode | what it does |
|---|---|
| `legacy` | the older SDKs' behaviour, with fewer kinds of error retried |
| `standard` | 3 attempts by default, exponential backoff with jitter, a cap on the wait |
| `adaptive` | `standard`, plus a rate the client lowers on its own when it is throttled |

**Throttling is the failure retries exist for.** Every API has a rate per account and region, and a
caller above it gets `ThrottlingException`, `Throttling` or `TooManyRequestsException`, depending on
the service, often with HTTP 400 or 429. A retry with backoff usually gets through; a program that
loops without one makes it worse for itself and for everybody else in the account. moto never
throttles, so this paragraph comes from AWS's documentation and was not run. A request that failed
for a reason a retry cannot fix, such as `AccessDenied` or a malformed parameter, is not retried.

## The console is a client too

**The AWS Management Console is a web application that, behind its screens, makes the same signed
API calls**, with temporary credentials for whoever signed in to it: a root user, an IAM user, or a
role reached through Identity Center as in lesson 11. Opening the EC2 page lists instances with
`DescribeInstances`; pressing a button to launch one sends `RunInstances`. That is why a permission
the console lacks shows up as the same `AccessDenied` a command would get, and why the console can
do nothing that the API does not offer.

It was not run here. **The console needs an account and a browser**, and this course draws no
pictures of it, because its screens change on AWS's schedule while the calls behind them do not.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l26-clients\" aria-label=\"Four clients, one API. The console in a browser, the AWS command line, a program using boto3 and curl with --aws-sigv4 each send a signed HTTPS request to the same service endpoint. The service evaluates the same IAM policies for all of them, and CloudTrail records each call, with the client's User-Agent.\"><defs><marker id=\"l26-clients-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l26-clients-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"26.0\" width=\"190.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the console</text><text x=\"125.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">in a browser</text><path d=\"M222.0 50.0 L348.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-clients-af-ah-phosphor)\"></path><rect x=\"30.0\" y=\"86.0\" width=\"190.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">aws</text><text x=\"125.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the command line</text><path d=\"M222.0 110.0 L348.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-clients-af-ah-phosphor)\"></path><rect x=\"30.0\" y=\"146.0\" width=\"190.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">boto3</text><text x=\"125.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a program</text><path d=\"M222.0 170.0 L348.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-clients-af-ah-phosphor)\"></path><rect x=\"30.0\" y=\"206.0\" width=\"190.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">curl --aws-sigv4</text><text x=\"125.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">by hand</text><path d=\"M222.0 230.0 L348.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-clients-af-ah-phosphor)\"></path><rect x=\"350.0\" y=\"100.0\" width=\"160.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"430.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the service</text><text x=\"430.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">same policies</text><text x=\"430.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">for all four</text><path d=\"M512.0 140.0 L558.0 140.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l26-clients-af-ah-amber)\"></path><rect x=\"560.0\" y=\"110.0\" width=\"140.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CloudTrail</text><text x=\"630.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one record each</text><text x=\"430.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a signed HTTPS request</text></svg>", "caption": "The console is one more client: it signs the same calls, and is judged and recorded the same way."}
```

## CloudTrail records the call, whoever made it

Every call that reaches AWS, from the console, the command line, an SDK or `curl`, is the kind of
event **AWS CloudTrail** records: who made it, from which address, with which key or role session,
when, and what was asked. The record carries the client's `User-Agent`, so it shows which client
it was, and it is the same record either way. That is the trail lesson 12 searched by key id after
a leak. CloudTrail itself belongs to the `aws-operations` course, and moto 5.2.3 answers
`lookup-events` with an internal error, so it was not run here.

## Where this course leaves you

Twenty-six lessons ago the lab was two programs on a laptop. Since then it has held an organisation
of accounts, the policies and roles that decide who may do what in them, the bill and the price
list, the networks the packets cross, and the API underneath all of it. **The vocabulary is the
part that lasts**: account, principal, policy, role, region, subnet, request.

::: track cloud-engineering
In this track two AWS courses follow. `aws-compute` puts machines, containers and functions into the
accounts and networks built here, and `aws-operations` delivers to them, watches them and reads the
bill, with CloudTrail among its tools. Both assume the identity and network of this course, so the
profiles, roles and VPCs you made are where they start.
:::

::: track data
In this track one AWS course follows, `aws-data`: the storage, the managed databases and the
analytics services the shop's data will live in. It assumes the account model and the identity of
this course, so the roles and policies here are what its pipelines will wear.
:::

::: track devops
In this track this course is the whole of AWS. The courses that follow, `iac`, `testing-cicd`,
`gitops` and `observability`, are written for any provider; the accounts, the roles for machines and
pipelines, and the networks you built here are what you point their tools at.
:::

::: track *
From here the AWS courses split by subject: `aws-compute` for what runs, `aws-operations` for
delivering and watching it, `aws-data` for where the data lives. Each assumes this one, and none
repeats it.
:::
