---
title: The two passwords, and the one nobody changes
version: 1
---

There are two passwords on that box and they protect completely different things. People know
about one of them.

## The Wi-Fi password, which is a key to the radio

This is the one printed on the sticker and given to visitors. It controls **who may join the
network**, and it also does something less obvious: it encrypts the traffic between each device
and the router. Without it the radio is readable by anybody in range.

Three generations are in use:

- **WEP** — broken since the early 2000s and breakable in minutes. If a box only offers WEP, the
  box is old enough to replace.
- **WPA2** — the standard almost everything uses, and adequate.
- **WPA3** — better, and worth switching on if every device supports it. Most boxes offer a mixed
  mode for the years in between.

Changing it disconnects every device in the house until each is told the new one, which is exactly
what makes people avoid changing it, and exactly why it should be changed the day the wrong person
learns it.

## The admin password, which is a key to the box

This is the one that opens the router's settings page — the page at `192.168.0.1` or similar,
where the network is configured.

**It is very often still `admin` / `admin`.**

That matters in a way the Wi-Fi password does not, because somebody with the settings page has
the network itself: they can read the Wi-Fi password in plain text, change where name lookups go,
open a path from outside to a device inside, and leave all of it in place.

Two things follow:

- **Change it, once, and write it down.** A router's settings page is the one place where
  *written on paper in a drawer* is a perfectly good password manager.
- **Never expose the settings page to the internet.** There is usually a setting called *remote
  management* or *administration from WAN*, and it should be off. It exists so a support
  technician can connect from outside; it is also how a stranger does.

## The guest network, which is free and nobody uses

Most boxes can run a **second Wi-Fi network with its own name and password**, on which devices can
reach the internet and **cannot reach anything else in the house**.

That is the correct place for two kinds of thing:

- **visitors**, who then never learn the real password and cannot reach the network drive;
- **everything cheap that connects** — a smart bulb, a plug, a camera, a television. These are
  computers, they run software nobody updates, and they have no business being on the same network
  as a laptop with your documents on it.

It takes ten minutes to set up and is the single largest security improvement available in a home
network.

## And the reset button

A pinhole on the back, held for ten seconds, returns the box to how it left the factory: the
sticker's Wi-Fi name and password, the default admin password, and none of your settings.

It is the right answer when something is misconfigured and nobody knows what. It is the wrong
answer when the internet is down, because it changes nothing about the line and costs you every
device's Wi-Fi connection at the moment you are least able to fix them.
