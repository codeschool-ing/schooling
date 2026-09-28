---
title: WPA3-Personal, SAE and protected management frames
version: 1
---

WPA3-Personal keeps the passphrase and the four-way handshake, and changes where the PMK comes from.
Instead of hashing the passphrase, the two sides run **SAE, Simultaneous Authentication of Equals**, a
key exchange in the Diffie-Hellman family with the password mixed into it. Each side sends values that
depend on the password and on secrets it picked for this exchange, and each ends up with the same PMK, a
**new random one every time**. The four-way handshake of the figure above then runs on that PMK exactly
as before.

That one change fixes both problems of the section before.

**A recording is no longer enough to test guesses.** The values on the air depend on random secrets that
never leave either side, so there is nothing in them to check a guess against. Each guess needs a live
SAE exchange with the AP, which is slow, visible and something an AP can rate-limit and log. A weak
password is still a bad idea, and it is no longer an offline problem.

**It has forward secrecy.** The PMK is not a function of the password alone, so learning the password
later does not decrypt anything recorded earlier. And one member of the network cannot derive another
member's keys from a recording of their handshake.

## Protected management frames

In the original 802.11, **management frames were not authenticated at all**. A deauthentication frame,
the one that tells a client to disconnect, was accepted from anybody who put the AP's address in it, so
disconnecting a client was trivial and the client had no way to tell. **Protected management frames**,
PMF, from the amendment 802.11w, sign the management frames sent after the handshake with keys derived
from it. A client with PMF ignores a disconnection it cannot verify.

**PMF is optional in WPA2 and mandatory in WPA3.** Beacons and probe responses come before any key exists and are not covered. And no protocol stops a transmitter drowning the channel: that is a physical problem, found by spectrum analysis (lesson 10).

## Transition mode, and when to leave it

Most networks cannot switch to WPA3 on one day, because some devices only speak WPA2. **Transition mode**
runs both on one SSID with the same passphrase: WPA3 clients use SAE, the others use the WPA2 handshake,
and PMF becomes optional so the old ones can join.

The cost is that **the passphrase is exactly as exposed as in WPA2**: any WPA2 handshake recorded on that
network allows the offline guessing described above, whatever the WPA3 clients do. The WPA3
specification adds a **Transition Disable** indication so that a client which has joined with WPA3 once refuses to use WPA2 on that network again. That protects the modern clients from being steered down to
the old method. It does not protect the passphrase. Two ways out:

- retire the last WPA2 device and switch the SSID to SAE only;
- move the old devices to an SSID of their own, on a VLAN of their own, with a different passphrase.

**On 6 GHz there is no transition mode.** The Wi-Fi Alliance allows only WPA3 or Enhanced Open there,
with PMF required (lesson 6 covers the band), so a 6 GHz network is WPA3 from the first day.

| | WPA2-Personal | WPA3-Personal (SAE) |
|---|---|---|
| where the PMK comes from | PBKDF2 of the passphrase | a fresh SAE exchange |
| guesses from a recording | yes, offline | no, one live exchange per guess |
| forward secrecy | no | yes |
| a member reading another's traffic | possible, with a recorded handshake | no |
| protected management frames | optional | required |
| revoking one person | change the passphrase for all | change the passphrase for all |
