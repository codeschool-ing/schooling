---
title: pg_hba.conf, linha por linha
version: 1
---

A lição 3 encontrou duas recusas: uma conexão pelo socket como alguém que você não é, e uma
conexão pela rede sem senha. As duas vieram de um arquivo, o `pg_hba.conf`, cujo nome quer dizer
autenticação baseada em host. **Ele decide quem pode conectar, de onde, a qual banco, e como prova
quem é**, e faz isso com uma lista curta lida a partir do topo, em que a primeira linha que casa
com uma conexão é a única que conta.

## As sete linhas

Como o `postgresql.conf`, ele é quase todo comentário, e só o `postgres` pode lê-lo:

```
ana@db:~$ sudo grep -n -Ev '^\s*(#|$)' /etc/postgresql/16/main/pg_hba.conf
118:local   all             postgres                                peer
123:local   all             all                                     peer
125:host    all             all             127.0.0.1/32            scram-sha-256
127:host    all             all             ::1/128                 scram-sha-256
130:local   replication     all                                     peer
131:host    replication     all             127.0.0.1/32            scram-sha-256
132:host    replication     all             ::1/128                 scram-sha-256
```

O `-n` manteve os números das linhas, que importam: o servidor os cita no log. Aqui estão as
mesmas linhas com o que cada uma faz:

```schooling-example
{"language": "conf", "file": "/etc/postgresql/16/main/pg_hba.conf", "parts": [{"code": "local   all             postgres                                peer", "note": "Linha 118. Pelo socket, o papel `postgres` entra quando o usuário do sistema operacional também é `postgres`, que é do que o `sudo -u postgres psql` depende. O comentário acima dela no arquivo diz para não desativá-la: as tarefas de manutenção do Ubuntu conectam assim."}, {"code": "# TYPE  DATABASE        USER            ADDRESS                 METHOD", "note": "O cabeçalho das colunas, do próprio arquivo, algumas linhas abaixo da primeira regra. Uma linha tem o tipo de conexão, o banco, o papel, um endereço para os tipos de rede e o método que decide se o cliente merece crédito. A conexão é comparada com as linhas a partir do topo, e a primeira linha cujas quatro colunas batem decide; nada abaixo dela é lido."}, {"code": "local   all             all                                     peer", "note": "Linha 123, a regra que a lição 3 encontrou. `local` é o socket, `all` e `all` batem com qualquer banco e qualquer papel, e `peer` pergunta ao kernel qual usuário está do outro lado e só o admite como o papel de mesmo nome. Nada é digitado: o sistema operacional já respondeu por você."}, {"code": "host    all             all             127.0.0.1/32            scram-sha-256", "note": "Linha 125. `host` é TCP, criptografado ou não, vindo do endereço único `127.0.0.1`, porque o `/32` mantém os 32 bits. `scram-sha-256` pede a senha do papel por meio de um desafio, de modo que a senha nunca atravessa a conexão. Um papel sem senha, como o seu, nunca passa por ela."}, {"code": "host    all             all             ::1/128                 scram-sha-256", "note": "Linha 127, a mesma regra para o endereço de loopback do IPv6. O `-h localhost` pode chegar por qualquer um dos dois, e uma máquina que responde nos dois precisa das duas linhas."}, {"code": "local   replication     all                                     peer\nhost    replication     all             127.0.0.1/32            scram-sha-256\nhost    replication     all             ::1/128                 scram-sha-256", "note": "Linhas 130 a 132. `replication` aqui não é nome de banco, e sim uma palavra-chave para as conexões que um standby faz para copiar o log de escrita antecipada, que a lição 11 de db-reliability monta. O `all` na coluna do banco não as inclui."}]}
```

**Não há passagem para a linha seguinte.** Uma conexão que casa com uma linha e depois falha no
método é recusada; o servidor não tenta a próxima linha. E uma conexão com que nenhuma linha casa
também é recusada, com uma mensagem própria. As duas recusas parecem iguais para quem está
conectando e são problemas diferentes, como o resto desta seção mostra.

Existem outros métodos, e vale reconhecê-los. O `trust` admite quem casar sem perguntar nada, e
não tem lugar num servidor que outra pessoa alcance. O `reject` recusa quem casar, o que é útil
acima de uma linha mais ampla para abrir uma exceção. O `md5` é o método de senha mais antigo que
o `scram-sha-256` substituiu. O `cert` pede um certificado do cliente. A lição 11 volta ao `peer`
com um mapa que deixa um usuário do sistema operacional entrar como um papel de outro nome.

## A leitura que o próprio servidor faz do arquivo

A view `pg_hba_file_rules` é o arquivo como o servidor o interpreta, e tem uma coluna `error`
como a do `pg_file_settings`:

```
ana@db:~$ psql
ana=# SELECT line_number, type, database, user_name, address, auth_method
ana-#   FROM pg_hba_file_rules;
 line_number | type  |   database    | user_name  |  address  |  auth_method  
-------------+-------+---------------+------------+-----------+---------------
         118 | local | {all}         | {postgres} |           | peer
         123 | local | {all}         | {all}      |           | peer
         125 | host  | {all}         | {all}      | 127.0.0.1 | scram-sha-256
         127 | host  | {all}         | {all}      | ::1       | scram-sha-256
         130 | local | {replication} | {all}      |           | peer
         131 | host  | {replication} | {all}      | 127.0.0.1 | scram-sha-256
         132 | host  | {replication} | {all}      | ::1       | scram-sha-256
(7 rows)

ana=# \q
```

Ela lê o arquivo no disco, não as regras em vigor, então é a conferência a fazer **depois de uma
edição e antes do reload**. Uma linha com erro aparece ali com o erro, e um reload com um
`pg_hba.conf` quebrado mantém as regras antigas, assim como um `postgresql.conf` quebrado mantém
os valores antigos.

## Uma recusa, e o que só o log sabe

Conecte por TCP com uma senha errada. O `PGPASSWORD` entrega ao `psql` uma senha sem perguntar.
Isso serve para uma senha feita para falhar, e é um hábito a evitar com uma senha de verdade, que
acabaria no histórico do seu shell; a lição 11 define senhas de verdade do jeito certo.

```
ana@db:~$ PGPASSWORD=not-my-password psql -h 127.0.0.1
psql: error: connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "ana"
connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "ana"
ana@db:~$ sudo tail -n 3 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:42:07.082 -03 [366] ana@ana FATAL:  password authentication failed for user "ana"
2026-10-10 04:42:07.082 -03 [366] ana@ana DETAIL:  User "ana" has no password assigned.
	Connection matched file "/etc/postgresql/16/main/pg_hba.conf" line 125: "host    all             all             127.0.0.1/32            scram-sha-256"
```

O `psql` tentou duas vezes, uma com criptografia e outra sem, porque o arquivo do servidor tem
`ssl = on` e o padrão do cliente é preferir criptografia e aceitar ficar sem; as duas tentativas
encontraram a mesma regra. Aí o log diz o que o cliente não ficou sabendo: **o motivo real, e a
linha que casou**. Um cliente que digita a senha errada e um cliente cujo papel não tem senha
nenhuma recebem a mesma frase de propósito, para que um estranho não descubra quais papéis existem.
O administrador lê o `DETAIL`.

## Mudando uma linha

Abra o arquivo com `sudo nano /etc/postgresql/16/main/pg_hba.conf` e mude a linha 125 para que o
TCP desta máquina alcance só o banco `shop`: troque o primeiro `all` por `shop`, mantendo as
colunas alinhadas. O `pg_hba.conf` é lido num reload como o resto da configuração, então dê reload
e tente os dois bancos:

```
ana@db:~$ sudo sed -n 125p /etc/postgresql/16/main/pg_hba.conf
host    shop            all             127.0.0.1/32            scram-sha-256
ana@db:~$ sudo systemctl reload postgresql
ana@db:~$ PGPASSWORD=not-my-password psql -h 127.0.0.1
psql: error: connection to server at "127.0.0.1", port 5432 failed: FATAL:  no pg_hba.conf entry for host "127.0.0.1", user "ana", database "ana", SSL encryption
connection to server at "127.0.0.1", port 5432 failed: FATAL:  no pg_hba.conf entry for host "127.0.0.1", user "ana", database "ana", no encryption
ana@db:~$ sudo tail -n 1 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:42:08.528 -03 [394] ana@ana FATAL:  no pg_hba.conf entry for host "127.0.0.1", user "ana", database "ana", no encryption
ana@db:~$ PGPASSWORD=not-my-password psql -h 127.0.0.1 shop
psql: error: connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "ana"
connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "ana"
```

A conexão ao `ana` agora não casa com linha nenhuma: `no pg_hba.conf entry`, seguido das quatro
coisas que o servidor comparou, **o endereço, o papel, o banco e a criptografia**. Cada uma é uma
coluna do arquivo, e ler a mensagem diante do arquivo mostra qual faltou. A conexão ao `shop`
continua casando com a linha 125, chega até a senha e falha ali.

Essa mensagem é a que você mais vai encontrar como administrador. Uma aplicação numa máquina
nova, um papel que ninguém acrescentou, um banco renomeado: cada um a produz, e os quatro valores
dela dizem que linha falta.

**Mudanças valem só para conexões novas.** Sessões já abertas continuam conectadas com a regra que
as admitiu. Ponha a linha de volta como estava e dê reload de novo:

```
ana@db:~$ sudo sed -n 125p /etc/postgresql/16/main/pg_hba.conf
host    shop            all             127.0.0.1/32            scram-sha-256
ana@db:~$ sudo systemctl reload postgresql
```

**A ordem é o que conferir quando uma linha nova parece não fazer nada.** Uma linha acrescentada
no fim do arquivo, abaixo de uma regra mais ampla que já casa com as mesmas conexões, nunca é
alcançada: a regra mais ampla decide antes. Regras estreitas vão acima das largas, e linhas
`reject` acima da regra para a qual abrem exceção.
