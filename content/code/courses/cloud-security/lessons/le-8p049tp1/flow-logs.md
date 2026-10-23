---
title: Flow logs: what actually crossed the wire
version: 1
---

**Configuration says what traffic is allowed; a flow log says what traffic happened.** The checker
in the last section can prove that SSH was open to everybody for a month. It cannot say whether
anybody connected, and after an exposure that is the first question anyone asks. In the cloud there
is no cable to tap, as lesson 1 put it. A flow log is the closest thing the provider offers:
**one line per conversation, recorded only if you turned it on before the conversation happened.**

## Turning them on

A flow log is attached to a VPC, a subnet or a single network interface, and delivered to a bucket or
to CloudWatch Logs. The clinic's goes to a bucket of its own, for the whole VPC, recording both
accepted and rejected traffic:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-flow-logs --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-flow-logs
ana@laptop:~/aws$ aws ec2 create-flow-logs --resource-type VPC --resource-ids "$vpc" --traffic-type ALL --log-destination-type s3 --log-destination arn:aws:s3:::clinic-flow-logs --query FlowLogIds --output text
fl-669057bdd6cb69ad6
ana@laptop:~/aws$ aws ec2 describe-flow-logs --query "FlowLogs[].[FlowLogId,ResourceId,TrafficType,LogDestination,LogFormat]" --output text
fl-669057bdd6cb69ad6	vpc-e1a208744d0ad63a7	ALL	arn:aws:s3:::clinic-flow-logs	${version} ${account-id} ${interface-id} ${srcaddr} ${dstaddr} ${srcport} ${dstport} ${protocol} ${packets} ${bytes} ${start} ${end} ${action} ${log-status}
ana@laptop:~/aws$ aws s3 ls s3://clinic-flow-logs --recursive
```

The last column of `describe-flow-logs` is the format each record will be written in, and since
nothing else was asked for it is the default one. **That, and an empty bucket, is the whole of what
the lab can show.** moto stores the flow log's configuration and records
nothing, since it carries no traffic. What follows is from AWS's
documentation, not a run.

## What a record says

In the default format, each record is one line of space-separated fields, in this order:

| field | what it holds |
|---|---|
| `version` | the format's version, `2` for the default |
| `account-id` | the account the interface belongs to |
| `interface-id` | the network interface the traffic crossed |
| `srcaddr`, `dstaddr` | the two addresses |
| `srcport`, `dstport` | the two ports |
| `protocol` | the IANA protocol number: `6` is TCP, `17` is UDP |
| `packets`, `bytes` | how much, during the aggregation window |
| `start`, `end` | the window, in seconds since 1970 |
| `action` | `ACCEPT` or `REJECT` |
| `log-status` | `OK`, or `NODATA` and `SKIPDATA` when there was nothing or something was lost |

The line below was **written by this course in that documented format**, with an address from the
range reserved for documentation, to show the shape. It is not a recording:

```
2 123456789012 eni-0123456789abcdef0 203.0.113.50 10.20.1.10 51544 22 6 14 2448 1792756800 1792756860 ACCEPT OK
```

Read it left to right: from `203.0.113.50`, a stranger's address, to port 22 of a web server, over
TCP, accepted. **That is a connection to the SSH port the last section closed**, and it is the line
an investigation is looking for. A `REJECT` from the same address afterwards would be the fix holding.

## What a flow log does not say

- **It records conversations, not contents.** There is no payload, no command typed, no file name.
  Whether that SSH session read the records database is a question for the server's own logs.
- **It is aggregated**, over windows of up to ten minutes by default, so it gives counts and not a
  timeline to the second.
- **Some traffic is not in it at all**, by AWS's documentation: requests to the instance metadata
  address, to Amazon's DNS resolver, and DHCP among them.
- **It is not on by default, and it is billed** as log delivery and storage. An account that turned
  it on the morning after an incident has nothing about the incident.

Google Cloud's VPC Flow Logs and Azure's virtual network flow logs answer the same question with
different fields; neither is run here. Lesson 15 puts flow logs beside the record of API calls, which
answers the other question: not *who connected* but *who opened the port*.
