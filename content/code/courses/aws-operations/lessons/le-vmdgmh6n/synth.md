---
title: Synthesis, and reading what it wrote
version: 1
---

`cdk synth` runs the program and writes the template it describes. Nothing is sent anywhere:
**synthesis is a program printing a file**, and it can run on a laptop with no network, in a build,
or in a test.

```
ana@laptop:~/aws/cdk$ cdk synth --app "node app.js" > template.yaml
83 feature flags are not configured. Run 'cdk flags --unstable=flags' to learn more.
ana@laptop:~/aws/cdk$ wc -l app.js template.yaml
  37 app.js
  84 template.yaml
 121 total
ana@laptop:~/aws/cdk$ grep -E '^    Type: ' template.yaml | sort | uniq -c
      1     Type: AWS::CDK::Metadata
      1     Type: AWS::CloudWatch::Alarm
      1     Type: AWS::Logs::LogGroup
      1     Type: AWS::S3::Bucket
      1     Type: AWS::S3::BucketPolicy
      1     Type: AWS::SNS::Topic
      1     Type: AWS::SSM::Parameter::Value<String>
ana@laptop:~/aws/cdk$ ls cdk.out
ShopBase.assets.json
ShopBase.metadata.json
ShopBase.template.json
cdk.out
manifest.json
tree.json
validation-report.json
```

The line about feature flags is a note on standard error: projects made with `cdk init` record a
list of behaviour switches in `cdk.json`, and this app, written by hand, has none. It changes nothing
here.

**37 lines of JavaScript became 84 lines of template**, and the types say where the difference went.
Four resources were asked for: the bucket, the log group, the topic, the alarm. Three more entries
appeared that nobody wrote:

- **`AWS::S3::BucketPolicy`**, from the one line `enforceSSL: true`;
- **`AWS::CDK::Metadata`**, a record of which library version made the stack, which AWS reads to
  count CDK usage; `--no-version-reporting` leaves it out;
- **`AWS::SSM::Parameter::Value<String>`**, which is not a resource at all but the type of a
  parameter, read in the next section.

## What one line became

```
ana@laptop:~/aws/cdk$ sed -n '/UploadsPolicy/,/Version/p' template.yaml
  UploadsPolicy148F8199:
    Type: AWS::S3::BucketPolicy
    Properties:
      Bucket:
        Ref: Uploads4F6EB0FD
      PolicyDocument:
        Statement:
          - Action: s3:*
            Condition:
              Bool:
                aws:SecureTransport: "false"
            Effect: Deny
            Principal:
              AWS: "*"
            Resource:
              - Fn::GetAtt:
                  - Uploads4F6EB0FD
                  - Arn
              - Fn::Join:
                  - ""
                  - - Fn::GetAtt:
                        - Uploads4F6EB0FD
                        - Arn
                    - /*
        Version: "2012-10-17"
```

That is the policy lesson 4's template would have needed by hand: deny every S3 action on the bucket
and on every object in it, from anybody, when the request did not come over TLS. **The construct
wrote it correctly, both resources and all**, which is the case for level 2 constructs: they encode
a decision once, and every bucket made with the option gets it right.

It is also the case against them. The policy is in the template and in nobody's head; a reviewer
reading `app.js` sees `enforceSSL: true` and has to know what it expands to. **Read the synthesized
template in review**, at least the first time a construct is used, and whenever the library is
upgraded, because a new version can change what an option writes.

## Names nobody chose

The logical ids end in hashes: `Uploads4F6EB0FD`, `UploadsPolicy148F8199`. The CDK derives each from
the construct's path in the tree (`ShopBase/Uploads/Resource`), so that two constructs called `Uploads`
in different places never collide. The consequence matters in production: **moving a construct to
another place in the tree changes its logical id**, and to CloudFormation a new logical id is a new
resource, so the bucket would be replaced. A change set in the pipeline shows that before it happens;
the habit of reading change sets from lesson 4 is what catches a refactoring that would have deleted
the uploads.

## The other files

`cdk.out` holds the template as JSON, which is what deployment uses, and a `manifest.json` describing
what to deploy where. `ShopBase.assets.json` lists files the stack needs uploaded first, such as a
Lambda function's code or a Docker image. This app has none, which is what lets it be deployed to moto
in the next section without the CDK's own tooling.
