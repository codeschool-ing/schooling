---
title: O handler, e a duplicata a que ele precisa sobreviver
version: 1
---

Um handler do Cloud Tasks é um endpoint HTTP comum com duas obrigações. **Ele responde 2xx só quando
o trabalho está feito, e faz o trabalho no máximo uma vez, por mais vezes que seja chamado.** A
primeira é como a fila sabe que pode parar; a segunda é porque a fila promete pelo menos uma
entrega, exatamente como o Pub/Sub na lição 18.

## O mailer

O mailer da loja recebe o pedido, manda a confirmação e guarda o nome da tarefa para que uma segunda
entrega não mande nada. **Crie `~/gcp/mailer` e salve isto como `main.py` dentro dela:**

```schooling-example
{"language": "python", "file": "main.py", "parts": [{"code": "import sqlite3\n\nfrom flask import Flask, request\n\napp = Flask(__name__)\ndb = sqlite3.connect('sent.db', check_same_thread=False)\ndb.execute('create table if not exists sent (task text primary key)')\n\n\n", "note": "Uma aplicação Flask e um banco SQLite pequeno ao lado, com uma tabela só: os nomes das tarefas já feitas. No Google Cloud essa tabela moraria num banco de verdade, porque o disco de uma instância não sobrevive a ela."}, {"code": "@app.post('/send')\ndef send():\n    task = request.headers.get('X-CloudTasks-TaskName', '')\n    retry = request.headers.get('X-CloudTasks-TaskRetryCount', '0')\n    order = request.get_json()\n", "note": "O Cloud Tasks dá nome a cada tarefa e conta as repetições dela, e manda os dois como cabeçalhos. O corpo é o que a tarefa levava ao ser criada; aqui, o pedido."}, {"code": "    if not task:\n        return 'not a Cloud Tasks request\\n', 400\n", "note": "Uma requisição sem nome de tarefa não veio de uma fila, e é recusada. No Google Cloud a verificação mais forte é o token de identidade que a fila pode anexar, conferido antes de tudo."}, {"code": "    if db.execute('select 1 from sent where task = ?', (task,)).fetchone():\n        return f'task {task} already done, nothing sent\\n', 200\n", "note": "A verificação de idempotência. Uma tarefa que já está na tabela recebe sucesso e nada é enviado, então uma entrega duplicada não custa nada."}, {"code": "    if order['email'].endswith('@down.example'):\n        return f'mail provider unavailable, attempt {int(retry) + 1}\\n', 503\n", "note": "Uma falha que vale repetir: o provedor de e-mail caiu. Um 503 diz à fila para tentar de novo mais tarde, e a contagem de repetições mostra qual tentativa era."}, {"code": "    print(f'confirmation for order {order[\"order\"]} to {order[\"email\"]}', flush=True)\n    with db:\n        db.execute('insert into sent values (?)', (task,))\n    return f'task {task} done\\n', 200\n", "note": "O trabalho, depois o registro dele. Entre os dois ainda há uma janela em que uma queda mandaria o e-mail duas vezes, e é por isso que a tabela é consultada antes de enviar e gravada logo depois."}]}
```

Ele imprime a confirmação em vez de mandá-la; um de verdade chamaria um provedor de e-mail ali.
Inicie-o no segundo terminal com o gunicorn, como na lição 19:

```
ana@laptop:~/gcp/mailer$ gunicorn -b :8082 main:app
[2026-10-30 15:42:19 -0300] [11242] [INFO] Starting gunicorn 26.2.0
[2026-10-30 15:42:19 -0300] [11242] [INFO] Listening at: http://0.0.0.0:8082 (11242)
[2026-10-30 15:42:19 -0300] [11242] [INFO] Using worker: sync
[2026-10-30 15:42:19 -0300] [11246] [INFO] Booting worker with pid: 11246
[2026-10-30 15:42:19 -0300] [11242] [INFO] Control socket listening at /home/ana/.gunicorn/gunicorn.ctl
```

## O curl no lugar da fila

Nada no seu laptop despacha tarefas do Cloud Tasks, então **o curl faz o papel da fila**: ele manda a
requisição que uma tarefa faria, com os cabeçalhos que o Google documenta que o Cloud Tasks
acrescenta a todo despacho. É o curl, não o Cloud Tasks; os nomes e o pedido são inventados para a
loja. A primeira entrega de uma tarefa, depois a mesma tarefa de novo, como uma repetição depois de
uma resposta perdida a traria:

```
ana@laptop:~/gcp/mailer$ curl -s -w '%{http_code}\n' localhost:8082/send -H 'X-CloudTasks-QueueName: emails' -H 'X-CloudTasks-TaskName: order-1042-confirmation' -H 'X-CloudTasks-TaskRetryCount: 0' -H 'content-type: application/json' -d '{"order": 1042, "email": "ana@example.com"}'
task order-1042-confirmation done
200
ana@laptop:~/gcp/mailer$ curl -s -w '%{http_code}\n' localhost:8082/send -H 'X-CloudTasks-QueueName: emails' -H 'X-CloudTasks-TaskName: order-1042-confirmation' -H 'X-CloudTasks-TaskRetryCount: 1' -H 'content-type: application/json' -d '{"order": 1042, "email": "ana@example.com"}'
task order-1042-confirmation already done, nothing sent
200
```

A segunda chamada recebeu sucesso e **não mandou nada**, que é exatamente o que a fila precisa: um
2xx encerra as repetições, e a tabela segurou a duplicata. Abaixo das linhas de partida, o terminal
do mailer mostra uma confirmação, não duas:

```
confirmation for order 1042 to ana@example.com
```

Depois uma tarefa cujo provedor está fora do ar, entregue duas vezes com a contagem de repetições
subindo, e uma requisição sem nome de tarefa nenhum:

```
ana@laptop:~/gcp/mailer$ curl -s -w '%{http_code}\n' localhost:8082/send -H 'X-CloudTasks-QueueName: emails' -H 'X-CloudTasks-TaskName: order-1043-confirmation' -H 'X-CloudTasks-TaskRetryCount: 0' -H 'content-type: application/json' -d '{"order": 1043, "email": "bo@down.example"}'
mail provider unavailable, attempt 1
503
ana@laptop:~/gcp/mailer$ curl -s -w '%{http_code}\n' localhost:8082/send -H 'X-CloudTasks-QueueName: emails' -H 'X-CloudTasks-TaskName: order-1043-confirmation' -H 'X-CloudTasks-TaskRetryCount: 1' -H 'content-type: application/json' -d '{"order": 1043, "email": "bo@down.example"}'
mail provider unavailable, attempt 2
503
ana@laptop:~/gcp/mailer$ curl -s -w '%{http_code}\n' localhost:8082/send -H 'content-type: application/json' -d '{"order": 1044, "email": "cy@example.com"}'
not a Cloud Tasks request
400
```

**Os 503 são falhas que a fila vai repetir**, com as esperas que a seção 04 calcula; o número da
tentativa vem do cabeçalho que a fila define. O 400 é a recusa de algo que não veio de uma fila, e
publicado você verificaria o token de identidade em vez de um cabeçalho que qualquer um digita.

Pare o gunicorn com Ctrl+C quando terminar.
