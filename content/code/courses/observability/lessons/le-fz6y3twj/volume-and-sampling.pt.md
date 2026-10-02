---
title: Volume, e amostrar as linhas que ninguém lê
version: 1
---

A loja a cinco requisições por segundo é uma loja pequena, e os seus quatro serviços escreveram isto
num minuto:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix --since 60s storefront orders payments mailer | wc -l
1065
ana@obs:~/shop$ docker compose logs --no-log-prefix --since 60s storefront orders payments mailer | wc -c
260212
```

**1065 linhas e 260 KB num minuto**, cerca de 245 bytes por linha. Mantido, isso dá uns 375 MB por
dia, para uma loja que caberia num canto de uma real. E quase tudo são os mesmos quatro eventos:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix --since 60s storefront orders payments mailer | jq -r .message | sort | uniq -c | sort -rn
    273 order stored
    273 checkout finished
    273 charge decided
    258 confirmation sent
```

Quatro mensagens, cada uma escrita uma vez por checkout, e todas um `INFO` dizendo que o checkout
correu normalmente. **As linhas que importam num incidente são uma fatia minúscula do volume**, e o
volume é aquilo de que a fatura da aula 10 é feita.

Há três respostas, na ordem em que recorrer a elas. **Não escreva o que ninguém lê**: uma linha por
passo bem-sucedido é muitas vezes uma linha por requisição a mais, quando o rastro já registra cada
passo e uma métrica os conta. **Escreva uma linha por requisição, com todos os campos dela**, em vez de
uma por passo: o *checkout finished* da vitrine já leva o pedido, o produto e o resultado. E **amostre
o que sobrar**: guarde todo aviso e todo erro, e uma fração do resto. O `sampled.py` faz isso com um
filtro de logging, guardando um `INFO` em dez e todo `WARNING`:

```python
import logging
import random

from common import logs


class OneIn(logging.Filter):
    """Keep every WARNING and above; keep one INFO or DEBUG line in `n`."""

    def __init__(self, n):
        super().__init__()
        self.n = n

    def filter(self, record):
        return record.levelno >= logging.WARNING or random.random() < 1 / self.n


log = logs.setup()
logging.getLogger().handlers[0].addFilter(OneIn(10))
random.seed(1)
for n in range(1000):
    if n % 100 == 99:
        log.warning("payments slow", extra={"fields": {"n": n}})
    else:
        log.info("checkout finished", extra={"fields": {"n": n}})
```

```
ana@obs:~/shop$ docker compose run --rm -e PYTHONPATH=/app sandbox python sampled.py 2>/dev/null | jq -r .level | sort | uniq -c
     95 INFO
     10 WARNING
```

**95 de 990 linhas `INFO` guardadas, e todos os 10 avisos.** A amostra é aleatória, por isso 95 e não
99. Essa é a propriedade a lembrar: um log amostrado serve para *que tipos de coisa acontecem* e *com
que frequência, mais ou menos*, e não serve para *o que aconteceu com o pedido 5011*. É por isso que a
amostragem vem por último, que ela nunca toca nos erros, e que o rastro, amostrado pelas suas próprias
regras na aula 12, leva o id que acha as linhas de uma requisição quando elas foram guardadas.
