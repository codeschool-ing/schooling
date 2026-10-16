#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of aws-compute (SQS, SNS and
# EventBridge), as a script that produces them. THE SCRIPT IS THE SOURCE AND ITS
# OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-wsphkepw/captures.sh
#
# moto 5.2.3 implements these three services for real enough to watch: a
# visibility timeout hides a message for its seconds, a redrive policy moves a
# message to the dead-letter queue after maxReceiveCount receives, SNS delivers
# a copy to each subscribed queue and applies filter policies, an EventBridge
# rule matches its pattern (numeric matching included) and delivers to an SQS
# target, and a FIFO queue drops a repeated deduplication id. The waits are
# real seconds. What moto does not check, and the lesson says so: the queue
# policies AWS requires before SNS or EventBridge may send to a queue.
# test-event-pattern returns an empty reply in moto, so the lesson does not
# use it.
#
# What is STAGED rather than typed:
#   - consumer.py is read out of the example in `ordering-and-duplicates`;
#   - attrs.json and entries.json are written with `put`, and the lesson shows
#     the same text;
#   - prices.py is read out of the example in lesson 1's `the-price-sheet`; its
#     cache (~/.cache/aws-prices) was filled by lesson 1's `prices` run.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

from_example "$HERE/ordering-and-duplicates.md" consumer.py > consumer.py
from_example "$HERE/../le-ps61q5st/the-price-sheet.md" prices.py > prices.py
block queue-create
run 'Q=https://sqs.sa-east-1.amazonaws.com/123456789012'
run 'aws sqs create-queue --queue-name work-dlq --query QueueUrl --output text'
put attrs.json <<'JSON'
{
  "VisibilityTimeout": "3",
  "RedrivePolicy": "{\"deadLetterTargetArn\": \"arn:aws:sqs:sa-east-1:123456789012:work-dlq\", \"maxReceiveCount\": \"3\"}"
}
JSON
run 'aws sqs create-queue --queue-name work --attributes file://attrs.json --query QueueUrl --output text'

block queue-delete
run 'aws sqs send-message --queue-url "$Q/work" --message-body "order 41" --query MessageId --output text'
run 'RH=$(aws sqs receive-message --queue-url "$Q/work" --query "Messages[0].ReceiptHandle" --output text)'
run 'aws sqs delete-message --queue-url "$Q/work" --receipt-handle "$RH"'
run 'sleep 4; aws sqs receive-message --queue-url "$Q/work" --query "Messages[0].Body" --output text'

block queue-redrive
run 'aws sqs send-message --queue-url "$Q/work" --message-body "order 42" --query MessageId --output text'
run 'for i in 1 2 3 4; do aws sqs receive-message --queue-url "$Q/work" --attribute-names ApproximateReceiveCount --query "Messages[0].[Body, Attributes.ApproximateReceiveCount]" --output text; aws sqs receive-message --queue-url "$Q/work" --query "Messages[0].Body" --output text; sleep 4; done'
run 'aws sqs receive-message --queue-url "$Q/work-dlq" --query "Messages[0].Body" --output text'

block topic
run 'TOPIC=$(aws sns create-topic --name orders --query TopicArn --output text); echo "$TOPIC"'
run 'for name in billing shipping; do aws sqs create-queue --queue-name $name --query QueueUrl --output text; aws sns subscribe --topic-arn "$TOPIC" --protocol sqs --notification-endpoint arn:aws:sqs:sa-east-1:123456789012:$name --query SubscriptionArn --output text; done'
run 'SHIP=$(aws sns list-subscriptions-by-topic --topic-arn "$TOPIC" --query "Subscriptions[?Endpoint==\`arn:aws:sqs:sa-east-1:123456789012:shipping\`].SubscriptionArn" --output text)'
run 'aws sns set-subscription-attributes --subscription-arn "$SHIP" --attribute-name FilterPolicy --attribute-value '"'"'{"kind": ["physical"]}'"'"''
run 'aws sns set-subscription-attributes --subscription-arn "$SHIP" --attribute-name RawMessageDelivery --attribute-value true'

block topic-publish
run 'aws sns publish --topic-arn "$TOPIC" --message "order 42 paid" --message-attributes '"'"'{"kind": {"DataType": "String", "StringValue": "physical"}}'"'"' --query MessageId --output text'
run 'aws sns publish --topic-arn "$TOPIC" --message "order 43 paid" --message-attributes '"'"'{"kind": {"DataType": "String", "StringValue": "digital"}}'"'"' --query MessageId --output text'
run 'aws sqs receive-message --queue-url "$Q/billing" --max-number-of-messages 10 | jq -c ".Messages[].Body | fromjson | {Type, Message, kind: .MessageAttributes.kind.Value}"'
run 'aws sqs receive-message --queue-url "$Q/shipping" --max-number-of-messages 10 --query "Messages[].Body" --output text'

block bus
run 'aws events create-event-bus --name shop --query EventBusArn --output text'
run 'aws events put-rule --name big-orders --event-bus-name shop --event-pattern '"'"'{"source": ["shop.orders"], "detail-type": ["OrderPlaced"], "detail": {"total": [{"numeric": [">", 1000]}]}}'"'"' --query RuleArn --output text'
run 'aws sqs create-queue --queue-name review --query QueueUrl --output text'
run 'aws events put-targets --rule big-orders --event-bus-name shop --targets Id=review,Arn=arn:aws:sqs:sa-east-1:123456789012:review --query FailedEntryCount'
put entries.json <<'JSON'
[
  {"EventBusName": "shop", "Source": "shop.orders", "DetailType": "OrderPlaced", "Detail": "{\"id\": \"42\", \"total\": 1500}"},
  {"EventBusName": "shop", "Source": "shop.orders", "DetailType": "OrderPlaced", "Detail": "{\"id\": \"43\", \"total\": 300}"}
]
JSON
run 'aws events put-events --entries file://entries.json --query FailedEntryCount'
run 'aws sqs receive-message --queue-url "$Q/review" --max-number-of-messages 10 --query "Messages[].Body" --output text | jq .'

block fifo
run 'aws sqs create-queue --queue-name orders.fifo --attributes FifoQueue=true --query QueueUrl --output text'
run 'aws sqs send-message --queue-url "$Q/orders.fifo" --message-group-id order-42 --message-deduplication-id 42-paid --message-body paid --query SequenceNumber --output text'
run 'aws sqs send-message --queue-url "$Q/orders.fifo" --message-group-id order-42 --message-deduplication-id 42-paid --message-body paid --query SequenceNumber --output text'
run 'aws sqs send-message --queue-url "$Q/orders.fifo" --message-group-id order-42 --message-deduplication-id 42-shipped --message-body shipped --query SequenceNumber --output text'
run 'aws sqs send-message --queue-url "$Q/orders.fifo" --message-group-id order-43 --message-deduplication-id 43-paid --message-body paid --query SequenceNumber --output text'
run 'aws sqs receive-message --queue-url "$Q/orders.fifo" --max-number-of-messages 10 --attribute-names MessageGroupId --query "Messages[].[Attributes.MessageGroupId, Body]" --output text'
run 'aws sqs send-message --queue-url "$Q/orders.fifo" --message-body paid'

block consumer
run 'aws sqs create-queue --queue-name payments --query QueueUrl --output text'
run 'for o in 42 42 43; do aws sqs send-message --queue-url "$Q/payments" --message-body "{\"key\": \"charge-$o\", \"id\": \"$o\", \"total\": 1500}" --query MessageId --output text; done'
run 'python3 consumer.py'
run 'aws sqs send-message --queue-url "$Q/payments" --message-body '"'"'{"key": "charge-42", "id": "42", "total": 1500}'"'"' --query MessageId --output text'
run 'python3 consumer.py'

block prices
run 'python3 prices.py integration | sed -n 14,18p'
