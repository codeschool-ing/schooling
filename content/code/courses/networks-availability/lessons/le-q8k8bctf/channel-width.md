---
title: Channel width, and the rate it buys
version: 1
---

Every rate in the table of the first section comes from four numbers the standard fixes, multiplied
together. A Wi-Fi channel is cut into hundreds of narrow **subcarriers**, each carrying a few bits at a
time, and all of them are sent together as one **symbol**. A stream's rate is how many data bits one
symbol carries, divided by how long a symbol lasts. **Widen the channel and there are more subcarriers,
so more bits per symbol**, which is the only thing width buys.

The program below does the multiplication for the amendments of this lesson. It was run with
`python3`, and what it printed is under it.

```schooling-example
{"language": "python", "file": "rates.py", "parts": [{"code": "# The rate of one spatial stream, from four numbers the standard fixes.\ndef per_stream(subcarriers, bits, coding, symbol_us):\n    return subcarriers * bits * coding / symbol_us  # bits per microsecond = Mbit/s", "note": "One OFDM symbol carries a bit or several on each of its data subcarriers. Multiply by the share of those bits that is data rather than error correction, divide by how long a symbol lasts in microseconds, and the answer is in Mbit/s."}, {"code": "# name, data subcarriers, bits per subcarrier, coding rate, symbol time in us, streams\nLINKS = [", "note": "One row per link. The coding rate is the share of real data: 3/4 means that one bit in four is redundancy the receiver uses to repair errors."}, {"code": "    (\"802.11a/g   20 MHz\",   48,  6, 3/4,  4.0,  1),\n    (\"802.11n     40 MHz\",  108,  6, 5/6,  3.6,  4),\n    (\"802.11ac   160 MHz\",  468,  8, 5/6,  3.6,  8),", "note": "802.11a and g: 48 data subcarriers in 20 MHz, 64-QAM carrying 6 bits on each, and a symbol every 4 microseconds, which gives the 54 Mbit/s of 1999. 802.11n widens to 40 MHz, shortens the guard between symbols to make them 3.6 long, and allows four streams. 802.11ac reaches 160 MHz, 256-QAM with 8 bits, and eight streams."}, {"code": "    (\"802.11ax    20 MHz\",  234, 10, 5/6, 13.6,  1),\n    (\"802.11ax    40 MHz\",  468, 10, 5/6, 13.6,  1),\n    (\"802.11ax    80 MHz\",  980, 10, 5/6, 13.6,  1),\n    (\"802.11ax   160 MHz\", 1960, 10, 5/6, 13.6,  1),\n    (\"802.11ax   160 MHz\", 1960, 10, 5/6, 13.6,  8),", "note": "802.11ax cuts the same channel into four times as many subcarriers, each four times as long, so a symbol lasts 13.6 microseconds with its guard, and adds 1024-QAM, 10 bits. The first four rows here are the width question alone, one stream each; the fifth is the top of the standard."}, {"code": "    (\"802.11be   320 MHz\", 3920, 12, 5/6, 13.6, 16),\n]", "note": "802.11be doubles the widest channel to 320 MHz, in 6 GHz only, carries 12 bits with 4096-QAM, and writes down sixteen streams. That is a ceiling on paper: access points ship with a few streams per radio and phones with two."}, {"code": "for name, subcarriers, bits, coding, symbol_us, streams in LINKS:\n    one = per_stream(subcarriers, bits, coding, symbol_us)\n    print(f\"{name}  {one:7.1f} x {streams:2} = {one * streams:8.1f} Mbit/s\")", "note": "Prints each row's rate for one stream, and for all its streams together."}], "output": "802.11a/g   20 MHz     54.0 x  1 =     54.0 Mbit/s\n802.11n     40 MHz    150.0 x  4 =    600.0 Mbit/s\n802.11ac   160 MHz    866.7 x  8 =   6933.3 Mbit/s\n802.11ax    20 MHz    143.4 x  1 =    143.4 Mbit/s\n802.11ax    40 MHz    286.8 x  1 =    286.8 Mbit/s\n802.11ax    80 MHz    600.5 x  1 =    600.5 Mbit/s\n802.11ax   160 MHz   1201.0 x  1 =   1201.0 Mbit/s\n802.11ax   160 MHz   1201.0 x  8 =   9607.8 Mbit/s\n802.11be   320 MHz   2882.4 x 16 =  46117.6 Mbit/s"}
```

Read the four 802.11ax rows at one stream: 143.4, 286.8, 600.5 and 1201.0 Mbit/s. **Each doubling of
the width slightly more than doubles the rate**, because a wider channel wastes proportionally fewer
subcarriers on its edges. That looks like a reason to always pick the widest channel. It is not,
because width has three costs, and none of them shows in the program.

**Width leaves fewer channels to go round.** A band has a fixed amount of spectrum, so every doubling halves the
number of channels in it. Access points near each other need different channels, or they take turns
(lesson 7 says how), and in 2.4 GHz a single 40 MHz channel takes nearly half the band. The 6 GHz band, the widest there is, shows the trade in numbers, where all 1200 MHz of it is open:

| channel width | 20 MHz | 40 MHz | 80 MHz | 160 MHz | 320 MHz |
|---|---|---|---|---|---|
| channels that do not overlap | 59 | 29 | 14 | 7 | 3 |
| one 802.11ax stream, Mbit/s (the program above) | 143.4 | 286.8 | 600.5 | 1201.0 | not in 802.11ax |

**Width leaves less signal against the noise.** A transmitter has a fixed power, and a wider channel spreads it
thinner, while the noise a receiver hears grows with the width it listens to. Double the width and the
signal's total stays the same while the noise doubles: **each doubling costs 3 dB of signal-to-noise
ratio**. At the edge of a cell, a client on 160 MHz drops to a slower modulation sooner than one on 40 MHz, and can end up with a lower rate than it would
have had on the narrower channel.

**Width means more exposure to a neighbour.** A 160 MHz channel overlaps anything transmitting in any of its
eight 20 MHz parts. Since 802.11ac an access point can fall back to part of its channel when the rest is
busy, and since 802.11ax it can leave out a busy slice. It still transmits less often than it would on a
channel of its own.

So the choice is made per band and per building. Practice has settled on a pattern that no standard
writes down: **20 MHz on 2.4 GHz, always**, and 20 or 40 MHz on 5 GHz where access points are dense. On
6 GHz, where there are channels enough to go round, it is 80 or 160. A house with
one access point and no neighbours can take the widest channel it has, because there is nobody to
share it with.
