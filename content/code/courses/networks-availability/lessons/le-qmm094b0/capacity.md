---
title: Capacity is airtime, not a client count
version: 1
---

An access point's data sheet says it supports some hundreds of clients, and the number is true in the
narrow sense that it will keep that many associated. **What runs out first is airtime.** A channel carries
one transmission at a time, as lesson 6 showed, so every client on it takes turns, and a client's turn
lasts as long as its data takes to send at its rate.

That is why the sticky client of the first section matters to everybody else. The same download, at three
data rates:

```schooling-example
{"language": "python", "file": "airtime.py", "parts": [{"code": "payload_bits = 10 * 8_000_000        # a 10 MB download", "note": "One download, the same for every client: ten megabytes is eighty million bits."}, {"code": "rates = [(\"near the AP\", 400), (\"mid-cell\", 150), (\"sticky, far away\", 12)]\nfor where, mbps in rates:\n    seconds = payload_bits / (mbps * 1_000_000)\n    print(f\"{where:18} {mbps:4} Mbit/s  {seconds:6.2f} s of airtime\")", "note": "Three clients at three data rates. The rates are illustrative, and they are treated as the speed the data actually moves at, leaving out the protocol overhead lesson 6 counted, which makes every line longer and changes nothing about the comparison."}, {"code": "near = payload_bits / 400e6\nfar = payload_bits / 12e6\nprint(f\"the far client holds the channel {far / near:.0f} times as long\")", "note": "The ratio is the point. While the far client is transmitting, nobody else on that channel is."}], "output": "near the AP         400 Mbit/s    0.20 s of airtime\nmid-cell            150 Mbit/s    0.53 s of airtime\nsticky, far away     12 Mbit/s    6.67 s of airtime\nthe far client holds the channel 33 times as long"}
```

**The far client holds the channel 33 times as long** as a client beside the AP for the same ten
megabytes, and for 6.67 seconds nobody else on that channel transmits. A room full of clients at good
rates can be slower than one with a few clients at bad ones.

## Planning from demand

So a design starts from what the clients will do, not from how many there are:

1. Count the devices that will be active at once in each area, not the people.
2. Multiply by what each needs: a video call, a few Mbit/s each way; a barcode scanner, almost nothing but
   a short roam.
3. Divide by what one radio really delivers at the rates your cells allow, which is well below the
   advertised rate (lesson 6), and leave margin.

Vendors' planning guides commonly quote a few dozen active clients per radio for office use, and fewer
for voice or video. **Those are starting points to check against step 3, not limits.** A lecture theatre
with 200 laptops needs several radios on different channels, placed so that each hears only its share of
the room, and lesson 7's advice holds here: more APs at lower power, not fewer shouting.

## Band steering

Most clients can use both 2.4 GHz and 5 GHz, and 5 GHz has more channels and less interference (lessons 6
and 7). Left alone, some clients pick 2.4 GHz because its signal is stronger at a distance. **Band
steering** nudges dual-band clients to 5 GHz: the AP, having heard a client probe on both bands, is slow
or silent in answering it on 2.4 GHz, or sends an 802.11v suggestion once it has joined.

It is **not a standard mechanism**, and each vendor's version behaves differently. Set too aggressively, it
delays a client's first connection while it waits for an answer on the band it asked on. The measure of
whether it works is where the dual-band clients end up, which a controller's client list shows.
