---
title: Tests for infrastructure, run before anything exists
version: 1
---

A program can be tested, and so can the template it writes. The CDK's `assertions` module builds the
template in memory and checks it, with no account, no moto and no network. **The decisions in the
previous sections become tests**, so a later edit that undoes one fails in the build instead of
reaching AWS. Node.js has a test runner built in; the file is `app.test.js`, beside the app:

```javascript
// app.test.js
const { test } = require("node:test");
const { App } = require("aws-cdk-lib");
const { Template, Match } = require("aws-cdk-lib/assertions");
const { ShopBase } = require("./app");

const template = Template.fromStack(new ShopBase(new App(), "Test"));

test("the uploads bucket refuses plain HTTP", () => {
  template.hasResourceProperties("AWS::S3::BucketPolicy", {
    PolicyDocument: {
      Statement: Match.arrayWith([
        Match.objectLike({
          Effect: "Deny",
          Condition: { Bool: { "aws:SecureTransport": "false" } },
        }),
      ]),
    },
  });
});

test("the uploads bucket survives the stack", () => {
  template.hasResource("AWS::S3::Bucket", {
    DeletionPolicy: "Retain",
    UpdateReplacePolicy: "Retain",
  });
});

test("one alarm, and it notifies somebody", () => {
  template.resourceCountIs("AWS::CloudWatch::Alarm", 1);
  template.hasResourceProperties("AWS::CloudWatch::Alarm", {
    AlarmActions: Match.anyValue(),
  });
});
```

`Template.fromStack` synthesizes the stack the way `cdk synth` does. `hasResourceProperties` passes
when **some** resource of that type has properties containing the ones given; `Match.objectLike` and
`Match.arrayWith` allow the rest of the object and the array to hold anything else. `hasResource`
checks the resource's own attributes, where the deletion policies live. `resourceCountIs` counts.

```
ana@laptop:~/aws/cdk$ node --test --test-reporter=spec
✔ the uploads bucket refuses plain HTTP (2.833395ms)
✔ the uploads bucket survives the stack (0.385392ms)
✔ one alarm, and it notifies somebody (0.311572ms)
ℹ tests 3
ℹ suites 0
ℹ pass 3
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 1750.102685
```

Now undo the decision the first test protects, as somebody tidying the file might:

```
ana@laptop:~/aws/cdk$ sed -i 's/enforceSSL: true/enforceSSL: false/' app.js
ana@laptop:~/aws/cdk$ node --test --test-reporter=spec 2>&1 | head -18
✖ the uploads bucket refuses plain HTTP (2.431477ms)
✔ the uploads bucket survives the stack (0.560651ms)
✔ one alarm, and it notifies somebody (0.23853ms)
ℹ tests 3
ℹ suites 0
ℹ pass 2
ℹ fail 1
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 1207.331431

✖ failing tests:

test at app.test.js:9:1
✖ the uploads bucket refuses plain HTTP (2.431477ms)
  Error [AssertionError]: Template has 0 resources with type AWS::S3::BucketPolicy.
  No matches found
```

**The test names the decision that was lost**, "the uploads bucket refuses plain HTTP", and the
reason, no bucket policy in the template. Put the line back before going on.

## What to test

Tests like these are worth writing for **decisions**, not for every property:

- a protection that is easy to remove and expensive to miss: encryption, a policy refusing plain
  HTTP, a bucket kept when the stack goes;
- a count that should not change by accident: one alarm per service, no public bucket;
- a relationship: the alarm notifies the topic the on-call rotation reads.

The other kind, the **snapshot test**, compares the whole template with a copy saved earlier and
fails on any difference. It catches everything and explains nothing, and after the third library
upgrade that changes a hash in it, people update the snapshot without reading it. Use it, if at all,
beside the fine-grained tests, never instead of them.
