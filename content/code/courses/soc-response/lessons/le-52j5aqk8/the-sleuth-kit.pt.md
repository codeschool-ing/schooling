---
title: O Sleuth Kit, camada por camada
version: 1
---

O **The Sleuth Kit** (TSK) é um conjunto de ferramentas de linha de comando para ler imagens de disco sem
montá-las, e é o motor por baixo do Autopsy, a ferramenta gráfica mais adiante nesta aula. A aula 1 o instalou
com o pacote `sleuthkit`. As ferramentas têm o nome da **camada** do sistema de arquivos que leem:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"As quatro camadas que o The Sleuth Kit lê, de cima para baixo: nomes, os nomes de arquivo nos diretórios, lidos pelo fls; metadados, os inodes com tamanhos, horários e listas de blocos, lidos pelo istat e pelo icat; conteúdo, os blocos de dados, lidos pelo blkcat; e o próprio sistema de arquivos, o seu layout, lido pelo fsstat. Um arquivo apagado perdeu a ligação do nome com o inode, mas o inode e os blocos continuam lá.\"><rect x=\"10\" y=\"14\" width=\"700\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"41\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">nomes</text><text x=\"190\" y=\"41\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">fls</text><text x=\"320\" y=\"41\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">exports/contacts-2026-08.csv  *</text><rect x=\"10\" y=\"70\" width=\"700\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">metadados</text><text x=\"190\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">istat · icat</text><text x=\"320\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">inode 24: 313 bytes, bloco 1561</text><rect x=\"10\" y=\"126\" width=\"700\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">conteúdo</text><text x=\"190\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">blkcat</text><text x=\"320\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">bloco 1561: client,contact,email…</text><rect x=\"10\" y=\"182\" width=\"700\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">sistema de arquivos</text><text x=\"190\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">fsstat</text><text x=\"320\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ext4, blocos de 4096 bytes</text></svg>", "caption": "Apagar corta a ligação de cima. Tudo que está embaixo espera ser sobrescrito."}
```

Primeiro a camada de baixo. O `fsstat` descreve o sistema de arquivos como um todo:

```
root@soc:~/case# fsstat work.dd | head -5
FILE SYSTEM INFORMATION
--------------------------------------------
File System Type: Ext4
Volume Name: files-data
Volume ID: 812eafe98540ccb188486ecf1d6d4db5
root@soc:~/case# fsstat work.dd | grep -E '^(Block Size|Block Range|Free Blocks)'
Block Range: 0 - 8191
Block Size: 4096
Free Blocks: 6631
```

Um sistema de arquivos ext4 chamado `files-data`, feito de 8.192 blocos de 4.096 bytes, dos quais 6.631 estão
livres. Depois a camada de cima: o `fls` lista nomes, `-r` por todas as pastas, `-p` com o caminho completo:

```
root@soc:~/case# fls -r -p work.dd
d/d 11:	lost+found
d/d 12:	clients
d/d 13:	clients/acme-logistica
r/r 14:	clients/acme-logistica/contracts.csv
d/d 15:	clients/bento-advogados
r/r 16:	clients/bento-advogados/contracts.csv
d/d 17:	clients/casa-verde
r/r 18:	clients/casa-verde/contracts.csv
d/d 19:	clients/delta-engenharia
r/r 20:	clients/delta-engenharia/contracts.csv
d/d 21:	clients/estrela-saude
r/r 22:	clients/estrela-saude/contracts.csv
d/d 23:	exports
r/r * 24:	exports/contacts-2026-08.csv
V/V 8193:	$OrphanFiles
```

Cada linha é um tipo (`d` um diretório, `r` um arquivo comum), um **número de inode** e um nome. O inode é o
registro por trás do nome: tamanho, dono, horários, e quais blocos guardam os dados. E uma linha é diferente:
**o asterisco em `r/r * 24`** marca um nome cujo inode não está mais alocado. É um arquivo apagado, e o `fls` o
achou porque o ext4 removeu a ligação entre o nome e o inode, não o próprio nome.

`$OrphanFiles` nem está no disco: é uma pasta que o TSK inventa para guardar inodes que têm dados mas nenhum nome
apontando para eles.
