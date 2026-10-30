---
title: The price sheet, and why this course could not read it
version: 1
---

**Azure publishes every price it charges, for every region, through a public interface that needs no
account and no key**: the Retail Prices API, at `https://prices.azure.com/api/retail/prices`. It
answers a filter with pages of JSON, one item per meter, and each item carries the service, the
region, the product, the unit, the price in US dollars and the date the price took effect. A meter is
the thing Azure counts: gigabytes stored in a tier for a month, ten thousand write operations, a
gigabyte sent out to the internet.

The program below is the course's price sheet. It asks for one service in `brazilsouth`, keeps the
answers in a file so that a second run asks nobody, and prints one line per meter:

```schooling-example
{"language": "python", "file": "prices.py", "parts": [
{"code": "import json, pathlib, sys, urllib.parse, urllib.request\n\nAPI = \"https://prices.azure.com/api/retail/prices\"\nREGION = \"brazilsouth\"\nCACHE = pathlib.Path(\"prices-cache\")\n", "note": "No key and no login: the Retail Prices API is public. The cache is a directory of JSON files, one per service, so the sheet can be printed again with no network."},
{"code": "\ndef fetch(service):\n    cached = CACHE / f\"{service}.json\"\n    if cached.exists():\n        return json.loads(cached.read_text())\n    query = f\"serviceName eq '{service}' and armRegionName eq '{REGION}' and priceType eq 'Consumption'\"\n    url = API + \"?\" + urllib.parse.urlencode({\"$filter\": query})\n    items = []\n    while url:\n        with urllib.request.urlopen(url, timeout=30) as answer:\n            page = json.load(answer)\n        items += page[\"Items\"]\n        url = page.get(\"NextPageLink\")\n    CACHE.mkdir(exist_ok=True)\n    cached.write_text(json.dumps(items))\n    return items\n", "note": "The filter is OData, the query language of the API. `priceType eq 'Consumption'` leaves out reservations, which are a discount for a commitment and a subject of `azure-foundations`. One service can run to thousands of meters across many pages, and `NextPageLink` is how the API says there are more."},
{"code": "\ndef sheet(service, words):\n    rows = [i for i in fetch(service)\n            if all(w.lower() in (i[\"productName\"] + \" \" + i[\"meterName\"]).lower() for w in words)]\n    for i in sorted(rows, key=lambda i: (i[\"productName\"], i[\"meterName\"])):\n        print(f\"{i['productName'][:34]:34} {i['meterName'][:30]:30} \"\n              f\"{i['retailPrice']:>12.6f} {i['unitOfMeasure']:>10}  {i['effectiveStartDate'][:10]}\")\n\n\nif __name__ == \"__main__\":\n    sheet(sys.argv[1], sys.argv[2:])\n", "note": "The words after the service narrow the list, so `python prices.py Storage Hot LRS` prints the Hot tier with local redundancy and not the other few thousand lines. The last column is the date the price took effect, which is the date to quote it with."}
]}
```

## Why there is no transcript under it

**This program was not run while the course was recorded.** The machine every transcript in this
course comes from reaches the internet through a proxy that only allows the addresses its owner
listed, and `prices.azure.com` was not one of them on 30 October 2026. The program is shown because
it is how you get today's prices, and it is written against the shape of the answer Microsoft
documents. What the course cannot show is the answer itself: if the first run on your computer
fails, the error is a real one this course never met.

So **this course quotes no Azure price as Azure's.** Where a lesson needs a number to do arithmetic
with, it writes a round one and says so: *"at an illustrative 0.02 USD per GB-month"* is an
instruction to do the sum with that number, not a claim about what Azure charges. Run the sheet,
read the real price, and do the same sum with it. The shape of the arithmetic is what lasts. Prices
move every few months; the facts the lessons lean on (a tier's minimum days, which operations are
charged, which transfers are free) move rarely, and the lessons take them from Microsoft's
documentation and say so.

## Running it yourself

In `~/azure`, with the network:

```sh
python prices.py Storage Hot LRS
```

The first run takes a minute, because Storage alone has thousands of meters in a region. The output
is one line per meter with its price, its unit and its date. **Read the unit before the price.** A
storage line is priced per `1 GB/Month`, and an operations line per `10K`, ten thousand operations.
The commonest mistake with an Azure bill is multiplying a count of operations by a price meant for
ten thousand of them.
