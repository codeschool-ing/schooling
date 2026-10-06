---
title: Camadas empilhadas num sistema de arquivos só
version: 1
---

**O sistema de arquivos de um container são vários diretórios empilhados de modo que sejam lidos
como um só**: as camadas da imagem embaixo, somente leitura, e um diretório vazio em cima que recebe
cada escrita. O Linux faz o empilhamento com o **overlayfs**, um sistema de arquivos de união que vem
no kernel. É por isso que os dois containers da aula 1 conseguiam compartilhar uma imagem sem que um
visse o arquivo do outro, e é por isso que iniciar um container não copia nada.

## A pilha, do jeito que o kernel a vê

O container `web` da primeira etapa continua rodando. A Ana faz duas mudanças dentro dele, cria um
arquivo e apaga um que veio com a imagem, e depois pergunta ao host como o sistema de arquivos raiz
do container está montado:

```
ana@vm:~$ docker exec web sh -c "echo hello > /tmp/new.txt; rm /etc/motd"
ana@vm:~$ findmnt -no OPTIONS /var/lib/docker/rootfs/overlayfs/$(docker inspect -f "{{.Id}}" web) | tr "," "\n"
rw
relatime
lowerdir=/var/lib/docker/containerd/daemon/io.containerd.snapshotter.v1.overlayfs/snapshots/211/fs:/var/lib/docker/containerd/daemon/io.containerd.snapshotter.v1.overlayfs/snapshots/110/fs
upperdir=/var/lib/docker/containerd/daemon/io.containerd.snapshotter.v1.overlayfs/snapshots/212/fs
workdir=/var/lib/docker/containerd/daemon/io.containerd.snapshotter.v1.overlayfs/snapshots/212/work
```

Três diretórios, cada um com um número, todos dentro do snapshotter do containerd que o Docker do
laboratório usa para guardar imagens:

- **`lowerdir`** é uma lista, lida da esquerda para a direita como de cima para baixo: o snapshot
  211, depois o 110. Os dois são somente leitura.
- **`upperdir`** é o snapshot 212, a camada do próprio container, onde cai cada mudança.
- **`workdir`** é um espaço de rascunho de que o overlayfs precisa para a própria contabilidade.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Quatro faixas horizontais. Embaixo, o snapshot 110, a camada da imagem do Alpine, somente leitura, que contém o etc/motd entre as 519 entradas. Acima, o snapshot 211, a camada que o Docker grava por container, com etc/hostname, etc/hosts, etc/resolv.conf e .dockerenv, também somente leitura. Acima, o snapshot 212, a camada superior de escrita do container, com tmp/new.txt e um whiteout para etc/motd. No topo, a visão mesclada que o container enxerga: o tmp/new.txt está lá e o etc/motd não.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">mesclado</text><text x=\"36\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que o container enxerga</text><text x=\"260\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tmp/new.txt</text><text x=\"372\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">etc/hostname</text><text x=\"484\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bin/…</text><text x=\"596\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">etc/motd</text><path d=\"M594 48 L658 48\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20\" y=\"95\" width=\"680\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">snapshot 212</text><text x=\"36\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">upperdir · escrita</text><text x=\"260\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">tmp/new.txt</text><text x=\"372\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">etc/motd  (whiteout)</text><rect x=\"20\" y=\"170\" width=\"680\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">snapshot 211</text><text x=\"36\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lowerdir · somente leitura</text><text x=\"260\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">etc/hostname</text><text x=\"372\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">etc/hosts</text><text x=\"484\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">etc/resolv.conf</text><text x=\"596\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">.dockerenv</text><rect x=\"20\" y=\"245\" width=\"680\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">snapshot 110 · alpine</text><text x=\"36\" y=\"284\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lowerdir · somente leitura</text><text x=\"260\" y=\"273\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">bin/…</text><text x=\"372\" y=\"273\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">etc/motd</text><text x=\"484\" y=\"273\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">… 519 entradas</text></svg>", "caption": "O overlayfs lê de cima para baixo e para na primeira camada que tem o caminho. O whiteout da camada superior responde primeiro pelo etc/motd, então a cópia na camada do Alpine fica escondida e nunca é tocada."}
```

## Para onde foram as mudanças

A camada superior guarda exatamente o que a Ana mudou, e mais nada:

```
ana@vm:~$ SNAP=/var/lib/docker/containerd/daemon/io.containerd.snapshotter.v1.overlayfs/snapshots
ana@vm:~$ sudo find $SNAP/212/fs -mindepth 1 -printf '%P\n'
etc
etc/motd
tmp
tmp/new.txt
ana@vm:~$ sudo ls -l $SNAP/212/fs/etc
total 0
c--------- 2 root root 0, 0 Oct  6 13:20 motd
```

`tmp/new.txt` é o arquivo novo, gravado inteiro na camada superior. **`etc/motd` é o apagado**, e nem
é um arquivo: o `c` no começo da linha marca um dispositivo de caractere numerado `0, 0`. Esse é o
**whiteout** do overlayfs. O `/etc/motd` da própria imagem continua no snapshot 110, intacto, porque
nada nunca escreve numa camada inferior; o whiteout por cima manda o overlayfs escondê-lo, então
dentro do container o arquivo sumiu.

Mudar um arquivo existente funciona do mesmo jeito, com um custo: a primeira escrita copia o arquivo
inteiro para a camada superior, e é a cópia que muda daí em diante. Um container que acrescenta uma
linha a um arquivo de 2 GB que veio na imagem faz antes uma cópia de 2 GB. A aula 8 mostra onde dados
que mudam deveriam morar.

## A camada do meio

O snapshot 110 é a camada do Alpine, o mesmo arquivo tar que a aula 3 abriu. O snapshot 211 fica
entre ela e a camada do próprio container, e é pequeno:

```
ana@vm:~$ sudo find $SNAP/211/fs -type f -printf '%P\n'
etc/hosts
etc/resolv.conf
etc/hostname
dev/console
.dockerenv
```

**O Docker grava esta camada para cada container**: o nome de máquina que ele recebeu, a
configuração de DNS e o arquivo de hosts que ele deve usar, e o `.dockerenv`, um arquivo vazio cuja
presença é um jeito comum de um programa saber que está num container Docker. Ela fica fora da
imagem para que a mesma imagem possa iniciar containers com nomes e redes diferentes.

## A imagem não mudou

Um container novo da mesma imagem mostra os arquivos originais:

```
ana@vm:~$ docker run --rm alpine:3.22 ls /tmp /etc/motd
/etc/motd

/tmp:
```

O `/etc/motd` está lá e o `/tmp` está vazio. A imagem é a base da pilha de todo container, e
**nenhum container nunca escreve nela**. É isso que torna descartáveis as mudanças de um container:
remova o container, e a camada superior dele vai junto, que é o assunto inteiro da aula 7.
