---
title: Three ways to pay for them
version: 1
---

**Request units are consumed per operation and paid for per second of capacity, unless you choose
to pay per unit.** That is the whole difference between the three ways Cosmos DB sells them, and the
choice is about the shape of the load more than its size. This section is taught from Microsoft's
documentation; the emulator, as its end shows, accepts every setting and enforces none.

| | you set | you are billed for | when it fits |
|---|---|---|---|
| manual throughput | a number of RU/s, from 400, in steps of 100 | that number, every hour it exists | a load that is busy most of the day |
| autoscale | a maximum, from 1,000 RU/s | each hour, the highest RU/s it scaled to, at 1.5 times the manual rate | a load with peaks and quiet hours |
| serverless | nothing | the request units consumed, per million | a load that is idle most of the time |

Storage is billed separately in all three, per gigabyte a month.

## Manual throughput

**You reserve a number of request units a second, and every second gets that many to spend.** A
container at 1,000 RU/s can do a thousand 1 KB point reads every second, all day, and pays the same
whether it does or not. Throughput can be set on a container, or on a database and shared by its
containers, which suits many small containers whose peaks do not coincide. The number can be changed
at any time; what it cannot do is change itself.

## Autoscale

**You choose a ceiling, Tmax, and Cosmos DB moves between a tenth of it and all of it, at once, as
the load asks.** There is no warm-up and no reaction delay of minutes: a container at an autoscale
maximum of 4,000 RU/s sits at 400 overnight and serves 4,000 the second the promotion starts. Each hour
is billed at the highest level it reached in that hour, never below the tenth. The documentation
prices an autoscale RU/s at 1.5 times a manual one for an account that writes in one region. That
factor sets the break-even: **autoscale is cheaper than manual whenever the hours, averaged, are
billed at less than two thirds of the maximum.** A load that sits near its peak all day is the one
case where manual wins.

## Serverless

**Nothing is reserved, and each request unit is billed as it is consumed.** A container that does
nothing costs only its storage. The documentation limits serverless to accounts in a single region,
and the choice is made when the account is created rather than per container. Its weakness is the
mirror of manual's: a unit consumed serverless costs far more than the same unit reserved and used,
so a busy container pays a premium on every request it makes. The next section puts numbers on where
each one stops being the cheapest.

## The free tier

One account per subscription can be created with the free tier, which the documentation describes as
the first 1,000 RU/s and 25 GB of storage at no charge, for the life of the account. It is enough for
a development account and for small production ones, and like every free allowance it is not a plan
for a business.

## What the emulator does with all this

Save as `modes.py` and run it:

`modes.py`:

```python
from azure.cosmos import CosmosClient, PartitionKey, ThroughputProperties

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
db = CosmosClient("http://localhost:8081", KEY).create_database_if_not_exists("quitanda")

asked = {
    "manual-1000": 1000,
    "autoscale-4000": ThroughputProperties(auto_scale_max_throughput=4000),
    "manual-100": 100,
}
made = {name: db.create_container_if_not_exists(name, PartitionKey("/id"), offer_throughput=throughput)
        for name, throughput in asked.items()}

for name, container in made.items():
    given = container.get_throughput()
    print(f"{name:15} reports {given.offer_throughput} RU/s, autoscale maximum "
          f"{given.auto_scale_max_throughput}; offer for {given.properties['offerResourceId']}, "
          f"container is {container.read()['_rid']}")
```

```
ana@laptop:~/azure$ python modes.py
manual-1000     reports 100 RU/s, autoscale maximum None; offer for MDAwNA==, container is MDAwMg==
autoscale-4000  reports 100 RU/s, autoscale maximum None; offer for MDAwNA==, container is MDAwMw==
manual-100      reports 100 RU/s, autoscale maximum None; offer for MDAwNA==, container is MDAwNA==
```

**Three containers asked for three different things, and all three report 100 RU/s and no autoscale
maximum.** The last two columns say why: every answer is the offer belonging to `MDAwNA==`, the last
container created, whichever container asked. Two of the three answers describe another container,
and the third describes a request Azure would have refused, since 100 is below the manual minimum of
400. **On the emulator, throughput is a field it stores and returns, not a budget anything spends**,
and not always the right container's field either. What a container is provisioned at on Azure is
read from its declaration and from the account, never from here.
