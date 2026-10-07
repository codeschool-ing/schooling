---
title: Cifrando uma coluna, e para onde foi a chave
version: 1
---

O CPF é a coluna que a Ipê menos gostaria de ver nas mãos de outra pessoa: o número de contribuinte
brasileiro, impresso em documentos e pedido em todo lugar, e por isso usado para se passar por
alguém. Cifrar só essa coluna, dentro da tabela, faria um backup, uma réplica e um `SELECT`
descuidado carregarem texto cifrado. O PostgreSQL traz uma extensão para isso, o **pgcrypto**:

```sql
-- pgcrypto in a schema of its own: the public schema is closed to
-- everybody (lesson 1's schema), and functions should not live there anyway.
CREATE SCHEMA crypto;
CREATE EXTENSION pgcrypto SCHEMA crypto;
GRANT USAGE ON SCHEMA crypto TO ipe_owner;
```

```
ana@lab:~/gov$ sudo -u postgres psql < pgcrypto.sql
CREATE SCHEMA
CREATE EXTENSION
GRANT
```

A extensão vai para um schema próprio, `crypto`, porque o schema da aula 1 fechou o `public` para
todo mundo, e porque um schema com o nome do que contém pode ser concedido sozinho. Depois, a
primeira tentativa da Ana:

```sql
-- A FIRST ATTEMPT: the CPF encrypted by the database, with a key in the SQL.
SET ROLE ipe_owner;
ALTER TABLE sales.customers ADD COLUMN cpf_enc bytea;
UPDATE sales.customers
   SET cpf_enc = crypto.pgp_sym_encrypt(cpf, 'chave-da-ipe-2026');
SELECT customer_id, cpf, left(encode(cpf_enc, 'hex'), 40) AS cpf_enc
FROM sales.customers WHERE customer_id = 1;
```

```
ana@lab:~/gov$ psql -f encrypt.sql
SET
ALTER TABLE
UPDATE 6012
 customer_id |      cpf       |                 cpf_enc                  
-------------+----------------+------------------------------------------
           1 | 372.874.168-09 | c30d040703020722140bf6f1c35668d23f0119ea
(1 row)
```

Cada um dos 6.012 CPFs tem agora uma cópia cifrada ao lado. `pgp_sym_encrypt` produz uma mensagem
OpenPGP — os bytes iniciais `c30d04` são o cabeçalho do primeiro pacote dela — cifrada com uma chave
derivada da frase-senha, com um sal aleatório para que dois CPFs iguais deem textos cifrados
diferentes. A coluna em claro continua lá, porque esta é uma primeira tentativa; o plano seria
apagá-la.

## A chave viajou junto com a consulta

Ler de volta também precisa da frase-senha, e é aí que o desenho quebra. A Ana liga o log completo
de comandos — que os times ligam para depurar, e deixam ligado mais tempo do que pretendiam — e lê
um CPF:

```sql
ALTER SYSTEM SET log_statement = 'all';
SELECT pg_reload_conf();
```

```
ana@lab:~/gov$ sudo -u postgres psql < leak.sql
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT crypto.pgp_sym_decrypt(cpf_enc, 'chave-da-ipe-2026') FROM sales.customers WHERE customer_id = 1"
SET
 pgp_sym_decrypt 
-----------------
 372.874.168-09
(1 row)

ana@lab:~/gov$ sudo grep -c "chave-da-ipe-2026" /var/log/postgresql/postgresql-16-gov.log
1
ana@lab:~/gov$ sudo grep -m 1 "pgp_sym_decrypt" /var/log/postgresql/postgresql-16-gov.log
2026-10-07 02:17:53.732 -03 [3958] ana@ipe LOG:  statement: SELECT crypto.pgp_sym_decrypt(cpf_enc, 'chave-da-ipe-2026') FROM sales.customers WHERE customer_id = 1
```

**A chave está no log do servidor**, em claro, na mesma linha da consulta que a usou. O comando
viajou ao servidor como texto, então a chave também, e todo lugar onde um comando pode parar agora
a guarda: o log, o `pg_stat_activity` enquanto a consulta roda, o `pg_stat_statements` se estiver
instalado, um relatório de consultas lentas, a captura de tela de um painel de monitoramento. E o
servidor de banco, aquilo de que a criptografia deveria proteger a coluna, guarda a chave na
memória toda vez que decifra. A Ana desliga o log de comandos de novo antes de seguir:

```sh
sudo -u postgres psql -c "ALTER SYSTEM RESET log_statement" -c "SELECT pg_reload_conf()"
```

**Cifrar dentro do banco protege contra quem obtém uma cópia do dado sem a chave.** Não protege
contra o banco, os administradores dele ou os logs dele, porque a chave passa pelos três. Isso não é
defeito do pgcrypto; é onde a criptografia termina, respondendo à pergunta da primeira seção desta
aula.

## Onde a chave deveria estar

A alternativa é cifrar **antes** de o dado chegar ao banco, na aplicação, com uma chave que o banco
nunca vê. O banco então guarda texto cifrado que não consegue ler, e um backup roubado, um
administrador curioso e um log verboso não guardam nada de útil. Em troca a aplicação precisa da
chave, então a pergunta muda de lugar: de onde a aplicação a tira, e quem mais consegue? Uma chave
no arquivo de configuração da aplicação é de novo uma senha num arquivo. A aula 4 a põe num serviço
de gestão de chaves que entrega o *uso* de uma chave sem entregar a chave — e substitui esta coluna.
