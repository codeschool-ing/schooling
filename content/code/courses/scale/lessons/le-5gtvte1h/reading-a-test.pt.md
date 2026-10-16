---
title: Lendo um teste
version: 1
---

Um teste de carga produz alguns números do lado do gerador, e o sistema produz milhares do lado dele.
O resultado do teste diz **se** o sistema bateu as metas; só o sistema diz **por quê**, e um teste que
não é lido junto com a telemetria do próprio sistema é meio teste.

Durante toda execução, olhe pelo menos:

- **As métricas RED da aula 7**, do Prometheus: a taxa que a bilheteria *diz* que atendeu, os erros
  por status e o histograma de latência. Quando discordam do gerador, um dos dois está mentindo, e
  descobrir qual costuma ser a coisa mais útil que o teste faz. Na seção 06, o gerador contou 1547
  falhas que a bilheteria nunca viu: estavam no nginx.
- **A saturação, o S do USE**: a CPU de cada cópia, o medidor de pedidos em andamento contra as
  vagas, as conexões com o banco, o medidor do disjuntor. O joelho da seção 06 é o momento em que um
  desses chega ao limite, e saber qual é saber o que comprar.
- **Os rastros da aula 8**: uma venda lenta da execução, aberta no Jaeger, diz para onde foi o tempo
  dela, o que nenhum percentil diz.
- **O próprio gerador**: a CPU dele, e o *never sent* do k6. Um gerador na mesma máquina que o
  sistema, como neste laboratório, tira CPU dele. Num teste de verdade o gerador roda em outro lugar,
  e testes grandes rodam vários geradores ao mesmo tempo.

## As armadilhas

- **Médias.** Todo número deste curso foi um percentil, porque uma média esconde a cauda lenta que os
  compradores sentem. A mediana de 2,4 ms da seção 06 é o lembrete de que até um percentil precisa da
  contagem de erros ao lado.
- **Curto demais.** Uma execução de quinze segundos acha o joelho; não acha um conjunto de conexões
  que vaza uma conexão por minuto. Esse é o teste de resistência.
- **Dados irreais.** Cinquenta shows e compradores aleatórios fazem uma carga uniforme. Uma abertura
  de verdade é um show, uma linha quente, o limite da aula 1, e um teste que espalha as vendas por
  cinquenta shows está testando outro sistema.
- **Cache quente ou frio.** A primeira execução depois de um reinício mede o aquecimento, como o
  percentil 99 da seção 04 mediu. Rode uma vez para aquecer, ou relate o começo à parte.
