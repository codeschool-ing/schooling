---
title: "Topics: one message, a copy for each subscriber"
version: 1
---

When an order is paid, billing needs to know and so does shipping. The first design that comes to
mind is a queue both of them read. **A queue gives each message to one consumer**, so billing and
shipping would split the orders between them, each seeing about half. What they need is a
**topic**: SNS takes one published message and delivers a copy to every subscription, and each
subscriber can have a queue of its own, read at its own pace. That shape is called fan-out.

## Two queues behind one topic

Ana creates the topic and subscribes a queue for each team:

```
ana@laptop:~/aws$ TOPIC=$(aws sns create-topic --name orders --query TopicArn --output text); echo "$TOPIC"
arn:aws:sns:sa-east-1:123456789012:orders
ana@laptop:~/aws$ for name in billing shipping; do aws sqs create-queue --queue-name $name --query QueueUrl --output text; aws sns subscribe --topic-arn "$TOPIC" --protocol sqs --notification-endpoint arn:aws:sqs:sa-east-1:123456789012:$name --query SubscriptionArn --output text; done
http://localhost:4567/123456789012/billing
arn:aws:sns:sa-east-1:123456789012:orders:9dc5471f-2567-45f1-ad4e-7df5df16ba5b
http://localhost:4567/123456789012/shipping
arn:aws:sns:sa-east-1:123456789012:orders:69e63d69-7e71-462f-ae44-4f8e86a2cb48
```

**On AWS each queue also needs a policy that lets the topic send to it**, an SQS queue policy
whose principal is `sns.amazonaws.com` and whose condition names the topic's ARN; without it SNS
delivers nothing and the subscription looks fine. moto checks no queue policy, so the lab works
without one. The policy is a resource policy of the kind `aws-foundations` lesson 7 reads.

## A filter per subscription

Shipping cares about physical goods only. Rather than receive every order and throw half away, its
subscription gets a **filter policy**, and SNS drops what does not match before it is delivered.
The same subscription is set to **raw delivery**, so its queue receives the message itself instead
of SNS's envelope around it:

```
ana@laptop:~/aws$ SHIP=$(aws sns list-subscriptions-by-topic --topic-arn "$TOPIC" --query "Subscriptions[?Endpoint==\`arn:aws:sqs:sa-east-1:123456789012:shipping\`].SubscriptionArn" --output text)
ana@laptop:~/aws$ aws sns set-subscription-attributes --subscription-arn "$SHIP" --attribute-name FilterPolicy --attribute-value '{"kind": ["physical"]}'
ana@laptop:~/aws$ aws sns set-subscription-attributes --subscription-arn "$SHIP" --attribute-name RawMessageDelivery --attribute-value true
```

Two orders are paid, one physical and one digital:

```
ana@laptop:~/aws$ aws sns publish --topic-arn "$TOPIC" --message "order 42 paid" --message-attributes '{"kind": {"DataType": "String", "StringValue": "physical"}}' --query MessageId --output text
4c3efa1a-0327-421b-a53a-a050642070e2
ana@laptop:~/aws$ aws sns publish --topic-arn "$TOPIC" --message "order 43 paid" --message-attributes '{"kind": {"DataType": "String", "StringValue": "digital"}}' --query MessageId --output text
1ecaf880-c606-4620-b2ba-59da62f81741
ana@laptop:~/aws$ aws sqs receive-message --queue-url "$Q/billing" --max-number-of-messages 10 | jq -c ".Messages[].Body | fromjson | {Type, Message, kind: .MessageAttributes.kind.Value}"
{"Type":"Notification","Message":"order 42 paid","kind":"physical"}
{"Type":"Notification","Message":"order 43 paid","kind":"digital"}
ana@laptop:~/aws$ aws sqs receive-message --queue-url "$Q/shipping" --max-number-of-messages 10 --query "Messages[].Body" --output text
order 42 paid
```

**Billing got both, shipping got one, and they arrived in different shapes.** Billing's messages
are SNS's JSON envelope, with `Type`, the `Message` and its attributes; a consumer reads
`Message` out of it, and the `jq` above did exactly that. Shipping's arrived raw, as the published
text and nothing else, and the digital order never reached its queue at all. moto applied the
filter as AWS does.

A filter policy reads message attributes by default. Since 2022 it can also read the body of a
JSON message instead, with the subscription attribute `FilterPolicyScope` set to `MessageBody`.
Either way, matching happens before delivery, so a message that matches no filter costs no
delivery and wakes no consumer.

## What a topic does not do

**A topic keeps nothing.** A message published while a subscription's endpoint cannot take it is
retried on a schedule and then dropped, unless that subscription has a dead-letter queue of its
own; a message published before a subscription existed is never delivered to it. That is the
other reason for the queue behind each subscription: the queue keeps the message until the
consumer is ready, for up to fourteen days, and the topic only has to reach the queue.

Order is the one thing a standard topic does not keep either. An **SNS FIFO topic**, whose name
ends in `.fifo`, delivers to SQS FIFO queues in order and drops duplicates, with the same group and
deduplication ids as the FIFO queue in the last section of this lesson.

SNS also delivers to other kinds of endpoint: a Lambda function, an HTTPS address, an e-mail
address, a phone number. With SQS behind it, the topic's job is narrow and dependable, and every
team keeps its own retries, its own dead-letter queue and its own speed.
