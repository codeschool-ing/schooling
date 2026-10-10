---
title: Rápido, inteiro e cego: o que um backup físico troca
version: 1
---

A lição 2 cronometrou uma restauração lógica do `bigshop`. Faça o mesmo com um base backup do
servidor inteiro, `bigshop`, o shop e tudo o mais que houver nele, e uma restauração por cópia:

```
ana@vm:~$ rm -rf base
ana@vm:~$ time pg_basebackup -D base -X stream -c fast

real	0m1.311s
user	0m0.064s
sys	0m0.809s
ana@vm:~$ du -sh base
318M	base
ana@vm:~$ sudo pg_ctlcluster 16 restore stop
ana@vm:~$ sudo rm -rf /var/lib/postgresql/16/restore
ana@vm:~$ time { sudo cp -a base /var/lib/postgresql/16/restore && sudo chown -R postgres:postgres /var/lib/postgresql/16/restore && sudo chmod 700 /var/lib/postgresql/16/restore && sudo pg_ctlcluster 16 restore start; }

real	0m3.813s
user	0m0.069s
sys	0m1.201s
ana@vm:~$ psql -X -A -t -p 5433 bigshop -c "SELECT count(*) FROM orders"
3000000
```

**1,3 segundo para tirar o backup e 3,8 para restaurá-lo e subir o servidor**, para 318 MB, contra
7,3 segundos da lição 2 para restaurar só o `bigshop` a partir do dump. Nada foi reconstruído. Os
índices voltaram como arquivos, já montados, e as chaves nunca foram conferidas porque nada nelas
tinha mudado. O tempo de uma restauração física cresce com o tamanho dos arquivos e a velocidade do
disco e da rede, e **não com quantos índices e constraints existem**, que foi o que tornou a
restauração lógica de um terabyte um trabalho de oito horas.

Essa velocidade se paga de três jeitos, e cada um é um motivo para manter também os dumps da
lição 2.

## O servidor inteiro, ou nada

Um base backup é o diretório de dados de um servidor. Não há como restaurar dele um banco, ou uma
tabela: os arquivos de todos os bancos compartilham um write-ahead log e um registro de commits, e
nenhum deles faz sentido sozinho. Recuperar os pedidos de Curitiba da lição 2 a partir de um backup
físico significa restaurar **o servidor inteiro em outro lugar** e depois copiar as linhas de lá, que
é a restauração seletiva de novo, com um primeiro passo maior.

## Mesma versão, mesmo tipo de máquina

Os arquivos estão no formato em disco do PostgreSQL 16, na arquitetura deste processador. Um base
backup só sobe na **mesma versão major** (qualquer 16.x) e no mesmo tipo de processador; ele não
sobe no 17, e um backup de um servidor Intel não sobe num ARM. Upgrades e migrações entre máquinas
continuam com as ferramentas lógicas.

## Fiel ao estrago

Uma página de tabela que foi corrompida no servidor é copiada como está, dada como correta pelo
manifesto (os bytes são os que o servidor mandou) e restaurada como estava. Um backup físico não tem
opinião sobre os dados, só sobre os arquivos. Um dump, que precisa ler cada linha através do banco
para escrevê-la, teria falhado nessa página. Esse é o motivo mais forte para manter os dois tipos:
**eles falham de jeitos diferentes**, e uma falha que derrota um costuma ficar visível para o outro.

## A pergunta que fica em aberto

Um base backup continua sendo um momento, o instante em que a cópia terminou. Um disco que falha
dezesseis horas depois do base backup noturno perde dezesseis horas, exatamente como um dump, só que
mais rápido de restaurar. A lição 4 guarda o write-ahead log que o servidor escreve entre um backup e
outro, e o base backup vira o ponto de partida de uma recuperação que pode parar em qualquer ponto
depois dele.
