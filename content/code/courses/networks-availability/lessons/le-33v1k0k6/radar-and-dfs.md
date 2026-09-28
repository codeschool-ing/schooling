---
title: 5 GHz, radar and DFS
version: 1
---

On 5 GHz the overlap problem of 2.4 GHz disappears: channel numbers go up in steps of four, 36, 40,
44, so every 20 MHz channel starts where the last one ended. What takes its place is a rule most people
meet only as a mystery, **the access point that changes channel by itself** in the middle of the day,
dropping every client for a minute.

The 5 GHz band is in pieces, and the pieces have names. They are the United States' names, used across
the industry, and which of them a country opens, and at what power, is its regulator's decision:

| piece | frequencies | channels (20 MHz) | shared with radar? |
|---|---|---|---|
| UNII-1 | 5150 to 5250 MHz | 36 to 48 | no |
| UNII-2A | 5250 to 5350 MHz | 52 to 64 | yes |
| UNII-2C | 5470 to 5725 MHz | 100 to 144 | yes |
| UNII-3 | 5725 to 5850 MHz | 149 to 165 | no |

**Sixteen of those twenty-five channels are shared with radar**: weather radar, military and airport
systems, which were there first and keep priority. Wi-Fi may use them only with **DFS**, dynamic frequency
selection, and DFS is a set of obligations with fixed times in them:

- Before transmitting on a radar channel, an access point listens for 60 seconds, the channel
  availability check, and sends nothing, not even a beacon. In Europe the check is 10 minutes on the
  channels around 5600 to 5650 MHz, where weather radars sit.
- If it detects a radar pulse while working, it has 10 seconds to stop and move its clients elsewhere.
- It may not return to that channel for 30 minutes.

So a network on channel 100 that has been fine all morning can vanish at noon, reappear on channel 36,
and have every client reconnect. **Nothing is broken when that happens; the law was obeyed.** What
is worth checking is how often it happens: a building near an airport or a weather station can see
it many times a day, and a false detection, noise that the radio mistook for a pulse, looks exactly
the same in the log.

The choice is a trade. Leaving out the radar channels leaves nine, on which a dense building will
put several access points to a channel. Keeping them gives sixteen more, and a sudden move now and
then. A common answer is to keep them and watch the logs, and to put what must never be dropped,
a hospital's voice handsets for instance, on a network that uses only UNII-1 and UNII-3.

## And 6 GHz

The 6 GHz band has neither problem. Its channels are numbered from its own base, 5950 MHz, so channel
1 is at 5955 and channel 233 at 7115, as the program in the previous section printed, and none of
them is shared with radar in the way 5 GHz is. Indoor low-power access points need no DFS there at all.
