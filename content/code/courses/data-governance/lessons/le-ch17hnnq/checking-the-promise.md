---
title: Checking the promise
version: 1
---

The checker reads the contract and asks the database what it actually serves:

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

It checks four things, and each one is a way contracts drift in practice:

1. **a field served and not promised** — the leak of section 1;
2. **a field promised and not served** — the loud failure, caught before the consumer finds it;
3. **a type that differs** — the quiet one, often a symptom of a changed meaning;
4. **a class that differs from `gov.column_class`** — the contract says `personal` and the
   classification says `sensitive`: one of them is wrong, and data is being sent under the wrong one.

Then it runs the contract's quality rules, the same shape as lesson 9's: a query that counts the rows
breaking the rule, which must be zero.

## Where it runs

On a laptop, the checker is a script. As governance, it is a step that runs **wherever either side can
change**: in the pipeline that deploys a change to the view, and in the pipeline that changes the
contract. A pull request that alters `share.delivery_feed` without altering the contract fails, and the
review that follows is the conversation the change needed: does Rota Certa need this, and has the
owner agreed?

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l11-contract\" aria-label=\"A data contract between a producer and a consumer. Ipê produces the view share.delivery_feed; Rota Certa consumes the file built from it. The contract sits between them in a repository. A check runs on Ipê's side whenever the view or the contract changes, and can run on the consumer's side against the file it receives.\"><defs><marker id=\"dg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"70.0\" width=\"180.0\" height=\"70.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Ipê, producer</text><text x=\"110.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">share.delivery_feed</text><rect x=\"270.0\" y=\"60.0\" width=\"180.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"81.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the contract</text><text x=\"360.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">delivery-feed.v1.json</text><text x=\"360.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">schema · meaning · quality</text><text x=\"360.0\" y=\"128.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">owner · privacy · version</text><rect x=\"520.0\" y=\"70.0\" width=\"180.0\" height=\"70.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Rota Certa, consumer</text><text x=\"610.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a CSV every morning</text><path d=\"M200.0 105.0 L268.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><path d=\"M450.0 105.0 L518.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"30.0\" y=\"170.0\" width=\"160.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">check_contract.py</text><rect x=\"530.0\" y=\"170.0\" width=\"160.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">their own check</text><path d=\"M110.0 168.0 L110.0 142.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M190.0 188.0 L300.0 152.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M610.0 168.0 L610.0 142.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M530.0 188.0 L420.0 152.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">in a repository, reviewed like code</text></svg>", "caption": "Two checks against one document turn a description into an agreement."}
```

The consumer can run a check too, from its side: the same contract, against the file it received. Two
checks against one document is what turns the contract from a description into an agreement.
