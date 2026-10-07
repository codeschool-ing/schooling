---
title: Fazendo o servidor exigir
version: 1
---

`verify-full` protege um cliente que o pede. Um cliente que não pede — um script antigo, uma
ferramenta de BI com uma caixinha que ninguém marcou, o notebook de um colega com o `prefer`
padrão — ainda consegue conectar em texto claro, porque o servidor deixa. A metade do servidor
está no `pg_hba.conf`, que tem dois tipos de conexão que a aula 1 não usou: **`hostssl`** casa só
conexões cifradas, e **`hostnossl`** só as não cifradas.

```conf
# TYPE     DATABASE  USER        ADDRESS        METHOD
local      all       postgres                   peer
local      ipe       ana                        peer
hostnossl  all       all         all            reject
hostssl    ipe       etl_loader  127.0.0.1/32   cert
hostssl    ipe       all         127.0.0.1/32   scram-sha-256
host       all       all         all            reject
```

Lido de cima para baixo, como o servidor lê:

- as linhas do socket não mudam — um socket local nunca atravessa uma rede;
- **toda conexão sem TLS é recusada**, nominalmente, antes de qualquer outra coisa;
- `etl_loader` com TLS faz login por **certificado** em vez de senha — a próxima seção;
- todos os outros com TLS usam SCRAM, como antes;
- a última linha recusa o que sobrar.

```
ana@lab:~/gov$ sudo install -o postgres -g postgres -m 640 pg_hba.conf /etc/postgresql/16/gov/
ana@lab:~/gov$ sudo -u postgres psql -c "SELECT pg_reload_conf()" >/dev/null
ana@lab:~/gov$ psql "service=bruno sslmode=disable" -c "SELECT 1"
psql: error: connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: FATAL:  pg_hba.conf rejects connection for host "127.0.0.1", user "bruno", database "ipe", no encryption
```

A conexão em texto claro que funcionou na seção 4 é recusada, e o log vai dizer `no encryption`
ao lado. **Essa linha do `pg_hba.conf` é o que faz da criptografia em trânsito uma política e não
um hábito**: ela deixa de depender de todo cliente estar bem configurado.

## O que ela não faz

Ela exige criptografia; não consegue exigir que o cliente tenha *conferido* o certificado do
servidor. Um cliente com `sslmode=require` conecta por TLS, satisfaz o `hostssl` e ainda confia em
qualquer certificado que receba. Conferir o servidor continua sendo trabalho do cliente, e o lugar
de torná-lo padrão é onde os clientes são configurados: um arquivo de serviço, uma string de
conexão num cofre de segredos, as configurações de uma ferramenta de BI. Uma revisão de uma
plataforma de dados pede para ver esses, não só o servidor.

O servidor pode, porém, exigir um certificado **do cliente**, e para um programa que conecta toda
noite sem ninguém olhando, essa é a escolha mais forte.
