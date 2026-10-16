---
title: Vários hosts numa string de conexão
version: 1
---

A `libpq`, a biblioteca por trás do `psql` e da maioria dos drivers de PostgreSQL, aceita uma **lista**
de hosts e portas, e uma condição que o servidor escolhido tem de cumprir. Ela tenta um por um, na
ordem, e fica com o primeiro que se qualifica:

```
ana@vm:~$ psql 'host=127.0.0.1,127.0.0.1,127.0.0.1 port=5441,5442,5443 user=postgres dbname=shop target_session_attrs=read-write' -XAt -c 'SELECT inet_server_port()'
5441
ana@vm:~$ psql 'host=127.0.0.1,127.0.0.1,127.0.0.1 port=5441,5442,5443 user=postgres dbname=shop target_session_attrs=standby' -XAt -c 'SELECT inet_server_port()'
5442
```

Com `target_session_attrs=read-write` ela não pulou nada, porque o `pg1` na 5441 é o primário e o
primeiro da lista. Com `standby` ela passou pela 5441 e ficou com o `pg2`. Depois de um failover, a
mesma string, sem mudança nenhuma, chega no novo primário; a última seção mostra isso acontecendo.

Esta é a mais barata das quatro: nada para instalar e nada no meio do caminho que possa falhar. Os
custos ficam do lado da aplicação. A configuração de cada aplicação lista todos os servidores, então
adicionar um é uma mudança em todas elas; cada conexão nova pode tentar primeiro um host morto e
esperar esgotar o tempo limite de conexão, então o `connect_timeout` deve ser curto; e drivers que não usam a
`libpq` precisam de suporte próprio para isso. O driver JDBC tem (`targetServerType=primary`); muitos
outros também têm, com outros nomes.
