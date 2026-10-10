---
title: O que contar, hora a hora
version: 1
---

Todo controle deste curso produz um veredito: o esquema da aula 9 recusa uma resposta, o canário da
aula 5 encontra um prompt de sistema numa resposta, o portão da aula 10 nega uma chamada, um cliente
denuncia uma resposta na aula 21. Cada veredito protege uma requisição. **Contados ao longo do tempo,
os mesmos vereditos dizem o que está acontecendo com o assistente inteiro**, e monitoramento é isso:
as defesas que você já tem, lidas como um fluxo em vez de uma de cada vez.

As contagens que importam na Tarefa, e o que um salto em cada uma costuma significar:

| sinal | de onde | um salto costuma significar |
|---|---|---|
| respostas que o esquema recusou | aula 9 | uma mudança de prompt ou de modelo quebrou o formato, como na aula 20 |
| canário numa resposta | aula 5 | o prompt de sistema chegou a um cliente; nunca deveria acontecer |
| chamadas de ferramenta negadas pelo portão | aula 10 | um agente propondo fora do escopo, muitas vezes para uma conta |
| bloqueios da moderação | aula 6 | uma mudança no que os clientes mandam, ou no modelo |
| gasto por hora | aula 18 | um laço, antes que o teto do dia pare todo mundo |
| denúncias por mil chamadas | aula 21 | algo que os clientes notam e nenhuma verificação nota |

Dois dias de contagens por hora, **escritos por uma regra e não observados**, com três incidentes
plantados no segundo dia. Salve o gerador como `~/guard/tools/hourly.py`:

```python
# hourly.py: two days of the assistant's hourly counts, written by a rule.
#
#   guard hourly
#
# It writes data/hourly.jsonl, one line per hour from 2026-10-07 00:00 to
# 2026-10-08 23:00: calls, replies the schema refused (lesson 9), canary
# hits in replies (lesson 5), tool calls the gate denied (lesson 10) and
# client reports (lesson 21). The first day is ordinary, busy by day and
# quiet at night. The second has three incidents, planted by the course:
# a prompt change at 10:00 that triples refused replies, one canary in a
# reply at 14:00, and an account whose proposals the gate denies from 16:00
# to 17:00. Nothing here was observed.
import json
import os

TRAFFIC = [4, 2, 1, 1, 1, 3, 10, 30, 70, 110, 130, 140,
           120, 130, 140, 130, 120, 100, 80, 60, 40, 25, 12, 6]
rows = []
for day in ("2026-10-07", "2026-10-08"):
    for h, calls in enumerate(TRAFFIC):
        second = day == "2026-10-08"
        rejects = calls // 50 + (1 if h in (3, 4) else 0)
        if second and 10 <= h <= 12:
            rejects = calls // 12
        rows.append({"hour": "%s %02d:00" % (day, h), "calls": calls, "rejects": rejects,
                     "canary": 1 if second and h == 14 else 0,
                     "denies": 30 if second and h in (16, 17) else calls // 60,
                     "reports": 1 if h in (11, 15) else 0})
with open(os.path.expanduser("~/guard/data/hourly.jsonl"), "w", encoding="utf-8") as f:
    for r in rows:
        f.write(json.dumps(r) + "\n")
print("%d hours written to data/hourly.jsonl" % len(rows))
```

```
ana@lab:~/guard$ guard hourly
48 hours written to data/hourly.jsonl
ana@lab:~/guard$ head -3 data/hourly.jsonl
{"hour": "2026-10-07 00:00", "calls": 4, "rejects": 0, "canary": 0, "denies": 0, "reports": 0}
{"hour": "2026-10-07 01:00", "calls": 2, "rejects": 0, "canary": 0, "denies": 0, "reports": 0}
{"hour": "2026-10-07 02:00", "calls": 1, "rejects": 0, "canary": 0, "denies": 0, "reports": 0}
```

Quarenta e oito linhas, uma por hora. O tráfego da Tarefa tem o formato da maioria dos serviços: 140
chamadas por hora no pico e uma às quatro da manhã. Esse formato importa mais que qualquer outra coisa
na próxima seção, porque **uma taxa calculada sobre uma chamada é uma moeda, não uma medida**.

## Contar o que os controles decidem, não o que o modelo diz

Nenhuma dessas contagens lê o conteúdo de uma resposta. Elas contam decisões que o código já tomou,
então são baratas, são as mesmas qualquer que seja o modelo, e não guardam dado pessoal. O log de
chamadas da aula 11 guarda o conteúdo, sob a própria retenção; o monitoramento guarda números, que
podem ser guardados por mais tempo e mostrados a mais gente. Um painel que exibisse as mensagens dos
clientes para mostrar o que está acontecendo seria um segundo log sem as regras de retenção de
ninguém.
