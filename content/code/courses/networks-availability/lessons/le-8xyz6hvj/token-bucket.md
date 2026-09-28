---
title: The token bucket both of them use
version: 1
---

A shaper and a policer decide "is there rate left for this packet?" in the same way, with **a token
bucket**. Tokens drip into a bucket at the configured rate, one per byte here. A packet may go when the
bucket holds as many tokens as the packet has bytes, and going removes them. The bucket has a size, and
tokens that arrive when it is full are lost, so **the rate says how fast credit is earned and the size
says how much can be saved up**.

The lab's numbers make it concrete. 5 Mbit/s is 5,000,000 bits a second, and a byte is 8 bits, so the
bucket fills at **625,000 bytes a second**, which is why the policer later in this lesson is written as
`625 kbytes/second`. Both limits in the lab have a bucket of 16 KB, 16,384 bytes, and a full-size
Ethernet frame is 1514 bytes:

| | |
|---|---|
| frames a full bucket lets through at once | 16,384 ÷ 1514 = **10**, and a bit |
| time to refill an empty bucket | 16,384 ÷ 625,000 = **26 ms** |
| time the rate needs for one frame | 1514 ÷ 625,000 = **2.4 ms** |

So a quiet link can send about ten frames at full speed, a burst, and then settles to one frame every
2.4 ms. A bigger bucket forgives bigger bursts; a bucket smaller than one frame would never let a frame
through at all.

The only difference between the two is the line that runs when the bucket is short. A shaper waits for
the tokens. A policer does not wait; the packet is dropped. The program below models both with the
lab's rate and bucket, and sends each of them the same burst: 40 full-size frames, one every half
millisecond, which is 24 Mbit/s for 20 ms.

```schooling-example
{"language": "python", "file": "bucket.py", "parts": [{"code": "RATE = 625_000   # tokens a second, one per byte: 5 Mbit/s\nBURST = 16_384   # the bucket's size: 16 KB, like burst 16kb\nFRAME = 1514     # one full-size Ethernet frame\nGAP = 0.0005     # a frame arrives every half millisecond: 24 Mbit/s", "note": "The lab's numbers. The bucket starts full, 16,384 tokens, and earns 625,000 a second. The burst is a frame every half millisecond, about five times the rate."}, {"code": "def shape(n):\n    tokens, clock, waits = BURST, 0.0, []\n    for i in range(n):\n        arrives = i * GAP\n        start = max(arrives, clock)\n        tokens = min(BURST, tokens + (start - clock) * RATE)\n        wait = max(0.0, (FRAME - tokens) / RATE)\n        clock = start + wait\n        tokens += wait * RATE - FRAME\n        waits.append(clock - arrives)\n    return n, 0, max(waits)", "note": "The shaper. A frame starts when it arrives or when the one before it has left, whichever is later, then waits until the bucket holds 1514 tokens. Nothing is ever dropped; the cost is the wait, and the function returns the longest one."}, {"code": "def police(n):\n    tokens, clock, sent = BURST, 0.0, 0\n    for i in range(n):\n        arrives = i * GAP\n        tokens = min(BURST, tokens + (arrives - clock) * RATE)\n        clock = arrives\n        if tokens >= FRAME:\n            tokens -= FRAME\n            sent += 1\n    return sent, n - sent, 0.0", "note": "The policer. The same bucket, refilled up to the moment the frame arrives. If the tokens are there the frame goes and pays; if not it is counted as dropped, and nothing waits."}, {"code": "for name, run in ((\"shaper\", shape), (\"policer\", police)):\n    sent, dropped, wait = run(40)\n    print(f\"{name:8} sent {sent:2}  dropped {dropped:2}  longest wait {wait * 1000:.1f} ms\")", "note": "The same 40 frames through each, and one line each."}], "output": "shaper   sent 40  dropped  0  longest wait 51.2 ms\npolicer  sent 18  dropped 22  longest wait 0.0 ms"}
```

**The shaper sent all 40 and made the last one wait 51.2 ms; the policer sent 18 and dropped 22 without
delaying anything.** The model's shaper holds everything it is given. `tc`'s shaper is told how much it may hold, in the next section with `latency 50ms`, and drops what does
not fit. A burst of 40 frames sits near that limit. A TCP upload, which keeps sending until something is
lost, goes past it, and the next section's counters show the drops.
