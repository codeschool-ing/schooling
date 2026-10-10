---
title: Wraparound, o contador que não pode acabar
version: 1
---

Toda transação que altera alguma coisa recebe um número, e `xmin` e `xmax` são esses números.
**Eles têm 32 bits**, cerca de quatro bilhões de valores, e um servidor movimentado gasta um bilhão
em um ou dois anos. Por isso os números são comparados num círculo: a partir de qualquer transação,
dois bilhões estão no passado e dois bilhões no futuro. Uma linha escrita pela transação 782 está
no passado para a transação 805. Dois bilhões de transações depois, a mesma 782 cairia no futuro, e
**a linha sumiria** de toda consulta sem que ninguém a tivesse apagado.

O congelamento é o que impede isso. Uma linha congelada é visível para todos, diga o número o que
disser, então o `xmin` dela não entra mais na comparação. Cada tabela registra em `relfrozenxid` a
transação não congelada mais antiga que ainda pode conter, cada banco registra em `datfrozenxid` a
mais antiga das suas tabelas, e `age()` transforma qualquer um dos dois numa contagem de transações:

@@1@@

O servidor de `shop` é jovem, então toda idade é de poucas dezenas. **`autovacuum_freeze_max_age`
é a linha**: uma tabela cuja idade passa de 200 milhões recebe um autovacuum agressivo, que lê toda
página ainda não congelada, seja qual for a situação das linhas mortas. Ele roda mesmo com o
`autovacuum` desligado, e não sai da frente quando alguém quer uma trava na tabela, como faz um
autovacuum comum. Numa tabela grande em que ninguém pensou, essa passada agressiva muitas vezes é a
primeira vez que alguém repara no autovacuum, porque ela lê a tabela inteira numa hora que ninguém
escolheu.

## Como é quando isso não funciona

Esperar dois bilhões de transações para ver o fim não é prático. O `pg_resetwal` consegue definir
diretamente o próximo id de transação de um cluster parado, e isso basta para ver o fim num
**cluster de rascunho criado para isso**, nunca num que importe. O `pg_resetwal` joga fora o
write-ahead log, o que num cluster de verdade perde dados. O `dd` cria o pedaço do commit log, em
`pg_xact`, de que o novo id de transação precisa; sem ele o servidor não conseguiria registrar se
essa transação fez commit:

@@2@@

As idades são 2.144.999.278, logo abaixo de 2.147.483.648, onde o círculo viraria. **O servidor
recusa tudo o que precisa de um novo id de transação** e continua atendendo leituras: o
`CREATE TABLE` falha, o `count(*)` funciona. Ele faz isso 3 milhões de transações antes do ponto
sem volta, e a partir de 40 milhões antes cada novo id de transação vem com um aviso no log. Esses
avisos são o alarme que um servidor monitorado teria dado semanas antes; este cluster pulou por
cima deles.

A saída é um VACUUM que congele todos os bancos:

@@3@@

**`as a failsafe`** apareceu 216 vezes. Passado o `vacuum_failsafe_age`, 1,6 bilhão por padrão, o
VACUUM larga tudo o que não seja congelar: nada de limpeza de índice, nada de freio, só trazer a
idade de volta para baixo. Os avisos no fim nomeiam os bancos ainda em risco.

@@4@@

`postgres` e `template1` estão em 0. **`template0` não**, porque não aceita conexões e o
`vacuumdb --all` o pula, então o servidor continua recusando. Esse fica com o autovacuum, que
consegue alcançá-lo, e em cerca de um minuto tinha feito:

@@5@@

A dica na recusa manda parar o servidor e rodar o vacuum em modo de usuário único. Aqui um
`vacuumdb` comum, com o servidor no ar e ainda atendendo leituras, fez o trabalho, e o autovacuum
fez o resto. Parar o servidor o tira de todo mundo, então tente primeiro o caminho comum.

Neste cluster a emergência inteira levou um minuto, porque ele quase não guarda nada. Num servidor
com uma tabela de dois terabytes, o mesmo congelamento lê dois terabytes enquanto a aplicação não
consegue escrever, e pode levar boa parte de um dia. **A cura é nunca chegar lá**: acompanhe
`age(datfrozenxid)` como a primeira consulta acima faz, e trate como incidente uma idade que
continua subindo além de `autovacuum_freeze_max_age`. Isso quer dizer que o autovacuum não
consegue terminar, em geral por um motivo que a seção anterior já nomeou.
