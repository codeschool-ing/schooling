---
title: Onde tudo mora: uma árvore, sem letras
version: 1
---

A primeira surpresa para quem vem do Windows é que não existe `C:`. O Linux tem *uma árvore de pastas*,
começando em `/`, a *raiz*, e todo disco, pendrive e compartilhamento de rede aparece em algum lugar
dentro dela:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois jeitos de organizar discos. No Linux, uma árvore começando na barra: home barra ana guarda seus arquivos, etc guarda a configuração, var barra log guarda os logs, usr guarda os programas, e um pendrive aparece como uma pasta, media barra usb, depois de montado. No Windows, uma árvore separada por unidade: C: é o disco do sistema, com Users barra Ana para seus arquivos, Windows para o sistema e Program Files para os programas; um pendrive ganha uma letra própria, E:.\"><defs><marker id=\"tr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Linux: uma árvore</text><text x=\"380\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Windows: uma árvore por unidade</text><rect x=\"20\" y=\"34\" width=\"40\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">/</text><path d=\"M40 60 L40 80 L60 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"66\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">home/ana</text><text x=\"170\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">seus arquivos</text><path d=\"M40 60 L40 114 L60 114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"66\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">etc</text><text x=\"170\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">configuração</text><path d=\"M40 60 L40 148 L60 148\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"66\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">var/log</text><text x=\"170\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">logs</text><path d=\"M40 60 L40 182 L60 182\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"66\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">usr</text><text x=\"170\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">programas</text><path d=\"M40 60 L40 216 L60 216\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"66\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">media/usb</text><text x=\"170\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">um pendrive, montado</text><rect x=\"380\" y=\"34\" width=\"44\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"402\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">C:\\</text><text x=\"432\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o disco do sistema</text><path d=\"M402 60 L402 80 L422 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"428\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Users\\Ana</text><text x=\"560\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">seus arquivos</text><path d=\"M402 60 L402 114 L422 114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"428\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Windows</text><text x=\"560\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o sistema</text><path d=\"M402 60 L402 148 L422 148\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"428\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Program Files</text><text x=\"560\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">programas</text><rect x=\"380\" y=\"196\" width=\"44\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"402\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">E:\\</text><text x=\"432\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">um pendrive, com letra própria</text></svg>", "caption": "Um segundo disco no Linux é uma pasta em algum lugar da única árvore. No Windows, é uma letra nova.", "same": ["logs"]}
```

Aqui está o topo dessa árvore no servidor recém-instalado:

```
ana@server:~$ ls /
bin                dev   lib                media  proc  sbin                sys  var
bin.usr-is-merged  etc   lib.usr-is-merged  mnt    root  sbin.usr-is-merged  tmp
boot               home  lib64              opt    run   srv                 usr
ana@server:~$ ls /home
ana
```

Você raramente vai precisar da maioria delas, e algumas valem ser reconhecidas desde o começo:

| pasta | guarda | o equivalente no Windows |
|---|---|---|
| `/home/ana` | os arquivos e configurações da Ana | `C:\Users\Ana` |
| `/etc` | a configuração do sistema, em arquivos de texto | o registro, aula 15 |
| `/var/log` | logs | o Visualizador de Eventos, aula 17 |
| `/usr` | programas instalados | `C:\Program Files` |
| `/tmp` | arquivos temporários, esvaziada ao reiniciar | `%TEMP%` |
| `/media`, `/mnt` | onde discos e pendrives extras aparecem | as outras letras de unidade |
| `/boot` | o kernel e os arquivos do GRUB | as partições EFI e do sistema |

Os nomes terminados em `.usr-is-merged` são restos de uma mudança recente do Ubuntu e podem ser
ignorados.

## Montagem

Prender um disco a uma pasta da árvore se chama **montar** o disco. Ligue um pendrive na versão Desktop
e ele aparece em `/media/ana/`, com o nome do pendrive depois. No servidor, nada é montado
automaticamente; a aula 12 faz isso à mão. O princípio é o da figura: no Linux um segundo disco é uma
*pasta*, no Windows é uma *letra*, e nos dois casos os arquivos são os mesmos.

## Maiúsculas e minúsculas

Mais uma diferença que derruba as pessoas: no Linux, `Report.txt` e `report.txt` são **dois arquivos
diferentes** na mesma pasta. No Windows e, por padrão, no macOS, são o mesmo arquivo. Um documento que
abre bem num PC com Windows e "não é encontrado" quando um servidor Linux o procura muitas vezes é isso.
