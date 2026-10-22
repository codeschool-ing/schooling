---
title: Um lock para todos os workers
version: 1
---

A rota de inscrição, do `app/main.py`:

```python
    event = session.scalar(select(Event).where(Event.slug == slug).with_for_update())
    if event is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, f"No event called {slug}")
    taken = session.scalar(
        select(func.count()).select_from(Registration).where(Registration.event_id == event.id)
    )
    if taken >= event.capacity:
        raise HTTPException(status.HTTP_409_CONFLICT, "This event is full.")
    row = Registration(event=event, **registration.model_dump())
    session.add(row)
    try:
        session.commit()
    except IntegrityError:
        raise HTTPException(status.HTTP_409_CONFLICT, "This address is already registered.")
    return row
```

**O `with_for_update()` é `SELECT … FOR UPDATE`**, o mesmo lock que o `select_for_update()` do Django
pegou na aula 4. Qualquer outra transação que peça a mesma linha com `FOR UPDATE` espera até esta dar
commit, então a contagem e o insert acontecem sem ninguém no meio. A contagem roda no SQL, e o
endereço repetido **fica com a restrição de unicidade**: conferir antes e inserir depois são dois passos
entre os quais outra requisição cabe, enquanto a restrição recusa dentro do próprio insert.

```
ana@vm:~/agenda-api$ curl -s -X POST http://127.0.0.1:8001/events/django-night/registrations -H 'Content-Type: application/json' -d '{"name": "Bruno", "email": "bruno@example.org"}'; echo
{"name":"Bruno","email":"bruno@example.org","created_at":"2026-10-22T20:14:47.154897-03:00"}
ana@vm:~/agenda-api$ curl -s -X POST http://127.0.0.1:8001/events/django-night/registrations -H 'Content-Type: application/json' -d '{"name": "Bruno", "email": "bruno@example.org"}'; echo
{"detail":"This address is already registered."}
```

A recusa da restrição chegou como `IntegrityError`, que a rota transformou num 409. Agora o
`crowd.py`, vinte inscrições de uma vez contra os quatro workers. Salve em `~/agenda-api`:

```python
# crowd.py
import asyncio
import sys

import httpx2


async def main(url):
    async with httpx2.AsyncClient(timeout=60) as client:
        answers = await asyncio.gather(
            *(client.post(url, json={"name": f"Person {i}", "email": f"p{i}@example.org"}) for i in range(20))
        )
    codes = [a.status_code for a in answers]
    print(codes.count(201), "registered,", codes.count(409), "refused")


asyncio.run(main(sys.argv[1]))
```

```
ana@vm:~/agenda-api$ uv run python crowd.py http://127.0.0.1:8001/events/async-workshop/registrations
12 registered, 8 refused
ana@vm:~/agenda-api$ psql agenda_api -c "select e.slug, count(r.id) from events e left join registrations r on r.event_id = e.id group by e.slug order by e.slug"
      slug      | count 
----------------+-------
 async-workshop |    12
 django-night   |     1
 testing-dojo   |     0
(3 rows)
```

**Doze dentro, oito recusadas, doze linhas.**

## Sem o lock

Para ver o que o lock faz, tire o `.with_for_update()` daquela linha, suba a API de novo e mande a
multidão três vezes, esvaziando o workshop entre as rodadas:

```
ana@vm:~/agenda-api$ grep -n "Event.slug == slug" app/main.py
61:    event = session.scalar(select(Event).where(Event.slug == slug))
ana@vm:~/agenda-api$ psql agenda_api -c "delete from registrations where email like 'p%@example.org'"
DELETE 12
ana@vm:~/agenda-api$ for round in 1 2 3; do uv run python crowd.py http://127.0.0.1:8001/events/async-workshop/registrations; psql agenda_api -qc "delete from registrations where email like 'p%@example.org'"; done
20 registered, 0 refused
19 registered, 1 refused
18 registered, 2 refused
```

**Vinte, dezenove e dezoito inscrições para doze vagas**, um número diferente a cada rodada, e nenhum
erro. Toda requisição contou antes de as outras terem dado commit em número suficiente. Outra máquina
vai dar outros números, e algumas rodadas podem até sair certas, que é como uma corrida chega à
produção: ela passa no teste que alguém rodou uma vez.

O `threading.Lock` da aula 8 não teria impedido isso. Ele mora num processo, e são quatro, cada um com
o seu. **O lock de linha mora no banco, onde os quatro olham**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"O crowd.py manda vinte inscrições de uma vez. O Uvicorn as espalha por quatro processos worker, do 552 ao 555, como o log dele mostrou. Todo worker pede ao PostgreSQL a linha do async-workshop FOR UPDATE, e só uma transação segura esse lock por vez.\"> <defs><marker id=\"wk-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"70\" width=\"120\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"80\" y=\"96\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">crowd.py</text> <text x=\"80\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20 POSTs de uma vez</text> <rect x=\"210\" y=\"20\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"290\" y=\"41\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">worker 552</text> <path d=\"M140 102 L204 37\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#wk-a)\"></path> <path d=\"M370 37 L444 72\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#wk-a)\"></path> <rect x=\"210\" y=\"64\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"290\" y=\"85\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">worker 553</text> <path d=\"M140 102 L204 81\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#wk-a)\"></path> <path d=\"M370 81 L444 92\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#wk-a)\"></path> <rect x=\"210\" y=\"108\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"290\" y=\"129\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">worker 554</text> <path d=\"M140 102 L204 125\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#wk-a)\"></path> <path d=\"M370 125 L444 112\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#wk-a)\"></path> <rect x=\"210\" y=\"152\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"290\" y=\"173\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">worker 555</text> <path d=\"M140 102 L204 169\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#wk-a)\"></path> <path d=\"M370 169 L444 132\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#wk-a)\"></path> <rect x=\"450\" y=\"60\" width=\"250\" height=\"84\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"575\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">PostgreSQL</text> <text x=\"575\" y=\"104\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">events row async-workshop</text> <text x=\"575\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">FOR UPDATE: um dono por vez</text> <text x=\"360\" y=\"206\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Um threading.Lock mora num processo. O lock de linha mora onde os quatro olham.</text> </svg>", "caption": "Quatro processos, um lock. Com ele, doze entraram em toda rodada; sem ele, entre dezoito e vinte.", "same": ["PostgreSQL"]}
```

Com a linha de volta como era:

```
ana@vm:~/agenda-api$ grep -n "Event.slug == slug" app/main.py
61:    event = session.scalar(select(Event).where(Event.slug == slug).with_for_update())
ana@vm:~/agenda-api$ uv run python crowd.py http://127.0.0.1:8001/events/async-workshop/registrations
12 registered, 8 refused
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/events/async-workshop; echo
{"slug":"async-workshop","title":"Async Python workshop","starts_at":"2026-11-19T14:00:00-03:00","venue":"Public Library, lab 2","capacity":12,"description":"","taken":12}
```

O workshop está cheio de novo, com o número certo dentro.

## O que ele custa

Um lock faz as inscrições de **um evento** esperarem na fila; inscrições para outros eventos pegam
outras linhas e nunca esperam umas pelas outras. A espera dura até o `commit`, então mantenha curta a
parte com lock: nenhuma chamada a parceiro e nenhum cálculo lento entre o `SELECT … FOR UPDATE` e o
commit. Ler um evento, o que toda listagem faz, não pega lock nenhum.
