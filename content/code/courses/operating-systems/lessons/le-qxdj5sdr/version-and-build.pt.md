---
title: Lendo a versão inteira
version: 1
---

"Que Windows é esse?" tem quatro respostas, e um chamado de suporte precisa de todas. A aula 2 abriu a
janela do `winver`; isto é o que a linha dele quer dizer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"O texto que o winver imprime, Windows 11 Pro, Versão 24H2, Compilação do SO 26100.4351, desmontado em quatro partes. Windows 11 Pro é o produto e a edição, que decide os recursos e como o PC pode ser gerenciado. Versão 24H2 é a atualização de recursos: o ano e o semestre em que saiu, e decide se o suporte dura 24 ou 36 meses. Compilação do SO 26100 é a versão-base, que é o que os programas conferem; 22000 ou mais quer dizer Windows 11. E .4351, a revisão, são os patches mensais: sobe a cada Patch Tuesday e diz o quanto o PC está em dia.\"><defs><marker id=\"bd-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o que o winver imprime, desmontado</text><rect x=\"20\" y=\"32\" width=\"170\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"105.0\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Windows 11 Pro</text><path d=\"M105.0 68 L105.0 88\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"105.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">produto e edição</text><text x=\"105.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quais recursos</text><text x=\"105.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e que gerenciamento</text><rect x=\"200\" y=\"32\" width=\"170\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"285.0\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Versão 24H2</text><path d=\"M285.0 68 L285.0 88\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"285.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a atualização de recursos</text><text x=\"285.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">que ano, que semestre</text><text x=\"285.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">24 ou 36 meses de suporte</text><rect x=\"380\" y=\"32\" width=\"180\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"470.0\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Compilação do SO 26100</text><path d=\"M470.0 68 L470.0 88\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"470.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a versão-base</text><text x=\"470.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que os programas conferem</text><text x=\"470.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">22000 ou mais: Windows 11</text><rect x=\"570\" y=\"32\" width=\"130\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"635.0\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.4351</text><path d=\"M635.0 68 L635.0 88\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"635.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">os patches mensais</text><text x=\"635.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sobe a cada Patch Tuesday</text><text x=\"635.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o quanto está em dia</text></svg>", "caption": "Dois PCs que dizem \"Windows 11\" podem diferir nas quatro partes. Um chamado de suporte precisa da linha inteira."}
```

- *O produto e a edição*, *Windows 11 Pro*. A edição é o assunto da seção 03.
- *A versão*, *24H2*: a *atualização de recursos*, com o nome do ano e do semestre em que saiu.
  24H2 é o segundo semestre de 2024, e a 25H2 veio um ano depois. A seção 02 é sobre por que isso
  importa.
- *O build*, *26100*. Toda atualização de recursos tem um, e é ele que programas e instaladores
  conferem, porque é um número. 22000 para cima é Windows 11; o último do Windows 10 foi o 19045.
- *A revisão*, *.4351*. Sobe cada vez que as atualizações de segurança do mês são instaladas, então
  dois PCs no mesmo build podem estar a meses de distância.

## Perguntando pela linha de comando

```sh
winver                                     # the window: edition, version, build
Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' |
  Select-Object ProductName, EditionID, DisplayVersion, CurrentBuild, UBR
```

**Nenhum destes foi rodado para esta aula**; são comandos do Windows, e os registros deste curso vêm do
Linux. O `Get-ItemProperty` lê o registro, que a aula 15 abre direito.

Um dos valores dele é famoso por estar errado. **O `ProductName` ainda diz *Windows 10* no Windows
11**, porque a Microsoft manteve o valor sem mudar para não quebrar programas antigos que o conferem. Um
script que o lê para decidir "isto é Windows 11?" responde não em todo PC com Windows 11. O número do
build e o `Caption` do `Get-CimInstance` estão certos; e essa é a lição geral também: **decida pelo
número, não pelo nome**.
