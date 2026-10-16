---
title: "Push sources: a URL, and a bucket that calls"
version: 1
---

A push source needs two things set up, and people set up one. **The source has to be told to call
the function, and the function has to allow the source to call it.** The second is a statement in
the function's own resource-based policy, which `aws-foundations` lesson 7 met as the other half of
IAM: a policy attached to the thing being reached, naming who may reach it. Forget it and the source
is configured perfectly and nothing ever arrives.

Two functions serve this lesson. They are created in moto from zips made the way lesson 14 made
`greet`, with a role the same as `greet-role`; `thumbs` is the handler further down this section,
and `orders` is section 04's:

```
ana@laptop:~/aws$ aws lambda create-function --function-name thumbs --runtime python3.12 --handler thumbs.handler --role arn:aws:iam::123456789012:role/trigger-role --zip-file fileb://thumbs.zip --query FunctionArn
"arn:aws:lambda:sa-east-1:123456789012:function:thumbs"
ana@laptop:~/aws$ aws lambda create-function --function-name orders --runtime python3.12 --handler orders.handler --role arn:aws:iam::123456789012:role/trigger-role --zip-file fileb://orders.zip --query FunctionArn
"arn:aws:lambda:sa-east-1:123456789012:function:orders"
```

## A function URL

The simplest synchronous caller is a **function URL**: an HTTPS address that belongs to one
function, with no API in front of it.

```
ana@laptop:~/aws$ aws lambda create-function-url-config --function-name orders --auth-type AWS_IAM
{
    "FunctionUrl": "https://231a86d105a2406d9da391d40f50dfbc.lambda-url.sa-east-1.on.aws",
    "FunctionArn": "arn:aws:lambda:sa-east-1:123456789012:function:orders",
    "AuthType": "AWS_IAM",
    "CreationTime": "2026-10-16T16:50:05.000+0000",
    "InvokeMode": "Buffered"
}
```

`AWS_IAM` means a request must be signed with credentials allowed `lambda:InvokeFunctionUrl`, which
suits a caller that is another AWS service or program. `NONE` makes the URL public, and then the
function's policy has to say so too, with a statement allowing the principal `*`. moto makes up the
address and serves nothing at it. **API Gateway is the other synchronous front door**, with what a
function URL lacks: routes, authorisers, throttling and usage plans, and lesson 19 is about it.
Either way, the event the handler receives is a description of an HTTP request, with its method,
path, headers and body, in a format called payload 2.0, and the handler's return becomes the
response.

## A bucket that calls a function

S3 invokes asynchronously, so the shop's thumbnails can be made after an upload without the
uploader waiting. The permission comes first, scoped to one bucket in one account:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-uploads-123456789012 --create-bucket-configuration LocationConstraint=sa-east-1 --query Location
"/shop-uploads-123456789012"
ana@laptop:~/aws$ aws lambda add-permission --function-name thumbs --statement-id s3-uploads --action lambda:InvokeFunction --principal s3.amazonaws.com --source-arn arn:aws:s3:::shop-uploads-123456789012 --source-account 123456789012 --query Statement --output text | jq .
{
  "Action": "lambda:InvokeFunction",
  "Principal": {
    "Service": "s3.amazonaws.com"
  },
  "Effect": "Allow",
  "Resource": "arn:aws:lambda:sa-east-1:123456789012:function:thumbs",
  "Sid": "s3-uploads",
  "Condition": {
    "ArnLike": {
      "AWS:SourceArn": "arn:aws:s3:::shop-uploads-123456789012"
    },
    "StringEquals": {
      "AWS:SourceAccount": "123456789012"
    }
  }
}
```

The two conditions matter. `AWS:SourceArn` limits the permission to this bucket. `AWS:SourceAccount`
adds the owner, because a bucket name is global, and a bucket of the same name in another account,
created after yours was deleted, would otherwise match the ARN. Then the bucket's side, for objects
created under `uploads/`:

```
ana@laptop:~/aws$ aws s3api put-bucket-notification-configuration --bucket shop-uploads-123456789012 --notification-configuration '{"LambdaFunctionConfigurations": [{"LambdaFunctionArn": "arn:aws:lambda:sa-east-1:123456789012:function:thumbs", "Events": ["s3:ObjectCreated:*"], "Filter": {"Key": {"FilterRules": [{"Name": "prefix", "Value": "uploads/"}]}}}]}'
ana@laptop:~/aws$ aws s3api get-bucket-notification-configuration --bucket shop-uploads-123456789012 --query 'LambdaFunctionConfigurations[0].[LambdaFunctionArn,Events[0]]'
[
    "arn:aws:lambda:sa-east-1:123456789012:function:thumbs",
    "s3:ObjectCreated:*"
]
```

On AWS, S3 checks the destination when you save the configuration, and if the function's policy does
not let S3 in, the call fails with `Unable to validate the following destination configurations`.
**moto does not check**, and that is easy to show:

```
ana@laptop:~/aws$ aws s3api put-bucket-notification-configuration --bucket shop-uploads-123456789012 --notification-configuration '{"LambdaFunctionConfigurations": [{"LambdaFunctionArn": "arn:aws:lambda:sa-east-1:123456789012:function:no-such-function", "Events": ["s3:ObjectCreated:*"]}]}' && echo accepted
accepted
```

A notification to a function that does not exist, accepted. On AWS that call is refused; it was not
run against AWS here. And moto runs no function, so an upload to this bucket now reaches nothing.

## What S3 sends

To see the event itself, point the bucket at an SQS queue instead, which moto does deliver to. On
AWS a queue as a destination needs an access policy letting S3 send to it; moto does not ask for
one. **Note that this second call replaces the first configuration rather than adding to it**:
`put-bucket-notification-configuration` writes the whole set, so the Lambda configuration above is
gone, as it would be on AWS. Then one upload inside `uploads/` and one outside it:

```
ana@laptop:~/aws$ aws sqs create-queue --queue-name s3-witness --query QueueUrl
"http://localhost:4567/123456789012/s3-witness"
ana@laptop:~/aws$ aws s3api put-bucket-notification-configuration --bucket shop-uploads-123456789012 --notification-configuration '{"QueueConfigurations": [{"QueueArn": "arn:aws:sqs:sa-east-1:123456789012:s3-witness", "Events": ["s3:ObjectCreated:*"], "Filter": {"Key": {"FilterRules": [{"Name": "prefix", "Value": "uploads/"}]}}}]}'
ana@laptop:~/aws$ aws s3api put-object --bucket shop-uploads-123456789012 --key uploads/cat.jpg --body photo.jpg --query ETag
"\"764efa883dda1e11db47671c4a3bbd9e\""
ana@laptop:~/aws$ aws s3api put-object --bucket shop-uploads-123456789012 --key drafts/dog.jpg --body photo.jpg --query ETag
"\"764efa883dda1e11db47671c4a3bbd9e\""
ana@laptop:~/aws$ aws sqs receive-message --queue-url http://localhost:4567/123456789012/s3-witness --max-number-of-messages 10 --visibility-timeout 0 --query 'Messages[].Body' | jq -r '.[]' | cut -c1-90
{"Service": "Amazon S3", "Event": "s3:TestEvent", "Time": "2026-10-16T16:50:10.980Z", "Buc
{"Records": [{"eventVersion": "2.1", "eventSource": "aws:s3", "awsRegion": "sa-east-1", "e
```

Two messages for one matching upload. The first is `s3:TestEvent`, which S3 also sends to a queue on
AWS when a configuration is saved, and which every consumer of a queue fed by a bucket must expect
and ignore; the second is the upload. `drafts/dog.jpg` sent nothing, because the prefix filter kept
it out. Keep the real event in a file and look at it:

```
ana@laptop:~/aws$ aws sqs receive-message --queue-url http://localhost:4567/123456789012/s3-witness --max-number-of-messages 10 --visibility-timeout 0 --query 'Messages[].Body' | jq -r '.[]' | grep Records > s3-event.json
ana@laptop:~/aws$ jq . s3-event.json
{
  "Records": [
    {
      "eventVersion": "2.1",
      "eventSource": "aws:s3",
      "awsRegion": "sa-east-1",
      "eventTime": "2026-10-16T16:50:11.639Z",
      "eventName": "ObjectCreated:Put",
      "s3": {
        "s3SchemaVersion": "1.0",
        "configurationId": "ak3LBhCG4mVjeCDbT1JuWHUamWefdqjeJoZ5mxR9vscRcIv71k",
        "bucket": {
          "name": "shop-uploads-123456789012",
          "arn": "arn:aws:s3:::shop-uploads-123456789012"
        },
        "object": {
          "key": "uploads%2Fcat.jpg",
          "size": 3,
          "eTag": "764efa883dda1e11db47671c4a3bbd9e"
        }
      }
    }
  ]
}
```

**One event can hold several records**, which is why everything is under `Records`. The key arrives
URL-encoded, here `uploads%2Fcat.jpg`, and AWS documents the same encoding; a handler that used it
as it comes would look for an object with `%2F` in its name. AWS's own event carries more fields
than moto's, among them who made the request and a `sequencer` for ordering the events of one key,
and the handler should read only what it needs. This one reads the bucket and the key. Save it as
`~/aws/thumbs/thumbs.py`:

```python
# thumbs.py
from urllib.parse import unquote_plus


def handler(event, context):
    done = []
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = unquote_plus(record['s3']['object']['key'])
        print(f'would resize s3://{bucket}/{key}')
        done.append(key)
    return {'resized': done}
```

and give it the event moto wrote, through the emulator of lesson 14:

```
ana@laptop:~/aws$ docker run --rm -d --name thumbs -p 9000:8080 -v "$PWD/thumbs":/var/task:ro public.ecr.aws/lambda/python:3.12 thumbs.handler
06e0b07f844444689cf4c96e27dbc23e6da45e414cbf2853aeccf78405f2a0ce
ana@laptop:~/aws$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d @s3-event.json; echo
{"resized": ["uploads/cat.jpg"]}
ana@laptop:~/aws$ docker logs thumbs 2>&1 | grep resize
would resize s3://shop-uploads-123456789012/uploads/cat.jpg
ana@laptop:~/aws$ docker stop thumbs
thumbs
```

`unquote_plus` turned the key back into `uploads/cat.jpg`, a key S3 would find. **A thumbnail
function that writes into the same bucket under the same prefix calls itself**, once per thumbnail,
for as long as anybody lets it: the output is an `ObjectCreated` event under `uploads/` like any
other. Writing the results under another prefix, or to another bucket, is the ordinary way out,
and AWS added a recursion check that stops some such loops; it is not a reason to build one.
