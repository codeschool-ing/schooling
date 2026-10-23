---
title: Quando o Redis falha
version: 1
---

A fila de tarefas tirou o servidor de e-mail da requisição e **pôs o Redis nela**. Pare o Redis, como
uma queda faria:

```
ana@vm:~/agenda$ sudo systemctl stop redis-server
```

As últimas linhas do terminal do worker:

```
Trying again in 2.00 seconds... (1/100)

[2026-10-22 21:19:40,890: ERROR/MainProcess] consumer: Cannot connect to redis://127.0.0.1:6379/0: Error 111 connecting to 127.0.0.1:6379. Connection refused..
Trying again in 4.00 seconds... (2/100)
```

**O worker sobrevive** e se reconecta com pausas crescentes, até cem tentativas. O lado web tem menos
paciência. Inscreva o Kai:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/events/testing-dojo/registrations/ -H 'Content-Type: application/json' -d '{"name": "Kai", "email": "kai@example.org"}' -o /dev/null -w '%{http_code}\n'
500
ana@vm:~/agenda$ psql agenda -c "select name, confirmation_sent_at from events_registration where name = 'Kai'"
 name | confirmation_sent_at 
------+----------------------
 Kai  | 
(1 row)
```

**A primeira falha desta aula, de novo**: o Kai teve commit, a resposta é 500, e nenhuma tarefa foi
para a fila. O `on_commit` roda a função depois do commit, e uma exceção ali escapa para a requisição.
O Django sabe contê-la: **`robust=True`** registra a exceção no log em vez de levantá-la.

```
ana@vm:~/agenda$ grep -n 'on_commit' events/services.py
20:        transaction.on_commit(lambda: send_confirmation.delay(registration.pk), robust=True)
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/events/testing-dojo/registrations/ -H 'Content-Type: application/json' -d '{"name": "Lia", "email": "lia@example.org"}' -w ' %{http_code}\n'
{"name":"Lia","email":"lia@example.org","created_at":"2026-10-22T21:19:48.061381-03:00"} 201
```

**201 para a Lia**, e a primeira linha do que o servidor de desenvolvimento imprimiu:

```
Error calling register.<locals>.<lambda> in on_commit() during transaction (Error 111 connecting to 127.0.0.1:6379. Connection refused.).
```

A Lia está inscrita e a tarefa dela nunca entrou na fila. Suba o Redis de novo, e o worker se
reconecta:

```
ana@vm:~/agenda$ sudo systemctl start redis-server
[2026-10-22 21:19:50,896: INFO/MainProcess] Connected to redis://127.0.0.1:6379/0
[2026-10-22 21:19:50,898: INFO/MainProcess] mingle: searching for neighbors
[2026-10-22 21:19:51,903: INFO/MainProcess] mingle: all alone
```

## As falhas que você vai encontrar

| sintoma | causa | conserto |
|---|---|---|
| `Cannot connect to redis://...: Connection refused` no worker | o Redis não está rodando | `sudo systemctl start redis-server`; o worker se reconecta sozinho |
| um 500 de uma view que põe uma tarefa na fila | o Redis estava fora quando o `.delay()` rodou | `robust=True`, e uma varredura para o que se perdeu (próxima seção) |
| `Received unregistered task of type 'events.tasks...'` | o worker subiu antes de a tarefa existir, ou não importa o módulo | reinicie o worker; confira a lista `[tasks]` na faixa de abertura |
| `Object of type Registration is not JSON serializable` | uma instância de model passada ao `.delay()` | passe o id |
| a tarefa não faz nada de novo depois de uma edição | o worker roda o código com que subiu | reinicie o worker |

As duas primeiras são desta seção. As três últimas não foram produzidas para este curso; as mensagens
são as que o Celery e o kombu imprimem para essas causas.
