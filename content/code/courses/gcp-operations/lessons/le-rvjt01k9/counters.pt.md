---
title: Um contador feito de linhas que casam
version: 1
---

**Uma métrica baseada em log transforma entradas que casam com um filtro numa série temporal.** Uma métrica
de contador soma um para cada entrada que casa em cada minuto; nada mais da entrada é guardado, exceto os
rótulos que você pede para extrair. É como uma linha de texto que um programa já escreve vira algo que um
gráfico desenha e que um alerta compara com um limite, sem ninguém mudar o programa. **Nada nesta lição chega
ao Cloud Logging nem ao Cloud Monitoring.** A contagem abaixo é feita no seu computador com `jq`, sobre um log
que um programa gera, para mostrar o que a métrica registraria; as métricas e o alerta são um plano do
Terraform.

O programa escreve trinta minutos do log de checkout da loja, quarenta pedidos por minuto, com um trecho ruim
no provedor de pagamento no meio. Escreva-o em `~/gcp/genlogs.py`:

```python
# genlogs.py
"""genlogs.py: thirty minutes of the shop's checkout log, as JSON lines.

Seeded, so every run writes the same file. The payment provider has a bad
patch between minutes 12 and 17, and checkout retries more often there.
"""
import json
import random
from datetime import datetime, timedelta, timezone

rng = random.Random(11)
start = datetime(2026, 10, 30, 14, 0, tzinfo=timezone.utc)
for minute in range(30):
    bad = 12 <= minute < 18
    for _ in range(40):
        t = start + timedelta(minutes=minute, seconds=rng.randint(0, 59))
        entry = {"timestamp": t.isoformat(), "severity": "INFO",
                 "message": "order placed", "total_cents": rng.choice([1890, 2490, 4380, 6870])}
        if rng.random() < (0.30 if bad else 0.02):
            entry.update(severity="WARNING", message="payment retried",
                         provider=rng.choice(["card", "pix"]))
        print(json.dumps(entry))
```

```
ana@laptop:~/gcp$ python3 genlogs.py > checkout.log
ana@laptop:~/gcp$ wc -l checkout.log
1200 checkout.log
```

## O que um contador de "payment retried" registraria

O filtro da métrica seria `jsonPayload.message="payment retried"`. Contado por minuto, que é o que uma métrica
de contador faz com as entradas que casam:

```
ana@laptop:~/gcp$ jq -r 'select(.message == "payment retried") | .timestamp[11:16]' checkout.log | sort | uniq -c
      2 14:00
      1 14:03
      1 14:04
      2 14:05
      1 14:07
      1 14:08
      1 14:10
      3 14:11
     12 14:12
     15 14:13
     18 14:14
     13 14:15
     16 14:16
     11 14:17
      1 14:19
      1 14:20
      1 14:21
      1 14:22
      1 14:25
      2 14:26
      1 14:27
      1 14:29
```

Leia a coluna da esquerda como os pontos da métrica. Uma ou duas tentativas por minuto é o fundo normal; de
14:12 a 14:17 salta para entre 11 e 18, que é o incidente. **Olhe também o que falta**: não há linha para
14:01, 14:02 ou 14:06. Um minuto sem entrada que case não produz **ponto nenhum**, e não um ponto de zero, e
essa diferença decide como um alerta sobre esta métrica se comporta quando está tudo bem (a lição 14 volta a
isso).

## Rótulos: a mesma contagem, dividida

Um contador pode extrair rótulos de cada entrada, e cada valor distinto vira uma série própria, como a lição 8
descreveu. Dividir as tentativas pelo método de pagamento diz se o problema foi um provedor ou os dois:

```
ana@laptop:~/gcp$ jq -r 'select(.message == "payment retried") | .provider' checkout.log | sort | uniq -c
     50 card
     56 pix
```

Os dois métodos tiveram tentativas, em números parecidos, então a causa está antes de qualquer um deles: a
chamada do próprio checkout ao serviço de pagamento, e não um provedor falhando. Vale extrair um rótulo quando
os valores dele respondem a uma pergunta como essa. **Um rótulo com valores sem limite** (um id de pedido, um
id de usuário, uma URL com um id dentro) transforma uma métrica em milhares de séries, cada uma cobrada e cada
uma lenta de consultar, e é o erro mais comum com métricas baseadas em log.
