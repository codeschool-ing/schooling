---
title: O que o placar não vê
version: 1
---

Uma ferramenta que responde rápido e com segurança é aquela cujos pontos cegos mais importam,
porque ninguém vai procurá-los. O `pg_stat_statements` tem cinco, e cada um já enganou alguém.

## Não sabe quem esperou

`total_exec_time` é tempo gasto **executando**, do ponto de vista do servidor. O tempo que um
comando passou na fila atrás de uma trava está dentro dele — o servidor estava executando, só
esperando —, mas o tempo que a aplicação passou esperando uma conexão livre, ou a rede, não está.
Um comando pode parecer barato no placar enquanto os usuários da tela por trás dele esperam
segundos, porque a fila estava na frente do servidor, e não dentro dele. A aula 16 trata
exatamente dessa fila.

## Não guarda os valores

As constantes saem de propósito, e com elas vai a resposta para "lento para quem?". No `market`, o
vendedor 1 tem um quarto de todos os pedidos e os outros 999 dividem o resto: uma consulta de
painel para o vendedor 1 lê centenas de vezes mais linhas que uma para o vendedor 42, e o placar as
guarda como um comando só, com uma média só. As colunas `stddev_exec_time` e `max_exec_time` são a
pista de que uma média está escondendo duas populações; o log, que guarda os valores, é como você
descobre quais. Por isso o `seller-dashboard.sql` da carga sorteia o vendedor de 2 a 1000 e deixa
o vendedor 1 de fora: a aula 7 trata do que esse vendedor faz com as estimativas do planejador.

## Esquece

A view guarda um número fixo de comandos distintos, definido por `pg_stat_statements.max`:

```
market=# SHOW pg_stat_statements.max;
 pg_stat_statements.max 
------------------------
 5000
(1 row)

Time: 0.770 ms

market=# SELECT dealloc, stats_reset FROM pg_stat_statements_info;
 dealloc |          stats_reset          
---------+-------------------------------
       0 | 2026-10-10 04:25:37.909729-03
(1 row)

Time: 1.187 ms
```

**5000**, e quando um comando novo chega com a tabela cheia, as entradas menos usadas são jogadas
fora, e `dealloc` em `pg_stat_statements_info` conta quantas vezes isso aconteceu. Zero aqui. Numa
aplicação que monta SQL colando valores em strings, em vez de passar parâmetros, cada valor
diferente pode ser um comando diferente, a tabela gira, e a consulta cara e rara é justamente a que
é despejada. Um `dealloc` que não para de subir é um sintoma que vale perseguir por si só.

`stats_reset` é a outra metade do mesmo cuidado: o momento em que o placar começou. Dois números
lidos dele só são comparáveis se contam a partir do mesmo momento.

## Não vê a máquina

O placar diz que um comando leu 1181 páginas do sistema operacional; não diz se vieram do cache
do sistema operacional na memória ou do disco, o que a aula 1 seção 06 mostrou poder ser um fator
de três ou mais. Também não vê um backup rodando ao mesmo tempo, ou outro programa na mesma máquina
tomando os processadores. Para o terceiro suspeito você olha a própria máquina, como fazem as aulas
16 e 23.

## Conta o que chegou ao servidor

Um comando que nunca rodou não está nele. Uma aplicação que desiste depois de dois segundos e
mostra um erro tem uma reclamação e talvez nenhuma linha, se o servidor cancelou o comando antes de
terminar. E uma aplicação que roda cem consultas minúsculas para desenhar uma página — o formato
N+1 que a aula 11 do `sql-databases` descreveu — aparece como um comando barato com um `calls`
enorme, que ordenar pelo total só põe no alto se o total for grande. **Leia `calls` além do
tempo**: um comando barato chamado cem vezes por página é um problema de desenho, e nenhum índice
o faz sumir.
