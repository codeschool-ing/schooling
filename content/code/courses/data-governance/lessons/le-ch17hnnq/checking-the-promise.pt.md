---
title: Conferindo a promessa
version: 1
---

O verificador lê o contrato e pergunta ao banco o que ele serve de fato:

```python
"""Compare a data contract with what the database actually serves: the same
columns, in the same types, with the classes gov.column_class gives their
sources, and the quality rules holding. Exit 1 on any difference."""
import json, subprocess, sys

def sql(q):
    out = subprocess.run(["psql", "-X", "-q", "-At", "-c", "SET ROLE ipe_owner", "-c", q],
                         capture_output=True, text=True, check=True).stdout
    return [line.split("|") for line in out.splitlines() if line]

contract = json.load(open(sys.argv[1]))
schema, rel = contract["relation"].split(".")
served = {n: t for n, t in sql(
    "SELECT column_name, data_type FROM information_schema.columns "
    f"WHERE table_schema = '{schema}' AND table_name = '{rel}' ORDER BY ordinal_position")}
promised = {f["name"]: f for f in contract["fields"]}
problems = []

for name in served.keys() - promised.keys():
    problems.append(f"{name}: served, and not in the contract")
for name in promised.keys() - served.keys():
    problems.append(f"{name}: in the contract, and not served")
for name in served.keys() & promised.keys():
    if served[name] != promised[name]["type"]:
        problems.append(f"{name}: contract says {promised[name]['type']}, served as {served[name]}")
    src = promised[name]["source"].split(".")
    if len(src) == 3:
        row = sql("SELECT class FROM gov.column_class "
                  f"WHERE (table_schema, table_name, column_name) = ('{src[0]}', '{src[1]}', '{src[2]}')")
        actual = row[0][0] if row else "unclassified"
        if actual != promised[name]["class"]:
            problems.append(f"{name}: contract says {promised[name]['class']}, "
                            f"gov.column_class says {actual}")
for q in contract["quality"]:
    n = int(sql(q["sql"])[0][0])
    if n:
        problems.append(f"quality: {q['rule']}: {n} rows break it")

name = f"{contract['contract']} {contract['version']}"
if problems:
    print(f"{name}: {len(problems)} problem(s)")
    for p in sorted(problems):
        print("  " + p)
    sys.exit(1)
print(f"{name}: {len(served)} fields and {len(contract['quality'])} rules, as promised")
```

Ele confere quatro coisas, e cada uma é um jeito como contratos se desatualizam na prática:

1. **um campo servido e não prometido** — o vazamento da seção 1;
2. **um campo prometido e não servido** — a falha visível, pega antes de o consumidor achá-la;
3. **um tipo diferente** — a silenciosa, muitas vezes sintoma de um sentido mudado;
4. **uma classe diferente da do `gov.column_class`** — o contrato diz `personal` e a classificação diz
   `sensitive`: um dos dois está errado, e o dado está indo sob o errado.

Depois ele roda as regras de qualidade do contrato, no mesmo formato das da aula 9: uma consulta que
conta as linhas que quebram a regra, que tem de dar zero.

## Onde ele roda

Num notebook, o verificador é um script. Como governança, ele é um passo que roda **onde quer que um
dos lados possa mudar**: no pipeline que publica uma mudança na view, e no pipeline que muda o contrato.
Um pull request que altera `share.delivery_feed` sem alterar o contrato falha, e a revisão que vem em
seguida é a conversa de que a mudança precisava: a Rota Certa precisa disso, e o dono concordou?

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l11-contract\" aria-label=\"Um contrato de dados entre um produtor e um consumidor. A Ipê produz a view share.delivery_feed; a Rota Certa consome o arquivo feito a partir dela. O contrato fica entre os dois, num repositório. Uma verificação roda do lado da Ipê sempre que a view ou o contrato mudam, e pode rodar do lado do consumidor contra o arquivo que ele recebe.\"><defs><marker id=\"dg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"70.0\" width=\"180.0\" height=\"70.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Ipê, produtora</text><text x=\"110.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">share.delivery_feed</text><rect x=\"270.0\" y=\"60.0\" width=\"180.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"81.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o contrato</text><text x=\"360.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">delivery-feed.v1.json</text><text x=\"360.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">esquema · sentido · qualidade</text><text x=\"360.0\" y=\"128.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dono · privacidade · versão</text><rect x=\"520.0\" y=\"70.0\" width=\"180.0\" height=\"70.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Rota Certa, consumidora</text><text x=\"610.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um CSV toda manhã</text><path d=\"M200.0 105.0 L268.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><path d=\"M450.0 105.0 L518.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"30.0\" y=\"170.0\" width=\"160.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">check_contract.py</text><rect x=\"530.0\" y=\"170.0\" width=\"160.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a verificação dela</text><path d=\"M110.0 168.0 L110.0 142.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M190.0 188.0 L300.0 152.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M610.0 168.0 L610.0 142.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M530.0 188.0 L420.0 152.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">num repositório, revisado como código</text></svg>", "caption": "Duas verificações contra um documento transformam uma descrição num acordo."}
```

O consumidor também pode rodar uma verificação, do lado dele: o mesmo contrato, contra o arquivo que
recebeu. Duas verificações contra um documento são o que transforma o contrato de uma descrição num
acordo.
