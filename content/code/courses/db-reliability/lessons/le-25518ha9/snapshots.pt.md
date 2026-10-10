---
title: Snapshots, e o sistema de arquivos congelado no lugar
version: 1
---

Copiar um terabyte arquivo por arquivo leva horas. Um **snapshot** leva um segundo, seja qual for o
tamanho: uma camada de armazenamento capaz de tirar snapshots (LVM, ZFS, btrfs, os discos de um
provedor de nuvem, uma SAN, o seu hipervisor) registra o estado de um volume inteiro num instante e
guarda os blocos antigos à medida que o volume vivo muda. É o backup mais rápido que existe, e o que
mais se tira errado.

## O que é um snapshot de um servidor rodando

Um snapshot do volume que guarda o diretório de dados de um servidor em funcionamento captura os
arquivos como estavam num instante, **como se a energia tivesse sido cortada naquele instante**.
Esse estado se chama **crash-consistent**, e o PostgreSQL foi feito para sobreviver a ele: o
write-ahead log é escrito antes dos dados, então um servidor que sobe numa cópia crash-consistent
reaplica o log e chega a um banco consistente. Um snapshot é, portanto, seguro de um jeito que o
`cp` não era, porque todo arquivo é do mesmo momento.

A condição é **todo arquivo do mesmo momento**, e ela cai no dia em que os dados e o log ficam em
dois volumes, o que é uma recomendação comum por desempenho:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois volumes, dados e write-ahead log. No alto, cada um ganha um snapshot separado, os dados às 10:00:00.000 e o log às 10:00:00.400, então o log descreve 400 ms de mudanças que a cópia dos dados não tem. Embaixo, os dois ganham snapshot como um grupo atômico, no mesmo instante.\"><defs><marker id=\"l3v-ph\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><defs><marker id=\"l3v-pa\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">volume de dados</text><rect x=\"20\" y=\"66\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">volume do WAL</text><rect x=\"20\" y=\"140\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">volume de dados</text><rect x=\"20\" y=\"186\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">volume do WAL</text><path d=\"M180 38 L230 38\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3v-pa)\"></path><text x=\"240\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">snapshot às 10:00:00.000</text><path d=\"M180 84 L230 84\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3v-pa)\"></path><text x=\"240\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">snapshot às 10:00:00.400</text><rect x=\"470\" y=\"34\" width=\"230\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"585\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">400 ms de log descrevem</text><text x=\"585\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">mudanças que a cópia dos dados não tem</text><path d=\"M180 158 L210 158 L210 204 L180 204\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M210 181 L240 181\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3v-ph)\"></path><rect x=\"250\" y=\"158\" width=\"220\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">um grupo atômico</text><text x=\"360\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">os dois no mesmo instante</text></svg>", "caption": "Dados e log em dois volumes. Com snapshots um depois do outro, eles são duas quedas, não uma; só um snapshot em grupo atômico os põe no mesmo instante."}
```

Dois snapshots, mesmo tirados com algumas centenas de milissegundos de diferença, já não são uma
queda só. O log pode estar atrás dos dados que deveria explicar, e o servidor que sobe nesse par
reaplica a história errada ou se recusa a subir. Um snapshot de vários volumes só é seguro se o
armazenamento os tira **atomicamente, como um grupo**, o que a maioria dos provedores de nuvem
oferece com um nome como consistency group ou snapshot multivolume, e que precisa ser pedido.

## Os dois jeitos seguros

1. **Um snapshot atômico de tudo o que o servidor escreve**: diretório de dados, write-ahead log e
   qualquer tablespace, num único snapshot ou num grupo que o armazenamento garante ser atômico.
   Restaure e suba o servidor: ele roda a recuperação de queda, exatamente como depois de um corte
   de energia.
2. **Avisar o PostgreSQL de que um backup está começando.** Em SQL,
   `SELECT pg_backup_start('label')` antes do snapshot e `SELECT * FROM pg_backup_stop()` depois
   dele, na mesma sessão, fazem o servidor devolver o texto do mesmo `backup_label` que o base
   backup tinha.
   Você o grava na cópia, e uma cópia tirada em momentos diferentes pode então ser consertada com o
   log. Essa é a conversa que o `pg_basebackup` tem por você.

O congelamento do próprio sistema de arquivos, o `fsfreeze` no Linux, segura toda escrita num volume
enquanto um snapshot é tirado, o que deixa o snapshot de um volume limpo no nível do sistema de
arquivos. Ele não transforma dois volumes num momento só, e **com o PostgreSQL acrescenta pouco**: o
próprio log do servidor já torna segura a cópia crash-consistent de um volume único.

## Sua máquina virtual é uma máquina de snapshots

A lição 1 sugeriu tirar um snapshot da máquina virtual no fim da instalação. Tirado com a máquina
ligada, esse snapshot é crash-consistent para tudo o que está dentro dela, PostgreSQL incluído,
porque o disco da máquina inteira é um volume só. É um bom jeito de desfazer uma tarde. Não é um
backup no sentido deste curso, pelo motivo a que a lição 9 se dedica: **ele mora no mesmo
computador que aquilo que protege.**

Este laboratório não tem gerenciador de volumes com que tirar snapshots, então esta seção é para
ler, não para digitar.
