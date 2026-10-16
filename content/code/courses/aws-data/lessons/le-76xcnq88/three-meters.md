---
title: Three meters on every bucket
version: 1
---

**An S3 bill has three meters, and storage is only one of them.** The other two run when the data is
used: one counts requests, the other counts bytes that leave. People estimate a bucket by its size,
multiply by the price per GB-month, and are right about the bucket and wrong about the bill, because
a bucket that is read a lot is mostly paid for by the reading.

This lesson needs no bucket for most of its work, only the price sheet from lesson 1, which reads its
cache and needs neither moto nor the network. Two of its blocks this time:

```
ana@laptop:~/aws$ python3 prices.py s3 transfer
AWS public price list, sa-east-1, USD, excluding tax

S3 storage, USD per GB-month
  Standard, first 50 TB                                 0.04050  GB-month
  Intelligent-Tiering, frequent                         0.04050  GB-month
  Standard-IA                                           0.02210  GB-month
  One Zone-IA                                           0.01770  GB-month
  Glacier Instant Retrieval                             0.00830  GB-month
  Glacier Flexible Retrieval                            0.00765  GB-month
  Glacier Deep Archive                                  0.00320  GB-month

S3 requests, USD per 1,000
  Standard: PUT, COPY, POST, LIST                       0.00700  per 1,000
  Standard: GET and the rest                            0.00056  per 1,000
  Standard-IA: GET                                      0.00100  per 1,000
  Glacier Instant Retrieval: GET                        0.01000  per 1,000
  Intelligent-Tiering monitoring, per 1,000 objects     0.00250  per month

S3 retrieval, USD per GB
  Standard-IA                                           0.01000  GB
  Glacier Instant Retrieval                             0.03000  GB
  Glacier Flexible, expedited                           0.04200  GB
  Glacier Flexible, standard                            0.01400  GB
  Deep Archive, standard                                0.02800  GB
  Deep Archive, bulk                                    0.00800  GB

Data transfer out of sa-east-1, USD per GB
  to the internet, first 10 TB                          0.15000  GB
  to the internet, next 40 TB                           0.13800  GB
  to the internet, next 100 TB                          0.12600  GB
  to the internet, over 150 TB                          0.11400  GB
  between zones, each direction                         0.01000  GB
  to us-east-1                                          0.13800  GB
  to CloudFront                                         0.00000  GB
  in from the internet                                  0.00000  GB
```

The three meters, read off that sheet:

| meter | unit | the line |
|---|---|---|
| storage | GB-month | Standard, 0.04050 |
| requests | 1,000 requests | `PUT`, `COPY`, `POST` and `LIST`, 0.00700; `GET` and the rest, 0.00056 |
| transfer | GB leaving the region | to the internet from 0.15000, falling with volume; to another zone 0.01000; to us-east-1 0.13800; to CloudFront 0.00000 |

**A `PUT` costs twelve and a half times a `GET`**, 0.00700 against 0.00056 per thousand, and a `LIST`
is billed like a `PUT`, not like a `GET`. A program that lists a prefix before reading each object
pays the expensive rate for the listing. **Data coming in is free**, `in from the internet` at
0.00000, which is why a bucket fills without anybody noticing the cost and empties expensively.

## The size of a request against the size of a gigabyte

The units hide the comparison that matters. One gigabyte stored for a month costs 0.0405. That buys
0.0405 / 0.00056 × 1,000 = 72,321 `GET` requests, or 0.0405 / 0.00700 × 1,000 = 5,786 `PUT`s. So **when a
gigabyte's objects are read more than about 72,000 times a month in all, the reads cost more than
the storage**. For one 1 GB file that never happens. For a gigabyte made of 262,144 objects of 4 KB
each, reading every object once costs 262,144 × 0.00056 / 1,000 = 0.15, more than three and a half
times the month's storage.

A request is priced per request whatever its size, and storage is priced per byte whatever the number
of objects. Everything in the next section follows from those two sentences.

## Not one of these is visible in moto

moto counts no requests and meters no bytes, and nothing in this lab produces a bill. Every figure in
this lesson is the price sheet multiplied by a count, with the arithmetic shown, and the counts are
the design's, not measurements of anything that ran. On a real account the same meters appear as
line items of the bill, by usage type, which `aws-foundations` lesson 15 reads in the Cost and Usage
Report.
