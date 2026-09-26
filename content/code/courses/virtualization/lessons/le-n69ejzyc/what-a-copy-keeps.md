---
title: What a copy keeps
version: 1
---

vm2 never answered on the network. The host could still ask its guest agent, lesson 3, which needs no
network:

```
ana@host:~$ virsh domhostname vm2 --source agent
vm1

ana@host:~$ virsh domifaddr vm2 --source agent
 Name       MAC address          Protocol     Address
-------------------------------------------------------------------------------
 lo         00:00:00:00:00:00    ipv4         127.0.0.1/8
 -          -                    ipv6         ::1/128
 enp1s0     52:54:00:c9:25:bc    N/A          N/A

ana@vm1:~$ sudo cat /etc/netplan/50-cloud-init.yaml
network:
  version: 2
  ethernets:
    enp1s0:
      match:
        macaddress: "52:54:00:bb:a6:55"
      dhcp4: true
      dhcp6: true
      set-name: "enp1s0"
```

The clone calls itself **`vm1`**, and its card, `52:54:00:c9:25:bc`, has **no address at all**. The last command
shows why, read from vm1, whose disk vm2 is a copy of: Ubuntu's network configuration applies to the
card **whose MAC is `52:54:00:bb:a6:55`**, vm1's card. vm2's card has a different MAC, so nothing configures it, and
it never even asks for an address.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"What a full clone changed and what it copied. virt-clone gave vm2 a new MAC address, 52:54:00:c9:25:bc instead of 52:54:00:bb:a6:55, and a new libvirt UUID. It copied everything else: the hostname vm1, the machine-id, the SSH host keys, and the network configuration, which still matches the old MAC address, 52:54:00:bb:a6:55, so vm2&#x27;s new card is left without an address.\"><defs><marker id=\"id-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"220\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">vm1</text><text x=\"430\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">vm2, its full clone</text><rect x=\"20\" y=\"36\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">MAC address</text><text x=\"220\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">52:54:00:bb:a6:55</text><text x=\"430\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">52:54:00:c9:25:bc</text><rect x=\"20\" y=\"72\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"91\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">libvirt UUID</text><text x=\"220\" y=\"91\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its own</text><text x=\"430\" y=\"91\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a new one</text><rect x=\"20\" y=\"108\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">hostname</text><text x=\"220\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">vm1</text><text x=\"430\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">vm1</text><rect x=\"20\" y=\"144\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">machine-id</text><text x=\"220\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its own</text><text x=\"430\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the same</text><rect x=\"20\" y=\"180\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SSH host keys</text><text x=\"220\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its own</text><text x=\"430\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the same</text><rect x=\"20\" y=\"216\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"235\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">netplan matches</text><text x=\"220\" y=\"235\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">52:54:00:bb:a6:55</text><text x=\"430\" y=\"235\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">52:54:00:bb:a6:55</text><rect x=\"20\" y=\"254\" width=\"12\" height=\"10\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"40\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">virt-clone changed it</text><rect x=\"240\" y=\"254\" width=\"12\" height=\"10\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"260\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">copied as it was</text></svg>", "caption": "The hypervisor changes what it owns, the MAC and the UUID. Everything the guest’s system wrote about itself comes along unchanged, including a network configuration that no longer fits the card."}
```

The network is only the part that fails loudly. Everything the system wrote about itself on its first
boot came along too. The **hostname**. The **machine-id**, a number systemd and many programs use to
tell one installation from another. And the **SSH host keys**, which are how an SSH client knows it is
talking to the machine it trusted before. Two machines with one set of keys are, to SSH, the same
machine, and monitoring or management software that identifies machines by the machine-id sees one
where there are two.

On Windows the same problem is handled by a tool with a famous name, Sysprep, section 04, and Microsoft
supports a copied Windows installation only after it has been through it. The fix everywhere is the same: **remove the identity
from the original before copying it**, and let each copy make its own.
