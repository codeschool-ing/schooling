---
title: A content scanner
version: 1
---

**A content scanner reads files and reports which ones hold personal data.** Run over a file
server, it answers the question DLP starts with, which is where the data is at rest; run at the
moment a file is about to leave, it is the check that decides whether it may. It is the same
program in both places, and this one is short enough to read. Save it on `desk` as `scan.py`:

```schooling-example
{"language": "python", "file": "scan.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"scan.py: find CPFs and card numbers in files, check them, and say how many without printing them.\"\"\"\nimport os, re, sys\n\nCPF = re.compile(r\"(?<![\\d.])\\d{3}\\.?\\d{3}\\.?\\d{3}-?\\d{2}(?![\\d-])\")\nCARD = re.compile(r\"(?<!\\d)(?:\\d[ -]?){12,18}\\d(?!\\d)\")", "note": "Two patterns find the candidates: a CPF written with or without its dots and dash, and a run of thirteen to nineteen digits, spaces and dashes allowed, which is every card length in use. The look-arounds stop a pattern from starting or ending in the middle of a longer number."}, {"code": "def cpf_ok(text):\n    d = [int(c) for c in text if c.isdigit()]\n    if len(set(d)) == 1:\n        return False\n    for n in (9, 10):\n        r = sum(x * w for x, w in zip(d, range(n + 1, 1, -1))) * 10 % 11\n        if (0 if r == 10 else r) != d[n]:\n            return False\n    return True\n\ndef luhn_ok(text):\n    d = [int(c) for c in text if c.isdigit()]\n    total = 0\n    for i, x in enumerate(reversed(d)):\n        x = x * 2 if i % 2 else x\n        total += x - 9 if x > 9 else x\n    return total % 10 == 0", "note": "Each candidate is checked the way the issuer computes it. A CPF made of one digit repeated, `111.111.111-11`, passes the arithmetic and is refused by the Receita Federal, so it is refused here too."}, {"code": "def mask(text):\n    digits = [c for c in text if c.isdigit()]\n    return \"\".join(digits[:3]) + \"*\" * (len(digits) - 5) + \"\".join(digits[-2:])", "note": "**A DLP tool that prints what it found has just copied the personal data into its own log.** So it prints a count, and one example masked down to its first three and last two digits, which is enough for a person to find the line and too little to use."}, {"code": "def scan(path, check):\n    found = {\"cpf\": [], \"card\": [], \"rejected\": 0}\n    text = open(path, errors=\"replace\").read()\n    for kind, pattern, ok in ((\"cpf\", CPF, cpf_ok), (\"card\", CARD, luhn_ok)):\n        for m in pattern.finditer(text):\n            if not check or ok(m.group()):\n                found[kind].append(m.group())\n            else:\n                found[\"rejected\"] += 1\n    return found\n\ncheck = \"--no-check\" not in sys.argv\nfor top in [a for a in sys.argv[1:] if not a.startswith(\"--\")]:\n    paths = [top] if os.path.isfile(top) else sorted(\n        os.path.join(root, name) for root, _, files in os.walk(top) for name in files)\n    for path in paths:\n        f = scan(path, check)\n        if f[\"cpf\"] or f[\"card\"]:\n            first = mask((f[\"cpf\"] or f[\"card\"])[0])\n            print(f'{path}: {len(f[\"cpf\"])} CPF, {len(f[\"card\"])} card, '\n                  f'{f[\"rejected\"]} rejected, e.g. {first}')", "note": "The rest takes files, or directories to walk, and prints one line per file that holds something. `--no-check` keeps every match without the arithmetic, which is how the next section measures what the check is worth."}]}
```

Give it something to read: a folder with the client list, a file of order numbers, and a memo with
no numbers in it at all.

```
ana@desk:~$ mkdir docs; mv clientes.csv docs/
ana@desk:~$ printf "Pedido 12345678901 entregue\nPedido 98765432100 pendente\nCaixa 111.111.111-11\n" > docs/pedidos.txt
ana@desk:~$ printf "Reunião de quinta às 10h, sala 2.\n" > docs/memo.txt
```

Then scan the folder:

```
ana@desk:~$ python3 scan.py docs
docs/clientes.csv: 20 CPF, 20 card, 0 rejected, e.g. 881******41
docs/pedidos.txt: 1 CPF, 0 card, 2 rejected, e.g. 987******00
```

The client list reports all twenty CPFs and all twenty cards. The memo is not mentioned, because a
file with nothing in it gets no line. **The order file is the interesting one.** Three things there
look like a CPF; two were rejected, and one passed: `98765432100`, an order number, happens to have
valid check digits. To the scanner it is a CPF, and no arithmetic can say otherwise, because it is
a perfectly valid one. The `111.111.111-11` on the cash line was refused because a CPF of eleven
equal digits passes the arithmetic and is not issued.

The examples are masked to their first three and last two digits. **That is not decoration.** A
DLP tool's output goes to a log, an alert, a ticket, and a mail to whoever reviews it; a tool that
printed what it found would copy the personal data into all of them. Every commercial product
masks for the same reason, and the reports it keeps about what it found are themselves treated as
personal data, which is the last section's subject.

## What the scanner does not see

Patterns find **identifiers**, numbers with a known shape. Most of what a firm would rather keep
also has no shape: a contract, a salary review, a client's tax situation written out in sentences.
No pattern finds those. Commercial tools add three things for them, none of which runs here:

- **labels**, set by a person or a rule when a document is created, which a tool then respects
  ("confidential: clients"), such as Microsoft Purview's sensitivity labels;
- **exact data match**: the tool is given a protected copy of the real client list and recognises
  any document containing rows of it, which finds real clients and not merely valid numbers;
- **fingerprints** of particular documents, so that a copy of the year's contract template is
  recognised even when edited.

A label depends on people applying it. The other two depend on the firm handing the tool a copy of
exactly the data it wants protected, so the tool's own store becomes one more place to protect.
