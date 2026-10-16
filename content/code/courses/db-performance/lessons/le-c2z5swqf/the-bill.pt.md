---
title: A conta, que chega todo mês
version: 1
---

A seção anterior contou quanto o sharding custa a uma consulta. Esses custos aparecem, estão num
plano, e uma equipe cuidadosa contorna a maioria deles no projeto. A conta maior não está em plano
nenhum. É o trabalho que era uma operação num servidor e agora é uma operação por shard, para
sempre, com um jeito novo de falhar a cada passo. A crença a derrubar é a de que sharding é um
projeto com fim. **É um custo contínuo**, e os itens abaixo são o porquê.

## Rebalancear

Dois shards enchem. Você acrescenta mais dois, e com roteamento por hash isso quer dizer que o
módulo vai de 2 para 4. O particionamento por hash do PostgreSQL foi pensado para que cada partição
antiga se divida certinho em duas novas, que é o melhor caso que existe. Pergunte quantos pedidos
cairiam nos dois shards novos:

```
market=# SELECT count(*) FILTER (WHERE satisfies_hash_partition('sharded_orders'::regclass, 4, 2, customer_id) OR satisfies_hash_partition('sharded_orders'::regclass, 4, 3, customer_id)) AS moving, count(*) AS total FROM orders;
 moving |  total  
--------+---------
 999306 | 2000000
(1 row)

Time: 450.232 ms
```

**999306 de 2000000.** Metade da tabela se muda, enquanto a aplicação grava nela. Cada uma dessas
linhas precisa ser copiada para o shard novo, a cópia mantida em dia com as escritas que chegam
durante a mudança, o roteamento trocado num instante só, e a cópia antiga apagada. Feito no lugar com
SQL puro, são dias de trabalho cuidadoso e uma janela em que um bug perde pedidos. Com roteamento por
resto de divisão num número que não dobra, indo de 2 shards para 3, a maioria das linhas troca de
shard, e por isso ninguém roteia assim.

A saída de costume é **dividir em muito mais pedaços do que você tem servidores** desde o começo:
digamos 64 shards lógicos em 2 máquinas, 32 em cada. Acrescentar máquinas passa a mover shards
lógicos inteiros, intactos por dentro, em vez de recalcular o hash das linhas. É por isso que os
produtos feitos para isso criam dezenas de shards num cluster de dois.

## Cada mudança de esquema, N vezes

Acrescentar uma coluna era um comando. Agora é um por shard, mais um no coordenador, e as partes não
sabem umas das outras:

```
ana@vm:~$ for s in shard1 shard2; do psql $s -c 'ALTER TABLE orders ADD COLUMN coupon text'; done
ALTER TABLE
Time: 7.081 ms
ALTER TABLE
Time: 3.156 ms
market=# SELECT coupon FROM sharded_orders WHERE customer_id = 42;
ERROR:  column "coupon" does not exist
LINE 1: SELECT coupon FROM sharded_orders WHERE customer_id = 42;
               ^
Time: 15.852 ms

market=# ALTER TABLE sharded_orders ADD COLUMN coupon text;
ALTER TABLE
Time: 4.058 ms

market=# SELECT count(coupon) FROM sharded_orders WHERE customer_id = 42;
 count 
-------
     0
(1 row)

Time: 22.595 ms
```

A coluna existe nos dois shards, e o coordenador ainda responde **`column "coupon" does not
exist`**, porque as tabelas estrangeiras dele descrevem os shards como eram. Só depois do terceiro
comando a consulta funciona. Com dois shards isso é um laço e um momento de confusão. Com quarenta,
é uma implantação que pode parar no meio, o shard 23 recusando por causa de uma trava (lock)
enquanto 22 shards já têm a coluna e a aplicação está prestes a começar a gravar nela. Toda
ferramenta de migração que você usa precisa aprender que o banco agora é plural, e toda migração
precisa de um plano para o estado em que só alguns shards a rodaram.

## Backups que não são um momento

O backup de um servidor é uma fotografia consistente de um momento: restaure e todo pedido tem as
suas linhas, todo pagamento o seu pedido. Dois shards copiados separadamente são **duas fotografias
tiradas em dois momentos**, e entre elas algumas transações foram confirmadas num shard e ainda não
no outro. A transação meio confirmada da seção 04 é o mesmo problema visto do outro lado. Restaurar
um banco dividido em shards para um ponto no tempo significa restaurar todos os shards para o mesmo
instante, o que exige o WAL de todos arquivado e um alvo de recuperação que todos alcancem. As aulas
3 a 6 de `db-reliability` tratam de backup e recuperação até um ponto no tempo num servidor só;
cada palavra delas agora vale N vezes, mais a coordenação.

## Ids

Num servidor só, o `GENERATED ALWAYS AS IDENTITY` entrega ids de uma sequência e nenhum par de
pedidos divide um. A seção 04 mostrou o que acontece quando essa garantia some: dois pedidos com o
id 1. A sequência de cada shard produziria os mesmos números que a de todos os outros, então os ids
precisam ser únicos por construção, não por restrição. As respostas de costume:

| esquema | como | o que custa |
|---|---|---|
| um UUID | `gen_random_uuid()`, 16 bytes aleatórios | índices maiores, linhas inseridas por todo o índice em vez de no fim |
| sequências intercaladas | o shard 1 conta 1, 3, 5…; o shard 2 conta 2, 4, 6… com `START` e `INCREMENT BY` | o número de shards fica gravado nos ids |
| o shard dentro do id | os bits altos dizem qual shard, os baixos contam | um id que codifica um lugar que o rebalanceamento pode mudar |
| um alocador central | um serviço, ou o coordenador, entrega blocos de ids | um ponto único de que toda escrita depende |

Nenhum é de graça, e a escolha precisa ser feita antes da primeira linha dividida ser gravada,
porque ids são o que outros sistemas guardam.

## E o resto da lista

**Monitoração** são N servidores cujos comandos mais caros são diferentes: o shard quente se acha
comparando shards, não lendo um. **Relatórios** que leem tudo, o ano da contabilidade e a tela de
operações, viram as consultas lentas espalhadas da seção 04, e quase sempre vão para um data
warehouse separado, alimentado por todos os shards. Chamados de **suporte** que dizem "meu pedido
sumiu" começam descobrindo em qual shard ele deveria estar.

## Produtos que carregam parte disso

Você não precisa construir o coordenador sozinho, e não deveria. O **Citus**, uma extensão de
código aberto para o PostgreSQL, transforma um servidor num coordenador sobre vários workers. Ele
distribui uma tabela por uma coluna que você escolhe e colocaliza tabelas distribuídas pela mesma
chave. Copia tabelas de referência para todos os workers e empurra joins e agregações para os
shards. Confirma entre shards com commit em duas fases, e move shards entre máquinas com a aplicação
rodando.
Ele carrega boa parte da conta acima no próprio código. Não escolhe a chave de shard, e não deixa
barata uma consulta que ignora a chave. Outros bancos já nascem divididos em shards, com a mesma
troca sob outros nomes. As perguntas desta aula são as que se fazem a qualquer um deles.

## Ponha a máquina de volta

Feche todas as sessões do `psql`, para que as conexões do coordenador com os shards terminem. Depois
apague os dois bancos de shard, tire a senha do seu papel e rode o script que a aula 2 te deu:

```
ana@vm:~$ dropdb shard1
ana@vm:~$ dropdb shard2
ana@vm:~$ psql market -c 'ALTER ROLE ana PASSWORD NULL'
ALTER ROLE
Time: 1.321 ms
```

```sh
~/reset-market.sh
```

O `~/reset-market.sh` apaga o `market` com tudo o que o coordenador acrescentou a ele, a extensão,
os dois servidores e a `sharded_orders`, e o cria de novo a partir do `market_base`.
