---
title: Log groups, and the retention nobody set
version: 1
---

CloudWatch Logs keeps lines in **log groups**, one per application or component, and inside each group
in **log streams**, one per source: a container, an instance, a function's execution environment. The
group is where the decisions are made: who may read it, how long it keeps lines, what is extracted
from them. Create the shop API's group and look at it:

```
ana@laptop:~/aws/logs$ aws logs create-log-group --log-group-name /shop/api
ana@laptop:~/aws/logs$ aws logs describe-log-groups --log-group-name-prefix /shop/api --query 'logGroups[0].[logGroupName,retentionInDays,storedBytes]' --output text
/shop/api	None	0
ana@laptop:~/aws/logs$ aws logs put-retention-policy --log-group-name /shop/api --retention-in-days 30
ana@laptop:~/aws/logs$ aws logs describe-log-groups --log-group-name-prefix /shop/api --query 'logGroups[0].[logGroupName,retentionInDays]' --output text
/shop/api	30
```

`None` is the retention a new log group gets, and it means **never expire**. Every line ever written
stays, and is billed every month for as long as the account exists. Nobody chooses that; it is what
happens when nobody chooses. `put-retention-policy` sets a number of days from the same fixed list
cfn-lint knew in lesson 4, and lines older than that are deleted by CloudWatch.

## What a gigabyte of logs costs

```
ana@laptop:~/aws/logs$ python3 price.py AmazonCloudWatch SAE1-DataProcessing-Bytes
AmazonCloudWatch, sa-east-1, published 2026-10-07
  SAE1-DataProcessing-Bytes                0.900000 USD per GB         $0.90 per GB custom log data ingested in Standard log class - South America (Sao Paulo)
ana@laptop:~/aws/logs$ python3 price.py AmazonCloudWatch TimedStorage-ByteHrs
AmazonCloudWatch, sa-east-1, published 2026-10-07
  Global-TimedStorage-ByteHrs              0.000000 USD per GB-Mo      Global
  SAE1-TimedStorage-ByteHrs                0.040800 USD per GB-Mo      $0.0408 per GB-mo of log storage - South America (Sao Paulo)
```

The two lines bill different things, and the difference decides how to save:

- **ingestion**: 0.90 USD per gigabyte written, once, when it arrives;
- **storage**: 0.0408 USD per gigabyte per month, for every month it is kept.

The shop's API writes 5 GB of logs a day. Ingestion is 150 GB a month, 135 USD, whatever the
retention. Storage under a 30-day retention holds about 150 GB, some 6 USD a month; under no retention
it grows by 150 GB every month, and after two years holds 3.6 TB, about 147 USD a month and still
growing. **Ingestion is the bigger bill, and retention is the one that grows by itself.** Logging less
(fewer lines, shorter lines, no request bodies) saves ingestion; a retention policy on every group
stops the growth.

The price list also carries an Infrequent Access log class, cheaper to ingest and store, with fewer
features. It is chosen when the group is created, and it suits logs kept for audit and rarely queried.

## Who may read it

Log lines carry what the application wrote into them, and applications write more than they should:
an email in an error message, a token in a request URL. A log group's permissions are therefore data
permissions. Read access to `/shop/api` should be granted like read access to the orders table, and
a **data protection policy** on the group can mask patterns such as email addresses and card numbers as
they arrive, which moto does not implement and was not run here.
