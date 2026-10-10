---
title: Três formas na bilheteria
version: 1
---

Três das cinco formas cabem num minuto cada, e rodá-las contra a bilheteria mostra o que uma tabela
não consegue: **a mesma requisição, na mesma máquina, leva vinte milissegundos ou doze segundos
dependendo só de quantas outras chegam junto com ela.** Toda rodada pede `GET /shows/990`, a página
do espetáculo da aula 1 que conta as suas reservas entre quase trezentas mil linhas.

Inicie a bilheteria num terminal, a partir de `~/boxoffice`, e deixe-a rodando:

```sh
cd ~/boxoffice && python3 seed.py && python3 app.py
```

Depois digite as rodadas abaixo num segundo terminal (`multipass shell nft`), em `~/loadtest`.
Espere cada uma imprimir a sua última linha antes de começar a próxima: uma rodada que terminou com
requisições ainda dentro do servidor as deixa lá por mais alguns segundos.

## Uma carga constante

Dez requisições por segundo durante cinco segundos, o que a bilheteria deveria carregar sem
perceber:

```
ana@nft:~/loadtest$ python3 hammer.py http://127.0.0.1:8000/shows/990 10:5
second  sent  done  errors  median ms  max ms
     0    10    10       0         23      68
     1    10    10       0         20      25
     2    10    10       0         19      30
     3    10    10       0         29      78
     4    10    10       0         23      33
0 answers came back after second 4; the last at 4.9 s
```

Toda requisição voltou, nenhuma falhou, e a mediana ficou entre 19 e 29 ms, perto do que uma
requisição sozinha levou na aula 1. **`done` é igual a `sent` em todos os segundos**: o servidor
respondeu tão depressa quanto as requisições chegavam. É assim que um teste de carga aprovado se
parece em miniatura, e é a referência contra a qual as outras duas rodadas são lidas.

## Um pico

Três segundos a dez por segundo, dois segundos a duzentos, depois três a dez de novo:

```
ana@nft:~/loadtest$ python3 hammer.py http://127.0.0.1:8000/shows/990 10:3 200:2 10:3
second  sent  done  errors  median ms  max ms
     0    10    10       0         25      55
     1    10    10       0         21      25
     2    10    10       0         22      37
     3   200    53       0       1000    4160
     4   200    70      10       2496   12051
     5    10    93       0        923    3138
     6    10    83       0        439    2071
     7    10    81       0        227    1093
50 answers came back after second 7; the last at 16.5 s
```

Leia uma coluna de cada vez. No segundo 3 a bilheteria recebeu 200 requisições e respondeu 53; no
segundo 4, 70. O resto esperou, e a mediana das requisições enviadas no segundo 4 é 2496 ms, mais
de cem vezes a da rodada constante. Dez delas falharam. Agora olhe os segundos 5 a 7, **em que a
carga voltou a dez por segundo e os tempos não voltaram**: 923, 439 e 227 ms na mediana, porque o
servidor ainda estava esvaziando a fila que o pico tinha deixado. Cinquenta respostas voltaram
depois que o cronograma tinha acabado, a última aos 16,5 s de uma rodada de oito segundos.

Essa é a metade de um teste de pico que uma olhada rápida no topo deixa passar. Um cliente que
chegou no segundo 6, num momento comum, esperou cerca de meio segundo por uma página que leva vinte
milissegundos, e o requisito da aula 1 teria reprovado para ele.

## Uma escada de estresse

Dois segundos em cada uma de seis taxas, de 40 por segundo a 240:

```
ana@nft:~/loadtest$ python3 hammer.py http://127.0.0.1:8000/shows/990 40:2 80:2 120:2 160:2 200:2 240:2
second  sent  done  errors  median ms  max ms
     0    40    39       0         20      64
     1    40    41       0         21      45
     2    80    75       0         22      95
     3    80    73       0        126    5416
     4   120    76       0        466   11404
     5   120    69       3        583   15105
     6   160    83      16       1437   14110
     7   160    90      20       2545   15135
     8   200   100      29       4017   15133
     9   200   113      17       2778   13625
    10   240   139      23       3171   14105
    11   240    79      26       2331   12064
703 answers came back after second 11; the last at 25.0 s
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-stress\" aria-label=\"A rodada de estresse desenhada segundo a segundo. As requisições enviadas sobem em degraus de 40 a 240 por segundo. As respostas que voltaram as acompanham até 75 por segundo no segundo 2, depois param de acompanhar: entre 69 e 139 por segundo no resto da rodada, qualquer que fosse o envio. Os erros começam no segundo 5 com 3, e ficam entre 16 e 29 por segundo do segundo 6 em diante.\"><path d=\"M90.0 240.0 L570.0 240.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M90.0 30.0 L90.0 240.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M86.0 240.0 L90.0 240.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M86.0 198.0 L90.0 198.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"198.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">50</text><path d=\"M90.0 198.0 L570.0 198.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M86.0 156.0 L90.0 156.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"156.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100</text><path d=\"M90.0 156.0 L570.0 156.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M86.0 114.0 L90.0 114.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"114.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">150</text><path d=\"M90.0 114.0 L570.0 114.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M86.0 72.0 L90.0 72.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"72.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">200</text><path d=\"M90.0 72.0 L570.0 72.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M86.0 30.0 L90.0 30.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">250</text><path d=\"M90.0 30.0 L570.0 30.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"110.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"150.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"190.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"230.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"270.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"310.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"350.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"390.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text><text x=\"430.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8</text><text x=\"470.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">9</text><text x=\"510.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"550.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">11</text><text x=\"330.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">segundo da rodada</text><text x=\"56.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">por segundo</text><rect x=\"300.0\" y=\"237.5\" width=\"20.0\" height=\"2.5\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"340.0\" y=\"226.6\" width=\"20.0\" height=\"13.4\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"380.0\" y=\"223.2\" width=\"20.0\" height=\"16.8\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"420.0\" y=\"215.6\" width=\"20.0\" height=\"24.4\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"460.0\" y=\"225.7\" width=\"20.0\" height=\"14.3\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"500.0\" y=\"220.7\" width=\"20.0\" height=\"19.3\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"540.0\" y=\"218.2\" width=\"20.0\" height=\"21.8\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M90.0 206.4 L130.0 206.4 L130.0 206.4 L170.0 206.4 L170.0 172.8 L210.0 172.8 L210.0 172.8 L250.0 172.8 L250.0 139.2 L290.0 139.2 L290.0 139.2 L330.0 139.2 L330.0 105.6 L370.0 105.6 L370.0 105.6 L410.0 105.6 L410.0 72.0 L450.0 72.0 L450.0 72.0 L490.0 72.0 L490.0 38.4 L530.0 38.4 L530.0 38.4 L570.0 38.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M110.0 207.2 L150.0 205.6 L190.0 177.0 L230.0 178.7 L270.0 176.2 L310.0 182.0 L350.0 170.3 L390.0 164.4 L430.0 156.0 L470.0 145.1 L510.0 123.2 L550.0 173.6\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"110.0\" cy=\"207.2\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"150.0\" cy=\"205.6\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"190.0\" cy=\"177.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"230.0\" cy=\"178.7\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"270.0\" cy=\"176.2\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"310.0\" cy=\"182.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"350.0\" cy=\"170.3\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"390.0\" cy=\"164.4\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"430.0\" cy=\"156.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"470.0\" cy=\"145.1\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"510.0\" cy=\"123.2\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"550.0\" cy=\"173.6\" r=\"3\" fill=\"var(--phosphor)\"></circle><path d=\"M588.0 60.0 L610.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\"></path><text x=\"616.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">enviadas</text><path d=\"M588.0 84.0 L610.0 84.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"616.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">done: a vazão</text><rect x=\"593.0\" y=\"102.0\" width=\"12.0\" height=\"12.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"616.0\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">erros</text><text x=\"588.0\" y=\"147.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">do segundo 3 em diante</text><text x=\"588.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as respostas param de</text><text x=\"588.0\" y=\"172.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">acompanhar o envio</text></svg>", "caption": "O que a rodada de estresse enviou, o que voltou e o que falhou, segundo a segundo. A distância entre a linha tracejada e a contínua é uma fila crescendo dentro do servidor."}
```

Até 80 por segundo o servidor acompanha. **A partir do segundo 3 a coluna `done` para de
acompanhar `sent`**: ela fica entre 69 e 139 respostas por segundo enquanto a carga dobra e depois
triplica. A distância entre as duas é uma fila, e as medianas mostram a fila crescendo, de 126 ms no
segundo 3 para mais de dois segundos no segundo 7. Os erros começam no segundo 5 com 3, e daí em
diante ficam entre 16 e 29 por segundo. Setecentas e três respostas ainda estavam chegando depois
que o cronograma acabou, a última aos 25,0 s.

Então o ponto de quebra de `GET /shows/990` nesta máquina fica em algum lugar perto de 80
requisições por segundo, e o jeito é o ruim de "Cinco testes, cinco perguntas": nada recusa o
excesso depressa, toda requisição entra na fila, os tempos sobem para a casa dos segundos, e os
erros chegam por cima disso. Um número assim vem de uma rodada curta numa máquina compartilhada, e
o seu vai ser diferente. A aula 8 trata de como lê-lo com mais cuidado do que "uns 80".

## O teste de resistência que não está aqui

Um teste de resistência é este gerador com um estágio só, `10:28800`, deixado a noite toda. Ele não
é rodado nesta aula; nada na bilheteria deveria mudar a dez requisições por segundo, e descobrir
leva oito horas. O que um teste de resistência acompanha também não está nesta saída: a memória do
servidor, os seus arquivos abertos, o tamanho do seu banco de dados. Essas são medidas do servidor,
e não das respostas, e a aula 22 as coleta.
