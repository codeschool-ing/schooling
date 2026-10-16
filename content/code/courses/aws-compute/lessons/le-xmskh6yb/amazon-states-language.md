---
title: "Amazon States Language: a workflow as a JSON document"
version: 1
---

Orchestration usually starts as code: a function that calls a second service, waits, calls a
third, and catches what goes wrong. It works until the function has to wait longer than its own
timeout, or something fails halfway and nobody knows which steps already ran. **A Step Functions
state machine moves the sequence out of your code and into a document the service runs for you.**
The service remembers where each run is, for up to a year, and writes down every step it took.
Your code shrinks to the steps themselves.

The document is written in the Amazon States Language, ASL for short, and it is JSON. A run of it
is an **execution**: one input in, one path through the states, one output or one error out.

## Asking moto to run it

moto answers the Step Functions API in two ways. By default an execution does nothing, and its
history is a fixed list of events moto invents for every execution alike. **Ask it to run state
machines instead**, once per start of `moto_server`, through moto's own configuration address:

```
ana@laptop:~/aws$ curl -s -XPOST localhost:4567/moto-api/config -d '{"stepfunctions": {"execute_state_machine": true}}'; echo
{"batch": {"use_docker": true}, "lambda": {"use_docker": true}}
```

The reply lists two other settings and leaves this one out, which is a quirk of moto's reply and
not a refusal; the executions below are the proof that it took. With it on, moto interprets the
document and calls its own SQS when a task says so. It runs the states for real, and it still
enforces no IAM policy, so the role below is never checked.

## The machine, state by state

Ana's orders go through four states. A large order waits through a cancel window before the
warehouse hears about it; a small one goes straight through. Save the file as
`~/aws/order.asl.json`:

```schooling-example
{"language": "json", "file": "order.asl.json", "parts": [{"code": "{\n  \"Comment\": \"One order: a cancel window if it is large, then the warehouse queue\",\n  \"StartAt\": \"Check\",\n  \"States\": {\n", "note": "The whole machine is one JSON document. `StartAt` names the first state and `States` holds every state by name; a name is how one state points at the next."}, {"code": "    \"Check\": {\n      \"Type\": \"Choice\",\n      \"Choices\": [\n        {\"Variable\": \"$.total\", \"NumericGreaterThan\": 1000, \"Next\": \"CancelWindow\"}\n      ],\n      \"Default\": \"Notify\"\n    },\n", "note": "A `Choice` does no work: it reads the input and picks the next state. Rules are tried in order; `Default` is where everything else goes, and a `Choice` without one fails the execution on an input no rule matches."}, {"code": "    \"CancelWindow\": {\n      \"Type\": \"Wait\",\n      \"Seconds\": 2,\n      \"Next\": \"Notify\"\n    },\n", "note": "A `Wait` holds the execution and runs nothing while it waits, so it costs nothing per second. Two seconds keeps the lab quick; a real cancel window would be thirty minutes, and `Timestamp` waits until a date instead."}, {"code": "    \"Notify\": {\n      \"Type\": \"Task\",\n      \"Resource\": \"arn:aws:states:::sqs:sendMessage\",\n      \"Parameters\": {\n        \"QueueUrl\": \"https://sqs.sa-east-1.amazonaws.com/123456789012/orders\",\n        \"MessageBody.$\": \"$.id\"\n      },\n      \"ResultPath\": \"$.sent\",\n      \"Next\": \"Done\"\n    },\n", "note": "A `Task` does the work. This `Resource` is a service integration: Step Functions calls SQS itself, with no function in between. A key ending in `.$` takes its value from the input, and `ResultPath` puts SQS's answer beside the input instead of replacing it."}, {"code": "    \"Done\": {\"Type\": \"Succeed\"}\n  }\n}\n", "note": "`Succeed` ends the execution with the input it received as the output. Its opposite, `Fail`, ends it with an error name and a cause, and the section on errors uses one."}]}
```

There are eight types of state and this file uses four. The other four are `Pass`, which only
shapes data, `Fail`, `Parallel` and `Map`, and the end of this section runs the last two. **Every
state that is not an end names its `Next`**, so the document is a graph you can read, and the
Step Functions console draws it as one.

The state machine needs a role that Step Functions can assume, and a queue for `Notify` to send to:

```
ana@laptop:~/aws$ aws sqs create-queue --queue-name orders --query QueueUrl --output text
http://localhost:4567/123456789012/orders
ana@laptop:~/aws$ aws iam create-role --role-name orders-sfn --assume-role-policy-document '{"Version": "2012-10-17", "Statement": [{"Effect": "Allow", "Principal": {"Service": "states.amazonaws.com"}, "Action": "sts:AssumeRole"}]}' --query Role.Arn --output text
arn:aws:iam::123456789012:role/orders-sfn
ana@laptop:~/aws$ ROLE=arn:aws:iam::123456789012:role/orders-sfn
ana@laptop:~/aws$ SM=$(aws stepfunctions create-state-machine --name orders --definition file://order.asl.json --role-arn "$ROLE" --query stateMachineArn --output text); echo "$SM"
arn:aws:states:sa-east-1:123456789012:stateMachine:orders
```

## Two executions, two paths

A large order first. `--name` gives the execution a name of its own, which must be unique within
the state machine for 90 days on AWS. The ARN of an execution is the state machine's with
`execution` in place of `stateMachine` and the name at the end:

```
ana@laptop:~/aws$ aws stepfunctions start-execution --state-machine-arn "$SM" --name order-42 --input '{"id": "42", "total": 1500}' --query executionArn --output text
arn:aws:states:sa-east-1:123456789012:execution:orders:order-42
ana@laptop:~/aws$ aws stepfunctions describe-execution --execution-arn "${SM/stateMachine/execution}:order-42" --query status
"RUNNING"
ana@laptop:~/aws$ sleep 3
ana@laptop:~/aws$ aws stepfunctions describe-execution --execution-arn "${SM/stateMachine/execution}:order-42" --query "{status: status, output: output}"
{
    "status": "SUCCEEDED",
    "output": "{\"id\": \"42\", \"total\": 1500, \"sent\": {\"MD5OfMessageBody\": \"a1d0c6e83f027327d8461063f4ac58a6\", \"MessageId\": \"d655fee0-5aae-463a-9a1e-5630782a1b62\"}}"
}
```

**The execution was still `RUNNING` when the command line came back.** `start-execution` returns
at once, and the work goes on without the caller: two seconds of `Wait`, then the task. The output
is the input with SQS's answer at `$.sent`, because `ResultPath` put it there. The history says
which states it went through, and the queue has the message:

```
ana@laptop:~/aws$ aws stepfunctions get-execution-history --execution-arn "${SM/stateMachine/execution}:order-42" --query "events[].[id, type]" --output text
1	ExecutionStarted
2	ChoiceStateEntered
3	ChoiceStateExited
4	WaitStateEntered
5	WaitStateExited
6	TaskStateEntered
7	TaskScheduled
8	TaskStarted
9	TaskSucceeded
10	TaskStateExited
11	SucceedStateEntered
12	SucceedStateExited
13	ExecutionSucceeded
ana@laptop:~/aws$ aws sqs receive-message --queue-url https://sqs.sa-east-1.amazonaws.com/123456789012/orders --query "Messages[0].Body" --output text
42
```

A small order takes the other branch. Its history has no `Wait` in it at all:

```
ana@laptop:~/aws$ aws stepfunctions start-execution --state-machine-arn "$SM" --name order-43 --input '{"id": "43", "total": 300}' --query executionArn --output text
arn:aws:states:sa-east-1:123456789012:execution:orders:order-43
ana@laptop:~/aws$ sleep 1
ana@laptop:~/aws$ aws stepfunctions get-execution-history --execution-arn "${SM/stateMachine/execution}:order-43" --query "events[].type" --output text
ExecutionStarted	ChoiceStateEntered	ChoiceStateExited	TaskStateEntered	TaskScheduled	TaskStarted	TaskSucceeded	TaskStateExited	SucceedStateEntered	SucceedStateExited	ExecutionSucceeded
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"The orders state machine as boxes: Check, a Choice, leads to CancelWindow, a Wait of two seconds, when total is above 1000, and otherwise by Default straight to Notify, a Task that sends to the SQS queue. Notify leads to Done. Execution order-42, total 1500, took the upper path in 13 events; order-43, total 300, took the lower path in 11 events with no Wait.\"><defs><marker id=\"sf-p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"sf-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"88\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"75.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Check</text><text x=\"75.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Choice</text><rect x=\"200\" y=\"20\" width=\"150\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"275.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">CancelWindow</text><text x=\"275.0\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Wait</text><text x=\"275.0\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">two seconds</text><rect x=\"420\" y=\"88\" width=\"150\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"495.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Notify</text><text x=\"495.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Task</text><text x=\"495.0\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">to the SQS queue</text><rect x=\"630\" y=\"88\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"667.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Done</text><text x=\"667.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Succeed</text><path d=\"M130 100 L170 100 L170 49 L196 49\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#sf-p)\"></path><text x=\"164\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">total > 1000</text><path d=\"M350 49 L385 49 L385 104 L416 104\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#sf-p)\"></path><path d=\"M130 122 L280 122 L280 130 L416 130\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#sf-a)\"></path><text x=\"205\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">Default</text><path d=\"M570 110 L626 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#sf-p)\"></path><path d=\"M20 186 L48 186\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></path><text x=\"56\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">order-42, total 1500: 13 events</text><path d=\"M370 186 L398 186\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"5 3\"></path><text x=\"406\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">order-43, total 300: 11 events, no Wait</text></svg>", "caption": "One definition, two executions. The Choice reads each input and sends it down a different path; the history of each execution lists the states it entered, which is how the two runs above differ."}
```

The queue address in the file is the AWS form, `https://sqs.sa-east-1.amazonaws.com/...`, and
moto accepted it, so the same file runs unchanged against a real account.

## What moto lets through

AWS checks a definition when it is created. A `Next` that names a state that does not exist, a
`Choice` rule with no `Next`, a state nothing can reach: each is refused with `InvalidDefinition`
and a message naming the state. **moto checks none of that:**

```
ana@laptop:~/aws$ aws stepfunctions create-state-machine --name broken --definition '{"StartAt": "A", "States": {"A": {"Type": "Pass", "Next": "B"}}}' --role-arn "$ROLE" --query stateMachineArn --output text
arn:aws:states:sa-east-1:123456789012:stateMachine:broken
```

`B` does not exist, and on AWS this command fails. In the lab, a mistake like this one shows up
only when an execution reaches the broken state, so read a definition before trusting that moto
accepted it. On AWS, `aws stepfunctions validate-state-machine-definition` makes the same check
without creating anything; moto does not implement it.

## Many at once: Map and Parallel

Two states run more than one thing. Save this one as `~/aws/split.asl.json`:

```schooling-example
{"language": "json", "file": "split.asl.json", "parts": [{"code": "{\n  \"StartAt\": \"Lines\",\n  \"States\": {\n    \"Lines\": {\n      \"Type\": \"Map\",\n      \"ItemsPath\": \"$.lines\",\n      \"MaxConcurrency\": 2,\n", "note": "A `Map` runs the same steps once for each item of a list, here each line of an order, with at most two at a time."}, {"code": "      \"ItemProcessor\": {\n        \"ProcessorConfig\": {\"Mode\": \"INLINE\"},\n        \"StartAt\": \"Price\",\n        \"States\": {\n          \"Price\": {\"Type\": \"Pass\", \"Parameters\": {\"sku.$\": \"$.sku\", \"cents.$\": \"$.cents\"}, \"End\": true}\n        }\n      },\n      \"ResultPath\": \"$.priced\",\n      \"Next\": \"Both\"\n    },\n", "note": "The steps for one item are a small state machine of their own. `Pass` does nothing but shape data, which makes it the stand-in for real work in a sketch; `INLINE` keeps the iterations inside this execution."}, {"code": "    \"Both\": {\n      \"Type\": \"Parallel\",\n      \"Branches\": [\n        {\"StartAt\": \"Invoice\", \"States\": {\"Invoice\": {\"Type\": \"Pass\", \"Result\": \"invoice queued\", \"End\": true}}},\n        {\"StartAt\": \"Pick\", \"States\": {\"Pick\": {\"Type\": \"Pass\", \"Result\": \"picking list queued\", \"End\": true}}}\n      ],\n      \"ResultPath\": \"$.done\",\n      \"End\": true\n    }\n  }\n}\n", "note": "A `Parallel` runs different branches at the same time and waits for all of them; its result is a list with one entry per branch, in the order the branches are written."}]}
```

An order with two lines goes through it:

```
ana@laptop:~/aws$ SPLIT=$(aws stepfunctions create-state-machine --name split --definition file://split.asl.json --role-arn "$ROLE" --query stateMachineArn --output text)
ana@laptop:~/aws$ aws stepfunctions start-execution --state-machine-arn "$SPLIT" --name order-44 --input '{"lines": [{"sku": "A1", "cents": 1200}, {"sku": "B7", "cents": 350}]}' --query executionArn --output text
arn:aws:states:sa-east-1:123456789012:execution:split:order-44
ana@laptop:~/aws$ sleep 1
ana@laptop:~/aws$ aws stepfunctions describe-execution --execution-arn "${SPLIT/stateMachine/execution}:order-44" --query output --output text | jq -c .
{"lines":[{"sku":"A1","cents":1200},{"sku":"B7","cents":350}],"priced":[{"sku":"A1","cents":1200},{"sku":"B7","cents":350}],"done":["invoice queued","picking list queued"]}
```

`priced` holds one result per line, in the order of the lines, and `done` one per branch. The
`Pass` states stand in for real work here; in a real machine each would be a `Task`. On AWS a
`Map` can also run in `DISTRIBUTED` mode, where each item becomes a child execution of its own and
a list of millions of objects in S3 is processed in parallel. This lesson runs only `INLINE`.
