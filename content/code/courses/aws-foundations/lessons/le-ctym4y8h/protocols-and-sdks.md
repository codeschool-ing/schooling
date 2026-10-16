---
title: Four wire protocols, and an SDK that hides them
version: 1
---

**AWS's services do not all speak the same dialect of HTTP.** The older ones take a form and answer
in XML. Most of the newer ones take JSON. S3 uses the URL itself as the address of what it acts on.
Signing is the same in all of them. An SDK knows which dialect each service speaks, and the program
that uses it never has to.

The wrong picture is that there is one AWS API with one format. **There are four protocols**, and a
request built by hand in the wrong one is refused, however well it is signed:

| protocol | how the action is named | body | answer | services |
|---|---|---|---|---|
| query | `Action=` and `Version=` in a form | form fields | XML | EC2, IAM, STS, older ones |
| JSON | an `X-Amz-Target` header | JSON | JSON | Organizations, DynamoDB, most newer ones |
| REST-XML | the method and the path | XML, when there is one | XML | S3, CloudFront, Route 53 |
| REST-JSON | the method and the path | JSON | JSON | Lambda, API Gateway and others |

## Three of them, measured

The same `--debug` and `grep` as before, on three services. Organizations speaks JSON:

```
ana@laptop:~/aws$ aws organizations create-organization --feature-set ALL --debug 2>&1 | grep -oE "method=POST, url=[^,]*|'(Content-Type|X-Amz-Target)': b'[^']*'"
method=POST, url=http://localhost:4567/
'X-Amz-Target': b'AWSOrganizationsV20161128.CreateOrganization'
'Content-Type': b'application/x-amz-json-1.1'
```

**The action is in a header**, `X-Amz-Target`, together with the service's API version,
`20161128`, and every call goes to `/`. S3 is REST: the bucket is the path, and creating one is a
`PUT` to it with an XML body:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1 --debug 2>&1 | grep -oE "method=PUT, url=[^,]*|b'<CreateBucketConfiguration[^']*'"
b'<CreateBucketConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><LocationConstraint>sa-east-1</LocationConstraint></CreateBucketConfiguration>'
method=PUT, url=http://localhost:4567/shop-assets
```

The XML names S3's version too, `2006-03-01`, in its namespace. Against AWS the bucket usually goes
into the host name instead, `shop-assets.s3.sa-east-1.amazonaws.com`. With a custom endpoint like
moto's the command line puts it in the path. EC2 speaks query, like STS:

```
ana@laptop:~/aws$ aws ec2 describe-vpcs --debug 2>&1 | grep -oE "'body': \{[^}]*\}"
'body': {'Action': 'DescribeVpcs', 'Version': '2016-11-15'}
```

**Every service carries an API version, and it is a date.** STS's is `2011-06-15` and EC2's
`2016-11-15`. AWS adds operations and fields under the same version and keeps old ones working,
which is why a fifteen-year-old script still runs. A new version date is rare, and the SDK names it
for you. Lambda's REST-JSON was not measured here.

## boto3, already in the lab

**boto3 is AWS's SDK for Python**, and the command line is built on its lower layer, botocore. The
lab has had it since lesson 1, as one of moto's own dependencies:

```
ana@laptop:~/aws$ python3 -m pip show boto3 | grep -E "^(Name|Version|Required-by)"
Name: boto3
Version: 1.43.114
Required-by: moto
ana@laptop:~/aws$ which python3
/opt/awslab/home/ana/aws/venv/bin/python3
```

`env.sh` activated `~/aws/venv`, so `python3` is the virtual environment's. boto3 reads the same
variables the command line does: the test keys, the region, and `AWS_ENDPOINT_URL`, which sends it
to moto. This program asks the lab three questions with it. Save it as `~/aws/shop-check.py`:

```schooling-example
{"language": "python", "file": "shop-check.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Asks the lab three questions with boto3, the SDK the command line is built on.\n\n    python3 shop-check.py\n\"\"\"\nimport boto3\nfrom botocore.config import Config\n\nconfig = Config(region_name='sa-east-1', retries={'mode': 'standard', 'max_attempts': 3})\n\n", "note": "`Config` holds what the command line takes from options and profiles. The region is the lab's, and the retry settings are the ones the command line used by default in the transcript of the next section, written out."}, {"code": "sts = boto3.client('sts', config=config)\nme = sts.get_caller_identity()\nprint('signed as', me['Arn'])\n\n", "note": "A client per service. The method's name is the action's, in Python's spelling, and the answer is a dictionary rather than XML: boto3 did the parsing the command line does. Nothing here names a key or an endpoint, because both come from the environment, through the chain of lesson 10."}, {"code": "s3 = boto3.client('s3', config=config)\ns3.put_object(Bucket='shop-assets', Key='hello.txt', Body=b'hello from boto3\\n')\nbody = s3.get_object(Bucket='shop-assets', Key='hello.txt')['Body'].read()\nprint('read back', body)\n\n", "note": "S3 speaks REST-XML and STS speaks query, and the code looks the same: that difference is the SDK's to know. The object goes into the bucket the command line created a moment ago."}, {"code": "iam = boto3.client('iam', config=config)\npages = policies = 0\nfor page in iam.get_paginator('list_policies').paginate(Scope='AWS'):\n    pages += 1\n    policies += len(page['Policies'])\nprint(policies, 'policies in', pages, 'pages')\n", "note": "A paginator follows the markers the way the command line did in lesson 25. In an SDK the pages are visible: each loop is one request."}]}
```

```
ana@laptop:~/aws$ python3 shop-check.py
signed as arn:aws:sts::123456789012:user/moto
read back b'hello from boto3\n'
1544 policies in 16 pages
```

**Same identity, same bucket, same 16 pages** as the command line, because it is the same library
making the same requests. Every other SDK, for Java, JavaScript, Go, .NET and the rest, is built
from the same service descriptions, which is why their methods and fields carry the same names.
