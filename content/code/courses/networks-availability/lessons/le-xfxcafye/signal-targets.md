---
title: Signal, noise and the −67 dBm rule of thumb
version: 1
---

A survey records two numbers at every point, and a design is judged by a third made from them.

| | what it is | typical range indoors |
|---|---|---|
| **signal** (RSSI) | the power received from an AP, in dBm | −30 near an AP, −80 at a poor cell edge |
| **noise floor** | everything received that is not the signal | around −90 to −95 dBm on a quiet 20 MHz channel |
| **SNR** | signal minus noise, in dB | the higher, the faster the data rate the link can hold |

**SNR is what decides the data rate.** A client picks its rate from how cleanly it can separate the signal
from the noise, and each step up needs a few more decibels. A strong signal next to a microwave oven, on a
noise floor raised to −75 dBm, can give a worse link than a weaker signal on a quiet channel.

## The targets

Design targets come from vendors' guides and from practice, not from the 802.11 standard, and they differ
a little between guides. These are the values most commonly quoted, all measured at the edge of the cell,
the worst spot a client is expected to use:

| use | signal at the cell edge | SNR |
|---|---|---|
| e-mail and web | −70 to −72 dBm | 20 dB |
| voice and video calls | −67 dBm | 25 dB |
| dense, high-throughput areas | −65 dBm or better | 25 to 30 dB |

**−67 dBm is the number that keeps coming up**, and the reasons behind it are what make it useful. It
leaves room for what the survey adapter did not experience: a phone's smaller antenna, a hand or a body
around it (3 to 5 dB in the path-loss table), and the signal's own fluctuation from moment to moment. And
it keeps the cell edge above the roaming thresholds of lesson 9, around −70 to −75 dBm, so a phone meets
the next AP before its call starts to suffer. For voice, guides also ask for **a second AP at a usable
level at every point**, so that there is somewhere to roam to.

## The direction a survey does not measure

A survey adapter measures what the AP sends. The AP has to hear the client too, and **the client's
transmitter is the weaker one**, the asymmetry of lesson 7: an AP transmits louder than a phone. A cell
drawn from the AP's signal can therefore be wider than a phone at its edge can answer across. That is one
more reason to size cells by the weakest client's needs rather than by turning the AP's power up until
the map turns green.

The adapter matters as well. **Two adapters can read the same spot several dB apart**, and neither
matches the phone in anybody's pocket. A survey worth reading says which adapter it used and how it
compared with the devices that will use the network, which the last section returns to.
