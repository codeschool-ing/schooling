---
title: Um papel para as ferramentas, que só lê a camada
version: 1
---

O Metabase vai se conectar ao PostgreSQL como um usuário do banco. Poderia conectar como você, e não
deveria: o seu papel é superusuário, então qualquer pergunta que alguém montasse no Metabase poderia
ler todas as tabelas, e um erro na configuração da ferramenta poderia escrever nelas. **Uma
ferramenta de BI ganha um papel próprio, que lê a camada e mais nada.**

Crie-o no `psql lantern`. Escolha a sua própria senha — esta está impressa num curso:

```sql
CREATE ROLE metabase LOGIN PASSWORD 'pick-your-own-password';
```

Depois deixe-o ver o schema e ler o que há nele:

```sql
GRANT USAGE ON SCHEMA semantic TO metabase;
GRANT SELECT ON ALL TABLES IN SCHEMA semantic TO metabase;
```

`USAGE` num schema é permissão para olhar dentro dele; `SELECT` nas tabelas e views é permissão para
lê-las. Juntos:

```
lantern=# CREATE ROLE metabase LOGIN PASSWORD 'pick-your-own-password';
CREATE ROLE

lantern=# GRANT USAGE ON SCHEMA semantic TO metabase;
GRANT

lantern=# GRANT SELECT ON ALL TABLES IN SCHEMA semantic TO metabase;
GRANT
```

Duas verificações, pelo shell, conectando do jeito que o Metabase vai conectar — pela rede, em
`localhost`, com a senha:

```
ana@vm:~$ PGPASSWORD=pick-your-own-password psql -h localhost -U metabase lantern -c 'SELECT count(*) FROM semantic.orders'
 count 
-------
  7098
(1 row)

ana@vm:~$ PGPASSWORD=pick-your-own-password psql -h localhost -U metabase lantern -c 'SELECT count(*) FROM shop.orders'
ERROR:  permission denied for schema shop
LINE 1: SELECT count(*) FROM shop.orders
                             ^
```

A camada responde, e as tabelas da própria loja recusam. As views de `semantic` leem de `shop` mesmo
assim, porque uma view roda com as permissões do dono — você —, então o papel vê exatamente o que a
camada mostra e nada do que ela esconde. **Essa é a fronteira de que o autoatendimento precisa**:
quem monta gráficos pode fazer qualquer pergunta à camada, e nenhuma pergunta a mais nada.

`GRANT SELECT ON ALL TABLES` vale para as views que existem quando ele roda. Rode o `semantic.sql` de
novo e as views são objetos novos, sem grants, então o segundo bloco precisa rodar de novo — três
seções adiante está como isso aparece do lado do Metabase.
