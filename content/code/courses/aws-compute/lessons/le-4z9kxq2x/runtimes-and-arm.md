---
title: Runtimes, Arm, and the image instead of the zip
version: 1
---

`--runtime python3.12` reads like a version of Python, and it is more than that. **A managed
runtime is a language version on a particular Amazon Linux, patched by AWS and retired by AWS on a
published schedule.** You choose it; AWS keeps it current; and one day AWS stops keeping it, which
is the part of the choice that has a date on it.

## What a runtime name promises

The names come in families: `python3.12`, `python3.13`, `nodejs22.x`, `java21`, `dotnet8`,
`ruby3.3`, and `provided.al2023` for a function that brings its own runtime, which is how Go and
Rust run on Lambda. `python3.12` is Python 3.12 on Amazon Linux 2023, the same files the base image
of section 02 carries.

**AWS patches a managed runtime underneath your function**, without a new deployment: security
fixes to the operating system and to the language arrive on their own. That is most of the reason
to use one. It is also the reason for the `LAMBDA_WARNING` line in the emulator's log in section
02, which tells whoever reads an unhandled exception to check whether the runtime version changed
just before the errors began. Lambda's runtime management settings decide when a function takes an
update, and the default is automatically.

## Deprecation, and what moto does not refuse

A runtime is **deprecated** when the language version it carries reaches the end of its community
support; for Python that is five years after the release, so Python 3.12, released in October 2023,
reaches it in October 2028. AWS's documentation lists a date for each runtime, and three steps
follow it. From the deprecation date the runtime gets no more security patches. A while later, new
functions can no longer be created with it, and later still, existing ones can no longer be updated.
A function on a deprecated runtime keeps running; it just runs unpatched.

moto keeps none of that:

```
ana@laptop:~/aws$ aws lambda create-function --function-name old --runtime python2.7 --handler app.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://greet/function.zip --query Runtime
"python2.7"
ana@laptop:~/aws$ aws lambda create-function --function-name typo --runtime python3.99 --handler app.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://greet/function.zip --query Runtime
"python3.99"
```

**Both functions exist in moto, and neither could be created on AWS.** `python2.7` was deprecated
years ago and has long been past the date when creation is blocked; `python3.99` is a typo for a
runtime that has never existed, and AWS refuses it with `InvalidParameterValueException` and the
list of names it accepts. Neither refusal was run here. **What this means in practice** is that a
function's runtime is a dependency with an end date, like any other, and somebody has to own the
upgrade before AWS's calendar forces it.

## x86 or Arm

Every function runs on one of two architectures, `x86_64` or `arm64`, the second on AWS's Graviton
processors. The choice is one flag:

```
ana@laptop:~/aws$ aws lambda create-function --function-name greet-arm --runtime python3.12 --architectures arm64 --handler app.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://greet/function.zip --query "[FunctionName,Architectures[0]]"
[
    "greet-arm",
    "arm64"
]
```

moto records it and runs nothing, so what follows is the price, which is the reason to look. The
Lambda block of the price sheet, on 16 October 2026:

```
ana@laptop:~/aws$ python3 prices.py lambda
AWS public price list, sa-east-1, USD, excluding tax

Lambda
  requests                                           0.2  per million
  duration, x86                             0.0000166667  per GB-second
  duration, Arm                             0.0000133334  per GB-second
  provisioned concurrency, x86              0.0000066372  per GB-second
  duration on provisioned, x86              0.0000154867  per GB-second
```

**A gigabyte-second on Arm costs 0.0000133334 USD against x86's 0.0000166667, a fifth less**;
requests cost the same on both. Put a month on it: three million invocations of a 512 MB function
that runs 120 ms each is 3,000,000 × 0.120 s × 0.5 GB = 180,000 GB-seconds.

| | x86 | Arm |
| --- | --- | --- |
| duration, 180,000 GB-s | 3.00 USD | 2.40 USD |
| requests, 3 million at 0.2 per million | 0.60 USD | 0.60 USD |
| month | 3.60 USD | 3.00 USD |

AWS also gives every account a monthly free allowance of Lambda requests and duration. It is not on
the sheet, and the table leaves it out.

The saving holds only if the function runs as fast on Arm, which pure Python and most interpreted
code do. **What breaks is a compiled dependency**: a wheel built for x86, such as an image or
cryptography library, does not load on `arm64`, and the package has to be built for the
architecture it will run on. The emulator cannot settle that question on an x86 laptop either,
because the image it pulled is `linux/amd64`, as section 02 printed. On a Mac with Apple silicon
the same `docker pull` brings the `arm64` image, and the question reverses.

## The image instead of the zip

The base image of section 02 is not only for testing. **A function can be deployed as a container
image**, `--package-type Image` with `--code ImageUri=` an image in ECR, built `FROM
public.ecr.aws/lambda/python:3.12` with the code copied into `/var/task`. Three things change. The
limit is 10 GB instead of 250 MB. The runtime is whatever the image holds, so it gets AWS's patches
only when you rebuild from a newer base image. And the image you ran with `docker run` on your
laptop is the very image Lambda runs, emulator and all. Lesson 10 is where an image waits in ECR
before it runs, and lesson 17 weighs what a larger image does to a cold start. Nothing in this
section created an image function, in moto or anywhere else.