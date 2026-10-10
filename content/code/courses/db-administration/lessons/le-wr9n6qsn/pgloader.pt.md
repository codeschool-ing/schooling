---
title: O pgloader, e as três vezes em que ele para
version: 1
---

O **pgloader** lê o catálogo de um banco MySQL, cria as mesmas tabelas no PostgreSQL com tipos que
ele escolhe, copia as linhas com o `COPY` do PostgreSQL e depois constrói os índices, as chaves e as
sequences. Um comando faz tudo isso. No Ubuntu 24.04 contra o MySQL 8.0, esse comando falha três
vezes antes de funcionar, e vale ver cada falha uma vez: duas são da ferramenta, e uma é dos dados.

```sh
sudo apt install -y pgloader
```

O pgloader lê do MySQL pela rede, como um cliente comum com senha, então precisa de um usuário MySQL
próprio. Ele só lê, e recebe só `SELECT`. O lado do PostgreSQL precisa de um banco vazio, e o seu
próprio papel basta para escrever nele:

```
ana@db:~$ sudo mysql -e "CREATE USER 'migrator'@'localhost' IDENTIFIED BY 'change-me'; GRANT SELECT, SHOW VIEW ON legacy.* TO 'migrator'@'localhost';"
ana@db:~$ createdb legacy
ana@db:~$ pgloader --version
pgloader version "3.6.7~devel"
compiled with SBCL 2.2.9.debian
ana@db:~$ pgloader mysql://migrator:change-me@localhost/legacy postgresql:///legacy
2026-10-10T07:33:41.020000Z LOG pgloader version "3.6.7~devel"
2026-10-10T07:33:41.104000Z LOG Migrating from #<MYSQL-CONNECTION mysql://migrator@localhost:3306/legacy {1005DC3983}>
2026-10-10T07:33:41.104000Z LOG Migrating into #<PGSQL-CONNECTION pgsql://ana@UNIX:5432/legacy {1005F8FAB3}>
2026-10-10T07:33:41.132000Z ERROR mysql: Failed to connect to mysql at "localhost" (port 3306) as user "migrator": Condition QMYND:MYSQL-UNSUPPORTED-AUTHENTICATION was signalled.
2026-10-10T07:33:41.132000Z LOG report summary reset
       table name     errors       rows      bytes      total time
-----------------  ---------  ---------  ---------  --------------
  fetch meta data          0          0                     0.000s
-----------------  ---------  ---------  ---------  --------------
-----------------  ---------  ---------  ---------  --------------
```

Os dois argumentos são a origem e o destino. `postgresql:///legacy`, sem nada entre as barras,
significa o socket local e o seu próprio papel, a mesma porta que o `psql` usa.

## Primeira: a troca de senha

**`MYSQL-UNSUPPORTED-AUTHENTICATION` é o cliente dentro do pgloader falhando ao entrar.** O MySQL 8
guarda senhas novas com `caching_sha2_password`, e o cliente MySQL embutido neste pgloader só fala o
antigo `mysql_native_password`. Mudar só o usuário não basta, e é bom saber disso antes de gastar
uma hora com o assunto:

```
ana@db:~$ sudo mysql -e "ALTER USER 'migrator'@'localhost' IDENTIFIED WITH mysql_native_password BY 'change-me';"
ana@db:~$ pgloader mysql://migrator:change-me@localhost/legacy postgresql:///legacy 2>&1 | grep ERROR
2026-10-10T07:33:42.164000Z ERROR mysql: Failed to connect to mysql at "localhost" (port 3306) as user "migrator": Condition QMYND:MYSQL-UNSUPPORTED-AUTHENTICATION was signalled.
```

O servidor abre toda conversa propondo o seu método padrão, e este cliente não consegue responder a
uma proposta que não conhece, nem para um usuário cuja senha está guardada do jeito antigo. **O padrão
do servidor também precisa mudar**, num arquivo próprio dentro do diretório de configuração do
MySQL:

```
ana@db:~$ printf '[mysqld]\ndefault_authentication_plugin = mysql_native_password\n' | sudo tee /etc/mysql/mysql.conf.d/pgloader.cnf
[mysqld]
default_authentication_plugin = mysql_native_password
ana@db:~$ sudo systemctl restart mysql
ana@db:~$ pgloader mysql://migrator:change-me@localhost/legacy postgresql:///legacy
2026-10-10T07:33:45.016000Z LOG pgloader version "3.6.7~devel"
2026-10-10T07:33:45.100000Z LOG Migrating from #<MYSQL-CONNECTION mysql://migrator@localhost:3306/legacy {1005DD1A33}>
2026-10-10T07:33:45.100000Z LOG Migrating into #<PGSQL-CONNECTION pgsql://ana@UNIX:5432/legacy {1005F9ECA3}>
2026-10-10T07:33:45.144000Z ERROR mysql: 76 fell through ECASE expression.
       Wanted one of (2 3 4 5 6 8 9 10 11 14 15 17 20 21 23 27 28 30 31 32 33
                      35 41 42 45 46 47 48 49 50 51 52 54 55 56 60 61 62 63 64
                      65 69 72 77 78 79 82 83 87 90 92 93 94 95 96 97 98 101
                      102 103 104 105 106 107 108 109 110 111 112 113 114 115
                      116 117 118 119 120 121 122 123 124 128 129 130 131 132
                      133 134 135 136 137 138 139 140 141 142 143 144 145 146
                      147 148 149 150 151 159 160 161 162 163 164 165 166 167
                      168 169 170 171 172 173 174 175 176 177 178 179 180 181
                      182 183 192 193 194 195 196 197 198 199 200 201 202 203
                      204 205 206 207 208 209 210 211 212 213 214 215 223 224
                      225 226 227 228 229 230 231 232 233 234 235 236 237 238
                      239 240 241 242 243 244 245 246 247 254).
2026-10-10T07:33:45.144000Z LOG report summary reset
       table name     errors       rows      bytes      total time
-----------------  ---------  ---------  ---------  --------------
  fetch meta data          0          0                     0.000s
-----------------  ---------  ---------  ---------  --------------
-----------------  ---------  ---------  ---------  --------------
```

O `mysql_native_password` é o método mais fraco, e o MySQL 8.0 o declara obsoleto; o 8.4 o desliga
por padrão. Use-o para a migração, e **apague o `pgloader.cnf` e remova o usuário `migrator` quando a
migração acabar**.

## Segunda: uma collation de que ele nunca ouviu falar

O login funciona agora, e a próxima falha é mais estranha: `76 fell through ECASE expression`,
seguida de uma lista de números. Toda collation do MySQL tem um número, e o cliente dentro do
pgloader decodifica o texto procurando esse número numa tabela com que foi compilado. **A tabela
termina antes do MySQL 8.** A collation 76 é a `utf8mb3_tolower_ci`, que o MySQL 8.0.30 e posteriores
usam para nomes de coluna no catálogo, então a primeiríssima pergunta do pgloader volta numa
collation que ele não sabe decodificar. O padrão de todas as tabelas aqui, `utf8mb4_0900_ai_ci`, é o
número 255, e também falta na lista.

O pgloader consegue carregar código próprio na partida com `--load-lisp-file`, e isso basta para
ensinar ao cliente os números que faltam. Salve isto como `mysql8.lisp`:

```
;; mysql8.lisp: teach the pgloader in Ubuntu 24.04 the collations of MySQL 8.
;; Load it with: pgloader --load-lisp-file mysql8.lisp ...
;;
;; The MySQL client inside pgloader decodes text by the collation's number,
;; and its table ends before MySQL 8: 76 (utf8mb3_tolower_ci) is in every
;; catalogue query MySQL 8.0.30 and later answers, and 255 and above are the
;; utf8mb4 collations MySQL 8 made the default. All of them are UTF-8.
(in-package :qmynd-impl)

(let ((known (fdefinition 'mysql-cs-coll-to-character-encoding)))
  (setf (fdefinition 'mysql-cs-coll-to-character-encoding)
        (lambda (id)
          (if (or (= id 76) (>= id 255))
              :utf-8
              (funcall known id)))))
```

Ele embrulha a consulta do cliente: os números que o MySQL 8 acrescentou são respondidos como UTF-8,
e todo outro número vai para a tabela original como antes. **É um contorno para uma compilação da
ferramenta**, e está impresso aqui porque foi o que fez esta migração rodar. Um pgloader compilado
com uma versão mais nova do seu cliente MySQL talvez não precise dele; teste a compilação que você
tiver contra o seu servidor do mesmo jeito, com um banco que não faça falta.

## Terceira: os dados

```
ana@db:~$ pgloader --load-lisp-file mysql8.lisp mysql://migrator:change-me@localhost/legacy postgresql:///legacy; echo "exit status $?"
Loading code from #P"mysql8.lisp"
2026-10-10T07:33:45.020000Z LOG pgloader version "3.6.7~devel"
2026-10-10T07:33:45.116000Z LOG Migrating from #<MYSQL-CONNECTION mysql://migrator@localhost:3306/legacy {1005EF41F3}>
2026-10-10T07:33:45.116000Z LOG Migrating into #<PGSQL-CONNECTION pgsql://ana@UNIX:5432/legacy {10060BF153}>
2026-10-10T07:33:45.488001Z ERROR Database error 23502: null value in column "birthdate" of relation "customers" violates not-null constraint
DETAIL: Failing row contains (7, customer7@example.com, Mário Customer 7, t, null, 2024-01-02 06:00:00-03).
CONTEXT: COPY customers, line 7: "7	customer7@example.com	Mário Customer 7	t	\N	2024-01-02 06:00:00"
2026-10-10T07:33:45.700001Z ERROR PostgreSQL Database error 23503: insert or update on table "orders" violates foreign key constraint "orders_customer_fk"
DETAIL: Key (customerid)=(1920) is not present in table "customers".
QUERY: ALTER TABLE legacy.orders ADD CONSTRAINT orders_customer_fk FOREIGN KEY(customerid) REFERENCES legacy.customers(customerid) ON UPDATE NO ACTION ON DELETE NO ACTION
2026-10-10T07:33:45.704001Z LOG report summary reset
             table name     errors       rows      bytes      total time
-----------------------  ---------  ---------  ---------  --------------
        fetch meta data          0          7                     0.084s
         Create Schemas          0          0                     0.004s
       Create SQL Types          0          1                     0.012s
          Create tables          0          4                     0.012s
         Set Table OIDs          0          2                     0.004s
-----------------------  ---------  ---------  ---------  --------------
       legacy.customers          1          0                     0.136s
          legacy.orders          0      10000   297.5 kB          0.132s
-----------------------  ---------  ---------  ---------  --------------
COPY Threads Completion          0          4                     0.136s
 Index Build Completion          0          4                     0.120s
         Create Indexes          0          4                     0.036s
        Reset Sequences          0          2                     0.032s
           Primary Keys          0          2                     0.004s
    Create Foreign Keys          1          0                     0.004s
        Create Triggers          0          0                     0.000s
        Set Search Path          0          1                     0.000s
       Install Comments          0          0                     0.000s
-----------------------  ---------  ---------  ---------  --------------
      Total import time          1      10000   297.5 kB          0.332s
exit status 0
```

Desta vez ele rodou, e **o resumo precisa ser lido linha por linha**. `legacy.orders` copiou todas as
linhas. `legacy.customers` tem um erro e **0 linhas**: a tabela inteira foi recusada, porque o
pgloader copia em lotes, uma linha ruim derruba o lote inteiro, e esta tabela cabe em um só. A
primeira linha `ERROR` diz por quê. Um `BirthDate` zerado virou NULL, que é o padrão do pgloader para
uma data zerada, e a coluna manteve o seu `NOT NULL`. O segundo erro decorre do primeiro: sem
clientes, a chave estrangeira de `orders` não pode ser criada.

**E o código de saída é 0.** Uma tabela inteira faltando, uma chave estrangeira que nunca foi criada,
e o pgloader disse ao shell que tudo correu bem. Um script que o rodasse com `&& echo done` teria
impresso `done`. Leia a coluna `errors` e as contagens de linhas, toda vez, e depois confira o
destino você mesmo, que é a próxima seção.

## A migração como arquivo

Rodar o pgloader pela linha de comando usa os padrões dele para toda decisão. Um **arquivo de carga**
escreve as decisões, que é o que você quer numa migração que vai ensaiar mais de uma vez. Salve isto
como `legacy.load`:

```sql
-- legacy.load: the migration, with its decisions written down.
-- Run it with: pgloader --load-lisp-file mysql8.lisp legacy.load
LOAD DATABASE
     FROM mysql://migrator:change-me@localhost/legacy
     INTO postgresql:///legacy

WITH include drop, create tables, create indexes, reset sequences,
     foreign keys, downcase identifiers

CAST type date when default '0000-00-00'
          to date drop not null drop default using zero-dates-to-null;
```

O `WITH` lista as opções de que esta migração depende, a maioria padrões do pgloader, para que
ninguém precise procurá-las: apagar o que uma tentativa anterior deixou, criar as tabelas e os
índices, levar cada sequence para depois do maior id, criar as chaves estrangeiras e converter todo
nome para minúsculas. **O `CAST` é a decisão que a terceira falha pediu**: uma coluna `date` cujo
padrão é a data zerada vira um `date` que aceita NULL, e cada zero vira NULL. Um `DATETIME` com
padrão zerado já é tratado assim pelas regras do próprio pgloader, e é por isso que `orders`
carregou.

```
ana@db:~$ pgloader --load-lisp-file mysql8.lisp legacy.load > load.log 2>&1; echo "exit status $?"
exit status 0
ana@db:~$ grep -E 'errors|legacy\.' load.log
             table name     errors       rows      bytes      total time
       legacy.customers          0       2001   155.7 kB          0.060s
          legacy.orders          0      10000   297.5 kB          0.056s
```

As duas tabelas, nenhum erro, 2.001 clientes e 10.000 pedidos. É isso que o pgloader diz que fez. A
próxima seção confere.
