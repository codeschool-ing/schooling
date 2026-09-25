---
title: The registry: hives, keys and values
version: 1
---

Windows keeps almost all of its settings, and most programs keep theirs, in **the registry**: one tree,
stored in a few binary files, opened by tools that understand it.

The top of the tree is five **root keys**, and two of them are where nearly everything happens:

| root key | holds | stored in |
|---|---|---|
| **HKEY_LOCAL_MACHINE** (`HKLM`) | the machine's settings, for everybody | `C:\Windows\System32\config\SOFTWARE`, `SYSTEM`… |
| **HKEY_CURRENT_USER** (`HKCU`) | the signed-in person's settings | `C:\Users\ana\NTUSER.DAT` |
| HKEY_USERS | every loaded user's settings | the same `NTUSER.DAT` files |
| HKEY_CLASSES_ROOT | file types and what opens them | a view over HKLM and HKCU |
| HKEY_CURRENT_CONFIG | the current hardware profile | a view into HKLM |

**HKLM and HKCU are `/etc` and the dotfiles of section 04**, in Windows form: one for the machine, one
per person. The files they are stored in are called **hives**.

Inside, **keys** are folders and **values** are the settings, each with a **name**, a **type** and
**data**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The values inside one registry key, HKLM SOFTWARE Microsoft Windows NT CurrentVersion, on a Windows 11 Pro PC, as regedit shows them: name, type and data. ProductName, a string, Windows 10 Pro. EditionID, a string, Professional. DisplayVersion, a string, 24H2. CurrentBuild, a string, 26100. UBR, a 32-bit number, 0x10ff, which is 4351.\"><defs><marker id=\"vl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion</text><text x=\"30\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">name</text><text x=\"240\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">type</text><text x=\"410\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">data</text><rect x=\"20\" y=\"52\" width=\"680\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ProductName</text><text x=\"240\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">REG_SZ</text><text x=\"410\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Windows 10 Pro</text><rect x=\"20\" y=\"88\" width=\"680\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">EditionID</text><text x=\"240\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">REG_SZ</text><text x=\"410\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Professional</text><rect x=\"20\" y=\"124\" width=\"680\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">DisplayVersion</text><text x=\"240\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">REG_SZ</text><text x=\"410\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">24H2</text><rect x=\"20\" y=\"160\" width=\"680\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CurrentBuild</text><text x=\"240\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">REG_SZ</text><text x=\"410\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">26100</text><rect x=\"20\" y=\"196\" width=\"680\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">UBR</text><text x=\"240\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">REG_DWORD</text><text x=\"410\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0x000010ff (4351)</text></svg>", "caption": "Lesson 5's numbers, where Windows keeps them, and lesson 5's warning with them: ProductName still says Windows 10 on this Windows 11 PC. A key holds values; each value has a name, a type and data."}
```

| type | holds |
|---|---|
| `REG_SZ` | text |
| `REG_EXPAND_SZ` | text with variables like `%USERPROFILE%` in it, expanded when read |
| `REG_MULTI_SZ` | a list of strings |
| `REG_DWORD` | a 32-bit number |
| `REG_BINARY` | raw bytes |

The registry exists only on Windows. PowerShell on the Linux server does not even have the provider
for it:

```
PS /home/ana> Get-PSDrive -PSProvider Registry
Get-PSDrive: Cannot find a provider with the name 'Registry'.
PS /home/ana> Get-ChildItem HKLM:\SOFTWARE
Get-ChildItem: Cannot find drive. A drive with the name 'HKLM' does not exist.
```
