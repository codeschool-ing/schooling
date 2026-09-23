---
title: Para que serve uma mensagem
version: 1
---

Aqui está uma semana de trabalho, com as mensagens do jeito que as pessoas escrevem quando ninguém pede
o contrário:

```
ana@vm:~/before$ git log --oneline
db63087 final
11fce14 more changes
b34fabb asdf
9fb788b fixed stuff
3699ea0 wip
4ede6f2 fix
83c90c8 changes
5d69802 update
ec3275a first
```

E a mesma semana do site da padaria como este curso a manteve:

```
ana@vm:~/site$ git log --oneline
6555c9b Link the menu from the home page
eadf998 Take rye bread off until the flour arrives
31a6298 Add cheese rolls
1b2d576 Put the prices up for September
8577a83 Open at half past five
95e3b9d Add rye bread to the menu
c3e07c2 Add the menu
5d6d04f Give the heading its colour
6abda31 Add the home page
```

Nove commits cada. O primeiro log não diz nada sem abrir cada commit, e abri-los diz o que mudou, mas
nunca por quê. O segundo pode ser lido como uma lista do que aconteceu. **A mensagem é a única parte de
um commit que diz por quê**, e a primeira linha é a única parte que a maioria das pessoas vê, uma linha
de `git log --oneline` de cada vez.

## A primeira linha

- **Diga o que o commit faz, como uma instrução**: *Add the menu*, *Take rye bread off until the flour
  arrives*. Isso é o imperativo, e combina com as mensagens do próprio Git, *Merge branch 'sunday'*,
  *Revert "…"*. Um teste útil: a linha deve completar a frase *se aplicado, este commit vai…*
- **Seja curto**, em torno de 50 caracteres, porque ela aparece em listas que a cortam. Diga a coisa
  única; os detalhes vão embaixo.
- **Sem ponto final.** É um título.

*Fix* falha nos três. Não diz o que foi corrigido, e quem lê o log é quem tem de abrir o commit para
descobrir.

## O corpo

Deixe uma linha em branco depois da primeira linha e escreva o quanto a mudança precisar. **O corpo é
para o porquê**, já que o diff mostra o quê:

```
ana@vm:~/site$ git log -1
commit 3095dd7534445864bf0ed2cd7e304078cac1fe60
Author: Ana Souza <ana@example.com>
Date:   Mon Sep 21 09:00:00 2026 -0300

    Open at half past six from October to March
    
    The first bus from the station now arrives at 06:20, so customers
    waiting at half past five were standing outside for nearly an hour.
    Summer hours stay as they are.
```

A primeira linha diz o quê; o corpo diz que problema resolveu e o que deliberadamente não mudou.
Quebre as linhas em uns 72 caracteres, porque o `git log` as indenta e não quebra nada sozinho. A
maioria dos commits não precisa de corpo nenhum. Um commit cujo motivo não é óbvio pela primeira linha
precisa, e são exatamente esses que alguém vai se perguntar mais tarde.

É também por isso que a aula 1 configurou um editor no `core.editor`: o `-m` serve para uma linha, e o
editor é onde se escreve um corpo.

## Quem lê

Você, daqui a seis meses, rodando `git blame` numa linha que parece errada, que a aula 3 prometeu que
leva a um motivo. Quem revisa, lendo os commits do pull request. Quem escreve as notas de release.
**Uma mensagem é escrita uma vez e lida muitas**, então o minuto que ela leva é a parte mais barata da
mudança.

*As mensagens deste curso estão em inglês, e isso é uma escolha comum de equipes: o histórico é lido
por quem entrar no projeto depois, e o inglês é a língua que mais gente compartilha. Uma equipe que
só fala português pode escrever em português; o que importa é todo mundo escrever na mesma.*
