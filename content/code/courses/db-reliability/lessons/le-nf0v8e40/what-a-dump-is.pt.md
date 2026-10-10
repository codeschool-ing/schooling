---
title: Um dump é um programa que reconstrói os dados
version: 1
---

A imagem mais comum de um backup é uma cópia de arquivos: algo que lê o disco do banco e escreve os
mesmos bytes em outro lugar. **O `pg_dump` não é isso.** Ele se conecta ao servidor como um cliente
qualquer, faz perguntas e escreve as respostas como instruções para montar o banco de novo. Essa
diferença decide para que ele serve e onde ele para, e esta lição trata das duas coisas.

## O que ele escreve

Antes de olhar, dê ao shop o que todo banco de verdade tem e a lição 1 deixou de fora: um dono que
não é você, e um papel (role) da aplicação com só os direitos de que ela precisa.

```
shop=# CREATE ROLE shop_owner NOLOGIN;
CREATE ROLE

shop=# CREATE ROLE shop_app LOGIN PASSWORD 'app-secret-1';
CREATE ROLE

shop=# ALTER TABLE customers OWNER TO shop_owner;
ALTER TABLE

shop=# ALTER TABLE orders OWNER TO shop_owner;
ALTER TABLE

shop=# GRANT SELECT, INSERT ON orders, customers TO shop_app;
GRANT
```

Agora peça ao `pg_dump` a saída padrão dele, SQL puro, e fique só com as linhas que começam um
comando:

```
ana@vm:~$ pg_dump shop | grep -E '^(CREATE|ALTER|GRANT|COPY)'
CREATE TABLE public.customers (
ALTER TABLE public.customers OWNER TO shop_owner;
CREATE TABLE public.orders (
ALTER TABLE public.orders OWNER TO shop_owner;
ALTER TABLE public.orders ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
COPY public.customers (id, name, city) FROM stdin;
COPY public.orders (id, customer_id, total_cents, placed_at) FROM stdin;
ALTER TABLE ONLY public.customers
ALTER TABLE ONLY public.orders
CREATE INDEX orders_customer ON public.orders USING btree (customer_id);
ALTER TABLE ONLY public.orders
GRANT SELECT,INSERT ON TABLE public.customers TO shop_app;
GRANT SELECT,INSERT ON TABLE public.orders TO shop_app;
```

Esse é o formato inteiro de um dump lógico. **Criar as tabelas, carregar as linhas, depois montar
os índices e as restrições, depois conceder as permissões.** As linhas viajam como
`COPY … FROM stdin`, o jeito mais rápido que o PostgreSQL tem de carregar dados, seguido das
próprias linhas como texto. Cada `ALTER TABLE ONLY` que aparece depois dos dados é uma chave
primária ou estrangeira sendo adicionada depois que as linhas entraram, porque conferir cinquenta
mil linhas contra uma restrição de uma vez só sai muito mais barato do que conferir cada linha à
medida que ela chega.

Três consequências decorrem de "um programa que reconstrói", e elas são o resto desta lição:

- **Ele não depende da versão nem da máquina do servidor.** Um dump tirado do PostgreSQL 16 num
  notebook Intel restaura no PostgreSQL 17 num servidor ARM, porque é SQL. É por isso que upgrades
  e migrações o usam, e por isso que a lição 20 do curso de administração o usou.
- **Ele descreve um banco.** Quem pode entrar, e com que senha, não está dentro de nenhum banco; as
  linhas `ALTER … OWNER TO shop_owner` citam um papel que o dump não cria. A seção depois da próxima
  restaura num servidor limpo e vê isso falhar.
- **Restaurá-lo é fazer todo o trabalho de novo.** Cada linha é inserida, cada índice montado, cada
  restrição conferida. A última seção cronometra isso num banco com sessenta vezes os pedidos do
  shop.

## Um único instante, mesmo com o banco mudando

O dump de um banco movimentado é tirado enquanto outras sessões continuam escrevendo. O `pg_dump`
abre uma transação e lê tudo através de **um snapshot**: o estado do banco inteiro no instante em
que o dump começou. Uma linha inserida um segundo depois não está nele, e nenhuma das metades de uma
transferência que fez commit durante o dump está nele sozinha. Toda tabela do arquivo concorda com
todas as outras sobre que horas são.

O que o snapshot custa é um lock. O `pg_dump` segura um lock leve em cada tabela de que está fazendo
dump até terminar, que permite leituras e escritas e recusa mudanças de schema. Um `ALTER TABLE`
iniciado durante um dump longo espera por ele, e **toda consulta que chega depois desse
`ALTER TABLE` espera atrás dele**. Um dump noturno que leva quarenta minutos e uma migração agendada
para o mesmo horário fazem uma indisponibilidade de quarenta minutos que nenhuma das duas rotinas
relata como erro.
