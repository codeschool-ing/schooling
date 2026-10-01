---
title: Power over the same cable
version: 1
---

A phone on a desk, an access point on a ceiling and a camera on an outside wall have one thing in
common: none of them is near a socket where anybody wants one. **Power over Ethernet (PoE) sends
the electricity down the same twisted-pair cable as the data**, so one cable from the switch is all
the device needs. On a ceiling, that is the difference between an electrician and a network cable.

**This lesson's lab could not run any of it.** The lab is network namespaces on one computer, and a
virtual cable carries frames and no electricity, so there is no output in this section and the next.
What follows is the standard, stated as the standard states it.

## Two roles, and a check before any power flows

The device that supplies power is the **PSE** (*power sourcing equipment*): usually a PoE switch,
or a *midspan* injector placed between an ordinary switch and the device. The device that receives
it is the **PD** (*powered device*).

The obvious worry is that a switch pushing power down every cable would damage a laptop plugged
into the wrong port. **A standard PSE puts no power on a cable until it has found a PD at the other
end.** It goes through three steps:

1. **Detection.** The PSE applies a small, harmless voltage and looks for a *signature resistance*
   of 25 kΩ that a PD presents across its input. A laptop's network card does not present it, so
   it never receives power.
2. **Classification.** The PD announces a **class**, which tells the PSE how much power it may
   draw. Devices of the later standards can also refine the figure afterwards over LLDP.
3. **Power-up**, and from then on the PSE watches the current. If the PD is unplugged, the PSE
   notices and removes power from the port.

That protection belongs to the standard. Some cheap equipment sells *passive PoE*, which puts a
voltage on the cable permanently with no detection, and it can damage a device that was not built
to receive it. A port labelled PoE is worth checking for which kind it is.

## The standards and how much each delivers

There are two figures for each standard, and the gap between them is the point. **The PSE has to
supply more at the port than the PD is promised at the far end**, because a long cable turns some
of the power into heat. The standards size that gap for 100 metres of cable.

| standard | type | at the switch port (PSE) | at the device (PD) |
| --- | --- | --- | --- |
| IEEE 802.3af (2003) | Type 1 | 15.4 W | 12.95 W |
| IEEE 802.3at (2009), "PoE+" | Type 2 | 30 W | 25.5 W |
| IEEE 802.3bt (2018) | Type 3 | 60 W | 51 W |
| IEEE 802.3bt (2018) | Type 4 | 90 W | 71.3 W |

802.3af and 802.3at send power over two of the cable's four pairs. **802.3bt can use all four**, which
is how it reaches 60 and 90 W, and why it is the standard for devices such as cameras with heaters,
large access points and small displays.

Within Type 1 the classes say how much less than the maximum a device needs: **class 1 reserves
4 W at the port, class 2 reserves 7 W, and class 3 the full 15.4 W.** Class 4 is Type 2's 30 W, and
802.3bt adds classes 5 to 8, up to 90 W. A device that announces nothing is class 0 and gets the
Type 1 maximum. Those reservations are what the next section adds up, because a switch does not have
90 W for every port.
