---
title: De olho na porta
version: 1
---

Um login recusado conta quase nada ao cliente, de propósito. O servidor guarda o motivo no
próprio log, onde só quem o administra consegue ler:

```
ana@lab:~/gov$ sudo grep DETAIL /var/log/postgresql/postgresql-16-gov.log
2026-10-06 23:46:05.049 -03 [9907] bruno@ipe DETAIL:  Connection matched file "/etc/postgresql/16/gov/pg_hba.conf" line 123: "local   all             all                                     peer"
2026-10-06 23:46:05.452 -03 [9992] bruno@ipe DETAIL:  Connection matched file "/etc/postgresql/16/gov/pg_hba.conf" line 4: "host    ipe       all       127.0.0.1/32   scram-sha-256"
2026-10-06 23:46:05.459 -03 [9993] bruno@ipe DETAIL:  Connection matched file "/etc/postgresql/16/gov/pg_hba.conf" line 4: "host    ipe       all       127.0.0.1/32   scram-sha-256"
2026-10-06 23:46:05.513 -03 [10000] nobody@ipe DETAIL:  Role "nobody" does not exist.
2026-10-06 23:46:05.519 -03 [10001] nobody@ipe DETAIL:  Role "nobody" does not exist.
2026-10-06 23:46:05.574 -03 [10008] lia@ipe DETAIL:  User "lia" has an expired password.
2026-10-06 23:46:05.580 -03 [10009] lia@ipe DETAIL:  User "lia" has an expired password.
```

Todas as recusas desta aula até aqui estão ali, cada tentativa pela rede duas vezes, e o cliente
viu quase a mesma frase para todas:

- **A primeira linha é o Bruno no socket**, na seção 7, antes de a Ana trocar o arquivo. Ela bateu
  com a linha 123 do padrão do Ubuntu, a regra `peer`, e o usuário de sistema era outro.
- **A senha errada do Bruno** não tem motivo além da regra que bateu: a linha 4 pediu uma senha,
  e a oferecida não servia.
- **`nobody`** não existe, e o log diz isso com essas palavras.
- **A senha da Lia** expirou: o controle da seção 9 fazendo seu trabalho, registrado.

O detalhe `Connection matched` nomeia a regra do `pg_hba.conf` que decidiu. Quando falha um login
que devia funcionar, é a linha a ler antes de qualquer outra: ela diz qual das suas regras o
servidor acha que se aplica, que muitas vezes não é a que você quis dizer. Para `nobody` e `lia` o
mesmo detalhe também está lá, na linha seguinte à que o `grep` imprimiu.

## Registrando também quem entrou

Falhas entram no log por padrão. Sucessos, não, e um log de quem foi recusado sem um log de quem
entrou responde só metade de qualquer pergunta que alguém fará sobre acesso. Uma configuração
muda isso:

```
ana@lab:~/gov$ sudo -u postgres psql -c "ALTER SYSTEM SET log_connections = on" -c "SELECT pg_reload_conf()"
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

ana@lab:~/gov$ psql -h db.ipe.example -U carla -c "SELECT 1" >/dev/null
ana@lab:~/gov$ sudo tail -n 2 /var/log/postgresql/postgresql-16-gov.log
2026-10-06 23:46:07.779 -03 [10047] carla@ipe LOG:  connection authenticated: identity="carla" method=scram-sha-256 (/etc/postgresql/16/gov/pg_hba.conf:4)
2026-10-06 23:46:07.779 -03 [10047] carla@ipe LOG:  connection authorized: user=carla database=ipe application_name=psql SSL enabled (protocol=TLSv1.3, cipher=TLS_AES_256_GCM_SHA384, bits=256)
```

`ALTER SYSTEM` grava a configuração no `postgresql.auto.conf`, que sobrepõe o arquivo de
configuração principal, e o reload a aplica sem reiniciar. Daí em diante toda conexão deixa duas
linhas: como quem ela se **autenticou**, por qual método e regra, e o que ela foi **autorizada** a
abrir — o banco, o programa que pediu, e se a conexão estava cifrada.

Essa última parte diz `SSL enabled`, com protocolo e cifra. **A sessão da Carla estava cifrada, e
ninguém nesta aula configurou criptografia.** O Ubuntu liga TLS em todo cluster novo com um
certificado gerado na hora — um que nenhum cliente consegue verificar, porque ninguém responde por
ele. A aula 3 parte exatamente dessa linha.

## Para que serve um log da porta

Três perguntas aparecem, cedo ou tarde, e só um log de conexões responde:

- **Alguém está tentando adivinhar?** Dezenas de falhas para um papel num minuto, ou falhas para
  papéis que não existem, vindas de um endereço.
- **Uma conta de serviço está sendo usada por uma pessoa?** `etl_loader` conectando às duas da
  tarde com `application_name=psql` é uma pessoa com a senha do pipeline.
- **A pessoa que saiu ainda entrou?** Uma linha de sucesso para um papel depois da data em que ele
  devia ter parado.

Nenhuma delas precisa de mais que essas linhas e um `grep`. A aula 10 acrescenta a outra metade —
o que uma sessão fez depois de entrar — com o `pgaudit`. Os dois só valem a pena se alguém os ler,
e é por isso que as perguntas são escritas antes do log.
