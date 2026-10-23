---
title: Testando tarefas sem broker
version: 1
---

Uma tarefa do Celery é uma função com um `.delay()` pendurado. Isso divide os testes dela em dois:
**que a tarefa certa entra na fila no momento certo**, e **que a função faz a coisa certa** quando roda.
Nenhum dos dois precisa de Redis nem de worker. O `tests/test_tasks.py`:

```schooling-example
{"language": "python", "file": "tests/test_tasks.py", "parts": [{"code": "# tests/test_tasks.py\nfrom events.models import Registration\nfrom events.services import register\nfrom events.tasks import send_confirmation\n\n\n"}, {"code": "def test_registering_queues_the_confirmation_after_commit(\n    workshop, monkeypatch, django_capture_on_commit_callbacks\n):\n    queued = []\n    monkeypatch.setattr(send_confirmation, \"delay\", queued.append)\n", "note": "**Nada de Redis num teste.** O `monkeypatch` troca o `delay`, só para este teste, pelo `append` de uma lista, e põe o original de volta depois."}, {"code": "    with django_capture_on_commit_callbacks(execute=True):\n        registration = register(workshop.pk, \"Carla\", \"carla@example.org\")\n        assert queued == []\n    assert queued == [registration.pk]\n\n\n", "note": "Dentro da transação do teste nada chega a ter commit, então o `on_commit` nunca dispararia. Esta fixture junta os callbacks e, com `execute=True`, os roda quando o bloco termina: **nada na fila antes, um id depois**."}, {"code": "def test_the_confirmation_is_sent_once(workshop, mailoutbox):\n    registration = Registration.objects.create(event=workshop, name=\"Carla\", email=\"carla@example.org\")\n    assert send_confirmation(registration.pk) == \"sent\"\n    assert send_confirmation(registration.pk) == \"already sent\"\n    assert len(mailoutbox) == 1\n    assert mailoutbox[0].to == [\"carla@example.org\"]\n    assert mailoutbox[0].subject == \"You are registered for Async Python workshop\"\n", "note": "A tarefa é uma função; chamá-la a roda aqui, de forma síncrona. O `mailoutbox` é a lista que o backend de e-mail de teste do Django preenche em vez de mandar."}]}
```

```
ana@vm:~/agenda$ uv run pytest tests/test_tasks.py -v
======================================= test session starts ========================================
platform linux -- Python 3.12.3, pytest-9.1.1, pluggy-1.7.0 -- /home/ana/agenda/.venv/bin/python
cachedir: .pytest_cache
django: version: 6.1.2, settings: config.settings (from ini)
rootdir: /home/ana/agenda
configfile: pyproject.toml
plugins: anyio-4.15.1, django-4.14.0
collecting ... collected 2 items

tests/test_tasks.py::test_registering_queues_the_confirmation_after_commit PASSED            [ 50%]
tests/test_tasks.py::test_the_confirmation_is_sent_once PASSED                               [100%]

======================================== 2 passed in 1.07s =========================================
```

O primeiro teste é o motivo de o `register` usar `on_commit`, escrito: o id entra na fila depois do
commit e não antes. O segundo é a idempotência da aula 13: duas chamadas, uma mensagem na caixa de
saída, endereçada à Carla, com o título do evento no assunto. **A preparação de testes do Django troca o
que o `MAILERS` disser por um backend em memória** durante a rodada inteira, então nenhum teste consegue
mandar um e-mail de verdade por acidente.

Com isso, o agenda tem dezessete testes, e a suíte inteira leva poucos segundos:

```
ana@vm:~/agenda$ uv run pytest
======================================= test session starts ========================================
platform linux -- Python 3.12.3, pytest-9.1.1, pluggy-1.7.0
django: version: 6.1.2, settings: config.settings (from ini)
rootdir: /home/ana/agenda
configfile: pyproject.toml
plugins: anyio-4.15.1, django-4.14.0
collected 17 items

tests/test_api.py ........                                                                   [ 47%]
tests/test_pages.py ....                                                                     [ 70%]
tests/test_services.py ...                                                                   [ 88%]
tests/test_tasks.py ..                                                                       [100%]

======================================== 17 passed in 8.65s ========================================
```

## O que estes testes não conferem

Eles conferem o código do agenda contra as decisões do agenda. Não conferem se o Redis está rodando, se
um worker está inscrito na fila certa, ou se o servidor de e-mail aceita as mensagens: esses são fatos
de uma implantação, e as conferências de um servidor rodando, na aula 16, são o lugar deles. Existe uma
configuração `CELERY_TASK_ALWAYS_EAGER` que roda todo `.delay()` na hora; ela esconde quando uma tarefa
entra na fila, que é exatamente o que o primeiro teste acima está ali para conferir.
