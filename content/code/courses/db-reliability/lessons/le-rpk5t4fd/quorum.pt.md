---
title: Dois standbys, e um quórum de um
version: 1
---

A saída do travamento não é esperar menos, e sim ter mais o que esperar. Construa um segundo standby do
mesmo jeito que o primeiro, na porta 5435, com o nome `standby2` e um slot próprio, suba os dois, e diga
ao primário que **qualquer um** dos dois basta:

```
ana@vm:~$ sudo -u postgres pg_basebackup -d 'host=127.0.0.1 port=5432 user=replicator application_name=standby2' -D /var/lib/postgresql/16/standby2 -R -C -S standby2 -X stream -c fast
ana@vm:~$ sudo pg_ctlcluster 16 standby2 start
ana@vm:~$ sudo pg_ctlcluster 16 standby start
shop=# ALTER SYSTEM SET synchronous_standby_names = 'ANY 1 (standby1, standby2)';
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

shop=# SELECT application_name, sync_state FROM pg_stat_replication ORDER BY 1;
 application_name | sync_state 
------------------+------------
 standby1         | quorum
 standby2         | quorum
(2 rows)
```

`sync_state: quorum` nos dois. Com `ANY 1 (standby1, standby2)`, um commit retorna assim que qualquer
um dos standbys tiver feito o flush dele, então ele está em pelo menos dois servidores, e o standby mais
lento não custa nada. Agora pare o `standby1` de novo:

```
ana@vm:~$ sudo pg_ctlcluster 16 standby stop
ana@vm:~$ timeout 10 psql shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (22, 2200, now())"; echo "exit $?"
INSERT 0 1
exit 0
shop=# SELECT application_name, sync_state FROM pg_stat_replication ORDER BY 1;
 application_name | sync_state 
------------------+------------
 standby2         | quorum
(1 row)
```

O pedido passou na hora, `exit 0`, e só o `standby2` aparece na lista. **Dá para perder um standby sem
parar uma escrita**, e todo commit confirmado continua em duas máquinas. São precisos três servidores
para chegar lá, e esse é o preço real da replicação síncrona: não o terço de milissegundo, mas a
terceira máquina.

## As formas da configuração

| `synchronous_standby_names` | um commit espera |
|---|---|
| vazio (o padrão) | ninguém: a replicação é assíncrona |
| `'standby1'` | o `standby1`, e para quando ele some |
| `'FIRST 1 (standby1, standby2)'` | o primeiro da lista que estiver conectado; o `standby2` assume quando o `standby1` some |
| `'ANY 1 (standby1, standby2)'` | o que responder primeiro |
| `'ANY 2 (s1, s2, s3)'` | quaisquer dois dos três |

O `FIRST` mantém uma ordem de preferência, o que importa quando um standby está perto e o outro está
longe: o distante só é esperado quando o próximo some, e aí todo commit fica mais lento, na medida da
distância dele. O `ANY` espera o mais rápido, então é o mais rápido dos dois em regime normal.

## Escolhendo

- **Assíncrono é a resposta certa na maioria das vezes.** Se o negócio aceitou na lição 8 um RPO de
  segundos, um standby assíncrono com o atraso monitorado (lição 13) atende, sem custo por commit, e a
  falha dele não para nada.
- **Síncrono é para os dados em que "dissemos sim ao cliente e depois perdemos" não é aceitável**:
  pagamentos, livros contábeis, qualquer coisa que sai do prédio depois do commit. Aí ele precisa de um
  quórum, para que a falha de um standby não seja uma queda, e os standbys precisam estar perto.
- **Por transação muitas vezes é o melhor de tudo.** A configuração pode ser `local` para o servidor
  inteiro e `remote_apply` na única transação que registra um pagamento, ou o contrário. A tabela da
  primeira seção é um cardápio, não uma escolha para o servidor inteiro.

E, seja qual for a escolha, um standby síncrono continua sendo uma cópia de cada erro, feita um pouco
mais cedo. Ele protege contra perder uma máquina; não faz nada contra um `DELETE` com o `WHERE` errado,
e é para isso que serve o arquivo.
