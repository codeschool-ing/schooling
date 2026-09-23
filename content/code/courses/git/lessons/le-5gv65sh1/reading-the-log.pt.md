---
title: Lendo o log
version: 1
---

A aula 1 mostrou o log uma vez. Assim é que você o usa de fato: o formato padrão, o curto, e os
filtros que transformam um histórico comprido nos três commits que você estava procurando.

## Os dois formatos que você mais vai usar

Sem opções, o `git log` imprime todos os commits, do mais novo para o mais antigo, por inteiro.
Limite com um número:

```
ana@vm:~/site$ git log -2
commit 6555c9b314e48ad30e5c97a2ec1c8657347caa91
Author: Ana Souza <ana@example.com>
Date:   Fri Sep 18 15:30:00 2026 -0300

    Link the menu from the home page

commit eadf99876ab90aa5308943f849d4eef920bc363f
Author: Bruno Lima <bruno@example.com>
Date:   Fri Sep 18 08:50:00 2026 -0300

    Take rye bread off until the flour arrives
```

Esse é o formato para ler com atenção. Para dar uma olhada geral, a forma de uma linha cabe uma
semana de trabalho numa tela:

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

Nove commits, duas pessoas, uma semana. **Cada linha é um id curto e a primeira linha da mensagem**,
e é por isso que a aula 11 gasta tempo com o que essa primeira linha diz: é a única parte que a
maioria das pessoas vai ler.

## O que um commit tocou

O `--stat` acrescenta os arquivos que cada commit mudou. Aqui está num commit só, escolhido com
`HEAD~3`:

```
ana@vm:~/site$ git log --stat -1 HEAD~3
commit 1b2d576126103b29221b62bff65378012554c501
Author: Bruno Lima <bruno@example.com>
Date:   Wed Sep 16 16:25:00 2026 -0300

    Put the prices up for September

 menu.html | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
```

**`HEAD` é o commit em que você está, e `HEAD~3` é o de três commits antes** — siga o `parent` três
vezes. Dá para usar um id curto no lugar, `1b2d576`, e qualquer coisa que nomeie um commit é aceita
onde o Git quiser um. A linha de estatística diz `menu.html | 4 ++--`: quatro linhas mexidas num
arquivo, duas acrescentadas e duas removidas, que é a cara de mudar dois preços.

## Filtros

Um histórico de algumas centenas de commits é normal, e ninguém o lê de cima. Quatro filtros fazem
a maior parte do trabalho de estreitar:

```
ana@vm:~/site$ git log --oneline --author=Bruno
eadf998 Take rye bread off until the flour arrives
1b2d576 Put the prices up for September
95e3b9d Add rye bread to the menu
ana@vm:~/site$ git log --oneline -- index.html
6555c9b Link the menu from the home page
8577a83 Open at half past five
6abda31 Add the home page
ana@vm:~/site$ git log --oneline --since=2026-09-17
6555c9b Link the menu from the home page
eadf998 Take rye bread off until the flour arrives
ana@vm:~/site$ git log --oneline --grep=price
1b2d576 Put the prices up for September
```

- `--author=Bruno` fica com os commits cujo autor combina. É um padrão, então o primeiro nome basta.
- `-- index.html` fica com os commits que mudaram esse arquivo. O `--` separa nomes de arquivo de
  todo o resto, e é um bom hábito mesmo quando o Git conseguiria adivinhar.
- `--since=2026-09-17` fica com o que aconteceu naquela data ou depois. O `--until` é a outra ponta,
  e os dois aceitam `"2 weeks ago"` além de uma data.
- `--grep=price` busca nas mensagens. Ele achou *prices* também, porque procura um padrão e não uma
  palavra inteira.

**Eles se combinam.** `git log --oneline --author=Bruno -- menu.html` é toda mudança que o Bruno fez
no cardápio, e costuma ser mais rápido digitar isso do que rolar a tela.

Mais uma coisa que o log faz sem avisar: **ele para na primeira tela e espera** quando a saída é
maior que o terminal, do jeito que o `less` faz. Espaço avança e `q` sai. As transcrições desta aula
foram capturadas sem isso, e é por isso que elas terminam onde a saída termina.
