---
title: What "free" means on a price list
version: 2
---

"It's on the free tier" is said as if it meant the thing costs nothing. **A free tier is not a price of
zero. It is a price of zero up to a limit**, or until a date, and the bill starts the moment either is
passed. Three different offers are called free, and each ends differently.

## An allowance

An allowance is a quantity each month that is not charged. Lambda's is on the sheet: 1,000,000 requests
and 400,000 GB-seconds a month. In the raw price list it is a tier, as the section on reading the price
list described one: a price dimension with a price of zero and an end. `$url` is the Lambda file for
`sa-east-1` that section set; in a new terminal, set it again with the same `url=` line.

```
ana@laptop:~/cloud$ curl -s "$url" | jq '(.products[] | select(.attributes.usagetype == "Global-Request") | .sku) as $s | .terms.OnDemand[$s][].priceDimensions[] | {description, beginRange, endRange, pricePerUnit}'
{
  "description": "AWS Lambda - Requests Free Tier - 1,000,000 Requests",
  "beginRange": "0",
  "endRange": "1000000",
  "pricePerUnit": {
    "USD": "0.0000000000"
  }
}
```

Two things in that answer matter. The range ends at `1000000`, and past it the ordinary price applies,
0.20 per million requests. And the query selected the product by the usage type `Global-Request`, not
`SAE1-Request`: **the allowance belongs to the account, not to a region or a function.** Twenty
functions in three regions share the same million requests.

Work one out. A function with 512 MB of memory runs for 200 ms per request and is called 3 million
times in a month. The requests past the allowance are 2 million, which cost 0.40. The compute is
3,000,000 × 0.2 s × 0.5 GB = 300,000 GB-seconds, inside the 400,000 that are free. **The month costs
0.40 USD.**

Now the product grows to 10 million requests. The requests past the allowance are 9 million, 1.80. The
compute is 1,000,000 GB-seconds, of which 600,000 are past the allowance, at 0.0000166667 each: 10.00.
The month costs 11.80. Nothing broke and nothing was changed; the allowance was simply used up, and the
second line, which had been zero for as long as anybody had looked, became most of the bill.

Traffic has an allowance too, and it is not on the sheet, which prints only the priced tiers. It is in
the data transfer offer, under a usage type that also starts with `Global`:

```
ana@laptop:~/cloud$ dt=https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AWSDataTransfer/20260916132208/sa-east-1/index.json
ana@laptop:~/cloud$ curl -s "$dt" | jq -r '(.products[] | select(.attributes.usagetype == "Global-DataTransfer-Out-Bytes") | .sku) as $s | .terms.OnDemand[$s][].priceDimensions[].description'
$0 for 100GB of data transfer out to the internet, aggregated globally, each month
```

That is why the estimate's 500 GB out would be billed as 400: 60.00 rather than the 75.00 the program
printed, which counted every gigabyte at the sheet's price.

## A trial

A trial is free for a period. For years the example everybody knew was twelve months of a small machine
on a new AWS account. The machine was free in month twelve and billed at the full hourly price in month
thirteen, still running, because **the end of a trial ends the discount, not the resource**. Nobody gets
a message saying the machine is now paid for. The next bill is the message.

## Credits

Credits are an amount of money to spend on anything, usually expiring. Google Cloud's free trial gives a
new customer 300 USD of credit for 90 days; Azure's free account gives 200 USD for 30 days. Credits
behave differently from the other two in one useful way: when those trial credits run out, the provider
stops the resources rather than billing for them, until you upgrade the account to a paid one. After the
upgrade, that protection is gone.

## A free tier is not a cap

Apart from that one case, **nothing in a free tier stops usage when the free part ends**. An allowance
that is exceeded is billed at list price. A function called in a loop by a bug does not stop at a
million requests; it carries on at 0.20 per million, and at the GB-second price, for as long as the loop
runs. A limit that stops spending has to be built, and the section on budgets shows how far the
providers' tools go towards that.

So treat a free tier as what it is: a discount on the first units, useful for learning and for small
products, with a date or a quantity after which the ordinary sheet applies. Estimate as if it were not
there, and subtract it afterwards.
