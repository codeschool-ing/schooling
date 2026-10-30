---
title: Serving files to the internet
version: 1
---

**Bytes that leave Azure for the internet are the most expensive thing Blob Storage does**, and they
are billed to the account's owner, whoever asked for them. A public website's images, a mobile app's
downloads, a report a customer fetches: each byte out is metered per GB, at a price several times what
keeping that byte for a month costs. This section is taught from Microsoft's bandwidth pricing page,
and nothing in it was run; Azurite sends nothing anywhere a meter could see.

Quitanda's product images are 500 GB, and the app and the site serve about 20 TB of them a month.
That is the fourth design of `costs.py`:

```
500 GB of images, 20 TB out          10.00     21.47       0.00  2,038.00  2,069.47
```

**Storage is 10.00 of a month that costs 2,069.47.** The reads, 53,687,091 `Get Blob` operations, are
21.47. The other 2,038.00 is the transfer: 20,480 GB, less the 100 GB that are free, at the
illustrative 0.10 a GB.

**The first 100 GB a month to the internet are free**, by Microsoft's bandwidth page, and past them
the price per GB falls in steps as the month's volume grows. `costs.py` uses one flat illustrative
rate instead of the steps, which keeps the sum readable and leaves its shape intact: at 20 TB a month,
the free 100 GB are half of one per cent of the transfer, and the transfer is 98.5% of the bill.

## Behind a content delivery network

**A content delivery network fetches a blob from the account once, keeps a copy close to the viewers,
and serves the next requests from the copy.** Azure's is Azure Front Door, which `azure-foundations`
lesson 22 places among Azure's load balancers. The account sees one `Get Blob` where it would have
seen many, and sends far less to the internet itself.

The last design assumes 19 of every 20 downloads are answered from the network's copies, so the
account answers 2,684,354 reads, which cost 1.07:

```
the same behind a CDN                10.00      1.07       0.00         -         -
```

**The dashes are honest.** The network charges for delivering the bytes to the viewers, and for their
requests, on a price list of its own, and that list also says whether the leg from the account to the
network is charged. `costs.py` reads none of it, so it prints no transfer and no total. What the line
does show is the half that belongs to the account: the 2,038.00 of the line above is gone from its
bill, and its reads fell from 21.47 to 1.07. Whether the whole is cheaper depends on the network's
price and on how many downloads its copies answer, and neither was checked here.

It has a second effect that matters as much: **the account stops being the address the internet talks
to.** With the network in front, the container can stay private, with the anonymous access of lesson
6 left off, and the account reached only through the network.

## Nobody else pays

**Blob Storage has no setting that sends the bill to whoever reads.** A partner who copies Quitanda's
5 TB of order history into another region, with a SAS token Quitanda gave them, moves 5 TB out of
`brazilsouth`, and the transfer lands on Quitanda's invoice. Sharing data without paying for every
read is an arrangement rather than a setting: copy it to the partner once, into an account they pay
for, or agree on what they pay you. A SAS token with a short expiry, from lesson 6, limits how long the
door stays open. It does nothing about who pays while it is.
