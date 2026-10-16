---
title: The question nobody designed for
version: 1
---

**Pattern A5 of lesson 9 was left without a key, and this section puts a number on it.** The back
office wants every order placed on 1 October, across all customers, to plan the next day's stock. The
table's partition key is the customer, so the question names no partition, and the only read that
answers it is a scan with a filter. On thirty items in lesson 9 the cost could not be seen. So this lesson starts from a table worth scanning. Begin with moto running in its own terminal and
the four lines of lesson 1's "Your lab, in brief" typed in this one. Create the table with the first
command of lesson 9's "The partition key and the sort key", and ask lesson 9's `seed.py`, saved in
`~/aws`, for four thousand customers. It takes about twenty seconds against moto.

```
ana@laptop:~/aws$ python3 seed.py 4000
4000 customers: 4000 profiles, 10029 orders, 20071 order lines, 34100 items
ana@laptop:~/aws$ aws dynamodb describe-table --table-name quitanda --query "Table.[ItemCount,TableSizeBytes]" --output text
34100	0
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda --filter-expression 'order_day = :d' --expression-attribute-values '{":d": {"S": "2026-10-01"}}' --select COUNT --query '[Count,ScannedCount]' --output text
240	11439
238	11445
260	11216
```

**34,100 items, and `TableSizeBytes` says 0.** moto counts items and does not measure them; AWS
measures both and refreshes the two numbers roughly every six hours, so on either side they are not a
way to watch a table. The scan answers in three lines because the command line followed the pages for
you, as it does by default, and ran the `--query` once per page. Added up: 738 orders found, 34,100
items read.

## A scan, page by page

**DynamoDB never returns a whole table in one answer.** A scan or a query stops after 1 MB of data
read, says where it stopped, and waits to be asked for the rest. The program below does that asking,
and counts what each page read, returned and weighed, which moto does not report. Save it as
`~/aws/pages.py`.

```schooling-example
{"language": "python", "file": "pages.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Read the table `quitanda` page by page, as DynamoDB hands it out.\n\n    python3 pages.py                      # a scan of every item\n    python3 pages.py 2026-10-01           # the same scan, filtered to one day's orders\n    python3 pages.py 2026-10-01 by-day    # a query on the index by-day instead\n\nFor each page: how many items DynamoDB read, how many it returned, and the\nsize of what it returned by AWS's rule for item size. moto reports neither\nsizes nor real read units, so this program counts them itself.\n\"\"\"\nimport math\nimport sys\n\nimport boto3\n\n", "note": "The manual. One program for three reads of the same question, so that their pages can be put side by side."}, {"code": "day = sys.argv[1] if len(sys.argv) > 1 else None\nindex = sys.argv[2] if len(sys.argv) > 2 else None\ndb = boto3.client('dynamodb')\nrequest = {'TableName': 'quitanda'}\nif index:\n    request.update(IndexName=index, KeyConditionExpression='order_day = :d',\n                   ExpressionAttributeValues={':d': {'S': day}})\nelif day:\n    request.update(FilterExpression='order_day = :d',\n                   ExpressionAttributeValues={':d': {'S': day}})\nread = db.query if index else db.scan\n\n\n", "note": "The arguments, and the request that every page repeats. A filter is a `FilterExpression`; the index is a `query` with `IndexName` and a key condition on its partition key."}, {"code": "def size(item):\n    total = 0\n    for name, value in item.items():\n        (kind, v), = value.items()\n        if kind == 'N':\n            digits = v.lstrip('-').replace('.', '').strip('0') or '0'\n            total += len(name) + (len(digits) + 1) // 2 + 1\n        else:\n            total += len(name) + len(v.encode())\n    return total\n\n\n", "note": "**AWS's rule for the size of an item**: every attribute's name plus its value. A string counts its UTF-8 bytes; a number about one byte per two significant digits, plus one. Close enough to price a read, which is what it is for."}, {"code": "page, scanned, returned, size_back, units = 0, 0, 0, 0, 0.0\nwhile True:\n    answer = read(**request)\n    page += 1\n    got = sum(size(i) for i in answer['Items'])\n    more = 'LastEvaluatedKey' in answer\n    print(f\"page {page}: read {answer['ScannedCount']:>6} items, returned {answer['Count']:>6}, \"\n          f\"{got:>9,} bytes returned, {'more' if more else 'last page'}\")\n    scanned += answer['ScannedCount']\n    returned += answer['Count']\n    size_back += got\n    units += 0.5 * math.ceil(got / 4096)\n    if not more:\n        break\n    request['ExclusiveStartKey'] = answer['LastEvaluatedKey']\n\n", "note": "**The loop every DynamoDB reader has.** A page ends at 1 MB of data read, or earlier with a `Limit`, and when there is more the answer carries `LastEvaluatedKey`. The next request sends it back as `ExclusiveStartKey`, and the reading stops only when a page comes back without one."}, {"code": "print(f\"{page} page{'s' if page > 1 else ''}, {scanned} items read, {returned} returned, {size_back:,} bytes returned, \"\n      f'{units:g} read units for them')\n", "note": "The totals. The read units are for what came back: each page's bytes in blocks of 4 KB, rounded up, and half a unit per block because these reads are eventually consistent. With no filter, what came back is what was read, and these are the units AWS would charge."}]}
```

```
ana@laptop:~/aws$ python3 pages.py
page 1: read  11439 items, returned  11439, 1,001,827 bytes returned, more
page 2: read  11445 items, returned  11445, 1,002,008 bytes returned, more
page 3: read  11216 items, returned  11216,   975,707 bytes returned, last page
3 pages, 34100 items read, 34100 returned, 2,979,542 bytes returned, 364.5 read units for them
ana@laptop:~/aws$ python3 pages.py 2026-10-01
page 1: read  11439 items, returned    240,    24,720 bytes returned, more
page 2: read  11445 items, returned    238,    24,503 bytes returned, more
page 3: read  11216 items, returned    260,    26,630 bytes returned, last page
3 pages, 34100 items read, 738 returned, 75,853 bytes returned, 10 read units for them
```

**The filter changed what came back and not what was read.** Both runs read the same three pages of
about a megabyte, 34,100 items in all. The first returned everything, 2,979,542 bytes, which is 364.5
read units: each page's bytes in 4 KB blocks, half a unit each for an eventually consistent read. The
second returned 738 items and 75,853 bytes, and AWS would still charge it for what it read, the same
364.5 units, because a filter runs after the read. The `10` on its last line is what the 738 orders
would cost if something could read only them, and an index can.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three scan pages of about a megabyte each read 11,439, 11,445 and 11,216 items and returned 240, 238 and 260 of them, a sliver of each page, for 364.5 read units in all. The query on the index by-day reads one page of 738 items and returns all 738, for 8.5 read units.\" data-fig=\"l10-pages\"><defs><marker id=\"l10-pages-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">scan, filtered to 1 October</text><text x=\"20\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">page 1</text><rect x=\"100\" y=\"40\" width=\"379.8007863695937\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><rect x=\"100\" y=\"40\" width=\"7.968545216251638\" height=\"28\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"490\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">11,439 read</text><text x=\"490\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">240 returned</text><text x=\"20\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">page 2</text><rect x=\"100\" y=\"80\" width=\"380.0\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><rect x=\"100\" y=\"80\" width=\"7.902140672782874\" height=\"28\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"490\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">11,445 read</text><text x=\"490\" y=\"101\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">238 returned</text><text x=\"20\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">page 3</text><rect x=\"100\" y=\"120\" width=\"372.39667977282653\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><rect x=\"100\" y=\"120\" width=\"8.632590650939274\" height=\"28\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"490\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">11,216 read</text><text x=\"490\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">260 returned</text><text x=\"620\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">364.5 read units</text><text x=\"20\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">query on by-day</text><text x=\"20\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">page 1</text><rect x=\"100\" y=\"192\" width=\"24.503276539973786\" height=\"28\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"140\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">738 read</text><text x=\"140\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">738 returned</text><text x=\"620\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">8.5 read units</text></svg>", "caption": "Drawn to scale by items. The filter thins what comes back; the pages, and the bill, stay the size of the table."}
```

## What the scan costs

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

**At 0.1875 dollars per million read units, one scan of this table is 364.5 × 0.1875 / 1,000,000 =
0.0000683 dollars**, which is nothing. A screen in the back office that refreshes every minute runs it
43,200 times in a 30-day month: 15,746,400 read units, or **2.95 dollars a month**. Still small,
because this table is small: 4,000 customers and two weeks of orders. A scan costs the size of the
table, and the table grows with every order ever placed. The same screen on a table a hundred times
this size is 295 dollars a month for one question, and the bill keeps growing after nobody remembers
why. The next section answers the same question for about a fortieth of the read units.
