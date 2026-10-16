---
title: Onde um backup lógico deixa de bastar
version: 1
---

Um dump é um ótimo backup para o shop. A pergunta é a partir de que tamanho, e para que perda, ele
deixa de ser, e as duas têm respostas que dá para medir.

## O custo cresce com o tamanho

Monte um shop maior ao lado do de verdade: o mesmo script, e depois quase três milhões de pedidos a
mais. Salve isto como `more-orders.sql`:

```sql
-- more-orders.sql: grow a copy of the shop to three million orders
INSERT INTO orders (customer_id, total_cents, placed_at)
SELECT 1 + (i::bigint * 7919) % 1000,
       500 + (i::bigint * 104729) % 20000,
       timestamptz '2026-01-01 09:00-03' + i * interval '5 seconds'
FROM generate_series(50001, 3000000) AS i;
```

Carregue os dois num banco novo e veja o tamanho dele. As duas linhas de `NOTICE` são o `shop.sql` não achando tabelas para apagar num banco que é novo:

```
ana@vm:~$ createdb bigshop
ana@vm:~$ psql -q bigshop -f shop.sql
psql:shop.sql:2: NOTICE:  table "orders" does not exist, skipping
psql:shop.sql:2: NOTICE:  table "customers" does not exist, skipping
ana@vm:~$ psql bigshop -f more-orders.sql
INSERT 0 2950000
ana@vm:~$ psql -X -A -t bigshop -c "SELECT pg_size_pretty(pg_database_size('bigshop'))"
268 MB
```

**268 MB**, com sessenta vezes os pedidos do shop. Faça o dump e restaure no segundo servidor, com
o `time` do shell na frente de cada um:

```
ana@vm:~$ time pg_dump -Fc -f bigshop.dump bigshop

real	0m4.350s
user	0m4.095s
sys	0m0.118s
ana@vm:~$ ls -lh bigshop.dump
-rw-r--r-- 1 ana ana 30M Oct 10 04:06 bigshop.dump
ana@vm:~$ createdb -p 5433 bigshop
ana@vm:~$ time pg_restore -p 5433 -d bigshop bigshop.dump

real	0m7.256s
user	0m0.515s
sys	0m0.251s
```

`real` é o tempo no relógio de parede, o que importa para quem está esperando. **4,4 segundos para o
dump e 7,3 para a restauração**, na máquina em que este curso foi gravado, que tem quatro
processadores e um disco rápido; a sua vai ser mais lenta. A restauração levou mais que o dump
porque faz mais trabalho: cada linha inserida, depois um índice e duas chaves montados sobre três
milhões de linhas, depois conferidos.

O formato directory pode usar mais de um processo. Experimente dois, o número que a lição 1 deu à
sua máquina:

```
ana@vm:~$ time pg_dump -Fd -j 2 -f bigshop.dir bigshop

real	0m4.022s
user	0m3.837s
sys	0m0.072s
ana@vm:~$ dropdb -p 5433 bigshop
ana@vm:~$ createdb -p 5433 bigshop
ana@vm:~$ time pg_restore -p 5433 -j 2 -d bigshop bigshop.dir

real	0m5.837s
user	0m0.581s
sys	0m0.047s
```

O dump quase não mudou, de 4,4 para 4,0 segundos, porque **o dump paralelo trabalha por tabela** e
quase todos os dados estão numa só: dois workers, um deles quase sem nada para fazer. A restauração
melhorou, de 7,3 para 5,8, porque os índices e as chaves são tarefas separadas e os dois workers as
montaram lado a lado. Um banco com muitas tabelas grandes ganha mais; um banco que é uma única
tabela enorme ganha pouco.

## A aritmética de um banco grande

No ritmo desta máquina, uma restauração leva cerca de 7,3 segundos a cada 268 MB. Multiplique isso
até um banco de um terabyte e dá **quase oito horas**, e o número real é pior, porque montar um
índice cresce mais rápido que o número de linhas e um servidor fica sem memória para ordenar muito
antes de ficar sem disco. Oito horas com a aplicação fora do ar, supondo que nada dê errado na
primeira tentativa.

Esse é o primeiro limite: **uma restauração lógica leva tempo proporcional aos dados, e mais um
pouco.** O backup físico da lição 3 copia arquivos em vez de reconstruí-los, e é restaurado na
velocidade de uma cópia.

## A perda é tudo desde o dump

O segundo limite está no que o dump guarda. Ele é o banco num único instante, o momento em que o
snapshot foi tirado. Um dump noturno às duas da manhã e um disco que falha às seis da tarde perdem
**dezesseis horas de pedidos**, e nenhum cuidado na restauração os traz de volta, porque eles nunca
estiveram no arquivo.

Fazer dumps com mais frequência só estreita essa janela. Um dump por hora num banco cujo dump leva
quarenta minutos é um servidor que passa dois terços do tempo fazendo dump. O que fecha a janela é
algo de outra natureza: um registro de cada mudança, mantido continuamente, que a lição 4 monta a
partir do write-ahead log.

## Para que os backups lógicos continuam servindo

Nenhum dos limites os torna inúteis, e toda instalação séria os mantém ao lado dos físicos:

- **Mover dados entre versões e máquinas**, o que uma cópia física não faz: ela só restaura na
  mesma versão major, no mesmo tipo de processador.
- **Recuperar uma tabela**, como fez a seção anterior, sem restaurar um servidor inteiro.
- **Um segundo tipo de cópia, independente.** Um bug que corrompe arquivos de dados é copiado
  fielmente por um backup em nível de arquivo. Um dump precisa ler cada linha através do banco para
  escrevê-la, então uma página danificada faz o dump falhar ruidosamente em vez de copiar o dano.
- **Bancos pequenos**, que restauram em menos tempo do que se leva para ler esta frase.
