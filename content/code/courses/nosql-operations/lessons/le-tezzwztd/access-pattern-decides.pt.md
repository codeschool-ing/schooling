---
title: O padrão de acesso decide, não a marca
version: 1
---

A pergunta costuma chegar como "devemos usar MongoDB ou Cassandra?", que é uma pergunta sobre
marcas, e é respondida com benchmarks e opiniões. **A pergunta que tem resposta é sobre as
operações**: o que a aplicação lê e escreve, com que frequência, em que forma, e quanto custa se
duas cópias discordarem. A aula 1 perguntou a última parte por operação, a aula 3 listou as consultas
antes das tabelas, a aula 4 decidiu o que gravar duas vezes e a aula 5 disse o que uma aplicação
precisa tolerar quando as cópias atrasam. Esta seção transforma tudo isso numa tabela só.

## Do padrão à família

Leia da esquerda. Encontre a linha que descreve uma operação sua, não o sistema inteiro:

| o padrão de acesso | do que precisa | a família que serve | onde este curso mostrou |
|---|---|---|---|
| ler e escrever uma entidade pela chave, e nada mais | uma busca rápida, sem joins | chave-valor | strings e hashes do Redis, aula 12 |
| a unidade lida e escrita é um agregado inteiro de forma variável: um pedido com seus itens, um produto com seus atributos | o agregado num só lugar, um esquema que se dobra | documento | MongoDB, aulas 6 a 8 |
| anexar um volume muito alto de escritas e lê-las de volta por uma chave conhecida e um intervalo | escritas espalhadas por muitas máquinas, consultas conhecidas de antemão | coluna larga | Cassandra, aula 16 |
| uma tabela por consulta, escrita duas vezes de propósito | desnormalização que o banco não vai manter consistente por você | coluna larga ou documento | aulas 3 e 4 |
| um contador, um ranking, um limite de taxa, uma sessão, uma fila, lidos e escritos na velocidade da memória | estruturas de dados em memória, com expiração | chave-valor com estruturas | Redis, aulas 12 e 14 |
| relações seguidas por muitos saltos: quem conhece quem, que peça está em que montagem | travessia | grafo | citado na aula 2 |
| medições ao longo do tempo, consultadas por janela de tempo e agregadas | compressão e retenção por tempo | série temporal | citado na aula 2 |
| várias entidades alteradas juntas, ou perguntas que ninguém fez ainda | transações, joins, consultas ad hoc | **relacional** | `sql-databases`, e a próxima seção |

**A última linha é aquela de que a maioria dos sistemas é feita.** Uma loja online tem clientes,
produtos, pedidos, estoque e pagamentos, alterados juntos em transações e consultados de jeitos que
o negócio vai inventar no ano que vem. A tabela da aula 1 disse que tirar o último monitor do estoque
e cobrar o cartão precisam de consistência; a aula 5 mostrou o que uma aplicação tem que fazer para
viver sem ela. Um banco relacional dá essa consistência às duas operações sem a aplicação fazer
nada.

## Dois avisos que a tabela não carrega

**Padrões, não sistemas.** A tabela classifica operações, e uma aplicação tem muitas. A loja cujos
pedidos pertencem ao Postgres ainda pode contar visualizações de página no Redis. A decisão é por
operação, e o custo de agir sobre ela, um segundo banco, é o assunto da seção depois da próxima.

**A tabela descreve o padrão que você tem, não o que você talvez tenha.** "Vamos ter um bilhão de
eventos por dia" justifica o Cassandra no dia em que for verdade, e antes disso custa tudo o que a
aula 16 pediu: toda consulta escrita antes, toda pergunta nova uma tabela nova. Um padrão que é
previsão entra no registro de decisão como previsão, com o número que o tornaria real.
