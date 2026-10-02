---
title: Níveis, e quem decide quais são escritos
version: 1
---

Um nível diz quanto um evento importa, e é a primeira coisa usada para decidir o que é escrito. Os
cinco do Python, que são os mesmos cinco em quase todo lugar com nomes um pouco diferentes:

| nível | para que serve | na loja |
|---|---|---|
| `DEBUG` | detalhe para quem está desenvolvendo este código | desligado em produção |
| `INFO` | um evento normal que vale um registro | *checkout finished*, *order stored* |
| `WARNING` | algo inesperado que o serviço contornou | *rabbitmq not reachable, retrying* |
| `ERROR` | uma operação falhou | *orders unreachable* |
| `CRITICAL` | o próprio serviço não consegue continuar | nenhum até agora |

O `levels.py` registra um evento em cada um dos quatro primeiros, pelo formatador da loja:

```python
import logging
import os

from common import logs

log = logs.setup()
log.debug("cache lookup", extra={"fields": {"key": "price:kettle"}})
log.info("checkout finished", extra={"fields": {"order_id": 7}})
log.warning("payments slow", extra={"fields": {"took_ms": 1500}})
log.error("payments unreachable", extra={"fields": {"attempt": 3}})
```

Rodado três vezes com um `LOG_LEVEL` diferente no ambiente:

```
ana@obs:~/shop$ docker compose run --rm -e PYTHONPATH=/app sandbox python levels.py 2>/dev/null | jq -c '{level, message}'
{"level":"INFO","message":"checkout finished"}
{"level":"WARNING","message":"payments slow"}
{"level":"ERROR","message":"payments unreachable"}
ana@obs:~/shop$ docker compose run --rm -e PYTHONPATH=/app -e LOG_LEVEL=DEBUG sandbox python levels.py 2>/dev/null | jq -c '{level, message}'
{"level":"DEBUG","message":"cache lookup"}
{"level":"INFO","message":"checkout finished"}
{"level":"WARNING","message":"payments slow"}
{"level":"ERROR","message":"payments unreachable"}
ana@obs:~/shop$ docker compose run --rm -e PYTHONPATH=/app -e LOG_LEVEL=ERROR sandbox python levels.py 2>/dev/null | jq -c '{level, message}'
{"level":"ERROR","message":"payments unreachable"}
```

**O nível definido é um piso**: `INFO` escreve INFO e tudo acima, e `DEBUG` acrescenta a consulta
ao cache. `ERROR` deixa uma linha. O código não mudou entre as três execuções; o ambiente mudou. É
isso que permite a um serviço em apuros ficar mais falante sem uma nova versão, e voltar ao normal
quando a causa é achada.

Dois hábitos mantêm os níveis úteis. **Um `ERROR` deveria querer dizer que alguém talvez precise
fazer algo.** Um cartão recusado não é erro do serviço. É um resultado normal registrado em `INFO`,
exatamente como a aula 2 deixou em paz o status de um span num `404`. E **`WARNING` é para o que o
serviço sobreviveu**, uma nova tentativa ou um plano B. Se ninguém jamais agiria sobre um aviso, ele
é um `INFO` falando mais alto.
