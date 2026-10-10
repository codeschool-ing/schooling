---
title: Regras que acordam alguém só quando devem
version: 1
---

Uma contagem que ninguém vigia não acha nada. Um alerta é uma regra que transforma uma contagem numa
mensagem para uma pessoa, e ele tem dois jeitos de falhar: **ficar quieto durante um incidente, e
gritar quando nada está errado**. O segundo é tão perigoso quanto o primeiro, porque uma equipe
chamada toda noite por nada aprende a dormir com o alarme tocando.

Dois conjuntos de regras para os mesmos dois dias, escritos pelo curso. Cole:

```sh
cat > ~/guard/data/alerts.json <<'EOF'
{
 "naive": [
  {"metric": "rejects", "rate_above": 0.02, "severity": "page"}
 ],
 "tuned": [
  {"metric": "canary", "count_at_least": 1, "severity": "page"},
  {"metric": "rejects", "times_baseline": 3, "min_events": 5, "severity": "ticket"},
  {"metric": "denies", "times_baseline": 5, "min_events": 10, "severity": "page"}
 ]
}
EOF
```

O programa repassa cada hora contra um conjunto e imprime o que teria disparado. Salve-o como
`~/guard/tools/monitor.py`:

```python
# monitor.py: alert rules replayed over the assistant's hourly counts.
#
#   guard monitor FILE --rules naive|tuned
#
# The rules are in data/alerts.json. Three shapes of rule:
#
#   count_at_least  fires whenever the metric reaches the count; for events
#                   that should never happen, such as a canary in a reply
#   rate_above      fires when the metric divided by the hour's calls passes
#                   a fixed rate
#   times_baseline  fires when the metric passes N times its median over the
#                   previous 24 hours, and only when at least min_events
#                   happened, so that one event in a quiet hour is not news
#
# Each alert is a page (somebody is woken) or a ticket (somebody looks in
# working hours). The last line counts both.
import argparse
import json
import os
import statistics

p = argparse.ArgumentParser(prog="guard monitor")
p.add_argument("file")
p.add_argument("--rules", choices=["naive", "tuned"], required=True)
a = p.parse_args()

with open(os.path.expanduser("~/guard/data/alerts.json"), encoding="utf-8") as f:
    rules = json.load(f)[a.rules]
with open(a.file, encoding="utf-8") as f:
    hours = [json.loads(line) for line in f]

fired = {"page": 0, "ticket": 0}
for i, h in enumerate(hours):
    for r in rules:
        value = h[r["metric"]]
        why = None
        if "count_at_least" in r and value >= r["count_at_least"]:
            why = "%s = %d" % (r["metric"], value)
        if "rate_above" in r and h["calls"] and value / h["calls"] > r["rate_above"]:
            why = "%s %d of %d calls, %.1f%%" % (r["metric"], value, h["calls"], 100 * value / h["calls"])
        if "times_baseline" in r and i >= 24:
            base = statistics.median(x[r["metric"]] for x in hours[i - 24:i])
            if value >= r["min_events"] and value > r["times_baseline"] * max(base, 1):
                why = "%s = %d, baseline %g" % (r["metric"], value, base)
        if why:
            fired[r["severity"]] += 1
            print("%s  %-6s %s" % (h["hour"], r["severity"].upper(), why))
print("rules %s: %d pages, %d tickets in %d hours" % (a.rules, fired["page"], fired["ticket"], len(hours)))
```

## A regra óbvia

O `naive` tem uma regra, a primeira que a maioria das equipes escreve: chamar alguém quando mais de 2%
das respostas forem recusadas.

```
ana@lab:~/guard$ guard monitor data/hourly.jsonl --rules naive
2026-10-07 03:00  PAGE   rejects 1 of 1 calls, 100.0%
2026-10-07 04:00  PAGE   rejects 1 of 1 calls, 100.0%
2026-10-08 03:00  PAGE   rejects 1 of 1 calls, 100.0%
2026-10-08 04:00  PAGE   rejects 1 of 1 calls, 100.0%
2026-10-08 10:00  PAGE   rejects 10 of 130 calls, 7.7%
2026-10-08 11:00  PAGE   rejects 11 of 140 calls, 7.9%
2026-10-08 12:00  PAGE   rejects 10 of 120 calls, 8.3%
rules naive: 7 pages, 0 tickets in 48 hours
```

**Sete chamadas, e quatro delas acordaram alguém às três e às quatro da manhã** por uma resposta
recusada em uma chamada. A regra viu 100% e disparou, o que foi aritmética, não incidente. E dos três
incidentes reais ela pegou um: as respostas recusadas a partir das 10:00. O canário das 14:00 e as
chamadas negadas das 16:00 nem foram medidos, porque ninguém escreveu regra para eles.

## Três regras, cada uma no formato do seu sinal

O `tuned` tem uma regra por sinal, cada uma num formato:

```
ana@lab:~/guard$ guard monitor data/hourly.jsonl --rules tuned
2026-10-08 10:00  TICKET rejects = 10, baseline 1
2026-10-08 11:00  TICKET rejects = 11, baseline 1
2026-10-08 12:00  TICKET rejects = 10, baseline 1
2026-10-08 14:00  PAGE   canary = 1
2026-10-08 16:00  PAGE   denies = 30, baseline 0.5
2026-10-08 17:00  PAGE   denies = 30, baseline 0.5
rules tuned: 3 pages, 3 tickets in 48 hours
```

**Os três incidentes, e nada mais.** O formato de cada regra combina com o que ela vigia:

- **o canário chama alguém no primeiro.** É um evento que nunca deveria acontecer, então uma linha de
  base não tem sentido e um basta;
- **respostas recusadas abrem um chamado com três vezes o nível habitual**, a mediana das 24 horas
  anteriores, e só a partir de cinco eventos. Essa única condição tirou as chamadas noturnas: uma
  recusa numa hora quieta fica abaixo de cinco, qualquer que seja a taxa;
- **chamadas de ferramenta negadas acordam alguém com cinco vezes o nível, a partir de dez.** Um agente
  forçando o portão trinta vezes por hora merece acordar alguém, porque o portão é a última coisa entre
  as propostas e as ferramentas.

As severidades também são decisões. O formato quebrar é um chamado: os clientes veem uma pessoa em vez
de uma resposta, o que custa tempo, não dano. Um canário ou um portão sob pressão acordam alguém,
porque o próximo passo de qualquer um dos dois é algo que a aula 24 vai ter de arrumar.
