---
title: O que registrar
version: 1
---

Do jeito que vem, o servidor registra a própria vida — subir, parar, checkpoints — e qualquer coisa
de `WARNING` para cima (`log_min_messages`). Isso basta para dizer que o servidor está com problema
e não basta para dizer por quê. Cinco parâmetros preenchem a lacuna, e cada um escreve um tipo de
linha que você vai agradecer no dia em que algo estiver lento. Eles valem a partir de um reload:

@@1@@

## Comandos lentos

O **`log_min_duration_statement`** escreve todo comando que levou mais que o valor, com a sua
duração. Cinquenta milissegundos é baixo, escolhido para que a demonstração tenha o que pegar; num
servidor de verdade o valor é o que "lento demais" significa para aquela aplicação, muitas vezes de
algumas centenas de milissegundos a um segundo.

@@2@@

@@3@@

A contagem leu a tabela inteira e está no log. A busca pela chave primária não está, e **esse é o
sentido de um limiar**: o log guarda os comandos que merecem uma olhada e não os milhões que foram
bem. O pg_stat_statements da lição 18 soma todo comando pela forma; esta linha é a ocorrência
única, com os valores reais, que é o que você cola num `EXPLAIN ANALYZE`.

## Ordenações que transbordaram para o disco

O **`log_temp_files = 0`** escreve uma linha para cada arquivo temporário que uma consulta precisou
criar, com o tamanho. Uma ordenação ou um hash que não cabe no `work_mem` transborda, que é o
assunto da lição 6. Aqui o `work_mem` é reduzido numa sessão para que uma ordenação de um milhão de
valores não caiba:

@@4@@

@@5@@

O `size` está em bytes: cerca de doze megabytes escritos e lidos de volta por uma ordenação que
teria rodado em memória com um `work_mem` maior. Um valor acima de zero registra só arquivos acima
de tantos kilobytes, o que num servidor movimentado deixa de fora os pequenos sobre os quais ninguém
vai agir.

## Esperas por trava

O **`log_lock_waits`** escreve uma linha quando uma sessão esperou por uma trava mais que o
`deadlock_timeout`, um segundo por padrão. Dois terminais produzem uma. No primeiro, uma transação
atualiza uma linha e dorme quatro segundos antes do commit:

@@6@@

No segundo, enquanto o primeiro ainda dorme, a mesma linha:

@@7@@

O segundo `UPDATE` ficou calado até o primeiro fazer commit. O log diz o que ele estava fazendo:

@@8@@

**A linha `DETAIL` dá o processo que segurava a trava**, e o comando do primeiro terminal também está
no log, com os seus quatro segundos, porque passou do `log_min_duration_statement`. Juntas, elas
dizem quem bloqueou quem e com o quê, escrito enquanto acontecia. Uma sessão bloqueada que foi
cancelada antes de alguém olhar não deixa nada no `pg_stat_activity`; deixa estas linhas. Encontrar
quem bloqueia, ao vivo, é a lição 13 de db-performance.

## Conexões

O **`log_connections`** e o **`log_disconnections`** escrevem uma linha quando uma sessão chega e
quando termina:

@@9@@

@@10@@

Três linhas para chegar e uma para sair. A linha `authenticated` dá o método e **a linha do
`pg_hba.conf` que casou**, que é o jeito mais rápido de responder à pergunta da lição 5, de por que
uma conexão entrou ou foi recusada. A linha `disconnection` traz a duração da sessão. Num servidor
cuja aplicação abre uma conexão por requisição, esses dois parâmetros escrevem um par de linhas por
requisição, que é o argumento da lição 10 a favor de um pool, visto pelo outro lado.

## Checkpoints, já ligados

O **`log_checkpoints`** vem ligado por padrão desde o PostgreSQL 16. Um `CHECKPOINT` manual mostra
o par de linhas que ele escreve:

@@11@@

@@12@@

O `[%p]` aqui é o checkpointer, e o `%q` deixou de fora o usuário e o banco. A lição 8 lê os números
da linha `complete`. Para o log, a palavra útil está na linha `starting`: o motivo, `immediate force
wait` para este manual, e `time` ou `wal` para os que o próprio servidor inicia. Um servidor que
escreve `wal` ali o tempo todo está fazendo checkpoint porque ficou sem espaço de WAL, e não porque
o relógio mandou.

## E o autovacuum

O **`log_autovacuum_min_duration`** é o último do conjunto. O seu padrão, `600000`, está em
milissegundos: uma execução do autovacuum que levou mais de dez minutos é registrada, o que na
maioria dos servidores não é nenhuma. A lição 14 o reduz e lê o que o autovacuum relata.

Um conjunto razoável para começar num servidor de produção é, então: um limiar de comando lento
com que os donos da aplicação concordem, `log_lock_waits = on`, `log_temp_files` em alguns
megabytes, conexões ligadas a menos que a taxa de conexões seja muito alta, e os checkpoints como
estão. **Cada um desses escreve linhas só quando aconteceu algo que vale ler.** A próxima seção mede
o único parâmetro que não funciona assim.
