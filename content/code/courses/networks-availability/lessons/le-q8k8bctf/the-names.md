---
title: The standards and the names on the box
version: 1
---

Two beliefs arrive with most people. One is that **Wi-Fi 6 is named after the 6 GHz band**, and the
other is that each new standard replaces the one before. Neither is true, and both cost money: the
first buys a router that cannot use 6 GHz at all, and the second leaves an old printer slowing down a
network that everybody thinks is new.

Wi-Fi is one standard, **IEEE 802.11**, published in 1997 with a top rate of 2 Mbit/s, and a series of
amendments to it, each named with letters after the number. The IEEE writes the amendments. The Wi-Fi
Alliance, an industry group, tests products against them and owns the name Wi-Fi. In 2018 it gave the
amendments plain numbers, and it went back only as far as 802.11n: **Wi-Fi 4 is 802.11n, Wi-Fi 5 is
802.11ac, Wi-Fi 6 is 802.11ax**, and Wi-Fi 7 came later for 802.11be. Calling 802.11b "Wi-Fi 1" is
common, and it is not an official name.

| amendment | name | year | bands | widest channel | streams | top rate in the standard |
|---|---|---|---|---|---|---|
| 802.11b | none | 1999 | 2.4 GHz | 22 MHz | 1 | 11 Mbit/s |
| 802.11a | none | 1999 | 5 GHz | 20 MHz | 1 | 54 Mbit/s |
| 802.11g | none | 2003 | 2.4 GHz | 20 MHz | 1 | 54 Mbit/s |
| 802.11n | Wi-Fi 4 | 2009 | 2.4 and 5 GHz | 40 MHz | 4 | 600 Mbit/s |
| 802.11ac | Wi-Fi 5 | 2013 | 5 GHz | 160 MHz | 8 | 6.9 Gbit/s |
| 802.11ax | Wi-Fi 6 | 2021 | 2.4 and 5 GHz | 160 MHz | 8 | 9.6 Gbit/s |
| 802.11ax | Wi-Fi 6E | 2021 | adds 6 GHz | 160 MHz | 8 | 9.6 Gbit/s |
| 802.11be | Wi-Fi 7 | 2024 | 2.4, 5 and 6 GHz | 320 MHz | 16 | 46 Gbit/s |

Two columns of that table need a word. The year is the year the IEEE published the amendment, and
products came before it: Wi-Fi 6 certification opened in 2019, two years before 802.11ax was final.
And the top rate is **a ceiling the standard writes down, never a speed anybody measures**. It assumes
the widest channel, the most streams and a signal clean enough for the densest modulation, all at
once. The section on channel width computes each of those rates from the standard's own numbers, and
the last section of this lesson says how much of one a phone gets.

**Wi-Fi 6E is the same 802.11ax, allowed into a third band.** Nothing about the radio's modulation
changed; the E is for the extension to 6 GHz, which the Wi-Fi Alliance started certifying in 2021. A
Wi-Fi 6 router with no 6E on the box does not transmit at 6 GHz, whatever its number suggests.

**The standards are backwards compatible inside a band.** An 802.11ax access point on 2.4 GHz still
talks to an 802.11b client from 1999, and on 5 GHz to an 802.11a one. It does so at the old client's
speed, using the old client's time on the air, which is why the last section of this lesson has a
printer in it. The 6 GHz band is the one exception, and the next section says why that matters: no
device older than Wi-Fi 6E can join it, so nothing old is there to be waited for.
