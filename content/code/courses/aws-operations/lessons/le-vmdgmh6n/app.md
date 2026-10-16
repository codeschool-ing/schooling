---
title: An app, in a language with types and loops
version: 1
---

A CloudFormation template is a list. Twenty buckets that differ only in their names are twenty
entries, and a rule that every bucket refuses plain HTTP is a policy written twenty times. **The
Cloud Development Kit writes the list for you**, from a program: a loop makes the twenty buckets, a
function holds the rule, and the result is an ordinary CloudFormation template. `iac` lesson 17 ran
the CDK once; this lesson looks at what it writes, how it reaches AWS, and how to test it.

## Installing Node.js and the CDK

The CDK's command line is a Node.js program, and the library needs Node.js 20 or newer, where
Ubuntu 24.04 ships 18. Node.js comes from the project's own build, unpacked into `~/.local` beside the
AWS command line, so nothing needs `sudo`; then the `cdk` command, and the library in the app's own
directory. The versions are the ones `iac` used and the transcripts were recorded with:

```sh
curl -fsSL https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz | tar -xJ -C ~/.local --strip-components=1
npm install -g aws-cdk@2.1144.0
mkdir -p ~/aws/cdk && cd ~/aws/cdk
npm init -y > /dev/null
npm install aws-cdk-lib@2.272.0 constructs@10
```

On an Arm computer the file is `node-v22.22.0-linux-arm64.tar.xz`. The library is the large part, some
180 MB in `node_modules`.

```
ana@laptop:~/aws/cdk$ node --version
v22.22.0
ana@laptop:~/aws/cdk$ cdk --version
2.1144.0 (build b9c5274)
```

## The app

The shop's base stack again, the one lesson 4 wrote as a template, now as a program in `app.js`:

```schooling-example
{"language": "javascript", "file": "app.js", "parts": [{"code": "const { App, Stack, Duration, RemovalPolicy } = require(\"aws-cdk-lib\");\nconst s3 = require(\"aws-cdk-lib/aws-s3\");\nconst sns = require(\"aws-cdk-lib/aws-sns\");\nconst logs = require(\"aws-cdk-lib/aws-logs\");\nconst cloudwatch = require(\"aws-cdk-lib/aws-cloudwatch\");\nconst actions = require(\"aws-cdk-lib/aws-cloudwatch-actions\");\n", "note": "The library is split by service, one module each, all inside `aws-cdk-lib`."}, {"code": "\nclass ShopBase extends Stack {\n  constructor(scope, id, props) {\n    super(scope, id, props);\n", "note": "**A stack is a class.** Everything created inside its constructor becomes a resource of this stack."}, {"code": "    new s3.Bucket(this, \"Uploads\", {\n      versioned: true,\n      enforceSSL: true,\n      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,\n      removalPolicy: RemovalPolicy.RETAIN,\n    });\n", "note": "The uploads bucket, with four decisions that lesson 4's template spelled out by hand: versions kept, plain HTTP refused, no public access, kept when the stack goes. `enforceSSL` is one line here and a whole bucket policy in the template."}, {"code": "    new logs.LogGroup(this, \"WebLogs\", {\n      logGroupName: \"/shop/web\",\n      retention: logs.RetentionDays.TWO_WEEKS,\n    });\n    const alerts = new sns.Topic(this, \"Alerts\", { topicName: \"shop-alerts\" });\n", "note": "The log group takes its retention from an enumeration, so the value 15 that cfn-lint caught in lesson 4 cannot be written at all. The topic is kept in a variable because the alarm needs it."}, {"code": "    const errors = new cloudwatch.Metric({\n      namespace: \"Shop\", metricName: \"Errors5xx\", statistic: \"Sum\", period: Duration.minutes(1),\n    });\n    const alarm = errors.createAlarm(this, \"ErrorsHigh\", {\n      threshold: 10, evaluationPeriods: 3, datapointsToAlarm: 2,\n    });\n    alarm.addAlarmAction(new actions.SnsAction(alerts));\n  }\n}\n", "note": "An alarm on the shop's error count, which notifies the topic. Lesson 10 explains every number in it; what matters here is that the alarm refers to the topic as an object, not by an ARN typed by hand."}, {"code": "\nmodule.exports = { ShopBase };\n\nif (require.main === module) {\n  const app = new App();\n  new ShopBase(app, \"ShopBase\", { env: { account: \"123456789012\", region: \"sa-east-1\" } });\n}\n", "note": "Exported so a test can build it, and an `App` only when the file is run directly. The account and region are fixed, the moto account and São Paulo, so the template names them."}]}
```

Each `new` creates a **construct**. The ones used here are what the CDK calls level 2: a class per
kind of resource, with defaults chosen and options named in the language. Below them, level 1
constructs (`CfnBucket`, `CfnLogGroup`) are the template's resources one to one, with nothing added;
above them, level 3 constructs, patterns, build a whole arrangement of several services from one
call. **The level decides how much the library writes for you**, and the next section counts it.
