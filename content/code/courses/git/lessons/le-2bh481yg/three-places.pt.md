---
title: Diretório de trabalho, área de preparo e repositório
version: 1
---

Um repositório começa como uma pasta comum. O `git init` a transforma em um:

```
ana@vm:~$ mkdir site && cd site
ana@vm:~/site$ git init
Initialized empty Git repository in /home/ana/site/.git/
ana@vm:~/site$ ls -a
.
..
.git
index.html
ana@vm:~/site$ ls .git
HEAD
branches
config
description
hooks
info
objects
refs
```

Nada no `index.html` mudou. O que mudou foi o diretório novo ao lado dele, `.git`, que o `ls` só
mostra quando você pede os arquivos ocultos com `-a`. **Esse diretório é o repositório.** Todo
commit, todo branch e toda configuração deste projeto moram dentro dele, e em nenhum outro lugar.
Copie a pasta e você copia o histórico; apague o `.git` e o histórico se vai, enquanto os arquivos
ficam exatamente como estão. Você nunca vai precisar editar nada ali à mão, e a aula 1 já mostrou a
única vez em que vale a pena olhar: os objetos lá dentro são commits, árvores e conteúdos de
arquivo.

## Três lugares, não dois

A imagem óbvia tem dois lugares: os arquivos e as versões salvas. O Git tem um terceiro no meio, e
boa parte da confusão que as pessoas têm com o Git vem de não saber que ele está ali.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Três caixas da esquerda para a direita: o diretório de trabalho, com os arquivos que você edita; a área de preparo, com o próximo commit enquanto ele é montado; e o repositório, com todos os commits. O git add leva uma mudança da primeira para a segunda, e o git commit leva tudo o que foi preparado para a terceira.\"><defs><marker id=\"tp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"180\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">diretório de trabalho</text><text x=\"110\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">os arquivos que você edita</text><rect x=\"270\" y=\"40\" width=\"180\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">área de preparo</text><text x=\"360\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o próximo commit, sendo montado</text><rect x=\"520\" y=\"40\" width=\"180\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">repositório</text><text x=\"610\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">todos os commits, em .git</text><path d=\"M203 75 L266 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tp-ah)\"></path><text x=\"235\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">git add</text><path d=\"M453 75 L516 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tp-ah)\"></path><text x=\"485\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">git commit</text><path d=\"M110 112 L110 150 L610 150 L610 112\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M360 112 L360 150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"360\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o git status compara os três e diz onde está cada mudança</text></svg>", "caption": "Uma mudança anda da esquerda para a direita em dois passos. Entre eles ela pode ser examinada, e deixada de fora."}
```

**O diretório de trabalho** é a pasta como você a vê: os arquivos que o seu editor abre e que o seu
navegador carrega. O Git o observa e nunca o muda pelas suas costas.

**A área de preparo** é o commit que você está montando. O `git add` copia um arquivo para ela, do
jeito que ele está naquele momento. Nada vai para o histórico ainda. Ela também se chama *index*, e
é esse o nome que você vai encontrar em documentação mais antiga e em algumas mensagens do próprio
Git. Em inglês, *staging area*.

**O repositório** é o histórico. O `git commit` pega o que estiver na área de preparo, tudo e nada
além disso, e registra como um commit novo.

## Por que o passo do meio existe

O Subversion, e a maioria dos sistemas antes do Git, não tinha área de preparo: um commit levava
todas as mudanças que você tinha feito, a não ser que você listasse os arquivos um a um. O problema é que um diretório de trabalho raramente
tem exatamente uma mudança. Você corrige o horário de abertura, começa uma folha de estilo nova,
deixa um parágrafo pela metade, e aí alguém pede que você faça o commit da correção. **A área de
preparo é onde você diz de qual dessas mudanças este commit trata.** O resto fica no diretório de
trabalho, intocado, para um commit posterior, ou para nenhum.

Esse é o motivo, e vale guardá-lo, porque os comandos desta aula só fazem sentido contra ele. O
`git add` não quer dizer *acompanhe este arquivo para sempre*. Quer dizer *ponha esta versão deste
arquivo no próximo commit*.
