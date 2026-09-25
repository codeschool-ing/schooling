---
title: The editions, one inside the next
version: 1
---

Windows 11 is sold in editions that are **the same system with more switched on**. Moving up is a
licence change, not a reinstall (section 05), which tells you how close they are.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The Windows editions drawn as nested boxes, each containing the one before. Home: the desktop, the Microsoft Store and device encryption; it can join nothing and cannot host Remote Desktop. Pro adds joining a domain or Entra ID, Group Policy, BitLocker, being a Remote Desktop host, Hyper-V and Windows Sandbox. Enterprise and Education add Credential Guard and 36 months of support per feature update, and are sold by subscription, never in a shop.\"><defs><marker id=\"ld-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"218\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"70\" y=\"88\" width=\"580\" height=\"142\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"120\" y=\"150\" width=\"480\" height=\"72\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"134\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Home</text><text x=\"134\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the desktop, Microsoft Store, device encryption</text><text x=\"134\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">can join nothing, can host no Remote Desktop</text><text x=\"84\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Pro</text><text x=\"84\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">+ domain and Entra ID join, Group Policy, BitLocker</text><text x=\"84\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">+ Remote Desktop host, Hyper-V, Windows Sandbox</text><text x=\"34\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">Enterprise / Education</text><text x=\"34\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">+ Credential Guard, 36 months per update</text><text x=\"34\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">+ sold by subscription, never in a shop</text></svg>", "caption": "Each edition is the one inside it plus more. For an office the line that matters is between Home and Pro: joining the organisation is on the Pro side."}
```

| | Home | Pro | Enterprise |
|---|---|---|---|
| join an Active Directory domain | no | yes | yes |
| join Microsoft Entra ID (work accounts) | no | yes | yes |
| Group Policy editor (`gpedit.msc`) | no | yes | yes |
| BitLocker, managed | device encryption only | yes | yes |
| be a Remote Desktop host | no | yes | yes |
| Hyper-V, Windows Sandbox | no | yes | yes |
| Credential Guard | no | no | yes |
| maximum memory | 128 GB | 2 TB | 6 TB |
| support per feature update | 24 months | 24 months | 36 months |
| how it is bought | in a shop, with the PC | in a shop, with the PC | by subscription or volume licence |

A few terms from that table:

- **Active Directory** is the directory an office's own Windows Server keeps, of every user and PC.
  **Microsoft Entra ID** is the same idea kept by Microsoft in the cloud, and it is what a *work or
  school account* signs into. Joining one of them is what lets an organisation manage a PC.
- **Group Policy** is how settings are pushed to many PCs at once, and `gpedit.msc` edits it on one.
- **Device encryption** on Home is BitLocker with no controls: it turns itself on when the PC signs in
  with a Microsoft account and keeps the recovery key in that account. Pro gives the full BitLocker,
  with a choice of where the key goes.
- **Remote Desktop host** means being connected *to*. Home can connect to another PC but nobody can
  connect to it.

**Education** is Enterprise priced for schools, and **Pro for Workstations** is Pro for machines with
more than 2 TB of memory or more than two processors. Neither is sold in an ordinary shop.
