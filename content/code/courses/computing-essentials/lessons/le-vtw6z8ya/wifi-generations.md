---
title: The generations, and the only security setting that matters
version: 1
---

Wi-Fi had two sets of names for twenty years: the engineering one, `802.11` followed by letters,
and nothing else. In 2018 somebody finally gave them numbers.

| engineering name | sold as | band | roughly |
|---|---|---|---|
| `802.11n` | **Wi-Fi 4** | 2.4 and 5 GHz | up to `450 Mb/s` |
| `802.11ac` | **Wi-Fi 5** | 5 GHz only | up to `1.3 Gb/s` |
| `802.11ax` | **Wi-Fi 6** | 2.4 and 5 GHz | faster, and much better in a crowd |
| `802.11ax` | **Wi-Fi 6E** | adds 6 GHz | the same, on an empty band |
| `802.11be` | **Wi-Fi 7** | all three | faster again |

**Wi-Fi 6 is the interesting one and not for its top speed.** Its real change is how it handles
many devices at once: it can talk to several clients in the same slice of time instead of strictly
one after another. A house with thirty connected things benefits from that far more than from a
bigger number.

They are backward compatible, always. A Wi-Fi 4 printer works on a Wi-Fi 7 router and connects at
Wi-Fi 4 speed.

## Security, in one paragraph and one recommendation

| | what it is |
|---|---|
| **open** | no encryption. Everything anyone sends is readable by everyone in range |
| `WEP` | broken since 2001. Crackable in minutes. Treat as open |
| `WPA` | superseded, and weak |
| `WPA2` | the sensible floor. Still fine with a long password |
| `WPA3` | current. Resists the offline password guessing WPA2 allows |

**Set `WPA2/WPA3` and a long password, and you are done.** There is no further tuning worth
doing, and there is one thing not to do: a short password on WPA2 can be captured once and then
guessed offline at whatever speed the attacker's machine manages. Length beats cleverness —
four ordinary words beat `P@ssw0rd!` by an enormous margin.

## Three things sold as security that are not

- **Hiding the network name.** A hidden network still announces itself every time one of your own
  devices looks for it, and those devices then advertise its name wherever else they go. It is
  worse than useless and it breaks some clients.
- **MAC address filtering.** The addresses travel unencrypted, so anybody watching sees a
  permitted one and copies it. This is a lock whose key is written on the door.
- **Turning the power down.** It reduces range for your own devices first; an attacker's
  directional antenna is unaffected.

## The guest network, which is real

A guest network puts visitors on a connection that reaches the internet and **not the rest of your
devices**. That matters less for people and more for **things**: a smart television, a doorbell,
a plug that was cheap and will never be updated again.

Those belong on the guest network, permanently. Not because you distrust your visitors, but
because an appliance with a four-year-old operating system and no way to patch it is the most
likely thing on your network to be taken over.
