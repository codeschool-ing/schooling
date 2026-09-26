---
title: Hyper-V’s switches, and PowerShell
version: 1
---

Hyper-V's networks are virtual switches, of three types, plus one Windows creates by itself:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Hyper-V&#x27;s virtual switch types. External: joined to a real network card, so guests are on the office network. Internal: the host and its guests, nobody else. Private: the guests only, not even the host. And the Default Switch that Windows 10 and 11 create: NAT out through the host.\"><defs><marker id=\"hv-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">External</text><text x=\"200\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">joined to a real card: guests are on the office network</text><rect x=\"20\" y=\"60\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Internal</text><text x=\"200\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the host and its guests, nobody else</text><rect x=\"20\" y=\"106\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Private</text><text x=\"200\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">guests only, not even the host</text><rect x=\"20\" y=\"152\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Default Switch</text><text x=\"200\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">NAT out through the host, made by Windows</text></svg>", "caption": "External is VMware’s VMnet0, Internal its VMnet1 and the Default Switch its VMnet8; Private has no counterpart there, and keeps guests away even from the host. A new guest on a Windows desktop lands on the Default Switch unless somebody picks another."}
```

When a guest on a Windows laptop "has no internet", check which switch its card is on first: the
Default Switch almost always works, and an External switch bound to the wired card does not while the
laptop is on Wi-Fi, the same fault as lesson 5's VMnet0.

In PowerShell, as an administrator:

```sh
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All   # switch it on; then reboot
Get-VM                                              # every VM, its state and uptime
New-VM -Name lab1 -Generation 2 -MemoryStartupBytes 2GB -NewVHDPath C:\VMs\lab1.vhdx -NewVHDSizeBytes 40GB -SwitchName "Default Switch"
Set-VMFirmware lab1 -SecureBootTemplate MicrosoftUEFICertificateAuthority   # so a Linux guest can boot
Add-VMDvdDrive lab1 -Path C:\ISO\ubuntu-24.04-live-server-amd64.iso
Start-VM lab1
Checkpoint-VM lab1 -SnapshotName clean              # Hyper-V's word for a snapshot
Get-VMSwitch                                        # the virtual switches and their types
Get-VMIntegrationService lab1                       # the guest services, Hyper-V's agent
```

**None of these were run for this lesson**; Hyper-V needs Windows, and the course's host is Ubuntu.
