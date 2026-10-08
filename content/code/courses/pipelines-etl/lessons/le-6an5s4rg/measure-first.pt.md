---
title: Medir antes de mudar qualquer coisa
version: 1
---

Toda carga deste curso levou segundos, porque a loja é pequena: umas trinta mil linhas de vendas em
três meses. Warehouses de verdade não são, e o mesmo código que é instantâneo num notebook pode levar
a noite inteira numa tabela cem vezes maior — ou custar, num warehouse alugado por consulta, mais que
o relatório que ele alimenta vale.

A primeira regra para deixar um pipeline mais rápido ou mais barato é a mesma primeira regra para
consertá-lo: **descobrir para onde vai o tempo antes de mudar qualquer coisa.** Palpites sobre
desempenho erram com frequência suficiente para que uma mudança feita por palpite tenha tanta chance
de custar tempo quanto de economizar. O PostgreSQL dá dois instrumentos, e esta lição usa os dois:

- **`\timing on`** no `psql`, que imprime quanto cada comando levou, do ponto de vista do cliente;
- **`EXPLAIN ANALYZE`**, que roda um comando e relata como o banco o executou — que linhas leu, por
  qual caminho, e quantas jogou fora. Com `BUFFERS` ele também conta as páginas da tabela que tocou,
  que é o número que um warehouse cobrado pelos dados que varre poria na fatura.

A lição mede quatro decisões que aparecem em todo pipeline: como as linhas são escritas, como um dia é
encontrado, quanto é refeito a cada noite e quanto é lido. Os tempos são desta máquina e serão outros
em outra. O que não muda de uma execução para outra é o tamanho da distância entre os métodos, e é
disso que cada seção trata.
