---
title: Cada chave estreita, de vida curta e anotada
version: 1
---

O verificador acha credenciais no lugar errado. Um segundo grupo de perguntas é sobre as próprias
credenciais, onde quer que estejam: **o que cada uma pode fazer, quem a usa, e quanto tempo ela tem.**
Essas perguntas pedem um inventário, uma linha por chave. O da Tarefa, escrito pelo curso:

```sh
cat > ~/guard/data/keys.json <<'EOF'
{
 "max_age_days": 90,
 "needs": {
  "assistant": ["chat"],
  "issue_refund": ["refund"],
  "lookup_order": ["read"],
  "call-log": ["write"]
 },
 "keys": [
  {"name": "provider-api", "kept_in": "secret store", "used_by": ["assistant"], "scope": ["chat"], "rotated": "2026-09-01"},
  {"name": "payments", "kept_in": "source code", "used_by": ["issue_refund"], "scope": ["refund", "payout", "read"], "rotated": "2025-11-02"},
  {"name": "orders-db", "kept_in": "secret store", "used_by": ["lookup_order"], "scope": ["read", "write"], "rotated": "2026-08-20"},
  {"name": "log-store", "kept_in": "secret store", "used_by": ["call-log"], "scope": ["write"], "rotated": "2026-04-12"}
 ]
}
EOF
```

O `needs` diz o que cada componente do assistente precisa conseguir fazer, a partir do manifesto da
aula 10: a ferramenta de reembolso reembolsa, a consulta de pedidos lê. O programa confere cada chave
contra três regras. Salve-o como `~/guard/tools/keys.py`:

```python
# keys.py: the inventory of Tarefa's credentials against three rules.
#
#   guard keys --now DATE
#
# data/keys.json lists every key: where it is kept, which components use it,
# what it is allowed to do, and when it was last rotated; and, per component,
# what that component needs. Each key is checked for:
#
#   KEPT   it lives anywhere but the secret store
#   SCOPE  it may do more than every component using it needs
#   AGE    it was last rotated more than max_age_days ago
#
# The exit status is 1 while any key breaks a rule.
import argparse
import datetime as dt
import json
import os

p = argparse.ArgumentParser(prog="guard keys")
p.add_argument("--now", required=True)
a = p.parse_args()
now = dt.date.fromisoformat(a.now)

with open(os.path.expanduser("~/guard/data/keys.json"), encoding="utf-8") as f:
    inv = json.load(f)

broken = 0
for k in inv["keys"]:
    problems = []
    if k["kept_in"] != "secret store":
        problems.append("KEPT   in %s" % k["kept_in"])
    needed = set()
    for user in k["used_by"]:
        needed |= set(inv["needs"][user])
    extra = [s for s in k["scope"] if s not in needed]
    if extra:
        problems.append("SCOPE  %s unused by %s" % (", ".join(extra), ", ".join(k["used_by"])))
    age = (now - dt.date.fromisoformat(k["rotated"])).days
    if age > inv["max_age_days"]:
        problems.append("AGE    %d days since rotation, limit %d" % (age, inv["max_age_days"]))
    broken += bool(problems)
    print("%-13s %s" % (k["name"], problems[0] if problems else "ok"))
    for pr in problems[1:]:
        print("%-13s %s" % ("", pr))
print("%d keys, %d breaking a rule" % (len(inv["keys"]), broken))
raise SystemExit(1 if broken else 0)
```

```
ana@lab:~/guard$ guard keys --now 2026-10-09; echo "exit status $?"
provider-api  ok
payments      KEPT   in source code
              SCOPE  payout, read unused by issue_refund
              AGE    341 days since rotation, limit 90
orders-db     SCOPE  write unused by lookup_order
log-store     AGE    180 days since rotation, limit 90
4 keys, 3 breaking a rule
exit status 1
```

Três de quatro chaves quebram uma regra, e a chave de pagamentos quebra as três.

- **KEPT.** Ela mora no código-fonte, o achado da primeira seção visto do outro lado. Uma chave no
  código é uma chave em cada clone.
- **SCOPE.** Ela pode reembolsar, pagar freelancers e ler contas, e o único componente que a usa
  reembolsa. Uma chave de pagamentos vazada que só reembolsasse seria ruim; uma que pode mandar
  pagamentos é pior, e nada se ganhou com esse escopo maior. **Uma chave recebe as permissões do
  componente mais estreito que a usa**, que é o menor privilégio aplicado a credenciais, como a aula 10
  o aplicou a ferramentas. O usuário do banco de pedidos pode escrever, e a consulta só lê.
- **AGE.** Ela foi rotacionada pela última vez há 341 dias, contra um limite de 90. Uma chave que nunca
  foi rotacionada é uma chave que ninguém sabe rotacionar, e o dia em que ela vaza é um dia ruim para
  descobrir.

O limite de 90 dias é uma política, não uma lei da natureza; algumas equipes rotacionam toda semana com
automação, outras uma vez por ano. A regra que importa é existir um limite, uma data em cada chave e um
programa que lê a data. A `log-store` quebra só essa, com 180 dias, e é o tipo de achado que uma
revisão trimestral deixa passar porque a chave funciona perfeitamente.

## Para que serve o inventário

O inventário responde a primeira pergunta de um incidente, que é o assunto da aula 24: **esta chave
vazou; o que alguém pode fazer com ela, e o que quebra quando a revogarmos?** O `scope` responde a
primeira metade e o `used_by` a segunda. Uma equipe sem a lista responde as duas procurando no código,
durante o incidente, sob pressão. O status de saída 1 deixa o `keys.py` rodar no build como toda outra
verificação aqui, para que uma chave que passou da data reprove um pull request antes de virar um
achado que ninguém assume.
