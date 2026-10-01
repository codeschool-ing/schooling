---
title: Remote access, a tunnel per person
version: 1
---

Remote access puts the tunnel on the person's own device. In lesson 4, Ana's laptop was a WireGuard peer
of `hq` with a key of its own, and then an OpenVPN client with a certificate of its own. **The other end
is a concentrator that many people connect to, and each connection is a person, not a network.** Nearly
everything that differs from site to site follows from that.

**The identity has to be a person's.** Lesson 4's status file wrote `ana` beside her address, and that
one word is what makes the log useful and makes it possible to cut off one person and nobody else. A key
or a password shared by a whole team would make every line of that file say the same thing, and leaving
the company would change nothing.

A password alone is not enough on a door that faces the internet. A VPN gateway is one of the most
attacked services a company runs, because one successful login puts the attacker inside the network. So
remote access asks for a second factor, MFA: a code from an app, a prompt on a phone, or a hardware key,
usually checked by the company's identity provider rather than by the VPN itself. OpenVPN does it with a
plugin or script that checks a name, a password and a code on top of the certificate; commercial
clients send the person to the identity provider's sign-in page. **None of that ran in the lab**, whose
OpenVPN accepted a certificate and nothing more.

**The device matters as well as the person.** A stolen laptop carries its WireGuard key or its
certificate with it, so the key has to live on an encrypted disk, and a lost device has to be revoked
the same day. Some gateways go further and check the device before letting it in: disk encrypted,
system patched, company software running.

The rest follows from the device being somewhere else. The endpoint moves between home, a hotel and a
phone, and is nearly always behind somebody's NAT, which is what lesson 4's roaming and
`PersistentKeepalive` are for. Its address inside the tunnel comes from a pool, `10.8.0.2` in lesson 4,
and not from anything the person chose.

| | site to site | remote access |
|---|---|---|
| the two ends | two routers | a device and a concentrator |
| who is authenticated | a site | a person, and ideally the device |
| who knows it is there | nobody on either LAN | the person, who starts it |
| when it is up | always | while the person is working |
| the far end's address | fixed | anywhere, usually behind NAT |
| how many tunnels | one per pair of offices | one per person |
| in this lab | `hq` to `branch` | `remote` to `hq` |
