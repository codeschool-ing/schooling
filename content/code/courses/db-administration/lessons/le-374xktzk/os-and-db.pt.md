---
title: Onde o sistema operacional e o banco se encontram
version: 1
---

As duas listas da primeira seção se encontram num lugar só: **o momento em que uma conexão é
aceita**. O `pg_hba.conf` decide como o servidor verifica quem está batendo, e para uma conexão
pelo socket local o arquivo do Ubuntu diz `peer`. A autenticação peer pergunta ao kernel qual
usuário do sistema operacional abriu o socket e deixa esse usuário entrar **como o papel de mesmo
nome, e só esse**. Depois desse momento o usuário do sistema é esquecido; tudo dentro da sessão é o
papel.

Então o peer é o motivo de o `psql` no shell da `ana` cair no papel `ana`, e o motivo de isto ser
recusado:

```
ana@db:~$ psql -U bruno shop
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "bruno"
```

A máquina não tem um `bruno` com quem fazer peer, e não deve ganhar um só para um teste conseguir
entrar. O peer tem uma opção exatamente para esse caso: um **mapa**, guardado no `pg_ident.conf`,
que lista quais usuários do sistema podem conectar como quais papéis. Com um mapa, a `ana` consegue
fazer login como `bruno` do jeito que o próprio `bruno` faria, e o teste que o `SET ROLE` não
conseguia fazer fica possível.

A lição 5 lê o `pg_hba.conf` linha por linha. Aqui você muda uma palavra de uma linha, e a põe de
volta no fim da seção.

## Mudando os arquivos, com caminho de volta

Copie os dois arquivos primeiro. **O `-p` mantém o dono**, e isso importa: um `sudo cp` simples faz
a cópia pertencer ao `root`, e se essa cópia um dia voltar para o lugar, o servidor, que roda como
`postgres`, não consegue mais ler a própria configuração.

```
ana@db:~$ sudo cp -p /etc/postgresql/16/main/pg_hba.conf /etc/postgresql/16/main/pg_hba.conf.orig
ana@db:~$ sudo cp -p /etc/postgresql/16/main/pg_ident.conf /etc/postgresql/16/main/pg_ident.conf.orig
```

Abra o `pg_hba.conf` com `sudo nano` e encontre a linha das conexões locais de todo mundo, a que diz
`local all all peer`. Acrescente `map=shop` no fim dela. Depois abra o `pg_ident.conf` do mesmo jeito
e acrescente estas linhas no final:

```conf
# pg_ident.conf: the operating-system user ana may connect as ana, bruno or reporting
shop            ana                     ana
shop            ana                     bruno
shop            ana                     reporting
```

As colunas são o nome do mapa, o usuário do sistema e o papel. **A primeira linha importa tanto
quanto as outras**: quando há um mapa na linha, a comparação simples de nomes do peer para, e sem o
`ana ana` você teria se trancado fora do seu próprio papel. A linha acima da editada é do usuário
`postgres` do sistema e não tem mapa, então o `sudo -u postgres psql` continua funcionando mesmo que
você erre algo aqui, e é por isso que o Ubuntu a entrega como uma linha separada.

Antes de recarregar, pergunte ao servidor o que ele vai ler. Os dois arquivos têm uma visão que lê o
arquivo **como está no disco agora** e aponta na coluna `error` qualquer linha que não consegue usar:

```
ana@db:~$ sudo grep -n '^local' /etc/postgresql/16/main/pg_hba.conf
118:local   all             postgres                                peer
123:local   all             all                                     peer map=shop
130:local   replication     all                                     peer
shop=# SELECT map_name, sys_name, pg_username, error FROM pg_ident_file_mappings;
 map_name | sys_name | pg_username | error 
----------+----------+-------------+-------
 shop     | ana      | ana         | 
 shop     | ana      | bruno       | 
 shop     | ana      | reporting   | 
(3 rows)

shop=# SELECT line_number, user_name, auth_method, options, error FROM pg_hba_file_rules WHERE type = 'local';
 line_number | user_name  | auth_method |  options   | error 
-------------+------------+-------------+------------+-------
         118 | {postgres} | peer        |            | 
         123 | {all}      | peer        | {map=shop} | 
         130 | {all}      | peer        |            | 
(3 rows)

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

Sem erros, então a recarga era segura. Uma recarga com um `pg_hba.conf` quebrado mantém as regras
antigas e avisa no log, e as novas conexões continuam sendo julgadas por um arquivo que você acha
que substituiu.

## Fazendo login como outra pessoa

O mapa permite que a `ana` seja `reporting`, e o servidor recusa mesmo assim:

```
ana@db:~$ psql -U reporting shop
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "reporting" is not permitted to log in
ana@db:~$ psql -U bruno shop
shop=> SELECT current_user, session_user;
 current_user | session_user 
--------------+--------------
 bruno        | bruno
(1 row)

shop=> SELECT count(*) FROM customers;
 count 
-------
 50000
(1 row)

shop=> SET ROLE reporting;
ERROR:  permission denied to set role "reporting"
```

Duas verificações, em dois lugares. **O `pg_hba.conf` e o mapa decidiram que a `ana` pode tentar ser
`reporting`; a falta de `LOGIN` no papel decidiu que ela não pode.** A autenticação diz quem você é
e os atributos do papel dizem se essa identidade pode abrir uma sessão, e é por isso que o `NOLOGIN`
vale até contra um mapa que cita o papel.

Como `bruno`, os dois usuários agora são `bruno`. Ele lê `customers` pelo privilégio herdado, e o
`SET ROLE reporting` é recusado, porque desta vez o usuário da sessão é o `bruno` e a participação
dele não tem a opção `SET`. Esse é o teste que a seção anterior não conseguia fazer da sessão da
`ana`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 276\" role=\"img\" aria-label=\"Dois usuários do sistema operacional à esquerda, postgres e ana, e quatro papéis do banco à direita, postgres, ana, bruno e reporting. Entre eles fica a porta, o pg_hba.conf com o pg_ident.conf. As setas mostram quem pode conectar como quem: postgres como postgres e ana como ana, por nomes iguais; com o mapa chamado shop, a ana também como bruno e como reporting, e a seta para reporting é tracejada porque o papel não tem LOGIN e a conexão é recusada.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"90\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">usuários do sistema</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a porta</text><text x=\"630\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">papéis do banco</text><rect x=\"285\" y=\"66\" width=\"150\" height=\"196\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">pg_hba.conf</text><text x=\"360\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">+ pg_ident.conf</text><rect x=\"40\" y=\"96\" width=\"100\" height=\"28\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">postgres</text><rect x=\"40\" y=\"186\" width=\"100\" height=\"28\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ana</text><rect x=\"580\" y=\"76\" width=\"100\" height=\"28\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">postgres</text><rect x=\"580\" y=\"126\" width=\"100\" height=\"28\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ana</text><rect x=\"580\" y=\"176\" width=\"100\" height=\"28\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">bruno</text><rect x=\"580\" y=\"226\" width=\"100\" height=\"28\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">reporting</text><line x1=\"140\" y1=\"110\" x2=\"578\" y2=\"90\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"140\" y1=\"200\" x2=\"578\" y2=\"140\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"140\" y1=\"200\" x2=\"578\" y2=\"190\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"140\" y1=\"200\" x2=\"578\" y2=\"240\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\" marker-end=\"url(#arr)\"></line><text x=\"470\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mesmo nome: peer</text><text x=\"470\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">recusado: sem LOGIN</text><text x=\"360\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">map=shop</text></svg>", "caption": "As duas listas só se encontram na porta. O peer junta nomes iguais; um mapa acrescenta os pares que lista; o papel ainda decide se pode fazer login."}
```

Um mapa é uma linha poderosa para deixar num arquivo. **Todo papel da direita fica alcançável pelo
usuário do sistema da esquerda, sem senha.** Numa máquina em que mais de uma pessoa faz login, um
mapa é uma concessão de identidade e merece a revisão que um `GRANT` recebe.

## Pondo de volta

Mova as cópias de volta, confira que o dono continua `postgres`, recarregue e confirme que a porta
fechou de novo:

```
ana@db:~$ sudo mv /etc/postgresql/16/main/pg_hba.conf.orig /etc/postgresql/16/main/pg_hba.conf
ana@db:~$ sudo mv /etc/postgresql/16/main/pg_ident.conf.orig /etc/postgresql/16/main/pg_ident.conf
ana@db:~$ sudo ls -l /etc/postgresql/16/main/pg_hba.conf /etc/postgresql/16/main/pg_ident.conf
-rw-r----- 1 postgres postgres 5924 Oct 10 03:18 /etc/postgresql/16/main/pg_hba.conf
-rw-r----- 1 postgres postgres 2640 Oct 10 03:18 /etc/postgresql/16/main/pg_ident.conf
ana@db:~$ psql -c "SELECT pg_reload_conf();"
 pg_reload_conf 
----------------
 t
(1 row)

ana@db:~$ psql -U bruno shop
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "bruno"
```

E desfaça os dois experimentos da seção anterior, para que a participação do `bruno` volte aos
padrões e o `reporting` não tenha nenhum privilégio em que a lição 12 tropece:

```
shop=# REVOKE SELECT ON customers FROM reporting;
REVOKE

shop=# GRANT reporting TO bruno WITH SET TRUE;
GRANT ROLE
```
