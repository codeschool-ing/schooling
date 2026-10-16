---
title: Life-cycle rules, and the clock moto does not have
version: 1
---

**A life-cycle configuration is a list of rules that S3 applies to a bucket's objects as they age**:
move them to a cheaper class after so many days, delete them after so many more, delete noncurrent
versions, clear away uploads that were started and never finished. It is the one place where S3 does
work on its own, with no request from you, and that is exactly the part moto cannot imitate.

A rule has a filter, which says which objects it applies to, and one or more actions:

| action | what it does |
|---|---|
| `Transitions` | moves current versions to another class after a number of days since they were written |
| `Expiration` | deletes current versions after a number of days; in a versioned bucket, adds a delete marker instead |
| `NoncurrentVersionTransitions` | moves noncurrent versions, counted from the day they were replaced |
| `NoncurrentVersionExpiration` | deletes noncurrent versions for good, optionally keeping the newest few |
| `AbortIncompleteMultipartUpload` | removes the parts of an upload started that many days ago and never completed |

The filter is a prefix, a tag, an object size range, or several of those joined with `And`. A rule
with an empty filter applies to the whole bucket.

## Quitanda's rules

The raw bucket holds the nightly exports of lesson 1 under `raw/orders/`. Analysts read the last
month often, the last year rarely, and nothing older except for an audit. Write that down as rules,
in a file:

`lifecycle.json`:

```json
{
  "Rules": [
    {
      "ID": "orders-age-out",
      "Status": "Enabled",
      "Filter": {"Prefix": "raw/orders/"},
      "Transitions": [
        {"Days": 30, "StorageClass": "STANDARD_IA"},
        {"Days": 365, "StorageClass": "DEEP_ARCHIVE"}
      ],
      "Expiration": {"Days": 2555}
    },
    {
      "ID": "scratch-goes-in-a-week",
      "Status": "Enabled",
      "Filter": {"And": {"Prefix": "raw/", "Tags": [{"Key": "kind", "Value": "scratch"}]}},
      "Expiration": {"Days": 7}
    },
    {
      "ID": "tidy-the-bucket",
      "Status": "Enabled",
      "Filter": {},
      "NoncurrentVersionExpiration": {"NoncurrentDays": 7},
      "AbortIncompleteMultipartUpload": {"DaysAfterInitiation": 3}
    }
  ]
}
```

**An export is Standard for its first month, Standard-IA until it is a year old, Deep Archive for
six more years, and then gone**, 2,555 days being seven years. An object tagged `kind=scratch`
under `raw/` lives a week. And anywhere in the bucket, a replaced version lives seven days and a
multipart upload left unfinished is cleared after three.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 222\" role=\"img\" aria-label=\"The orders-age-out rule on a timeline of days, on a square-root scale. Days 0 to 30, Standard at 0.0405 a GB-month; 30 to 365, Standard-IA at 0.0221; 365 to 2,555, Deep Archive at 0.0032; on day 2,555 the object is deleted. One GB costs 0.52 USD over its life under the rule, against 3.45 USD if it stayed in Standard.\" data-fig=\"l03-lifeline\"><defs><marker id=\"lc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40.0\" y=\"70.0\" width=\"69.3\" height=\"40.0\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"74.7\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--ink)\" font-weight=\"600\">Standard</text><text x=\"74.7\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0405 a GB-month</text><rect x=\"109.3\" y=\"70.0\" width=\"172.5\" height=\"40.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"195.6\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Standard-IA</text><text x=\"195.6\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0221 a GB-month</text><rect x=\"281.9\" y=\"70.0\" width=\"398.1\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"480.9\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Deep Archive</text><text x=\"480.9\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0032 a GB-month</text><path d=\"M40.0 60.0 L40.0 116.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"40.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><path d=\"M109.3 60.0 L109.3 116.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"109.3\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">30</text><path d=\"M281.9 60.0 L281.9 116.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"281.9\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">365</text><path d=\"M680.0 60.0 L680.0 116.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"680.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2,555</text><text x=\"680.0\" y=\"158.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">deleted</text><text x=\"40.0\" y=\"24.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">days since the object was written</text><text x=\"40.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">one GB for its whole life, seven years:</text><text x=\"40.0\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">with the rule 0.52 USD; in Standard alone 3.45 USD</text></svg>", "caption": "The life of an export under the rule. The scale is the square root of the days, so that the first month does not vanish beside the seven years."}
```

**Over its seven years a gigabyte under the first rule costs about 0.52 USD**, against 3.45 if it had
stayed in Standard, at the prices of lesson 2. A month is 30 days: Standard for 30 days is
30 / 30 × 0.0405 = 0.0405, Standard-IA for 335 days is 335 / 30 × 0.0221 = 0.2468, Deep Archive for
2,190 days is 2,190 / 30 × 0.0032 = 0.2336, together 0.5209. Standard for all 2,555 days would be
2,555 / 30 × 0.0405 = 3.449. Apply the file and read it back:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-raw-prod
make_bucket: quitanda-raw-prod
ana@laptop:~/aws$ aws s3api put-bucket-lifecycle-configuration --bucket quitanda-raw-prod --lifecycle-configuration file://lifecycle.json
ana@laptop:~/aws$ aws s3api get-bucket-lifecycle-configuration --bucket quitanda-raw-prod --query '[TransitionDefaultMinimumObjectSize, Rules[].ID]'
[
    "all_storage_classes_128K",
    [
        "orders-age-out",
        "scratch-goes-in-a-week",
        "tidy-the-bucket"
    ]
]
```

**`TransitionDefaultMinimumObjectSize` was added by S3, not by the file**: its value,
`all_storage_classes_128K`, means objects smaller than 128 KB are not transitioned at all unless the
configuration says otherwise. That is AWS's default since 2024, and it is the previous lesson's
128 KB rule applied for you: a 10 KB export moved to Standard-IA would be billed as 128 KB, so S3
leaves it where it is.

The unfinished upload is worth the rule because it is invisible. A multipart upload sends a large
file in parts and joins them at the end; if the program dies before the end, the parts stay, are
billed, and appear in no listing of objects. They only show in `list-multipart-uploads`.

## What moto does with the rules

**moto stores the configuration and never applies it.** There is no clock in moto that ages an
object; nothing happens in it between two requests. The plainest test is a rule that should act at
once. A `put-bucket-lifecycle-configuration` replaces the whole configuration, so this one takes the
place of Quitanda's three rules:

```
ana@laptop:~/aws$ aws s3api put-bucket-lifecycle-configuration --bucket quitanda-raw-prod --lifecycle-configuration '{"Rules":[{"ID":"at-once","Status":"Enabled","Filter":{"Prefix":"now/"},"Transitions":[{"Days":0,"StorageClass":"GLACIER"}],"Expiration":{"Days":1}}]}'
ana@laptop:~/aws$ head -c 200000 /dev/urandom > big.bin && aws s3 cp big.bin s3://quitanda-raw-prod/now/big.bin
upload: ./big.bin to s3://quitanda-raw-prod/now/big.bin           
ana@laptop:~/aws$ sleep 5; aws s3api head-object --bucket quitanda-raw-prod --key now/big.bin --query '{class: StorageClass, expiration: Expiration}'
{
    "class": null,
    "expiration": null
}
ana@laptop:~/aws$ aws s3api create-multipart-upload --bucket quitanda-raw-prod --key now/half.bin --query Key
"now/half.bin"
ana@laptop:~/aws$ aws s3api list-multipart-uploads --bucket quitanda-raw-prod --query 'Uploads[].[Key,Initiated]' --output text
now/half.bin	2010-11-10T20:48:33+00:00
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod --recursive
2026-10-16 13:11:17     200000 now/big.bin
```

**The object is still `STANDARD`, and no expiration date is announced.** It is 200,000 bytes, above
the 128 KB line, so the default described above is not the reason. On AWS this rule would move every
new object under `now/` to Glacier Flexible Retrieval at the next run, and `head-object` on a
key covered by an expiration rule carries an `Expiration` field naming the day it goes. moto shows
neither. The `Initiated` date of the unfinished upload, in 2010, is another sign that the time in
moto is not a time anything is measured against.

And moto checks less than S3 when the rule is written. AWS refuses a transition to Standard-IA or
One Zone-IA before 30 days, because an object has to spend 30 days in Standard first:

```
ana@laptop:~/aws$ aws s3api put-bucket-lifecycle-configuration --bucket quitanda-raw-prod --lifecycle-configuration '{"Rules":[{"ID":"too-soon","Status":"Enabled","Filter":{"Prefix":"raw/"},"Transitions":[{"Days":10,"StorageClass":"STANDARD_IA"}]}]}'
ana@laptop:~/aws$ aws s3api get-bucket-lifecycle-configuration --bucket quitanda-raw-prod --query 'Rules[].Transitions'
[
    [
        {
            "Days": 10,
            "StorageClass": "STANDARD_IA"
        }
    ]
]
```

**It was accepted.** Against S3 the same request fails, and the error says that the days of a
transition to `STANDARD_IA` must be at least 30. What a life-cycle rule does over months is taught
here from AWS's documentation, and the rule files are checked by you: moto confirms only that they
parse.

Two documented details complete the picture. S3 evaluates rules about once a day, so an object
reaches its new class some time after the day it qualifies, not at the minute. And a transition is
a request per object, billed by the target class, which is one more reason the 128 KB default exists.
