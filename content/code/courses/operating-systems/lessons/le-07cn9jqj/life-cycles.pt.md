---
title: Quanto dura uma versão
version: 1
---

Toda versão tem um **fim de vida**, o dia em que as correções de segurança param. Depois dele a máquina
continua rodando e não recebe mais correções, que é o problema do Windows 10 da aula 5 com outro nome.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Um gráfico de barras de quantos anos cada tipo de versão recebe correções de segurança. Uma versão intermediária do Ubuntu, nove meses. O Fedora, cerca de treze meses. O Debian stable, três anos, e cinco com a equipe LTS do Debian. O Ubuntu LTS, cinco anos, e dez com o Ubuntu Pro. O RHEL e as reconstruções dele, dez anos.\"><defs><marker id=\"sp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"31\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Ubuntu, versão intermediária</text><rect x=\"220\" y=\"20\" width=\"34.5\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"69\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Fedora</text><rect x=\"220\" y=\"58\" width=\"50.6\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Debian stable</text><rect x=\"220\" y=\"96\" width=\"138\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"358\" y=\"96\" width=\"92\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"20\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Ubuntu LTS</text><rect x=\"220\" y=\"134\" width=\"230\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"450\" y=\"134\" width=\"230\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"20\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">RHEL e as reconstruções</text><rect x=\"220\" y=\"172\" width=\"460\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><path d=\"M220 206 L220 214\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"220\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M312 206 L312 214\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"312\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><path d=\"M404 206 L404 214\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"404\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><path d=\"M496 206 L496 214\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"496\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><path d=\"M588 206 L588 214\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"588\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><path d=\"M680 206 L680 214\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"680\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"450\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">anos de correções de segurança</text><rect x=\"220\" y=\"260\" width=\"22\" height=\"12\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"248\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">de graça</text><rect x=\"330\" y=\"260\" width=\"22\" height=\"12\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"358\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">com as equipes LTS ou o Ubuntu Pro</text></svg>", "caption": "Um servidor é instalado para anos. Só as três últimas linhas duram mais do que a troca de hardware em que ele vai ser substituído.", "same": ["Fedora", "Debian stable", "Ubuntu LTS"]}
```

As datas são publicadas, e no Ubuntu o pacote `distro-info` as traz, então o servidor responde sozinho:

```
ana@server:~$ ubuntu-distro-info --series noble --fullname
Ubuntu 24.04 LTS "Noble Numbat"
ana@server:~$ ubuntu-distro-info --series noble --days=eol
979
ana@server:~$ ubuntu-distro-info --series noble --days=eol-esm
2769
ana@server:~$ ubuntu-distro-info --supported --fullname
Ubuntu 22.04 LTS "Jammy Jellyfish"
Ubuntu 24.04 LTS "Noble Numbat"
Ubuntu 26.04 LTS "Resolute Raccoon"
Ubuntu 26.10 "Stonking Stingray"
ana@server:~$ ubuntu-distro-info --lts
resolute
ana@server:~$ ubuntu-distro-info --devel
stonking
```

- O `--days=eol` conta os dias até o fim do **suporte padrão** da 24.04: 979 a partir do dia em que
  isto foi registrado, um pouco mais de dois anos e meio.
- O `--days=eol-esm` conta até o fim da **Expanded Security Maintenance**: 2769 dias, a marca dos dez
  anos. A ESM vem com o **Ubuntu Pro**, gratuito para uso pessoal em poucas máquinas e pago para
  empresas.
- O `--supported` lista o que ainda tem manutenção. **A 24.04 não é mais a LTS mais nova**: a 26.04,
  *Resolute Raccoon*, saiu em abril de 2026. A 26.10 também está na lista, e o `--devel` mostra que é a
  que ainda está sendo preparada.

A lista do Debian tem o mesmo formato:

```
ana@server:~$ debian-distro-info --stable --fullname
Debian 13 "Trixie"
ana@server:~$ debian-distro-info --supported
trixie
forky
sid
experimental
```

O Debian 13 é a versão estável. O `forky` é o que vai virar a 14, o `sid` é o ramo contínuo da seção
03, e o `experimental` é o que o nome diz.

## Para que servem os números

- Um **servidor** é instalado para anos, então ele vai para uma versão com anos pela frente. Instalar a
  24.04 num servidor novo em setembro de 2026 desperdiça dois deles; a 26.04 é a escolha.
- **Uma LTS ganha a primeira versão pontual alguns meses depois do lançamento**, a *26.04.1*. Só então
  o `do-release-upgrade` oferece o salto a partir da LTS anterior, e administradores cuidadosos esperam
  por ela de qualquer jeito, porque as primeiras semanas encontram os bugs.
- Saber a data de fim é só metade. **Ponha na agenda** com um ano de antecedência, porque mover um
  servidor entre versões é um projeto, não uma noite.
