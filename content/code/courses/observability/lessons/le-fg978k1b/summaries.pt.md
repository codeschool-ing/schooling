---
title: Summaries, e por que os histogramas venceram
version: 1
---

O quarto tipo, o **summary**, foi pensado para resolver o problema dos buckets calculando os
percentis dentro do serviço, com exatidão, a partir de cada observação, e publicando-os prontos. A
biblioteca cliente de Python implementa o tipo na forma mínima, e o `summary.py` mostra qual é:

```python
from prometheus_client import CollectorRegistry, Summary, generate_latest

registry = CollectorRegistry()
took = Summary("demo_request_seconds", "A summary, observed three times.", registry=registry)
for seconds in (0.2, 0.4, 1.9):
    took.observe(seconds)
print(generate_latest(registry).decode(), end="")
```

```
ana@obs:~/shop$ docker compose run --rm sandbox python summary.py 2>/dev/null
# HELP demo_request_seconds A summary, observed three times.
# TYPE demo_request_seconds summary
demo_request_seconds_count 3.0
demo_request_seconds_sum 2.5
# HELP demo_request_seconds_created A summary, observed three times.
# TYPE demo_request_seconds_created gauge
demo_request_seconds_created 1.790936343199444e+09
```

**Uma contagem e uma soma, e nenhum percentil**: o cliente de Python não os calcula. Clientes de
outras linguagens calculam, e a saída deles traz linhas como `{quantile="0.99"}`. Mesmo assim, um
summary tem um defeito que nenhum cliente conserta: **percentis não se somam**. Se três cópias de um
serviço informam cada uma um percentil 99, nenhuma conta com os três números dá o percentil 99 de
todas as requisições juntas. Seriam necessárias as observações, e elas foram jogadas fora. Buckets
*se somam*: somar os buckets de três histogramas dá o histograma dos três, e o percentil dele está
certo até a resolução do bucket.

É por isso que a vitrine usa um histograma, e que o conselho é o mesmo em quase todo lugar: **um
histograma, com buckets escolhidos de propósito**. O Prometheus 3 também suporta **histogramas
nativos**, cujos buckets são escolhidos automaticamente numa resolução relativa fixa e guardados de
forma muito mais compacta. Eles exigem que a biblioteca cliente e o servidor concordem no formato, e
os buckets clássicos do laboratório são o que este curso usa para medir.
