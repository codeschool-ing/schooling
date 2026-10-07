---
title: Chaves que vencem juntas
version: 1
---

Os estouros até aqui foram de uma chave. Uma versão mais silenciosa envolve milhares: **chaves gravadas
no mesmo instante, com o mesmo tempo de vida, vencem no mesmo instante**. Um script de aquecimento
depois de um deploy, um job noturno, um cache reabastecido depois de um reinício; cinco minutos depois
todas erram juntas, e o banco vê cada uma dessas consultas no mesmo segundo.

A correção é fazê-las parar de concordar: somar um número aleatório de segundos a cada tempo de vida, o
que se chama **jitter**. Este programa grava mil chaves de uma vez, primeiro com 300 segundos fixos e
depois com 300 mais até 60, e conta os segundos em que elas vão vencer:

```schooling-example
{"language": "python", "file": "jitter.py", "parts": [{"code": "import random\nfrom collections import Counter\n\nimport redis\n\nr = redis.Redis(decode_responses=True)\nrandom.seed(7)\n\nfor name, ttl in ((\"fixed\", lambda: 300), (\"jittered\", lambda: 300 + random.randint(0, 60))):\n    with r.pipeline() as pipe:\n        for i in range(1000):\n            pipe.set(f\"{name}:book:{i}\", \"x\", ex=ttl())\n        pipe.execute()\n    with r.pipeline() as pipe:\n        for i in range(1000):\n            pipe.ttl(f\"{name}:book:{i}\")\n        per_second = Counter(pipe.execute())\n    print(f\"{name:>8}: different expiry seconds: {len(per_second):>2}, most keys expiring in one second: {max(per_second.values())}\")\n", "note": "Mil chaves com tempo de vida fixo, depois com jitter, e em quantos segundos elas vencem."}]}
```

```
ana@web:~/work$ python3 jitter.py
   fixed: different expiry seconds:  1, most keys expiring in one second: 1000
jittered: different expiry seconds: 61, most keys expiring in one second: 27
```

**Fixo, as mil chaves vencem num segundo só.** Com jitter, elas se espalham por 61 segundos e no máximo
27 vencem em qualquer um deles. O banco vê as mesmas consultas no fim, mas como um minuto de carga leve
em vez de um único segundo de carga pesada, e a pergunta da aula 10 sobre quão velho um valor pode ser
continua respondida, agora como "de cinco a seis minutos".

O jitter custa uma linha, e pertence a **todo tempo de vida que muitas chaves compartilham**. Ele não faz
nada por uma chave popular sozinha, que é para isso que servem as outras seções.
