---
title: Paired regions, and what it costs to cross a boundary
version: 1
---

**Most Azure regions have a pair: a second region, normally in the same geography, that Microsoft
treats as its partner.** The pairing is Microsoft's decision, not yours, and it does three things:

- **platform updates are rolled out to one region of a pair at a time**, so a faulty update reaches
  one of the two before the other;
- **in a broad outage, one region of every pair is first in the queue for recovery**;
- **some services replicate to the pair on their own.** A storage account set to geo-redundant
  storage copies every write to the paired region, and you do not choose where.

The pair is in `metadata.pairedRegion` of each region in `az account list-locations`, which this lab
cannot run, and in a table in Microsoft's documentation, which is where these two come from:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l01-pairs\" aria-label=\"Four regions and the pairs Microsoft documents for them. brazilsoutheast, in Rio de Janeiro, is paired with brazilsouth, in São Paulo. brazilsouth is paired with southcentralus, in Texas, outside its own geography. southcentralus and northcentralus are paired with each other. The arrows from Rio to São Paulo and from São Paulo to Texas run one way only.\"><defs><marker id=\"l01-pairs-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-pairs-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"70.0\" width=\"140.0\" height=\"58.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"100.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">brazilsoutheast</text><text x=\"100.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Rio de Janeiro</text><rect x=\"205.0\" y=\"70.0\" width=\"140.0\" height=\"58.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"275.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">brazilsouth</text><text x=\"275.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">São Paulo</text><rect x=\"380.0\" y=\"70.0\" width=\"140.0\" height=\"58.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"450.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">southcentralus</text><text x=\"450.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Texas</text><rect x=\"555.0\" y=\"70.0\" width=\"140.0\" height=\"58.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"625.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">northcentralus</text><text x=\"625.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Illinois</text><text x=\"117.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">Brazil</text><text x=\"467.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">United States</text><path d=\"M30.0 52.0 L345.0 52.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M380.0 52.0 L695.0 52.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M171.0 99.0 L204.0 99.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l01-pairs-af-ah-amber)\"></path><path d=\"M346.0 99.0 L379.0 99.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l01-pairs-af-ah-amber)\"></path><path d=\"M521.0 92.0 L554.0 92.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l01-pairs-af-ah-phosphor)\"></path><path d=\"M554.0 106.0 L521.0 106.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l01-pairs-af-ah-phosphor)\"></path><text x=\"360.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">amber: the pair runs one way, the region it points at has another pair</text><text x=\"360.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">green: two regions that are each other's pair</text></svg>", "caption": "São Paulo's pair is in Texas, and Texas's pair is not São Paulo."}
```

**São Paulo's pair is not in Brazil.** `brazilsouth` is paired with `southcentralus`, in Texas, and
the pairing runs one way: South Central US's own pair is North Central US. `brazilsoutheast` is
paired with `brazilsouth`. So a storage account in São Paulo with geo-redundant replication keeps its
second copy in the United States, and **for a company bound to keep its data in Brazil that is a
decision the pairing made for it**. The way out is to replicate yourself, to a region you choose,
which for data that must stay in the country is `brazilsoutheast`, the region Microsoft opens for
that reason.

Pairs are a property of the older regions. Several regions opened in recent years have no pair at
all, and rely on their availability zones; Microsoft's own advice is to design recovery around the
regions your system needs, and treat the pair as one input among several.

## Crossing a boundary has a price

Every arrow between two places in Azure is data moving, and moving data is billed by the gigabyte,
at a price that depends on which boundary it crosses:

| the data goes | what Microsoft charges, by its price list |
|---|---|
| into Azure from the internet | nothing |
| between availability zones of one region | nothing, at the time this course was written |
| between two regions | a price per GB, higher between continents than inside one |
| out of Azure to the internet | a price per GB that falls with volume, by tiers, and depends on the region it leaves |

**The figures themselves are on Microsoft's price list and nowhere else**, and they change. The list
is public through an API that needs no account, and the program below reads it.

## Reading the price list yourself

Save this as `~/azure/price.py`:

```schooling-example
{"language": "python", "file": "price.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Read Azure's public price list: price.py SERVICE REGION [TEXT].\"\"\"\nimport json\nimport sys\nimport urllib.parse\nimport urllib.request\n\nAPI = 'https://prices.azure.com/api/retail/prices'\n\n", "note": "Standard library only, so it runs in the lab's virtual environment and outside it. `API` is Microsoft's **Retail Prices API**, which answers anybody: no account, no key, no sign-in."}, {"code": "def prices(service, region):\n    query = f\"serviceName eq '{service}' and armRegionName eq '{region}' and priceType eq 'Consumption'\"\n    url = API + '?' + urllib.parse.urlencode({'$filter': query})\n", "note": "The filter is OData, a query language written into the address. `serviceName` and `armRegionName` take the exact strings the price list uses, such as `Bandwidth` and `brazilsouth`. `Consumption` keeps pay-as-you-go prices and leaves out reservations, which lesson 14 reads."}, {"code": "    while url:\n        with urllib.request.urlopen(url, timeout=60) as reply:\n            page = json.load(reply)\n        yield from page['Items']\n        url = page.get('NextPageLink')\n\n\n", "note": "One page holds at most a thousand prices, and `NextPageLink` is the address of the next one, absent on the last. Following it until it is gone is the only way to be sure you have them all."}, {"code": "def main():\n    service, region = sys.argv[1], sys.argv[2]\n    text = sys.argv[3].lower() if len(sys.argv) > 3 else ''\n    for p in prices(service, region):\n        name = f\"{p['productName']} | {p['meterName']}\"\n        if text not in name.lower():\n            continue\n        print(f\"{p['retailPrice']:>10.4f} {p['currencyCode']} per {p['unitOfMeasure']:<8}\"\n              f\" from {p['tierMinimumUnits']:>8g}  {name}  ({p['effectiveStartDate'][:10]})\")\n\n\nmain()\n", "note": "Each price is one **meter**: the thing being counted, its unit and its price per unit. `tierMinimumUnits` is where a tier starts, since some meters get cheaper past a quantity. **`effectiveStartDate` is the date that price took effect**, and it is the date to quote beside any price you repeat."}]}
```

Then ask it for the bandwidth meters of São Paulo, keeping the ones that mention data transfer:

```sh
python3 price.py Bandwidth brazilsouth 'data transfer'
```

Each line it prints is a price, in US dollars, per unit, from the tier's first unit, with the meter's
name and the date it took effect. Run it with `southcentralus` instead and compare: what leaving São
Paulo costs against what leaving Texas costs is the whole argument of this section, in two lists.

**This program was not run for the course.** The machine the lessons were recorded on is not allowed
to reach `prices.azure.com`, so there is no transcript here, and no price in these lessons comes from
it. It was checked to be correct Python and to follow the API's pages; the prices are yours to read.
Lessons 13 to 15, which are about money, quote no figure as Azure's without saying where it came
from, and reason with round numbers that say they are round.

**Write the date beside any price you repeat**, from the `effectiveStartDate` the program prints. A
price without a date is a claim nobody can check, and in a year it will be wrong without anybody
having noticed it change.
