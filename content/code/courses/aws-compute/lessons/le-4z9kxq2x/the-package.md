---
title: The deployment package, and what Lambda keeps of it
version: 1
---

A function on AWS is two things kept apart: **the code, as a package Lambda stores, and a
configuration that says how to run it** — the runtime, the handler, the memory, the timeout and the
role. You upload the package once per change and edit the configuration whenever you like. For a
Python function the package is the simplest one there is, a zip file with your code at its root.

## A zip with the handler at the top

In `~/aws/greet`:

```
ana@laptop:~/aws/greet$ zip function.zip app.py
  adding: app.py (deflated 46%)
ana@laptop:~/aws/greet$ unzip -l function.zip
Archive:  function.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
      510  2026-10-16 13:32   app.py
---------                     -------
      510                     1 file
ana@laptop:~/aws/greet$ aws lambda create-function --function-name greet --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://function.zip

aws: [ERROR]: An error occurred (InvalidParameterValueException) when calling the CreateFunction operation: The role defined for the function cannot be assumed by Lambda.
```

The zip holds one file, `app.py`, at its root, which is where `app.handler` tells the runtime to
look: Lambda unpacks the package into `/var/task`, the directory the emulator had mounted. A zip
whose files sit inside a folder, `greet/app.py`, is the commonest first mistake, and on AWS it
fails at the first invocation with the same `Runtime.ImportModuleError` the next section produces
on purpose.

The refusal is the more interesting part. **A function cannot exist without a role**, the
execution role that `aws-foundations` lesson 9 introduced: Lambda assumes it to run your code, and
whatever the code does on AWS it does with that role's permissions. moto checks, as AWS does, that
the role exists and that its trust policy lets the Lambda service assume it. So create one, with a
trust policy naming `lambda.amazonaws.com`, and try again:

```
ana@laptop:~/aws/greet$ aws iam create-role --role-name greet-role --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' --query Role.Arn
"arn:aws:iam::123456789012:role/greet-role"
ana@laptop:~/aws/greet$ aws lambda create-function --function-name greet --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://function.zip --query "{State:State,CodeSize:CodeSize,MemorySize:MemorySize,Timeout:Timeout,Architectures:Architectures,EphemeralStorage:EphemeralStorage}"
{
    "State": "Active",
    "CodeSize": 438,
    "MemorySize": 128,
    "Timeout": 3,
    "Architectures": [
        "x86_64"
    ],
    "EphemeralStorage": {
        "Size": 512
    }
}
```

Now there is a function, and its configuration shows **AWS's defaults, which moto copies**: 128 MB
of memory, a timeout of three seconds, the x86 architecture and 512 MB of `/tmp`. Each is a setting
rather than a fact about Lambda. Memory goes from 128 MB to 10,240 MB, and the processor power
Lambda gives a function grows with it. The timeout goes up to 900 seconds, fifteen minutes, the
longest any single invocation can run. `/tmp` goes up to 10,240 MB. The role here has no permission
policy at all, so on AWS the function would run and fail to write its log until
`AWSLambdaBasicExecutionRole`, or a policy like it, were attached.

## Where the package went

```
ana@laptop:~/aws/greet$ aws lambda get-function --function-name greet --query "Code"
{
    "RepositoryType": "S3",
    "Location": "https://awslambda-sa-east-1-tasks.s3.sa-east-1.amazonaws.com/greet-b5c47ccc-abc8-4f2e-8d04-caf6a96fabab"
}
```

On AWS that `Location` is a pre-signed S3 URL, valid for ten minutes, from which you can download
the exact package the function runs. moto prints the shape of one and stores the zip in its own
memory. **The package belongs to Lambda once it is uploaded**: it lives in storage AWS manages,
and changing a file on your laptop changes nothing until you upload again.

## Changing the code, and freezing a version

An edit is a new zip and one call. The configuration is untouched:

```
ana@laptop:~/aws/greet$ sed -i "s/'hello, /'olá, /" app.py
ana@laptop:~/aws/greet$ zip -q function.zip app.py
ana@laptop:~/aws/greet$ aws lambda update-function-code --function-name greet --zip-file fileb://function.zip --query "[CodeSize,CodeSha256,Version]"
[
    441,
    "LRJpbyQkRSXJg6Gcp8aABFoi/aC17fsctkEzwCdC9Es=",
    "$LATEST"
]
ana@laptop:~/aws/greet$ aws lambda publish-version --function-name greet --query "[Version,CodeSha256]"
[
    "1",
    "LRJpbyQkRSXJg6Gcp8aABFoi/aC17fsctkEzwCdC9Es="
]
```

`CodeSha256` is the base64 SHA-256 of the zip, and it is how you tell which package a function is
running: compute the same hash of a zip on your laptop and compare. `$LATEST` is the one version
that changes, and every update lands in it. `publish-version` freezes the current code and
configuration as version `1`, which never changes again; lesson 16's aliases and provisioned
concurrency point at versions like this one, never at `$LATEST`.

## Invoking it through moto, here

The last thing to try against moto is running it:

```
ana@laptop:~/aws/greet$ aws lambda invoke --function-name greet --cli-binary-format raw-in-base64-out --payload '{"name": "ana"}' out.json
{
    "StatusCode": 200,
    "FunctionError": "Handled"
}
ana@laptop:~/aws/greet$ cut -c1-150 out.json; echo
error running docker: 500 Server Error for http+docker://localhost/v1.56/images/create?tag=python3.12&fromImage=docker.io%2Fmlupin%2Fdocker-lambda: In
```

**`FunctionError: Handled` with a status of 200 is how Lambda reports a function that failed**, and
here the failure is moto's, not the function's: to run the code, moto pulls a community image of
the Lambda runtime from Docker Hub and runs the handler in it, and this machine could not pull it.
On a computer that reaches Docker Hub, moto runs the handler that way. This course uses AWS's own
base image, as in the last section, because it is the runtime Lambda itself uses and because it is
on your machine already.

## The limits, which moto does not keep

One more upload, of a package that is mostly sixty megabytes of random bytes:

```
ana@laptop:~/aws/greet$ head -c 60000000 /dev/urandom > blob.bin
ana@laptop:~/aws/greet$ zip -q big.zip app.py blob.bin && stat -c '%s bytes' big.zip
60009740 bytes
ana@laptop:~/aws/greet$ aws lambda create-function --function-name big --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://big.zip --query CodeSize
60009740
```

**moto accepted it, and AWS would not.** Lambda's documented quotas for a package are:

| | limit |
| --- | --- |
| a zip uploaded directly, as here | 50 MB |
| a zip uploaded from S3 instead | no limit on the zip itself |
| the package unzipped, including every layer | 250 MB |
| a container image | 10 GB, uncompressed |

So a 60 MB zip has to go through S3 (`--code S3Bucket=…,S3Key=…`), and even then it must unzip to
less than 250 MB together with its layers. None of these refusals was run here; moto keeps none of
the four limits. They are the reason the next section exists, and the reason the one after it
mentions images.
