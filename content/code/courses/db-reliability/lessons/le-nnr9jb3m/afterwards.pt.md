---
title: Depois do ensaio
version: 1
---

Os resultados vão para o mesmo formulário do relatório pós-incidente da lição 22, com a expectativa ao
lado de cada número, e as diferenças viram ações com responsáveis e datas. Um ensaio que não encontrou
nada também é registrado: ele é a evidência de que, naquela data, o failover funcionou em tantos
segundos, e o próximo ensaio é comparado com ele.

Depois ele é repetido, com calendário, porque tudo o que ele testou continua mudando: o Patroni e o
PostgreSQL são atualizados, a aplicação ganha um driver novo, alguém edita o `haproxy.cfg`. A cada
trimestre é comum. E a cada vez um pouco mais se torna real:

1. um **switchover** (lição 16), que não perde nada;
2. um **líder morto**, como nesta lição, num ambiente de teste;
3. o mesmo, com a aplicação de verdade e o tráfego de verdade, num ambiente de teste;
4. um líder morto **em produção**, num horário combinado, com as pessoas da lição 22 de prontidão;
5. as falhas mais difíceis de arranjar: o etcd perdido (lição 16), um líder congelado (lição 17), uma
   região inteira (lição 20).

**Nenhum dos passos seguintes é seguro antes que os anteriores tenham passado**, e um time que já fez o
quarto é um time que viu o próprio failover funcionar com clientes em cima. É essa a afirmação que
este curso vem construindo desde a lição 1, feita com evidência.
