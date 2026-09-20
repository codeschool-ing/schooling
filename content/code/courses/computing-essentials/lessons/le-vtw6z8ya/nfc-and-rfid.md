---
title: NFC, where the short range is the security
version: 1
---

`NFC` — Near Field Communication — works at about **four centimetres**, and that is not a
limitation anybody is trying to overcome. It is the point.

A payment that only works when the card is touching the terminal cannot be read from the next
table, and the physics does the enforcing rather than a rule somebody has to implement correctly.

## How a card with no battery answers

The reader broadcasts a field. A passive tag has a coil in it; the field induces a small current
in that coil, and the tag uses that current to power itself for long enough to reply. **The
reader is powering the thing it is reading.**

That is why the range is short — the field falls away very fast — and why a card works after ten
years in a wallet with nothing to charge.

`RFID` is the same idea at a longer range and with less intelligence: a shop's security tags, a
pallet label, the chip in a pet. NFC is a subset of it, at close range, with two-way
communication.

## What it is used for

| | what happens |
|---|---|
| **contactless payment** | the card or phone signs a one-off number, not your card number |
| **transit cards** | a stored balance, or a token the barrier checks |
| **pairing** | tapping a speaker hands over the Bluetooth details so you skip the menus |
| **tags and stickers** | a URL or a short instruction, readable by any phone |
| **building access** | a badge with an identifier the door looks up |

The payment row is the important one. **A contactless payment does not send your card number.**
The chip produces a cryptogram — a one-time value derived from a key that never leaves the card —
so a captured transaction cannot be replayed and the merchant never holds anything reusable.

This is genuinely more private than handing a waiter a card with the number printed on it.

## The honest risks, which are small and not zero

- **Relay attacks** are real and hard: two accomplices, one beside your pocket and one at a
  terminal, passing the signal along in real time. Bank limits on contactless amounts exist
  because of this.
- **Reading a tag you did not mean to** — a sticker on a poster that opens a page. Your phone
  asks first, and that ask is the defence.
- **Cloning a building badge** is often easy, because many access systems still use an old tag
  type that just announces a number. That is a property of the building's system, not of NFC.

**A wallet that blocks radio is sold for the first risk.** It works and the risk it addresses is
already limited by the amount the bank allows. Buy one if it settles your mind; it is not the
thing standing between you and a fraud.

## Where it will not go

NFC will not transfer a file of any size — `424 kb/s`, at four centimetres, holding two things
together. It hands over the details for a faster radio to take over, which is exactly the job it
is good at, and the reason tapping two phones together starts a Bluetooth or Wi-Fi transfer
rather than doing one.
