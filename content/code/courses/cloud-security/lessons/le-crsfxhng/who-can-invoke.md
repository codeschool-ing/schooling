---
title: Who can call the function
version: 1
---

**The execution role says what a function may do. A different document says who may make it run:
the function's own resource-based policy, and for a function URL, the URL's authentication type.**
The previous section closed the first edge. This one is the edge that faces the internet.

The common wrong belief is that a function nobody linked to is a function nobody calls. A function
URL is an `https://` address on `lambda-url.<region>.on.aws`, and an address that answers is found:
by a log, a browser history, a screenshot in a ticket, a scanner walking the internet. **An address
being hard to guess is not an access control.**

## Two switches, both on "anybody"

moto 5.2.3 answers Lambda's requests with signature errors when its checking is on, so this section and the next
run with checking off. Stop moto with Ctrl+C and start it plainly, empty:

```sh
moto_server -p 4567
```

The function needs its role again, this time with the trust policy it should have had all along,
`lambda-trust.json` from the previous section. Save the smallest handler there is as `handler.py`:

```sh
cat > handler.py <<'EOF'
def handler(event, context):
    return {"statusCode": 200, "body": "export done"}
EOF
```

Create the role, pack the handler into a zip file, which Python can make without any other tool,
and create the function:

```
ana@laptop:~/aws$ aws iam create-role --role-name export-fn --assume-role-policy-document file://lambda-trust.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/export-fn
ana@laptop:~/aws$ python3 -m zipfile -c function.zip handler.py
ana@laptop:~/aws$ aws lambda create-function --function-name daily-export --runtime python3.12 --handler handler.handler --role arn:aws:iam::123456789012:role/export-fn --zip-file fileb://function.zip --query "[FunctionName,Runtime,State]" --output text
daily-export	python3.12	Active
```

caio wanted the reception's tablet to start an export without anybody signing in, so he gave the
function a URL whose authentication type is `NONE` and allowed `"*"` to call it:

```
ana@laptop:~/aws$ aws lambda create-function-url-config --function-name daily-export --auth-type NONE --query "[FunctionUrl,AuthType]" --output text
https://01908989b9bb401ea800d33cc91a7c9e.lambda-url.sa-east-1.on.aws	NONE
ana@laptop:~/aws$ aws lambda add-permission --function-name daily-export --statement-id anyone --action lambda:InvokeFunctionUrl --principal '*' --function-url-auth-type NONE --query Statement --output text
{"Action": "lambda:InvokeFunctionUrl", "Principal": "*", "FunctionUrlAuthType": "NONE", "Effect": "Allow", "Resource": "arn:aws:lambda:sa-east-1:123456789012:function:daily-export", "Sid": "anyone"}
ana@laptop:~/aws$ aws lambda get-policy --function-name daily-export --query Policy --output text | jq .
{
  "Version": "2012-10-17",
  "Id": "default",
  "Statement": [
    {
      "Action": "lambda:InvokeFunctionUrl",
      "Principal": "*",
      "FunctionUrlAuthType": "NONE",
      "Effect": "Allow",
      "Resource": "arn:aws:lambda:sa-east-1:123456789012:function:daily-export",
      "Sid": "anyone"
    }
  ]
}
```

Read the statement as AWS would: **the principal is `*`, everybody; the action is invoking the URL;
and `FunctionUrlAuthType: NONE` says no signature is required.** An unsigned request from anywhere
on the internet would start the function, and every start runs the export with the role's
permissions and lands on the clinic's bill. moto carries no traffic and runs no function, so nobody
called that address here. What you read is the configuration that would let them, which is exactly
what a reviewer reads in a real account.

## Closing it, and proving it closed

Take the statement away and make the URL demand a signature:

```
ana@laptop:~/aws$ aws lambda remove-permission --function-name daily-export --statement-id anyone
ana@laptop:~/aws$ aws lambda update-function-url-config --function-name daily-export --auth-type AWS_IAM --query AuthType --output text
AWS_IAM
ana@laptop:~/aws$ aws lambda get-policy --function-name daily-export

aws: [ERROR]: An error occurred (ResourceNotFoundException) when calling the GetPolicy operation: The resource you requested does not exist.
```

`ResourceNotFoundException` is the answer to read: **the function has no resource-based policy at
all**, so nobody outside the account is allowed to call it, and inside the account only identities
whose own policies allow `lambda:InvokeFunctionUrl` can, with a signed request. Against AWS, the
same unsigned request that would have started the export now gets `403 Forbidden`. That last
request was **not run here**, since moto serves no function URLs.

If the tablet really needs to start the export, give the tablet an identity, or put the function
behind something that authenticates the tablet. Do not give the function's address to the world.

## When a service calls the function

Most functions are not called by people at all. A file lands in a bucket, and S3 calls the function.
Here the principal is a service, and the danger is quieter: `s3.amazonaws.com` names **every bucket
in every account**, so a permission naming only the service lets anybody's bucket, set up to notify
your function, make it run. AWS calls this the *confused deputy* problem. The fix is to say which
bucket, and which account owns it:

```
ana@laptop:~/aws$ aws lambda add-permission --function-name daily-export --statement-id from-uploads --action lambda:InvokeFunction --principal s3.amazonaws.com --source-arn arn:aws:s3:::clinic-uploads --source-account 123456789012 --query Statement --output text | jq .
{
  "Action": "lambda:InvokeFunction",
  "Principal": {
    "Service": "s3.amazonaws.com"
  },
  "Effect": "Allow",
  "Resource": "arn:aws:lambda:sa-east-1:123456789012:function:daily-export",
  "Sid": "from-uploads",
  "Condition": {
    "ArnLike": {
      "AWS:SourceArn": "arn:aws:s3:::clinic-uploads"
    },
    "StringEquals": {
      "AWS:SourceAccount": "123456789012"
    }
  }
}
```

The `Condition` block is the part that matters: the call is allowed only when it comes from the
bucket `clinic-uploads` in account `123456789012`. moto stores the condition and does not judge it,
since it ignores conditions everywhere; AWS judges it on every call. The account matters even with
the bucket named, because a bucket name is free again once its owner deletes the bucket, and anybody
may then create one with the same name in another account.
