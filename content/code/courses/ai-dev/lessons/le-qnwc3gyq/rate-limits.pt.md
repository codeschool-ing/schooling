---
title: Limites de taxa
version: 2
---

Todo provedor limita quanto uma conta pode pedir: requisições por minuto, tokens por minuto e,
muitas vezes, tokens por dia. Os números dependem do nível da conta e do modelo, e ficam no console
do provedor. **O que importa ao código é o que acontece no limite**: o provedor responde 429 e diz
quando tentar de novo.

Um 429 precisa de uma conta, e esta aula não gasta nada, então ele é descrito aqui em vez de
mostrado. **A resposta de um provedor traz a contagem antes de o limite chegar**: os cabeçalhos da
Anthropic incluem `anthropic-ratelimit-requests-remaining` e `anthropic-ratelimit-tokens-remaining`,
e a requisição que passa do limite recebe 429 com um cabeçalho `retry-after`, o número de segundos a
esperar. Os outros provedores mandam a mesma informação com nomes próprios. O SDK lança o 429 como
`RateLimitError`, depois das próprias repetições, que a seção 05 mede.

A sua própria máquina também tem um limite, e não é uma contagem por minuto. Cinco perguntas mandadas
no mesmo instante:

```python
"""Five requests at the same moment, and when each one is answered."""
import time
from concurrent.futures import ThreadPoolExecutor

import anthropic

model = anthropic.Anthropic()
t0 = time.monotonic()


def ask(n):
    model.messages.create(model="llama3.2:3b", max_tokens=20,
                          messages=[{"role": "user", "content": "Say hello in five words."}])
    return n, time.monotonic() - t0


with ThreadPoolExecutor(5) as pool:
    for n, seconds in pool.map(ask, range(1, 6)):
        print(f"request {n}: answered after {seconds:.1f} s")
```

```
ana@dev:~/shop$ python burst.py
request 1: answered after 3.7 s
request 2: answered after 1.2 s
request 3: answered after 1.9 s
request 4: answered after 2.7 s
request 5: answered after 4.3 s
```

**Cinco respostas, com uns oito décimos de segundo entre uma e outra**, numa ordem que ninguém
escolheu: a segunda requisição foi respondida primeiro e a quinta por último. O Ollama responde uma
pergunta de cada vez nesta máquina, e as outras esperam a vez. O modelo nunca roda mais rápido por ser
chamado mais vezes; forma-se uma fila, e a última pessoa nela espera a resposta de todo mundo. O
limite de um provedor e o da sua máquina são os dois motivos para pôr uma fila sua na frente do
modelo, onde você decide quem espera.

## O que fazer com um 429

- **Espere o que o `retry-after` diz**, não menos. Repetir antes só rende outro 429.
- **Leia a contagem restante antes de chegar a zero.** Um job em lote que vê `remaining: 1` pode
  desacelerar em vez de falhar.
- **Divida o limite de propósito.** Uma chave serve a todo usuário da aplicação. Uma fila na frente
  do modelo, com limite por usuário, impede o pico de um usuário de gastar o minuto de todos.
- **Peça mais quando os números pedirem.** Os limites sobem com o uso e com um pedido ao provedor.
  Um projeto que só funciona num nível mais alto precisa saber qual nível e como chegar lá.
