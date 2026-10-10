---
title: Contadores e rótulos
version: 2
---

Um sistema de métricas como o Prometheus não lê spans. Ele coleta **contadores**: números que só sobem,
cada um com um conjunto de **rótulos**, e calcula taxas a partir de quão rápido eles sobem. O
`exposition.py` conta as respostas da mesma semana num contador e o imprime no formato de texto do
Prometheus, que é o que uma coleta receberia. A biblioteca dele, `prometheus-client`, entrou no ambiente
com o Phoenix na aula 7; se você pulou essa aula, instale-a:

```sh
pip install prometheus-client==0.26.0
```

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
ana@dev:~/obs$ python exposition.py
# HELP assistant_replies_total Customer replies, by what kind of reply they were.
# TYPE assistant_replies_total counter
assistant_replies_total{feature="order",outcome="answered",release="2026.09.4"} 23.0
assistant_replies_total{feature="help",outcome="answered",release="2026.09.4"} 80.0
assistant_replies_total{feature="help",outcome="refused",release="2026.09.4"} 22.0
assistant_replies_total{feature="order",outcome="refused",release="2026.09.4"} 9.0
assistant_replies_total{feature="help",outcome="answered",release="2026.10.1"} 63.0
assistant_replies_total{feature="help",outcome="refused",release="2026.10.1"} 43.0
assistant_replies_total{feature="order",outcome="refused",release="2026.10.1"} 14.0
assistant_replies_total{feature="order",outcome="answered",release="2026.10.1"} 22.0
```

Os rótulos são as dimensões pelas quais as aulas 3 e 5 dividiram tudo: funcionalidade, versão,
resultado. Um painel divide uma série por outra para desenhar a parcela de recusas por funcionalidade e
por versão, e as perguntas de pedido sob a 2026.10.1 saem em 14 recusadas de 36, os 39% que a aula 5
achou.

**O que nunca é rótulo** importa tanto quanto. Cada combinação diferente de rótulos é uma série separada
que o sistema de métricas guarda por todo o tempo em que guarda qualquer coisa, então um rótulo com muitos
valores multiplica o custo de tudo:

- **Nunca o usuário ou a sessão.** Milhares de valores, e dados pessoais num sistema aonde as regras da
  aula 2 nunca chegaram.
- **Nunca a pergunta ou a resposta.** Valores sem limite, e as palavras dos clientes.
- **Nunca um id de trace.** Uma série por requisição é um armazenamento de traces mal feito.

Esses pertencem aos traces, onde a aula 1 os pôs. O contador diz quantos, o rótulo diz de que tipo, e o
trace diz qual, com um link do painel para os traces por trás de um ponto dele.

As séries `_created` que esta versão do cliente acrescenta por padrão estão desligadas no script: elas
guardam a hora em que cada contador foi criado, que aqui é o momento em que o script rodou, e nada sobre a
semana.
