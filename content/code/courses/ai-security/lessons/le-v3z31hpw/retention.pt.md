---
title: Um limite de retenção é um job que roda
version: 2
---

A política da Tarefa está no `retention.json`: o texto bruto por 30 dias, o texto com redação por
180, as contagens por 730. **Esses números são escolhas, e nenhuma lei os entrega a você.** A LGPD
pede que o dado seja guardado enquanto a finalidade exigir e depois eliminado, ou seja, a finalidade
define o número. Trinta dias para o texto bruto é uma aposta de que um cliente que recebeu uma
resposta ruim reclama em até um mês. Uma empresa cujas disputas levam noventa dias para chegar
precisa de uma camada bruta mais longa e de uma razão mais forte para mantê-la.

Um limite escrito num documento não faz nada sozinho. O trabalho que o aplica lê a política e um
segundo arquivo, o `holds.json`, que o fim desta seção explica; cole-o agora:

```sh
cat > ~/guard/holds.json <<'EOF'
[
 {"file": "raw/2026-08-14.jsonl", "case": "INC-2208", "until": "2026-12-31",
  "reason": "a client asking for a freelancer's address and phone; kept for the safety team's investigation"}
]
EOF
```

E salve o trabalho como `~/guard/tools/sweep.py`:

```python
# sweep.py: the retention policy, applied to logs/.
#
#   guard sweep [--now YYYY-MM-DD] [--dry-run | --check]
#
# Every file older than its tier's limit in retention.json is deleted, unless
# holds.json keeps it until a date that has not passed. --dry-run prints what
# would go; --check prints what is overdue and exits 1 if anything is.
import argparse
import datetime as dt
import json
import os
import sys

HOME = os.path.expanduser("~/guard/")
p = argparse.ArgumentParser(prog="guard sweep")
p.add_argument("--now")
g = p.add_mutually_exclusive_group()
g.add_argument("--dry-run", action="store_true")
g.add_argument("--check", action="store_true")
a = p.parse_args()

with open(HOME + "retention.json") as f:
    policy = json.load(f)
with open(HOME + "holds.json") as f:
    holds = {h["file"]: h for h in json.load(f)}
now = dt.date.fromisoformat(a.now) if a.now else dt.date.today()

print("policy: " + ", ".join("%s %d days" % (t, policy[t]["days"]) for t in policy))
gone = kept = late = 0
for tier, rule in policy.items():
    folder = HOME + "logs/" + tier
    for name in sorted(os.listdir(folder)):
        rel = tier + "/" + name
        age = (now - dt.date.fromisoformat(name.split(".")[0])).days
        if age <= rule["days"]:
            continue
        hold = holds.get(rel)
        if hold and dt.date.fromisoformat(hold["until"]) >= now:
            print("%-27s %4d days  KEEP    hold %s until %s" % (rel, age, hold["case"], hold["until"]))
            kept += 1
        elif a.check:
            print("%-27s %4d days  OVERDUE limit %d" % (rel, age, rule["days"]))
            late += 1
        else:
            print("%-27s %4d days  %s" % (rel, age, "would delete" if a.dry_run else "deleted"))
            if not a.dry_run:
                os.remove(os.path.join(folder, name))
            gone += 1
if a.check:
    print("%d file(s) past their limit, %d kept by a hold" % (late, kept))
    sys.exit(1 if late else 0)
print("%s%d file(s) %s, %d kept by a hold" % ("dry run: " if a.dry_run else "", gone,
                                            "would be deleted" if a.dry_run else "deleted", kept))
```

Assim ficam os logs quando a política foi escrita e nada jamais a aplicou:

```
ana@lab:~/guard$ guard sweep --now 2026-09-30 --check; echo "exit $?"
policy: raw 30 days, redacted 180 days, metrics 730 days
raw/2026-03-10.jsonl         204 days  OVERDUE limit 30
raw/2026-03-24.jsonl         190 days  OVERDUE limit 30
raw/2026-04-07.jsonl         176 days  OVERDUE limit 30
raw/2026-04-21.jsonl         162 days  OVERDUE limit 30
raw/2026-05-05.jsonl         148 days  OVERDUE limit 30
raw/2026-05-19.jsonl         134 days  OVERDUE limit 30
raw/2026-06-02.jsonl         120 days  OVERDUE limit 30
raw/2026-06-16.jsonl         106 days  OVERDUE limit 30
raw/2026-06-30.jsonl          92 days  OVERDUE limit 30
raw/2026-07-14.jsonl          78 days  OVERDUE limit 30
raw/2026-07-28.jsonl          64 days  OVERDUE limit 30
raw/2026-08-11.jsonl          50 days  OVERDUE limit 30
raw/2026-08-14.jsonl          47 days  KEEP    hold INC-2208 until 2026-12-31
raw/2026-08-25.jsonl          36 days  OVERDUE limit 30
redacted/2026-03-10.jsonl    204 days  OVERDUE limit 180
redacted/2026-03-24.jsonl    190 days  OVERDUE limit 180
15 file(s) past their limit, 1 kept by a hold
exit 1
```

Quinze arquivos além do limite, e o arquivo bruto mais antigo tem 204 dias diante de uma promessa de
30. Um dos registros do log é um cliente perguntando por quanto tempo os chats são guardados, e o
assistente responde com a política. Nesta máquina essa resposta é falsa. Ninguém escreveu nada
falso: a política foi escrita, o job que a aplica não.

O `--check` não apaga nada. Ele relata e **sai com 1 quando há algo atrasado**, então pode rodar no
mesmo agendador que a varredura e disparar um alarme quando a varredura para. Uma varredura que falha
em silêncio e uma que nunca foi configurada parecem idênticas de fora, e o `--check` é o que as
distingue num painel.

## Uma retenção para o relógio, por um motivo e até uma data

Um arquivo do `--check` está marcado `KEEP`. O cliente do `rq-0014` e do `rq-0015` pediu ao
assistente o endereço e o telefone de um freelancer, e disse que ia atrás dele. A equipe de segurança
abriu uma investigação, e o texto bruto daquele dia é a prova:

```
ana@lab:~/guard$ cat holds.json
[
 {"file": "raw/2026-08-14.jsonl", "case": "INC-2208", "until": "2026-12-31",
  "reason": "a client asking for a freelancer's address and phone; kept for the safety team's investigation"}
]
```

Uma retenção nomeia o arquivo, o caso, o motivo e uma data final. **Uma retenção sem data final é uma
segunda política de retenção que ninguém escreveu**, e o caso que a justificou se encerra enquanto o
arquivo fica. Quando o `until` passa, a varredura seguinte apaga o arquivo como qualquer outro;
estender a retenção é uma decisão que alguém precisa tomar de novo, com o caso ainda aberto.

## Rodando

O `--dry-run` imprime o que uma varredura apagaria sem apagar, e é assim que uma política nova é
testada num depósito real antes de ganhar confiança:

```
ana@lab:~/guard$ guard sweep --now 2026-09-30 --dry-run | tail -4
raw/2026-08-25.jsonl          36 days  would delete
redacted/2026-03-10.jsonl    204 days  would delete
redacted/2026-03-24.jsonl    190 days  would delete
dry run: 15 file(s) would be deleted, 1 kept by a hold
ana@lab:~/guard$ guard sweep --now 2026-09-30 | tail -4
raw/2026-08-25.jsonl          36 days  deleted
redacted/2026-03-10.jsonl    204 days  deleted
redacted/2026-03-24.jsonl    190 days  deleted
15 file(s) deleted, 1 kept by a hold
ana@lab:~/guard$ guard sweep --now 2026-09-30 --check; echo "exit $?"
policy: raw 30 days, redacted 180 days, metrics 730 days
raw/2026-08-14.jsonl          47 days  KEEP    hold INC-2208 until 2026-12-31
0 file(s) past their limit, 1 kept by a hold
exit 0
ana@lab:~/guard$ ls logs/raw
2026-08-14.jsonl
2026-09-01.jsonl
2026-09-08.jsonl
2026-09-15.jsonl
2026-09-22.jsonl
2026-09-29.jsonl
```

A camada bruta agora guarda os últimos trinta dias e o arquivo retido. Todo `--now` desta aula está
fixado em 30 de setembro de 2026 para as idades baterem com o texto; uma varredura de verdade usa a
data de hoje.

## As cópias que a varredura não alcança

Apagar um arquivo apaga uma cópia. Três outras são comuns, e cada uma precisa de resposta própria:

- **Backups.** Um backup guardado por um ano tem um ano de camada bruta, faça a varredura o que
  fizer. Ou a camada bruta fica fora dos backups, ou os backups duram no máximo o prazo da camada
  mais curta que contêm.
- **Os lugares para onde os logs são enviados.** Um fornecedor de observabilidade que recebe o texto
  bruto o guarda pelo prazo dele. Envie as métricas, ou no máximo a camada com redação.
- **O fornecedor do modelo.** O fornecedor recebe cada prompt e mantém registros próprios das suas
  chamadas, para monitorar abuso, por um prazo definido nos termos dele. A sua varredura não os
  toca. O que o fornecedor guarda, onde, e se há para você um arranjo sem retenção é uma questão de
  contrato, e a aula 12 trata desse contrato.
