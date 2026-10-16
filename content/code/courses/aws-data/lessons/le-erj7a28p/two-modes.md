---
title: Provisioned and on demand
version: 1
---

**There are two ways to pay for the same units, and they differ in what you promise in advance.** On
demand, the mode of every table so far, you promise nothing: each request is counted in **request
units**, the units of the previous section, and charged by the million. Provisioned, you declare a
number of **capacity units per second**, read and write separately, and pay for them by the hour
whether or not anything uses them. A provisioned table with 100 write units can absorb 100 writes of
1 KB a second; it is billed for 100 every hour of the month, at three in the morning as well.

```
ana@laptop:~/aws$ python3 prices.py dynamodb
AWS public price list, sa-east-1, USD, excluding tax

DynamoDB, USD
  on demand, per million write request units            0.93750  million
  on demand, per million read request units             0.18750  million
  provisioned, per WCU-hour                            0.000975  WCU-hour
  provisioned, per RCU-hour                            0.000195  RCU-hour
  storage beyond 25 GB                                  0.37500  GB-month
  storage, Standard-IA table class                      0.15000  GB-month
  streams, per million read requests beyond free        0.30000  million
  point-in-time recovery                                0.30000  GB-month
```

**Per unit of work, provisioned is cheaper, and the gap is the whole argument.** A million writes on
demand cost 0.9375 dollars. One write unit provisioned for an hour costs 0.000975 dollars and can
carry 3,600 writes, so a million writes at full use of it cost 0.000975 × 1,000,000 / 3,600 = 0.27
dollars, less than a third. Reads keep the same ratio: 0.1875 on demand against 0.000195 × 1,000,000 /
3,600 = 0.054. The catch is "at full use". A unit nobody uses still costs its hour, and the next
section finds where that stops being worth it. The price sheet reads the second tier of the two
provisioned lines because AWS's list makes the first tier free, a monthly allowance of 25 units of
each.

## Switching a table

The products table was created on demand, and reports the warm throughput of a new on-demand table.
Moving it to provisioned names the capacity; changing the capacity later is the same command:

```
ana@laptop:~/aws$ aws dynamodb describe-table --table-name products --query 'Table.[BillingModeSummary.BillingMode,WarmThroughput]'
[
    "PAY_PER_REQUEST",
    {
        "ReadUnitsPerSecond": 12000,
        "WriteUnitsPerSecond": 4000,
        "Status": "ACTIVE"
    }
]
ana@laptop:~/aws$ aws dynamodb update-table --table-name products --billing-mode PROVISIONED --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=5 --query 'TableDescription.[BillingModeSummary.BillingMode,ProvisionedThroughput]'
[
    "PROVISIONED",
    {
        "ReadCapacityUnits": 10,
        "WriteCapacityUnits": 5
    }
]
ana@laptop:~/aws$ aws dynamodb update-table --table-name products --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=3 --query 'TableDescription.ProvisionedThroughput'
{
    "ReadCapacityUnits": 10,
    "WriteCapacityUnits": 3
}
ana@laptop:~/aws$ aws dynamodb update-table --table-name products --billing-mode PAY_PER_REQUEST --query 'TableDescription.BillingModeSummary.BillingMode'
"PAY_PER_REQUEST"
ana@laptop:~/aws$ aws dynamodb update-table --table-name products --billing-mode PROVISIONED --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=5 --query 'TableDescription.BillingModeSummary.BillingMode'
"PROVISIONED"
```

**moto switched the table back and forth as often as it was asked, and AWS would not.** AWS's
documentation allows a switch from provisioned to on demand at most four times in a rolling 24 hours, and a switch the other way at any time. It also allows only a
limited number of capacity decreases a day, counted in
the `NumberOfDecreasesToday` that `describe-table` reports. Those limits were not run here; moto has
none of them. A table that is provisioned too low is fixed by raising it, which is always allowed, and
a table that is provisioned too high costs money until the day's decreases allow it down.

**Which one to start with is not a close call for a new table.** On demand cannot be under-provisioned
and costs nothing while idle, so it is the mode for a table whose load nobody has measured yet. AWS
also lets a new on-demand table take, without warning, up to 4,000 writes and 12,000 reads a second,
which is what the `WarmThroughput` of an on-demand table reports, in moto as on AWS. Provisioned is
the mode for a load somebody has measured, and the next section is how to tell that the measurement
justifies it.
