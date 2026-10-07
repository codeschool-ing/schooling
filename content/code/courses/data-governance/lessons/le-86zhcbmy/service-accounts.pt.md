---
title: Pessoas saem, programas se multiplicam
version: 1
---

Um login é criado no primeiro dia de alguém. Esta seção trata do que acontece com ele no último,
e com os logins que não pertencem a pessoa nenhuma.

## Uma conta com data de fim

Lia era estagiária. O contrato dela terminou em 30 de junho, e o papel dela foi criado sabendo
disso: `VALID UNTIL '2026-06-30'`. Depois dessa data a senha para de funcionar, quer alguém se
lembre de fazer algo, quer não:

```
ana@lab:~/gov$ psql -h db.ipe.example -U lia -c "SELECT 1"
psql: error: connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: FATAL:  password authentication failed for user "lia"
password retrieved from file "/home/ana/.pgpass"
connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: FATAL:  password authentication failed for user "lia"
password retrieved from file "/home/ana/.pgpass"
```

O cliente só fica sabendo que a autenticação falhou — a mesma resposta de uma senha errada, pelo
motivo que a seção anterior deu. A linha `password retrieved from file` é a libpq contando à Ana
de onde veio a senha que ela tentou, que é a primeira coisa a conferir quando um login que
funcionava ontem não funciona hoje.

**Uma data de expiração é o controle mais barato desta aula e o que mais falta.** Revisões de
acesso acontecem a cada trimestre, quando acontecem; o fim de um contrato é conhecido no primeiro
dia. Escrevê-lo no papel faz com que o resultado padrão de esquecer seja o acesso acabar.

Não é a resposta inteira, porém. `VALID UNTIL` expira a *senha*: um papel que loga por `peer` ou
por certificado não é afetado, e o papel, as permissões dele e tudo o que ele é dono continuam
lá. O desligamento completo são três comandos. A aula 2 os executa, quando a Lia já tiver
permissões a perder:

```sql
ALTER ROLE lia NOLOGIN;            -- no new sessions, by any method
REASSIGN OWNED BY lia TO ipe_owner; -- anything she created now has an owner who stays
DROP OWNED BY lia;                 -- and every privilege granted to her goes
```

## Logins que são programas

Dois dos seis papéis não são pessoas. `site_app` é o site e `etl_loader` é o pipeline noturno.
Eles se chamam **contas de serviço**, e as regras para elas são outras porque os riscos são
outros:

- **Ninguém digita a senha delas, então ela pode ser longa e aleatória**, e deve ser. Ela mora num
  cofre de segredos ou num ambiente que o programa lê, nunca no código — a aula 4 guarda uma num
  servidor de gestão de chaves.
- **Elas devem poder fazer exatamente o que o programa faz, e nada mais.** O site insere pedidos e
  lê produtos; não tem motivo para ler `health.prescriptions` em massa. A aula 2 constrói isso.
- **Elas devem ser limitadas em quanto fazem ao mesmo tempo.** Um programa com bug pode abrir
  conexões em loop, e cada conexão custa memória ao servidor.

Esse último é um atributo, e a Ana o definiu ao criar o papel:

```
ana@lab:~/gov$ for i in 1 2 3; do psql -h db.ipe.example -U site_app -c "SELECT pg_sleep(2)" >/dev/null & done; sleep 1; psql -h db.ipe.example -U site_app -c "SELECT 1"; wait
psql: error: connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: FATAL:  too many connections for role "site_app"
```

Três conexões já estavam abertas, cada uma dormindo dois segundos; a quarta foi recusada. Um
vazamento no site agora derruba os logins do próprio site, e não o banco que todo mundo usa. O
limite cabe numa conta de serviço, não numa pessoa: uma pessoa que abre uma quarta janela não é
defeito.

**Uma conta de serviço por programa, nunca uma compartilhada por vários.** Quando o pipeline
noturno e uma ferramenta de relatório dividem o `etl_loader`, uma enxurrada de conexões, uma
consulta lenta ou uma leitura estranha no log tem dois donos possíveis, e a investigação começa
descobrindo qual.
