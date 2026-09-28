---
title: Same channel, next channel, and things that are not Wi-Fi
version: 1
---

When two access points in range of each other share a channel, the instinct is to move one of them
to the channel next door, as if a little distance were better than none. **On 2.4 GHz it is worse.**
Two networks on the same channel slow each other down politely. Two on overlapping channels damage
each other's frames. The difference is whether each can understand the other.

Every Wi-Fi radio listens before it talks. It is called **clear channel assessment**, and the standard
gives it two thresholds, one for each thing a radio can hear:

| what the radio hears | it treats the channel as busy from | typical of |
|---|---|---|
| a Wi-Fi preamble it can decode | −82 dBm, for a 20 MHz channel | another network on the same channel |
| energy it cannot decode | −62 dBm, a hundred times stronger | an overlapping channel, a microwave oven |

The 20 dB between them is the whole story. On the **same channel**, a neighbour's frame is decoded at
signal levels far below anything that would disturb it, so each radio waits for the other to finish.
That is **co-channel contention**: the two networks share one channel's airtime, both get slower,
and nothing is lost. On an **overlapping channel**, the neighbour's frame cannot be decoded, and unless
it is louder than −62 dBm the radio does not wait for it. It transmits over it, and the part of the
neighbour's signal that falls inside its channel arrives at the receiver as noise. That is
**adjacent-channel interference**, and it costs corrupted frames, retries and slower modulations on
both sides.

So the rule for 2.4 GHz follows from a threshold, not from taste: **share a channel of the plan, 1, 6
or 11, rather than sit between two of them.** A network on channel 3 is interfered with by both.

## Transmitters that are not Wi-Fi

2.4 GHz is an unlicensed band, open to anything within the power limits, and Wi-Fi is one tenant
among several. None of the others speaks 802.11, so to a Wi-Fi radio they are all energy it cannot
decode, the second row of the table.

- A microwave oven heats food at around 2450 MHz, and the little that leaks from its door is
  enough to disturb the middle and upper channels of the band nearby while it runs. The pattern,
  Wi-Fi in the kitchen failing at lunchtime, is the diagnosis.
- Bluetooth hops over 79 channels of 1 MHz, 1600 times a second in its classic form, and modern
  devices avoid the frequencies they find busy. One headset does little; a room of them adds up.
- Zigbee sensors, baby monitors and wireless video senders sit on fixed frequencies, some of
  them transmitting continuously.
- Cordless phones are often blamed and are usually innocent: the DECT phones sold in Brazil and Europe
  work near 1.9 GHz, outside every Wi-Fi band.

**Wi-Fi's own tools cannot name any of these.** A client sees retries and a low rate, and an access
point sees a noisy channel; only a spectrum analyser, which draws energy against frequency without
decoding anything, shows the shape of the culprit. Many enterprise access points can turn one radio
into one. The lab has no radio of any kind, so this section has no capture of one.
