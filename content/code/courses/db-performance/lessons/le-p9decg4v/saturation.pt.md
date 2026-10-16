---
title: Mais clientes, o mesmo trabalho
version: 1
---

A crença: **mais conexões, mais vazão.** Se oito clientes tiram mil transações por segundo do
servidor, noventa deveriam tirar mais. Não tiram, e o motivo é uma conta da qual o servidor não
escapa. Ele tem um número fixo de processadores, quatro na máquina destas transcrições, e um disco
fixo. Quando eles estão ocupados, um cliente novo não acrescenta trabalho feito; acrescenta um lugar
para esperar.

## Medindo

Este script roda a mistura da aula 2 em sete quantidades de clientes, vinte segundos cada, e imprime
os dois números que importam de cada execução, a vazão e a latência média:

```sh
cat > ~/workload/curve.sh <<'SH'
#!/bin/sh
# Lesson 2's mix at a growing number of clients, twenty seconds each.
cd ~/workload
for c in 1 4 8 16 32 64 90; do
  pgbench -n -c "$c" -j 4 -T 20 \
    -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 \
    -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 \
    market 2>&1 |
  awk -v c="$c" '/^latency average/ { ms = $4 } /^tps/ { tps = $3 }
                 END { printf "%3d clients  %7.0f tps  %7.1f ms\n", c, tps, ms }'
done
SH
chmod +x ~/workload/curve.sh
```

Leva dois minutos e meio, e a carga grava pedidos, então o `~/reset-market.sh` no fim da aula põe
`market` de volta. No computador em que este curso foi gravado:

```
ana@vm:~$ ~/workload/curve.sh
  1 clients      489 tps      2.0 ms
  4 clients     1389 tps      2.9 ms
  8 clients     1334 tps      6.0 ms
 16 clients     1413 tps     11.3 ms
 32 clients     1436 tps     22.3 ms
 64 clients     1396 tps     45.9 ms
 90 clients     1481 tps     60.8 ms
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dois gráficos sobre as mesmas sete quantidades de clientes, 1, 4, 8, 16, 32, 64 e 90. À esquerda, vazão: 489 transações por segundo com um cliente, 1389 com quatro, e depois estável entre 1334 e 1481 até noventa. À direita, latência média: 2,0 milissegundos com um cliente, subindo sem parar até 60,8 com noventa.\"><text x=\"30\" y=\"24\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">vazão, transações por segundo</text><path d=\"M30 230 L330 230\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M30 60 L30 230\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"50.0\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1</text><text x=\"45.0\" y=\"172.1\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--phosphor)\">489</text><text x=\"93.33333333333334\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">4</text><text x=\"88.33333333333334\" y=\"82.1\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--phosphor)\">1389</text><text x=\"136.66666666666669\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">8</text><text x=\"131.66666666666669\" y=\"87.6\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--phosphor)\">1334</text><text x=\"180.0\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">16</text><text x=\"175.0\" y=\"79.69999999999999\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--phosphor)\">1413</text><text x=\"223.33333333333334\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">32</text><text x=\"218.33333333333334\" y=\"77.4\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--phosphor)\">1436</text><text x=\"266.66666666666663\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">64</text><text x=\"261.66666666666663\" y=\"81.4\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--phosphor)\">1396</text><text x=\"310.0\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">90</text><text x=\"305.0\" y=\"72.9\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--phosphor)\">1481</text><path d=\"M50.0 181.1 L93.3 91.1 L136.7 96.6 L180.0 88.7 L223.3 86.4 L266.7 90.4 L310.0 81.9\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><circle cx=\"50.0\" cy=\"181.1\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"93.33333333333334\" cy=\"91.1\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"136.66666666666669\" cy=\"96.6\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"180.0\" cy=\"88.69999999999999\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"223.33333333333334\" cy=\"86.4\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"266.66666666666663\" cy=\"90.4\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"310.0\" cy=\"81.9\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"180.0\" y=\"262\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">clientes</text><text x=\"390\" y=\"24\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">latência média, milissegundos</text><path d=\"M390 230 L690 230\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M390 60 L390 230\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"410.0\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1</text><text x=\"405.0\" y=\"216.14285714285714\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--amber)\">2.0</text><text x=\"453.3333333333333\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">4</text><text x=\"448.3333333333333\" y=\"213.95714285714286\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--amber)\">2.9</text><text x=\"496.6666666666667\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">8</text><text x=\"491.6666666666667\" y=\"206.42857142857142\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--amber)\">6.0</text><text x=\"540.0\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">16</text><text x=\"535.0\" y=\"193.55714285714285\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--amber)\">11.3</text><text x=\"583.3333333333334\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">32</text><text x=\"578.3333333333334\" y=\"166.84285714285716\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--amber)\">22.3</text><text x=\"626.6666666666666\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">64</text><text x=\"621.6666666666666\" y=\"109.52857142857144\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--amber)\">45.9</text><text x=\"670.0\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">90</text><text x=\"665.0\" y=\"73.34285714285716\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"end\" fill=\"var(--amber)\">60.8</text><path d=\"M410.0 225.1 L453.3 223.0 L496.7 215.4 L540.0 202.6 L583.3 175.8 L626.7 118.5 L670.0 82.3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><circle cx=\"410.0\" cy=\"225.14285714285714\" r=\"3\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"453.3333333333333\" cy=\"222.95714285714286\" r=\"3\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"496.6666666666667\" cy=\"215.42857142857142\" r=\"3\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"540.0\" cy=\"202.55714285714285\" r=\"3\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"583.3333333333334\" cy=\"175.84285714285716\" r=\"3\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"626.6666666666666\" cy=\"118.52857142857144\" r=\"3\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"670.0\" cy=\"82.34285714285716\" r=\"3\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"540.0\" y=\"262\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">clientes</text></svg>", "caption": "A mistura da aula 2 em sete quantidades de clientes. A vazão para de crescer por volta de quatro clientes, o número de processadores; a latência continua crescendo."}
```

## Lendo a curva

**Vazão.** Um cliente consegue 489 transações por segundo: uma requisição por vez, cada uma esperando
a anterior. Quatro conseguem 1389, quase o triplo, porque agora quatro processadores trabalham ao
mesmo tempo. Dali em diante a linha é plana: oito, dezesseis, trinta e dois, sessenta e quatro e
noventa clientes ficam todos entre 1334 e 1481. O servidor chegou ao que quatro processadores
conseguem fazer por volta de quatro clientes, e cada cliente acrescentado depois disso tomou uma parte
do mesmo trabalho.

**Latência.** O tempo médio por transação vai no sentido contrário: 2,0 milissegundos com um cliente,
60,8 com noventa. A vazão ficou parada, então os clientes tinham de estar esperando: sobretudo na fila
do sistema operacional por um processador, já que quatro processos por vez é tudo o que quatro
processadores rodam. É a lei de Little, da teoria das filas: o número de requisições em andamento é
igual à vazão vezes a latência. Com noventa clientes e 1481 transações por segundo, cada uma leva
cerca de noventa divididos por 1481 de segundo, os 60,8 milissegundos da tabela.

A dobra é o número útil. Abaixo dela, mais clientes significa mais trabalho feito; acima, mais
clientes significa o mesmo trabalho, mais lento para todo mundo. Nesta máquina ela fica em **cerca de
quatro**, o número de processadores, porque a mistura da aula 2 é quase toda trabalho de processador e
os dados cabem na memória. Uma mistura que espera o disco ou a rede dobra mais tarde, porque um
processo esperando deixa o processador livre; uma mistura que disputa as mesmas linhas dobra mais
cedo. É por isso que o número vem de medir a sua própria carga, e a seção 06 faz isso para o pool.

## Por que subir o `max_connections` não ajuda

Subir o limite para 500 muda onde a linha termina, não o formato dela. Cada conexão a mais é um
processo que o sistema operacional precisa escalonar, com memória própria, disputando os mesmos quatro
processadores. Passada a dobra, mais delas não acrescentam vazão, como a tabela mostra, e não são de
graça: os processadores gastam parte do tempo trocando de processo, e as estruturas compartilhadas do
servidor — as tabelas de travas, a lista de transações em andamento que todo snapshot lê — são
percorridas mais vezes. O horizonte da aula 15 é calculado a partir dessa lista também.

O que a aplicação precisa de verdade não são noventa conexões rodando ao mesmo tempo. Ela precisa de
noventa **clientes capazes de mandar trabalho**, e de quatro ou oito conexões fazendo esse trabalho,
com um lugar para o resto esperar que custe menos que um processo do servidor. Esse lugar é um pool de
conexões.
