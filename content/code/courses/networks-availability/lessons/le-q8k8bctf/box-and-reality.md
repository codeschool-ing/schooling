---
title: The number on the box and the number you get
version: 1
---

A router sold as **AX3000** promises nobody 3000 Mbit/s. The number is a sum of two radios. On 2.4
GHz, two streams on a 40 MHz channel give 2 × 286.8 = 573.6 Mbit/s; on 5 GHz, two streams on 160 MHz
give 2 × 1201.0 = 2402 Mbit/s, both rates from the program of the channel-width section. Together they
make 2975.6, and the box rounds it to 3000. **No client can use both radios at once**, so the most any
one device could see is the 2402, and even that is a link rate, not a download.

The **link rate** is the rate at which the frames themselves are sent, and it is what a phone shows in
its Wi-Fi details. What arrives, the throughput, is always less, for reasons that have nothing to do
with a fault, and **the first of them is that only one device talks at a time**:

- The air is half duplex. On one channel, one device transmits at a time: the access point and every
  client take turns, and an upload and a download share the same air rather than running side by side
  as on a switched Ethernet cable.
- Every transmission pays a fixed cost before its data: a preamble sent at a slow, fixed rate so that
  everybody can hear it, a gap, a random wait to avoid colliding with others, and an acknowledgement
  afterwards.
- A frame lost to noise or to a collision is sent again, and a client that loses many is moved to a
  slower modulation.

How much is left depends on how much data each transmission carries, but the figure usually quoted
for a single client close to the access point, with TCP, is **about 50 to 70% of the link rate**. That
is a typical value from practice, not a number any standard sets. The program below takes 60%.

## Airtime is the resource

What a channel shares is time, and a client uses time in inverse proportion to its rate. Four clients
on one access point, on an 80 MHz channel, each download a 10 MB file, at the link rates a Wi-Fi 6 phone and laptop would
negotiate at different distances, plus an old 802.11g printer. It was run with `python3`:

```schooling-example
{"language": "python", "file": "airtime.py", "parts": [{"code": "# Four clients each download 10 MB from one access point, on one channel.\nFILE_BITS = 10 * 8_000_000  # 10 MB\nEFFICIENCY = 0.6            # share of the link rate left after overheads: a typical value", "note": "Ten megabytes is eighty million bits. The 60% is the assumption of this section, a typical share for one client near the access point, and changing it moves every time below by the same factor without changing which client is the problem."}, {"code": "clients = {                 # the link rate each one negotiated, in Mbit/s\n    \"phone, same room\": 1201,\n    \"laptop, next room\": 720,\n    \"phone, far corner\": 72,\n    \"old 802.11g printer\": 54,\n}", "note": "Two streams on 80 MHz give the phone 1201 Mbit/s up close. The laptop in the next room has dropped to 64-QAM, 720, and the phone in the far corner to the slowest modulation, 72. The printer speaks only 802.11g and its best is 54."}, {"code": "busy = 0.0\nfor name, link in clients.items():\n    seconds = FILE_BITS / (link * 1e6 * EFFICIENCY)\n    busy += seconds\n    print(f\"{name:20} {link:5} Mbit/s  {seconds:6.3f} s of airtime\")", "note": "Each client's airtime is its file divided by the rate it really gets. The channel serves one at a time, so the times add up."}, {"code": "moved = FILE_BITS * len(clients)\nprint(f\"channel busy {busy:.3f} s for 40 MB: {moved / busy / 1e6:.1f} Mbit/s in all\")\nprint(f\"four phones in the same room instead: {1201 * EFFICIENCY:.1f} Mbit/s in all\")", "note": "The channel's whole throughput is everything moved over the time it was busy, set against the same four downloads to four phones that were all close."}], "output": "phone, same room      1201 Mbit/s   0.111 s of airtime\nlaptop, next room      720 Mbit/s   0.185 s of airtime\nphone, far corner       72 Mbit/s   1.852 s of airtime\nold 802.11g printer     54 Mbit/s   2.469 s of airtime\nchannel busy 4.617 s for 40 MB: 69.3 Mbit/s in all\nfour phones in the same room instead: 720.6 Mbit/s in all"}
```

The two fast clients were done in under a third of a second between them. **The slow two held the
channel for 4.3 of its 4.6 seconds**, and pulled the whole channel down to 69.3 Mbit/s, where four
phones in the same room would have shared 720.6. Nobody in that room complains about the printer.
They complain that the Wi-Fi is slow.

Lessons 7, 9 and 10 build on this arithmetic: more access points, each close to its clients, and
the oldest rates switched off so that nothing that slow can join. Some access points also share the
air **by time rather than by bytes**, an equal share of seconds per client. Vendors call it airtime
fairness. It protects the fast clients from the slow ones and makes nobody faster.

## What this lab cannot show

The lab has **no radio**. Its machines are joined by virtual Ethernet, which is full duplex, never
loses a frame to noise and has no airtime to share, so nothing in this lesson is a capture: the rates
are the standard's arithmetic and the 60% is a stated assumption. On a real Linux laptop, `iw dev
wlan0 link` reports the link rate and `iperf3`, which lesson 22 runs over the lab's wires, measures
what arrives. Neither was run over the air for this lesson.
