---
title: "Hetzner: German, dedicated servers and cloud servers"
version: 1
---

Hetzner is a German company, founded in 1997, that owns and runs its own data centres. It sells
two things that are worth keeping apart, because they are different trades.

## Dedicated servers

A **dedicated server** is a physical machine rented by the month. Nobody else runs on it: you get
the whole processor, the whole memory and the disks, usually with no virtualisation at all
between you and the hardware. This is older than the cloud, and it is still the cheapest way to buy
a lot of computing that runs all day, every day. Hetzner even runs an auction of used servers,
priced down as they wait.

What you take on in exchange is everything lesson 1 filed under "left to you". A disk that fails is replaced by
Hetzner's staff when you ask, but the RAID that kept the data alive, the backups, the operating
system and its updates are yours. **A dedicated server takes minutes to hours to arrive, not
seconds, and it does not scale by an API call.** You buy it for a load you already know.

## Hetzner Cloud

Hetzner Cloud is the other product: virtual machines created in seconds through an API, with
volumes, private networks, load balancers, firewalls and, since 2024, S3-compatible object storage.
It is billed by the hour up to a monthly cap, with a generous quantity of transfer included, the
same shape as DigitalOcean's model.

The list stops there. **Its catalogue is essentially the IaaS layer**: there is no managed queue, no
data warehouse, and the database, the cache and whatever else your application needs are yours to
run on the machines. For a team that is comfortable doing that, the reason to accept it is the
price.

## Low prices, described without numbers

Hetzner is known for low prices, and the reputation is earned: for the same processor count and
memory, its list prices sit well below the hyperscalers'. This course did not capture Hetzner's
price pages, so there is no figure here to quote. What is worth understanding is **where the
difference comes from**, because that tells you whether it applies to you:

- the catalogue is short, so the price is not carrying the engineering of hundreds of services;
- the company builds and runs its own data centres, in a few places, and fills them with machines
  it sells as they are rather than dressed as managed services.

Neither reason is a weakness in the machine you rent. Both are reasons it comes with less around
it.

## Where it is

Hetzner's own data centres are in Germany, at Nuremberg and Falkenstein, and in Finland, at
Helsinki. Hetzner Cloud also has locations in the United States and in Singapore. **It has none in
South America.**

Being a German company with data centres in the European Union is an argument of its own for
customers there: their data stays under European law and in European buildings, which matters for
the GDPR, the European counterpart of the LGPD that lesson 2 discussed. For a Brazilian audience,
the same fact cuts the other way, and the distance across the Atlantic is one more line that lesson
9 turns into milliseconds.
