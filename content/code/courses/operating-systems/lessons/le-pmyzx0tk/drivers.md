---
title: Drivers: where they come from, and the old scanner
version: 1
---

Lesson 1 described a driver as the code that translates between the kernel and one device. This
section is about getting the right one, and keeping it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Three places a device&#x27;s driver can come from. With the system: in the Linux kernel or in Windows itself, which covers most keyboards, disks and network cards. Through updates: Windows Update or a distribution&#x27;s packages, which deliver new versions tested for the system. From the maker: the maker&#x27;s website or tool, usually for printers, graphics cards and scanners.\"><defs><marker id=\"dv-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"190\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"115\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">with the system</text><text x=\"230\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">in the kernel or in Windows itself</text><text x=\"230\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">most keyboards, disks, network cards</text><rect x=\"20\" y=\"76\" width=\"190\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"115\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">through updates</text><text x=\"230\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Windows Update, a distribution&#x27;s packages</text><text x=\"230\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">new versions, tested for the system</text><rect x=\"20\" y=\"132\" width=\"190\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"115\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">from the maker</text><text x=\"230\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the maker&#x27;s website or tool</text><text x=\"230\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">printers, graphics cards, scanners</text></svg>", "caption": "The further down, the less the system knows about it. A driver from the maker is the one an operating system upgrade is most likely to leave behind."}
```

**On Linux most drivers are part of the kernel**, maintained with it, and arrive with kernel updates. The
exceptions are proprietary ones, graphics cards above all, which Ubuntu installs as packages:

```sh
lspci -k                                       # each PCI device and the driver in use
lsusb                                          # USB devices
ubuntu-drivers list                            # proprietary drivers Ubuntu can install
modinfo e1000e | head -3                       # about one kernel driver
```

**None of those were run for this lesson.** The server this course records on runs inside another
machine and has no hardware of its own to show, which is the virtualization course's subject. `lspci -k`
is the one to remember: each device, and *Kernel driver in use*.

**On Windows**, Device Manager is the place: right-click a device for **Update driver**, **Roll back
driver** (if a previous one was kept), **Disable** and **Uninstall**. From the command line:

```sh
driverquery                                    # every driver, Command Prompt
pnputil /enum-drivers                          # third-party driver packages in the store
pnputil /enum-devices /problem                 # devices with a problem
```

**Not run for this lesson.** Windows Update also offers driver updates, some under *Optional updates*,
where they wait until somebody chooses them.

## The old scanner

The scanner stopped after a feature update. In order:

1. **Device Manager**: is it there, with a warning triangle? Then the driver failed to load.
2. **Roll back driver**, if Windows replaced a working one with a generic one.
3. **The maker's site**, for a driver for the new version. Many makers stop after a few years.
4. If there is none, the choices are **a generic driver** (many scanners speak a standard, *WIA* on
   Windows and *SANE* on Linux), **keeping one machine on the older version** as long as it is still
   supported, or **replacing the scanner**. The third is often the cheapest over a year.
