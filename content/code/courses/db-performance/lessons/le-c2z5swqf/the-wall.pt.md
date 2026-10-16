---
title: O muro, e tudo o que tentar antes dele
version: 1
---

**Sharding** é dividir as linhas de uma tabela entre vários servidores de banco, cada um com uma
parte e nenhum com o todo. É a última ferramenta deste curso, e vem por último de propósito: todas
as anteriores fazem um servidor render mais, e esta desiste de ter um servidor só. É uma troca que
se faz uma vez e se paga todo dia depois, então a primeira coisa a saber sobre ela é quando você é
de fato obrigado a fazê-la.

A crença a derrubar primeiro é a de que sharding é o que um banco grande precisa. Não é. Um banco
precisa de sharding quando **uma máquina não dá mais conta do trabalho**, por melhor que seja usada,
e esse ponto fica bem mais longe do que a maioria imagina na primeira vez que diz a palavra. Muitas
empresas com bilhões de linhas rodam num único primário com algumas réplicas atrás.

## O que "o muro" quer dizer

Um servidor se esgota de três jeitos, e só um deles é motivo para fazer sharding:

| o que acaba | como aparece | o que costuma resolver |
|---|---|---|
| **leituras** | processadores ocupados com `SELECT`s, o cache errando | índices, um cache, réplicas de leitura |
| **armazenamento** | o disco enchendo, o conjunto de trabalho não cabendo mais na memória | arquivamento, particionamento, um disco maior |
| **escritas** | todo commit espera pelo único disco que guarda o WAL; os processadores do primário ocupados com `INSERT` e `UPDATE` | uma máquina maior, depois sharding |

A assimetria na última coluna é o argumento inteiro. Leituras podem ser espalhadas por cópias: a
aula 20 põe um segundo servidor ao lado do primeiro e manda os `SELECT`s para ele. Escritas não,
porque toda cópia precisa receber toda escrita. Quando **só as escritas** passam do que a maior
máquina que você consegue comprar absorve, dividir os dados para que cada servidor receba só uma
parte delas é o movimento que sobra. Esse é o muro.

## O que esgotar antes, na ordem do custo

Cada linha aqui é algo que aulas anteriores ensinaram ou que as próximas ensinam, e cada uma custa
menos que sharding, porque nenhuma muda o que a aplicação precisa saber.

- **Consertar as consultas.** O placar da aula 2 pôs três comandos em 98% do tempo do servidor.
  Um servidor "sem capacidade" muitas vezes é um servidor rodando três planos ruins. As aulas 3 a 11
  são este passo.
- **Uma máquina maior.** Sem glamour e quase sempre a linha mais barata da lista. Dobrar a memória
  para o conjunto de trabalho caber, ou passar para discos mais rápidos, custa uma migração e uma
  fatura; sharding custa uma reescrita e uma equipe de operação.
- **Pooling.** Um servidor afogado em conexões não está sem capacidade; a aula 16 é esse conserto.
- **Particionamento** de uma tabela num servidor só, aulas 17 e 18. Encolhe índices, barateia
  descartar dados antigos e deixa uma consulta pular a maior parte da tabela, tudo sem segunda
  máquina.
- **Réplicas de leitura**, aula 20, para uma carga quase toda de leitura, e um **cache**, aula 21,
  para leituras que se repetem.
- **Arquivamento.** Dado que ninguém lê ainda custa memória nos índices, tempo em todo vacuum e
  horas em todo restore.

Esse último merece um olhar concreto, porque o `market` tem o formato de sempre:

```
market=# SELECT extract(year FROM placed_at) AS year, count(*) FROM orders GROUP BY 1 ORDER BY 1;
 year |  count  
------+---------
 2023 |  221610
 2024 |  668658
 2025 | 1109732
(3 rows)

Time: 531.364 ms

market=# SELECT pg_size_pretty(pg_total_relation_size('orders')) AS orders, pg_size_pretty(pg_database_size('market')) AS market;
 orders | market  
--------+---------
 247 MB | 1348 MB
(1 row)

Time: 1.866 ms
```

**221610 pedidos de 2023, 668658 de 2024 e 1109732 de 2025.** As telas da aplicação leem as últimas
semanas: os pedidos recentes de um cliente, o dezembro de um vendedor, a contagem de pendentes. Os
pedidos de 2023 ficam para a contabilidade e são lidos poucas vezes por ano. Movê-los para um
armazenamento mais barato, ou para uma partição em disco mais lento que a aula 17 deixa fácil de
desanexar, deixa a parte quente de `orders` um nono menor hoje, e a fatia cresce a cada ano que a
loja funciona. O banco inteiro tem **1348 MB**, e `orders` é **247 MB** disso: em qualquer servidor
vendido hoje ele cabe na memória várias vezes. O `market` está longe do muro, e quase nenhum banco
que você encontrar estará perto.

## Os sinais de que você chegou lá

Quando a lista acima está feita e o servidor continua se afogando, os sinais são estes. Os
processadores do primário estão ocupados e os comandos mais caros no `pg_stat_statements` são
escritas. O WAL está sendo gravado tão rápido quanto o disco aguenta. A maior máquina que o seu
fornecedor vende é a que você já tem, ou a próxima custa mais que os engenheiros que fariam o
sharding. E o crescimento não é um pico: as escritas por segundo sobem todo mês.

Há um segundo motivo, menos comum, que **não tem nada a ver com velocidade**: dados que precisam
morar em lugares diferentes. Uma lei dizendo que os dados de clientes brasileiros ficam no Brasil e
os de europeus na Europa é uma chave de shard escolhida por um regulador. A mecânica desta aula é a
mesma; o motivo para aceitar a conta é outro.

Nenhum dos dois vale para o `market`, e mesmo assim você vai dividi-lo na seção 04, numa máquina só,
porque o único jeito de entender a conta é ver cada item dela chegar. Antes disso, a decisão que o
sharding não deixa desfazer: por qual coluna dividir.
