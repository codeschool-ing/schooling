---
title: WPA3, and what to configure at Vereda
version: 1
---

**WPA3-Personal replaces the step that made WPA2's passphrase testable offline. The passphrase no
longer feeds a fixed key; it feeds a key exchange, and every guess has to be made against the access
point, one exchange at a time.** That one change removes both problems of the previous section.

## SAE: a key exchange that a password authenticates

WPA3-Personal joins with **SAE**, *Simultaneous Authentication of Equals*, a
password-authenticated key exchange. Each side picks fresh random values and runs a Diffie-Hellman
exchange (lesson 7) in which the passphrase determines the group element both use. If the two
passphrases match, both sides arrive at the same secret. If they do not, the exchange fails and
reveals nothing that lets anybody test a second guess offline.

Two consequences follow from that design:

- **A recording is useless for guessing.** Every guess needs a live exchange with the access point,
  which is slow, visible in its logs, and can be rate-limited. A passphrase that would fall in hours
  offline holds against online guessing for a very long time.
- **Forward secrecy.** The session key comes from random values that are thrown away afterwards, so
  learning the passphrase later, or knowing it today, does not decrypt a recorded session. The
  receptionist with the passphrase can no longer read the physiotherapist's traffic.

The four-way handshake still runs after SAE, but the PMK it starts from is now a fresh secret per
session instead of a function of the passphrase.

## Protected management frames

Wi-Fi also sends **management frames**: the messages that associate a device, and the ones that
disconnect it. WPA2 left them unauthenticated, so anybody in range could send a forged "disconnect"
and knock devices off the network, which was also a way to force a fresh handshake to record.
**Protected Management Frames** (802.11w) add a check to them. WPA3 makes them mandatory.

## Transition mode, and the networks with no password

- **Transition mode** lets one network accept WPA3 devices with SAE and older ones with WPA2 on the same
  passphrase. It exists so that a building can migrate, but the WPA2 side keeps every weakness of the
  previous section, and a recorded WPA2 join still tests guesses against the passphrase the WPA3 devices
  use too. Use it as a step with an end date, not as a destination.
- **Enhanced Open**, built on OWE (*Opportunistic Wireless Encryption*), encrypts a network that has
  no password, such as a waiting room's. Each device runs an unauthenticated Diffie-Hellman with the
  access point. It authenticates nobody, so it does not stop a fake access point, but it stops the
  person at the next table from reading everybody's traffic, which an open network does not.
- **WPS**, the push-button and PIN pairing of older routers, has a known design weakness in its PIN
  mode. Turn it off.

## What Vereda configures

Vereda runs three networks, each on its own VLAN, with the patients' network unable to reach anything
of the clinic's:

| network | for | security |
| --- | --- | --- |
| `Vereda-Equipe` | staff laptops and tablets | WPA2/WPA3-Enterprise, 802.1X (lesson 16) |
| `Vereda-Recepcao` | patients' phones | Enhanced Open, or WPA3-Personal with a printed passphrase |
| `Vereda-Dispositivos` | the card machine, two printers | WPA2/WPA3 transition, a random 5-word passphrase, rotated yearly |

On an access point running `hostapd`, the open-source software inside many of them, the devices'
network looks like this. The settings that decide its security are `wpa_key_mgmt`, which lists SAE
for WPA3 devices and WPA-PSK for the older ones, and `ieee80211w`, where `1` offers protected
management frames to whoever supports them and `2` would require them:

```ini
interface=wlan0
ssid=Vereda-Dispositivos
wpa=2
wpa_key_mgmt=SAE WPA-PSK
rsn_pairwise=CCMP
ieee80211w=1
sae_require_mfp=1
wpa_passphrase=replace-with-a-random-five-word-passphrase
```

`rsn_pairwise=CCMP` leaves TKIP out, and `sae_require_mfp=1` makes protected management frames
compulsory for the WPA3 devices even while the WPA2 ones are allowed without them. When the last WPA2
device is replaced, `wpa_key_mgmt=SAE` and `ieee80211w=2` close the transition.
