---
title: pytest, e um banco para cada teste
version: 1
---

Todas as aulas até aqui conferiram o agenda à mão: curl, um script, uma olhada nas linhas. Isso acha um
problema uma vez. Um **teste** o acha toda vez que alguém muda o código, que é quando os problemas
chegam. Esta aula escreve as conferências das aulas 3 a 13 como testes, com o **pytest**, o executor
que a maioria dos projetos Python usa, e o **pytest-django**, que ensina o Django a ele.

A aula 2 prometeu que o `events/tests.py` vazio daria lugar a um diretório. Apague-o, acrescente os
dois pacotes só para desenvolvimento, e diga ao pytest-django onde estão as configurações, numa tabela
no fim do `pyproject.toml`:

```
ana@vm:~/agenda$ rm events/tests.py
ana@vm:~/agenda$ uv add --dev pytest pytest-django
Resolved 41 packages in 259ms
Downloading pygments (1.2MiB)
 Downloaded pygments
Prepared 5 packages in 145ms
Installed 5 packages in 8ms
 + iniconfig==2.3.1
 + pluggy==1.7.0
 + pygments==2.21.0
 + pytest==9.1.1
 + pytest-django==4.14.0
ana@vm:~/agenda$ sed -n '/^\[tool.pytest/,$p' pyproject.toml
[tool.pytest.ini_options]
DJANGO_SETTINGS_MODULE = "config.settings"
```

Os testes ficam em `~/agenda/tests/`. O que vários testes precisam vai em `tests/conftest.py`, que o
pytest lê primeiro:

```schooling-example
{"language": "python", "file": "tests/conftest.py", "parts": [{"code": "# tests/conftest.py\nfrom datetime import datetime\nfrom zoneinfo import ZoneInfo\n\nimport pytest\nfrom django.contrib.auth.models import Group, Permission, User\n\nfrom events.models import Event\n\nSAO_PAULO = ZoneInfo(\"America/Sao_Paulo\")\n\n\n", "note": "Uma **fixture** é uma função que o pytest chama para montar algo que um teste pede pelo nome. Estas criam as pessoas e os eventos do agenda, novos para cada teste."}, {"code": "@pytest.fixture\ndef ana(db):\n    return User.objects.create_superuser(\"ana\", \"ana@example.org\", \"not-a-real-password\")\n\n\n", "note": "**O `db` é do pytest-django**: pedi-lo dá ao teste acesso ao banco de testes, dentro de uma transação desfeita depois."}, {"code": "@pytest.fixture\ndef bruno(db):\n    organisers = Group.objects.create(name=\"Organisers\")\n    organisers.permissions.add(Permission.objects.get(codename=\"change_event\"))\n    bruno = User.objects.create_user(\"bruno\", \"bruno@example.org\", \"not-a-real-password\", is_staff=True)\n    bruno.groups.add(organisers)\n    return bruno\n\n\n@pytest.fixture\ndef carla(db):\n    return User.objects.create_user(\"carla\", \"carla@example.org\", \"not-a-real-password\")\n\n\n", "note": "O grupo da aula 5 é uma linha no banco de desenvolvimento, não no de testes, então a fixture o cria de novo."}, {"code": "@pytest.fixture\ndef workshop(ana):\n    return Event.objects.create(\n        slug=\"async-workshop\",\n        title=\"Async Python workshop\",\n        starts_at=datetime(2026, 11, 19, 14, 0, tzinfo=SAO_PAULO),\n        venue=\"Public Library, lab 2\",\n        capacity=2,\n        organiser=ana,\n    )\n\n\n@pytest.fixture\ndef dojo(bruno):\n    return Event.objects.create(\n        slug=\"testing-dojo\",\n        title=\"Testing dojo\",\n        starts_at=datetime(2026, 11, 26, 19, 0, tzinfo=SAO_PAULO),\n        venue=\"Community Centre, room 3\",\n        capacity=20,\n        organiser=bruno,\n    )\n", "note": "**Fixtures pedem fixtures.** O `workshop` precisa da `ana` como organizadora, então pedir o workshop cria a ana também. Duas vagas, para que enchê-lo leve duas inscrições."}]}
```

E os primeiros testes, do `register` da aula 4, em `tests/test_services.py`:

```python
# tests/test_services.py
import pytest

from events.services import RegistrationRefused, register


def test_register_saves_a_row(workshop):
    registration = register(workshop.pk, "Carla", "carla@example.org")
    assert registration.event == workshop
    assert workshop.registrations.count() == 1


def test_the_same_address_twice_is_refused(workshop):
    register(workshop.pk, "Carla", "carla@example.org")
    with pytest.raises(RegistrationRefused, match="already registered"):
        register(workshop.pk, "Carla again", "carla@example.org")


def test_a_full_event_refuses(workshop):
    register(workshop.pk, "Carla", "carla@example.org")
    register(workshop.pk, "Davi", "davi@example.org")
    with pytest.raises(RegistrationRefused, match="full"):
        register(workshop.pk, "Elisa", "elisa@example.org")
```

Um teste é uma função cujo nome começa com `test_`; ele passa se retornar, e falha se um `assert` for
falso ou se uma exceção escapar. O `pytest.raises` transforma "isto precisa falhar" em algo que pode
passar:

```
ana@vm:~/agenda$ uv run pytest tests/test_services.py -v
======================================= test session starts ========================================
platform linux -- Python 3.12.3, pytest-9.1.1, pluggy-1.7.0 -- /home/ana/agenda/.venv/bin/python
cachedir: .pytest_cache
django: version: 6.1.2, settings: config.settings (from ini)
rootdir: /home/ana/agenda
configfile: pyproject.toml
plugins: anyio-4.15.1, django-4.14.0
collecting ... collected 3 items

tests/test_services.py::test_register_saves_a_row PASSED                                     [ 33%]
tests/test_services.py::test_the_same_address_twice_is_refused PASSED                        [ 66%]
tests/test_services.py::test_a_full_event_refuses PASSED                                     [100%]

======================================== 3 passed in 1.67s =========================================
```

## Para onde foram as linhas

Nada mudou no banco de desenvolvimento. **O pytest-django cria um banco para a rodada**,
`test_agenda`, aplica as migrações nele, e o destrói no fim, que é o motivo de a aula 4 ter dado à
`ana` o direito de criar bancos. Cada teste então roda dentro de uma transação que é desfeita, então
os três testes acima começaram sem inscrições, fizesse o anterior o que fizesse.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 222\" role=\"img\" aria-label=\"Duas caixas. No pytest-django, a fixture db abre uma transação antes de cada teste e a desfaz depois; os blocos atomic do próprio teste viram savepoints dentro dela. No agenda-api, a fixture session começa uma transação numa conexão e liga a ela uma session com join_transaction_mode create_savepoint, então cada session.commit numa rota só libera um savepoint, e o rollback de fora remove tudo.\"> <text x=\"20\" y=\"26\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pytest-django: db</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"30\" y=\"54\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BEGIN, antes do teste</text> <rect x=\"40\" y=\"64\" width=\"280\" height=\"50\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o teste: fixtures, requisições,</text> <text x=\"180\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">register(), o atomic() dele como savepoint</text> <text x=\"30\" y=\"140\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ROLLBACK, depois dele</text> <text x=\"380\" y=\"26\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">agenda-api: a fixture session</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"390\" y=\"54\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">connection.begin()</text> <rect x=\"400\" y=\"64\" width=\"280\" height=\"50\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o teste: TestClient, rotas,</text> <text x=\"540\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">session.commit() como savepoint</text> <text x=\"390\" y=\"140\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">outer.rollback()</text> <text x=\"360\" y=\"190\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Toda linha que um teste escreve some com a transação de fora,</text> <text x=\"360\" y=\"207\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">então cada teste começa só das fixtures.</text> </svg>", "caption": "O mesmo truque nos dois frameworks: o teste roda dentro de uma transação que nunca tem commit.", "same": ["pytest-django: db"]}
```

O rollback tem uma consequência que vale saber agora: **nada num teste chega a ter commit**, então o
`on_commit` que põe a confirmação na fila nunca dispara, e estes testes não precisaram de Redis. A
seção sobre tarefas trata disso de propósito.
