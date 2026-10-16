---
title: Transações leves, e quanto custam
version: 1
---

Leituras e escritas em `QUORUM` fazem uma leitura ver a última escrita. Elas não impedem **duas
escritas correndo uma contra a outra**, e o monitor da loja mostra por quê. Dois clientes leem
`units = 1` em `QUORUM`, cada um conclui que resta um, cada um grava `units = 0` em `QUORUM`. Todos os
comandos deram certo, os dois clientes ouviram sim, e um monitor foi vendido duas vezes. A
verificação e a escrita eram duas operações, e nada segurou a linha entre elas.

A resposta do Cassandra é a **transação leve**, LWT: uma escrita com um `IF` com que as réplicas
concordam antes de aplicá-la, usando o protocolo de consenso Paxos. Ela é leve comparada a uma
transação relacional, porque cobre uma partição e um comando.

## Comparar e gravar

```
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CONSISTENCY QUORUM
Consistency level set to QUORUM.
cqlsh> UPDATE shop.stock SET units = 1 WHERE sku = 'MN-330';
cqlsh> UPDATE shop.stock SET units = 0 WHERE sku = 'MN-330' IF units = 1;

 [applied]
-----------
      True

cqlsh> UPDATE shop.stock SET units = 0 WHERE sku = 'MN-330' IF units = 1;

 [applied] | units
-----------+-------
     False |     0

cqlsh> INSERT INTO shop.stock (sku, name, units) VALUES ('KB-101', 'Mechanical keyboard', 5) IF NOT EXISTS;

 [applied]
-----------
      True

cqlsh> INSERT INTO shop.stock (sku, name, units) VALUES ('KB-101', 'Mechanical keyboard', 9) IF NOT EXISTS;

 [applied] | sku    | name                | units
-----------+--------+---------------------+-------
     False | KB-101 | Mechanical keyboard |     5

cqlsh> SERIAL CONSISTENCY
Current serial consistency level is SERIAL.
cqlsh> exit
```

Reponha o monitor e venda-o duas vezes com o mesmo `UPDATE` condicional. **O primeiro devolve
`[applied] True`. O segundo devolve `False` e o valor que encontrou**, `units` 0, então a aplicação
fica sabendo numa só conversa que perdeu a corrida e por quê. O mesmo formato protege um insert: `IF
NOT EXISTS` criou a linha do teclado uma vez, e a segunda tentativa foi recusada e mostrou a linha que
já estava lá, com suas 5 unidades, intocada.

Essa é a ferramenta para tudo o que precisa acontecer uma vez só: reservar um nome de usuário, levar
a última unidade, passar um pedido de `pending` para `paid` exatamente uma vez.

## Os dois níveis de consistência de uma escrita condicional

Uma transação leve tem dois níveis, e o `cqlsh` mostra o segundo com `SERIAL CONSISTENCY`:

- **O nível serial, `SERIAL` por padrão**, vale para as rodadas do Paxos que decidem se a condição é
  verdadeira. Ele sempre precisa de uma maioria de réplicas, e é por isso que o `UPDATE` condicional
  com dois nós caídos foi recusado com `Cannot achieve consistency level SERIAL` enquanto a sessão
  estava em `ONE`. `LOCAL_SERIAL` é o mesmo dentro de um data center.
- **O nível comum**, o que `CONSISTENCY` define, vale para o commit que grava o resultado depois de
  decidido.

Então uma LWT fica indisponível sempre que a maioria fica, e não há nível que a faça responder com
menos.

## Quanto custa

Rastreando um `UPDATE` comum e um condicional na mesma linha, e contando as mensagens que o `c1`
mandou aos outros dois nós:

```
ana@vm:~$ docker exec c1 cqlsh -e "CONSISTENCY QUORUM; TRACING ON; UPDATE shop.stock SET units = 4 WHERE sku = 'KB-101';" | grep -oE 'Sending [A-Z0-9_]+ message to /[0-9.:]+' | sort | uniq -c
      1 Sending MUTATION_REQ message to /172.18.0.3:7000
      1 Sending MUTATION_REQ message to /172.18.0.4:7000
ana@vm:~$ docker exec c1 cqlsh -e "CONSISTENCY QUORUM; TRACING ON; UPDATE shop.stock SET units = 3 WHERE sku = 'KB-101' IF units = 4;" | grep -oE 'Sending [A-Z0-9_]+ message to /[0-9.:]+' | sort | uniq -c
      1 Sending PAXOS_COMMIT_REQ message to /172.18.0.3:7000
      1 Sending PAXOS_COMMIT_REQ message to /172.18.0.4:7000
      1 Sending PAXOS_PREPARE_REQ message to /172.18.0.3:7000
      1 Sending PAXOS_PREPARE_REQ message to /172.18.0.4:7000
      1 Sending PAXOS_PROPOSE_REQ message to /172.18.0.3:7000
      1 Sending PAXOS_PROPOSE_REQ message to /172.18.0.4:7000
      1 Sending READ_REQ message to /172.18.0.3:7000
      1 Sending READ_REQ message to /172.18.0.4:7000
rc=0
```

A escrita simples é **uma mensagem para cada outra réplica**, uma mutação. A condicional são **quatro
rodadas**: `PREPARE` para reservar o direito de propor, `READ` para buscar o valor atual e conferir a
condição, `PROPOSE` para concordar com o valor novo, e `COMMIT` para aplicá-lo. Cada rodada espera
uma maioria antes de a próxima começar, então a escrita condicional custa cerca de quatro idas e
voltas onde a simples custa uma. Num data center isso são alguns milissegundos; atravessando um
oceano são quatro vezes a distância da aula 1.

Mais dois custos vêm do mesmo mecanismo. Escritas condicionais na **mesma partição** fazem fila uma
atrás da outra, e sob disputa algumas falham por tempo esgotado e precisam ser repetidas, então uma
LWT numa linha disputada é um gargalo. E misturar escritas condicionais e simples nas mesmas células
anula o propósito: um `UPDATE` simples não participa do Paxos, e pode sobrescrever um valor que uma
LWT acabou de acordar. A regra é usar LWT para as poucas operações que não podem correr uma contra a
outra, manter condicional toda escrita nessas células, e deixar o resto para os níveis mais baratos
das seções anteriores.
