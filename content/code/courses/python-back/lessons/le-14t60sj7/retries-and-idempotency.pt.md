---
title: Novas tentativas, e rodar duas vezes sem estrago
version: 1
---

Uma tarefa que fala com outro servidor deve tentar de novo, e uma tarefa que tenta de novo precisa
poder rodar mais de uma vez sem estrago, porque vai rodar. As duas coisas começam com a linha
registrando se a confirmação saiu. Acrescente um campo ao `Registration` em `events/models.py`, abaixo
do `created_at`:

```python
    confirmation_sent_at = models.DateTimeField(null=True, blank=True)
```

```
ana@vm:~/agenda$ grep -n 'confirmation_sent_at' events/models.py
33:    confirmation_sent_at = models.DateTimeField(null=True, blank=True)
ana@vm:~/agenda$ uv run python manage.py makemigrations events
Migrations for 'events':
  events/migrations/0004_registration_confirmation_sent_at.py
    + Add field confirmation_sent_at to registration
ana@vm:~/agenda$ uv run python manage.py migrate events
Operations to perform:
  Apply all migrations: events
Running migrations:
  Applying events.0004_registration_confirmation_sent_at... OK
```

Depois a tarefa, reescrita em `events/tasks.py`:

```schooling-example
{"language": "python", "file": "events/tasks.py", "parts": [{"code": "# events/tasks.py\nfrom celery import shared_task\nfrom django.utils import timezone\n\nfrom . import mail\nfrom .models import Registration\n\n\n"}, {"code": "@shared_task(autoretry_for=(OSError,), retry_backoff=True, max_retries=10)\ndef send_confirmation(registration_id):\n    registration = Registration.objects.select_related(\"event\").get(pk=registration_id)\n", "note": "**O `autoretry_for`** transforma essas exceções em novas tentativas; `ConnectionRefusedError` é um `OSError`. **O `retry_backoff`** dobra a espera a cada vez, com variação aleatória, até dez tentativas."}, {"code": "    if registration.confirmation_sent_at is not None:\n        return \"already sent\"\n    mail.confirmation(registration)\n", "note": "**A conferência que torna inofensiva uma segunda execução.** Uma tarefa pode rodar duas vezes: uma nova tentativa depois de um envio que funcionou mas estourou o tempo, ou um worker morto entre o envio e o save."}, {"code": "    registration.confirmation_sent_at = timezone.now()\n    registration.save(update_fields=[\"confirmation_sent_at\"])\n    return \"sent\"\n", "note": "Registre que aconteceu, na mesma linha que a próxima execução lê."}]}
```

Um worker carrega o código quando sobe, então **reinicie o worker** depois de mudar uma tarefa; o
servidor de desenvolvimento se recarrega sozinho, o worker não. Com o servidor de e-mail ainda parado,
inscreva a Joana, e suba o servidor de e-mail de novo alguns segundos depois. O terminal do worker:

```
[2026-10-22 21:18:48,031: INFO/MainProcess] Task events.tasks.send_confirmation[0363cbd1-7594-4da3-b60b-63cf9c83fb8f] received
[2026-10-22 21:18:48,059: INFO/MainProcess] Task events.tasks.send_confirmation[0363cbd1-7594-4da3-b60b-63cf9c83fb8f] received
[2026-10-22 21:18:48,061: INFO/ForkPoolWorker-1] Task events.tasks.send_confirmation[0363cbd1-7594-4da3-b60b-63cf9c83fb8f] retry: Retry in 0s: ConnectionRefusedError(111, 'Connection refused')
[2026-10-22 21:18:48,079: INFO/MainProcess] Task events.tasks.send_confirmation[0363cbd1-7594-4da3-b60b-63cf9c83fb8f] received
[2026-10-22 21:18:48,081: INFO/ForkPoolWorker-4] Task events.tasks.send_confirmation[0363cbd1-7594-4da3-b60b-63cf9c83fb8f] retry: Retry in 2s: ConnectionRefusedError(111, 'Connection refused')
[2026-10-22 21:18:50,084: INFO/MainProcess] Task events.tasks.send_confirmation[0363cbd1-7594-4da3-b60b-63cf9c83fb8f] received
[2026-10-22 21:18:50,085: INFO/ForkPoolWorker-1] Task events.tasks.send_confirmation[0363cbd1-7594-4da3-b60b-63cf9c83fb8f] retry: Retry in 3s: ConnectionRefusedError(111, 'Connection refused')
[2026-10-22 21:18:53,093: INFO/MainProcess] Task events.tasks.send_confirmation[0363cbd1-7594-4da3-b60b-63cf9c83fb8f] received
[2026-10-22 21:18:53,093: INFO/ForkPoolWorker-1] Task events.tasks.send_confirmation[0363cbd1-7594-4da3-b60b-63cf9c83fb8f] retry: Retry in 3s: ConnectionRefusedError(111, 'Connection refused')
[2026-10-22 21:18:56,118: INFO/ForkPoolWorker-1] Task events.tasks.send_confirmation[0363cbd1-7594-4da3-b60b-63cf9c83fb8f] succeeded in 0.02377533399976528s: 'sent'
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Uma linha do tempo da confirmação da Joana: 4 tentativas recusadas pelo servidor de e-mail parado, em intervalos crescentes, e então uma que deu certo 8,1 segundos depois da primeira, quando o servidor de e-mail voltou.\"> <path d=\"M60 110 L660 110\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path> <circle cx=\"60.0\" cy=\"110\" r=\"7\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\"></circle> <text x=\"60.0\" y=\"136\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.0 s</text> <circle cx=\"61.5\" cy=\"110\" r=\"7\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\"></circle> <text x=\"61.5\" y=\"152\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.0 s</text> <circle cx=\"210.7\" cy=\"110\" r=\"7\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\"></circle> <text x=\"210.7\" y=\"136\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2.0 s</text> <circle cx=\"434.7\" cy=\"110\" r=\"7\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\"></circle> <text x=\"434.7\" y=\"152\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5.0 s</text> <circle cx=\"660.0\" cy=\"110\" r=\"7\" fill=\"var(--phosphor)\" fill-opacity=\"0.35\" stroke=\"var(--phosphor)\"></circle> <text x=\"660.0\" y=\"136\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8.1 s</text> <text x=\"60\" y=\"70\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">recusada: tentar depois</text> <text x=\"660\" y=\"70\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">enviada</text> <text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Cada tentativa da confirmação da Joana, em segundos depois da primeira, lida do log do worker.</text> </svg>", "caption": "O retry_backoff espaça as tentativas, com variação aleatória, para que um servidor fora do ar não seja martelado enquanto volta."}
```

Toda tentativa é a mesma tarefa, com o mesmo id, mandada de volta ao Redis para esperar a vez; a
última encontrou o servidor de e-mail de pé. Sem o backoff, dez tentativas teriam sido gastas em um
segundo.

## Rodando duas vezes

Chame direto a função da tarefa, como uma segunda entrega faria:

```
ana@vm:~/agenda$ uv run python manage.py shell -v 0 -c "from events.models import Registration; from events.tasks import send_confirmation; joana = Registration.objects.get(name='Joana'); print(joana.confirmation_sent_at); print(send_confirmation(joana.pk))"
2026-10-23 00:18:56.112136+00:00
already sent
```

**`already sent`**: a segunda execução leu a linha e parou. Isso é **idempotência**, uma operação que
pode ser repetida sem repetir o efeito, e é o que torna seguro tentar de novo. O Celery promete que uma
tarefa roda **pelo menos uma vez**, não exatamente uma, então toda tarefa com efeito fora do banco
precisa de uma conferência como esta.

Ela não é perfeita: um worker morto depois de o e-mail sair e antes do `save()` ainda manda duas vezes.
Fechar essa brecha de vez exige que o outro lado elimine duplicatas, como gateways de pagamento fazem
com uma chave de idempotência. Para um e-mail de confirmação, uma duplicata rara é um preço justo.
