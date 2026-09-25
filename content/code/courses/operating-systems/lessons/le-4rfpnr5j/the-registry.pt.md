---
title: O registro: hives, chaves e valores
version: 1
---

O Windows guarda quase todas as suas configurações, e a maioria dos programas guarda as deles, no
**registro**: uma árvore, armazenada em alguns arquivos binários, aberta por ferramentas que o entendem.

O topo da árvore são cinco **chaves raiz**, e duas delas são onde quase tudo acontece:

| chave raiz | guarda | armazenada em |
|---|---|---|
| **HKEY_LOCAL_MACHINE** (`HKLM`) | as configurações da máquina, para todos | `C:\Windows\System32\config\SOFTWARE`, `SYSTEM`… |
| **HKEY_CURRENT_USER** (`HKCU`) | as configurações da pessoa conectada | `C:\Users\ana\NTUSER.DAT` |
| HKEY_USERS | as configurações de todo usuário carregado | os mesmos arquivos `NTUSER.DAT` |
| HKEY_CLASSES_ROOT | tipos de arquivo e o que os abre | uma visão sobre o HKLM e o HKCU |
| HKEY_CURRENT_CONFIG | o perfil de hardware atual | uma visão dentro do HKLM |

**O HKLM e o HKCU são o `/etc` e os arquivos de ponto da seção 04**, na forma do Windows: um para a
máquina, um por pessoa. Os arquivos em que eles ficam guardados se chamam **hives**.

Dentro, as *chaves* são pastas e os *valores* são as configurações, cada um com *nome*, *tipo* e
*dados*:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Os valores dentro de uma chave do registro, HKLM SOFTWARE Microsoft Windows NT CurrentVersion, num PC com Windows 11 Pro, como o regedit os mostra: nome, tipo e dados. ProductName, uma cadeia, Windows 10 Pro. EditionID, uma cadeia, Professional. DisplayVersion, uma cadeia, 24H2. CurrentBuild, uma cadeia, 26100. UBR, um número de 32 bits, 0x10ff, que é 4351.\"><defs><marker id=\"vl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion</text><text x=\"30\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nome</text><text x=\"240\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tipo</text><text x=\"410\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dados</text><rect x=\"20\" y=\"52\" width=\"680\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ProductName</text><text x=\"240\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">REG_SZ</text><text x=\"410\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Windows 10 Pro</text><rect x=\"20\" y=\"88\" width=\"680\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">EditionID</text><text x=\"240\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">REG_SZ</text><text x=\"410\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Professional</text><rect x=\"20\" y=\"124\" width=\"680\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">DisplayVersion</text><text x=\"240\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">REG_SZ</text><text x=\"410\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">24H2</text><rect x=\"20\" y=\"160\" width=\"680\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CurrentBuild</text><text x=\"240\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">REG_SZ</text><text x=\"410\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">26100</text><rect x=\"20\" y=\"196\" width=\"680\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">UBR</text><text x=\"240\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">REG_DWORD</text><text x=\"410\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0x000010ff (4351)</text></svg>", "caption": "Os números da aula 5, onde o Windows os guarda, e o aviso da aula 5 junto: o ProductName ainda diz Windows 10 neste PC com Windows 11. Uma chave guarda valores; cada valor tem nome, tipo e dados."}
```

| tipo | guarda |
|---|---|
| `REG_SZ` | texto |
| `REG_EXPAND_SZ` | texto com variáveis como `%USERPROFILE%` dentro, expandidas ao ler |
| `REG_MULTI_SZ` | uma lista de cadeias |
| `REG_DWORD` | um número de 32 bits |
| `REG_BINARY` | bytes crus |

O registro só existe no Windows. O PowerShell do servidor Linux nem tem o provedor para ele:

```
PS /home/ana> Get-PSDrive -PSProvider Registry
Get-PSDrive: Cannot find a provider with the name 'Registry'.
PS /home/ana> Get-ChildItem HKLM:\SOFTWARE
Get-ChildItem: Cannot find drive. A drive with the name 'HKLM' does not exist.
```
