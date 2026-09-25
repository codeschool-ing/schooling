---
title: Feature updates, and how long each one lasts
version: 1
---

Windows 11 is not one system that gets patched forever. **Once a year it receives a feature update**,
24H2, then 25H2, and **each feature update has its own end of support**:

| edition | support per feature update |
|---|---|
| Home, Pro | **24 months** |
| Enterprise, Education | **36 months** |

When a PC's feature update reaches its end, the monthly security updates stop for it, even though it
still says *Windows 11*.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"A timeline from 2024 to 2028 with four bars. Windows 11 version 24H2 on Home and Pro, from late 2024 for 24 months, to late 2026. The same version on Enterprise, for 36 months, to late 2027. Version 25H2 on Home and Pro, from late 2025 to late 2027. And Windows 10 with Extended Security Updates for homes, from October 2025 to October 2026. A mark shows September 2026.\"><defs><marker id=\"lf-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M200 176 L200 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"200\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2024</text><path d=\"M320 176 L320 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"320\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2025</text><path d=\"M440 176 L440 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"440\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2026</text><path d=\"M560 176 L560 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"560\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2027</text><path d=\"M680 176 L680 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"680\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2028</text><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">24H2, Home and Pro</text><rect x=\"290.0\" y=\"40\" width=\"240.0\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">24H2, Enterprise</text><rect x=\"290.0\" y=\"76\" width=\"360.0\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">25H2, Home and Pro</text><rect x=\"410.0\" y=\"112\" width=\"240.0\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Windows 10, ESU for homes</text><rect x=\"414.8\" y=\"148\" width=\"118.79999999999997\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><path d=\"M520.4 172 L520.4 208\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M520.4 24 L520.4 36\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"520.4\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">September 2026</text></svg>", "caption": "A PC is supported only while its feature update is. Staying on 24H2 at home is the same as running out of updates in October."}
```

So the question for each office PC is not "is it Windows 11?" but "is its **version** still
supported?". Windows Update normally installs the next feature update on its own before the old one
ends. The PCs that fall behind are the ones where something stopped it: a disk too full to download it,
an old driver that blocks it, or a policy somebody set and forgot.

## Monthly updates

Between feature updates come the **monthly cumulative updates**, released on the second Tuesday of the
month, which people in IT call **Patch Tuesday**. Each one contains every fix before it, so a PC that
missed three months catches up with one. They are what raises the revision number from section 01.

## Windows 10

**Windows 10 reached its end of support in October 2025.** Microsoft offers **Extended Security
Updates** (*ESU*), paid for organisations, for up to three years, and for home PCs one year, to
**October 2026**. ESU delivers security fixes only; nothing new.

For an office in September 2026 that means a Windows 10 PC is either on a paid ESU plan with a date
on it, or already unprotected. Neither is a place to stay: lesson 2's hardware check decides whether it
moves to Windows 11 or out of the office.
