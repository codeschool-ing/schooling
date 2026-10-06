---
title: Contadores e rótulos
version: 1
---

Um sistema de métricas como o Prometheus não lê spans. Ele coleta **contadores**: números que só sobem,
cada um com um conjunto de **rótulos** (*labels*), e calcula taxas pela velocidade com que sobem. O
`exposition.py` conta as respostas da mesma semana num contador e o imprime no formato de texto do
Prometheus, que é o que uma coleta receberia:

```python
"""exposition.py: the same replies as the counters a metrics system scrapes, in Prometheus's text format."""
from prometheus_client import CollectorRegistry, Counter, disable_created_metrics, generate_latest

import replies

disable_created_metrics()   # a counter's creation time is now, not the week's: leave it out
registry = CollectorRegistry()
answers = Counter("assistant_replies", "Customer replies, by what kind of reply they were.",
                  ["feature", "release", "outcome"], registry=registry)
for r in replies.week():
    answers.labels(r["feature"], r["release"], "refused" if r["refused"] else "answered").inc()
print(generate_latest(registry).decode(), end="")
```

```
ana@lab:~/obs$ python exposition.py
# HELP assistant_replies_total Customer replies, by what kind of reply they were.
# TYPE assistant_replies_total counter
assistant_replies_total{feature="help",outcome="refused",release="2026.09.4"} 114.0
assistant_replies_total{feature="help",outcome="answered",release="2026.09.4"} 481.0
assistant_replies_total{feature="order",outcome="answered",release="2026.09.4"} 123.0
assistant_replies_total{feature="order",outcome="refused",release="2026.09.4"} 71.0
assistant_replies_total{feature="order",outcome="answered",release="2026.10.1"} 37.0
assistant_replies_total{feature="help",outcome="refused",release="2026.10.1"} 99.0
assistant_replies_total{feature="help",outcome="answered",release="2026.10.1"} 232.0
assistant_replies_total{feature="order",outcome="refused",release="2026.10.1"} 64.0
```

Os rótulos são as dimensões pelas quais as aulas 3 e 5 dividiram tudo: funcionalidade, versão,
resultado. Um painel divide uma série por outra para desenhar a parcela de recusas por funcionalidade e
por versão, e as perguntas de pedido na 2026.10.1 dão 64 recusadas de 101, o "quase duas em três" que a
aula 5 achou.

**O que nunca é rótulo** importa tanto quanto. Cada combinação distinta de rótulos é uma série separada
que o sistema de métricas guarda por todo o tempo que guarda qualquer coisa, então um rótulo com muitos
valores multiplica o custo de tudo:

- **Nunca o usuário ou a sessão.** Milhares de valores, e dados pessoais num sistema que as regras da
  aula 2 nunca alcançaram.
- **Nunca a pergunta ou a resposta.** Valores sem limite, e as palavras dos clientes.
- **Nunca um id de trace.** Uma série por requisição é um armazenamento de traces mal feito.

Isso pertence aos traces, onde a aula 1 os pôs. O contador diz quantos, o rótulo diz de que tipo, e o
trace diz qual, com um link do painel para os traces por trás de um ponto dele.

As séries `_created` que esta versão do cliente acrescenta por padrão estão desligadas no script: elas
guardam a hora em que cada contador foi criado, que aqui é o momento em que o script rodou, não algo sobre
a semana.
