---
title: sslmode, ou o que o cliente aceita
version: 1
---

Se uma conexão é cifrada, e se o cliente confere quem respondeu, é decidido pelo **cliente**, numa
configuração só: `sslmode`. O servidor pode exigir TLS (a seção 6 faz isso), mas só o cliente pode
exigir conferir o certificado.

A entrada de serviço do Bruno não diz nada sobre isso, então o psql usa o padrão, `prefer`. Pedir
nada também é permitido:

```
ana@lab:~/gov$ psql "service=bruno sslmode=disable" -c "SELECT ssl FROM pg_stat_ssl WHERE pid = pg_backend_pid()"
 ssl 
-----
 f
(1 row)
```

**O servidor aceitou uma conexão em texto claro**, porque nada no `pg_hba.conf` recusa uma: uma
linha `host` bate com as duas. Essa é a primeira lacuna. A segunda está no próprio padrão:

| sslmode | cifra | confere o certificado | se o TLS não estiver disponível |
|---|---|---|---|
| `disable` | não | — | texto claro |
| `allow` | só se o servidor exigir | não | texto claro |
| `prefer` (o padrão) | se o servidor oferecer | não | **texto claro, em silêncio** |
| `require` | sim | não | recusa |
| `verify-ca` | sim | que uma CA confiável o assinou | recusa |
| `verify-full` | sim | que uma CA confiável o assinou **para este nome de host** | recusa |

**`prefer` é uma palavra para ler com cuidado.** Ela quer dizer: tente TLS, e se falhar por
qualquer motivo, tente de novo sem ele e não diga nada. A aula 1 viu isso acontecer: toda senha
errada foi recusada duas vezes, uma com criptografia e outra sem, porque o cliente recuou depois
da primeira recusa. Quem consegue interferir na conexão pode fazer a primeira tentativa falhar de
propósito, e o `prefer` vai lhe entregar a segunda. `require` fecha isso e ainda confia em qualquer
certificado; **`verify-full` é o único modo seguro contra alguém no meio.**

Pedi-lo hoje falha, por um motivo que o cliente soletra:

```
ana@lab:~/gov$ psql "service=bruno sslmode=verify-full" -c "SELECT 1"
psql: error: connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: root certificate file "/home/ana/.postgresql/root.crt" does not exist
Either provide the file, use the system's trusted roots with sslrootcert=system, or change sslmode to disable server certificate verification.
```

`verify-full` precisa saber em quais autoridades certificadoras confiar, e por padrão as procura
em `~/.postgresql/root.crt`. Esse arquivo não existe, e mesmo que existisse, o certificado
snakeoil não é assinado por autoridade nenhuma para pôr nele. O conserto tem duas metades: o
servidor precisa de um certificado assinado por uma autoridade, e o cliente precisa do certificado
dessa autoridade. A próxima seção faz as duas.

A mensagem também oferece `sslrootcert=system`, disponível desde o PostgreSQL 16: confiar na lista
de autoridades públicas do próprio sistema operacional. Isso está certo para um banco gerenciado
numa nuvem, cujo certificado é assinado por uma CA pública. O laboratório da Ipê usa uma privada,
então o cliente a recebe explicitamente.
