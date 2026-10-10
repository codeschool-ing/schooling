---
title: Um orçamento por pessoa, e um teto para o dia
version: 1
---

Uma chamada custa centavos. **Um laço custa o mês.** Uma integração que tenta de novo a cada erro, um
agente que chama a si mesmo, um script de cliente com um bug: cada um manda o mesmo tipo de requisição
de novo e de novo, e cada requisição é barata o bastante para ninguém notar até o total chegar.

Um dia de chamadas do assistente, escrito por uma regra e não observado: cinco clientes fazendo vinte
perguntas cada ao longo do dia, e uma conta, a `ac-3H8V`, cuja integração entra em laço às 14:00 e
manda seiscentas requisições numa hora. Salve o gerador como `~/guard/tools/daylog.py`:

```python
# daylog.py: one day of the assistant's calls, written by a rule, not observed.
#
#   guard daylog
#
# It writes data/day-usage.jsonl: five clients asking twenty questions each,
# spread from 08:00 to 17:30, and one account, ac-3H8V, whose integration
# loops from 14:00 and sends six hundred requests in an hour. Every number is
# the course's: the token counts are typical of a support question, not
# measured from anybody's traffic.
import json
import os

rows = []
for c, account in enumerate(["ac-7Q2M", "ac-0Z5Q", "ac-5K2W", "ac-9P4R", "ac-2D6M"]):
    for n in range(20):
        minute = 8 * 60 + n * 30 + c * 5
        rows.append({"time": "%02d:%02d:00" % divmod(minute, 60), "account": account,
                     "in": 1200, "out": 300})
for n in range(600):
    seconds = 14 * 3600 + n * 6
    rows.append({"time": "%02d:%02d:%02d" % (seconds // 3600, seconds // 60 % 60, seconds % 60),
                 "account": "ac-3H8V", "in": 2500, "out": 500})
rows.sort(key=lambda r: r["time"])
with open(os.path.expanduser("~/guard/data/day-usage.jsonl"), "w", encoding="utf-8") as f:
    for r in rows:
        f.write(json.dumps(r) + "\n")
print("%d calls written to data/day-usage.jsonl" % len(rows))
```

E o replay, que atende ou recusa cada chamada na ordem em que chegou, contra dois tipos de limite.
Salve-o como `~/guard/tools/budget.py`:

```python
# budget.py: a day of calls replayed against spending limits.
#
#   guard budget FILE [--user-tokens N] [--day-cents C]
#
# Each call is served or refused in the order it arrived. --user-tokens is a
# daily budget per account, in tokens; a call that would take the account past
# it is refused. --day-cents is a daily ceiling on what the whole assistant
# may spend: an ALERT is printed when spending reaches 80% of it, and from the
# moment it is reached every further call is refused, for every account.
# Prices come from data/prices.json, and money is integer millionths of a
# cent until it is printed.
import argparse
import json
import os

p = argparse.ArgumentParser(prog="guard budget")
p.add_argument("file")
p.add_argument("--user-tokens", type=int)
p.add_argument("--day-cents", type=int)
a = p.parse_args()

with open(os.path.expanduser("~/guard/data/prices.json"), encoding="utf-8") as f:
    prices = json.load(f)
with open(a.file, encoding="utf-8") as f:
    calls = [json.loads(line) for line in f]


def cost(call):
    return (call["in"] * prices["cents_per_million_input"]
            + call["out"] * prices["cents_per_million_output"])


def brl(millionths):
    cents = (millionths + 500_000) // 1_000_000
    return "R$ %d,%02d" % divmod(cents, 100)


spent = 0
alerted = stopped = False
per = {}
for call in calls:
    s = per.setdefault(call["account"], {"sent": 0, "served": 0, "tokens": 0, "spent": 0})
    s["sent"] += 1
    tokens = call["in"] + call["out"]
    if stopped:
        continue
    if a.user_tokens and s["tokens"] + tokens > a.user_tokens:
        continue
    s["served"] += 1
    s["tokens"] += tokens
    s["spent"] += cost(call)
    spent += cost(call)
    if a.day_cents and not alerted and spent * 100 >= a.day_cents * 1_000_000 * 80:
        alerted = True
        print("%s ALERT  spending reached 80%% of %s" % (call["time"], brl(a.day_cents * 1_000_000)))
    if a.day_cents and spent >= a.day_cents * 1_000_000:
        stopped = True
        print("%s STOP   the day's ceiling is spent; every further call is refused" % call["time"])

print("limits: %s per account a day, %s for the day" % (
    "%d tokens" % a.user_tokens if a.user_tokens else "none",
    brl(a.day_cents * 1_000_000) if a.day_cents else "no ceiling"))
print("%-9s %5s %7s %8s %9s" % ("account", "sent", "served", "tokens", "spent"))
for account in sorted(per):
    s = per[account]
    print("%-9s %5d %7d %8d %9s" % (account, s["sent"], s["served"], s["tokens"], brl(s["spent"])))
print("total spent %s" % brl(spent))
```

Primeiro o dia como aconteceu, sem limite de nenhum tipo:

```
ana@lab:~/guard$ guard daylog
700 calls written to data/day-usage.jsonl
ana@lab:~/guard$ guard budget data/day-usage.jsonl
limits: none per account a day, no ceiling for the day
account    sent  served   tokens     spent
ac-0Z5Q      20      20    30000   R$ 0,72
ac-2D6M      20      20    30000   R$ 0,72
ac-3H8V     600     600  1800000  R$ 40,50
ac-5K2W      20      20    30000   R$ 0,72
ac-7Q2M      20      20    30000   R$ 0,72
ac-9P4R      20      20    30000   R$ 0,72
total spent R$ 44,10
```

**R$ 40,50 de R$ 44,10 são uma conta em uma hora.** Cada cliente honesto gastou 72 centavos. Nada neste
replay é malicioso, e nada precisa ser: um laço não precisa ser um ataque para custar o mesmo que um.

## Um teto sozinho para todo mundo

A proteção óbvia é um teto para o assistente inteiro, R$ 20,00 por dia, com um alerta em 80%:

```
ana@lab:~/guard$ guard budget data/day-usage.jsonl --day-cents 2000
14:20:12 ALERT  spending reached 80% of R$ 20,00
14:26:06 STOP   the day's ceiling is spent; every further call is refused
limits: none per account a day, R$ 20,00 for the day
account    sent  served   tokens     spent
ac-0Z5Q      20      13    19500   R$ 0,47
ac-2D6M      20      13    19500   R$ 0,47
ac-3H8V     600     262   786000  R$ 17,69
ac-5K2W      20      13    19500   R$ 0,47
ac-7Q2M      20      13    19500   R$ 0,47
ac-9P4R      20      13    19500   R$ 0,47
total spent R$ 20,03
```

O teto segurou, e o alerta veio seis minutos antes dele. **Ele também parou todo cliente que perguntou
alguma coisa depois das 14:26**: cada um dos cinco perdeu sete das suas vinte perguntas, por um laço
com que não tinha nada a ver. O total parou em R$ 20,03, acima do teto por parte de uma chamada,
porque a verificação roda depois de a chamada ser atendida; um teto que nunca pode ser ultrapassado
confere o custo estimado antes. Um teto global é a última linha, para o caso que nada mais pegou. Como
única linha, ele transforma o bug de uma conta na queda de todos.

## Um orçamento por pessoa isola o laço

O mesmo dia com um orçamento diário de 100.000 tokens por conta, e o mesmo teto atrás:

```
ana@lab:~/guard$ guard budget data/day-usage.jsonl --user-tokens 100000 --day-cents 2000
limits: 100000 tokens per account a day, R$ 20,00 for the day
account    sent  served   tokens     spent
ac-0Z5Q      20      20    30000   R$ 0,72
ac-2D6M      20      20    30000   R$ 0,72
ac-3H8V     600      33    99000   R$ 2,23
ac-5K2W      20      20    30000   R$ 0,72
ac-7Q2M      20      20    30000   R$ 0,72
ac-9P4R      20      20    30000   R$ 0,72
total spent R$ 5,83
```

**A conta em laço foi cortada depois de 33 chamadas, e todos os outros foram atendidos por inteiro.** O
total caiu para R$ 5,83, e o teto nem chegou perto, que é como um teto deveria aparecer na maior parte
dos dias. O orçamento por conta é aplicado com o identificador de usuário final da aula 7, e é isso que
faz "por conta" significar alguma coisa quando todas as requisições chegam pela chave de um parceiro.

Três níveis, então, e cada um pega o que os outros não pegam:

| limite | para | aula |
|---|---|---|
| `max_tokens` por chamada | uma resposta que se alonga | esta, e a aula 9 |
| requisições por minuto | uma rajada | aula 7 |
| tokens por conta por dia | o laço de uma conta, lento ou rápido | esta |
| um teto para o dia, com alerta | todo o resto, ao custo de todos | esta |
