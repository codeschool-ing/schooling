---
title: What personal data looks like to a machine
version: 1
---

**A DLP tool cannot read a document the way a person does. It finds patterns, and then checks
them.** The pattern is the shape of the thing: eleven digits for a CPF, sixteen for a card. The
check is the arithmetic the issuer built into the number, and it is what separates a CPF from any
other eleven digits on a page.

Both of the identifiers that matter most to a Brazilian accounting firm carry their own check
digits. A **CPF** is nine digits and two check digits computed from them. A **card number** ends in
one Luhn check digit computed from all the others. Mistyping one digit changes the check, which is
why the issuers put it there; a scanner uses the same arithmetic to tell a real-looking number from
a number that only has the right length.

## A client list nobody is on

To practise, you need a file full of personal data, and **real personal data is never the way to
get one**: a test file with real clients in it is a leak waiting for a careless copy. So the lesson
makes its own. Save this on `desk` as `fakedata.py`:

```schooling-example
{"language": "python", "file": "fakedata.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"fakedata.py: a client list for Jatobá made of invented people, with valid-looking CPFs and cards.\"\"\"\nimport random, sys\n\nrng = random.Random(2026)\nFIRST = [\"Ana\", \"Bruno\", \"Carla\", \"Diego\", \"Elisa\", \"Fábio\", \"Gabriela\", \"Heitor\", \"Iara\", \"João\"]\nLAST = [\"Souza\", \"Lima\", \"Pereira\", \"Costa\", \"Rocha\", \"Alves\", \"Gomes\", \"Ribeiro\"]", "note": "The generator is seeded, so it writes the same list every time and on every computer, and your file matches the one in the transcripts. The names are combinations of common first and last names: nobody in particular."}, {"code": "def cpf():\n    d = [rng.randrange(10) for _ in range(9)]\n    for n in (10, 11):\n        r = sum(x * w for x, w in zip(d, range(n, 1, -1))) * 10 % 11\n        d.append(0 if r == 10 else r)\n    s = \"\".join(map(str, d))\n    return f\"{s[:3]}.{s[3:6]}.{s[6:9]}-{s[9:]}\"", "note": "A CPF is nine digits and two check digits. The first check digit weighs the nine by 10 down to 2, the second weighs ten digits by 11 down to 2, and each is the remainder of ten times the sum divided by eleven, with 10 written as 0. A number made up at random passes this test about once in a hundred tries, and that is what a scanner will use."}, {"code": "def card():\n    d = [9, 9, 9, 9] + [rng.randrange(10) for _ in range(11)]\n    total = 0\n    for i, x in enumerate(reversed(d)):\n        x = x * 2 if i % 2 == 0 else x\n        total += x - 9 if x > 9 else x\n    d.append((10 - total % 10) % 10)\n    return \" \".join(\"\".join(map(str, d[i:i + 4])) for i in range(0, 16, 4))", "note": "A card number ends in a Luhn check digit: from the right, every second digit is doubled, nine is taken off anything above nine, and the last digit makes the total a multiple of ten. These all start with `9999`, a prefix no card network issues, so they look like card numbers to a scanner and are nobody's card."}, {"code": "print(\"name;cpf;card\")\nfor _ in range(int(sys.argv[1]) if len(sys.argv) > 1 else 20):\n    print(f\"{rng.choice(FIRST)} {rng.choice(LAST)};{cpf()};{card()}\")", "note": "One line per client, separated by semicolons, as a Brazilian spreadsheet exports them. The argument is how many clients; twenty if you give none."}]}
```

Run it and look at the first lines:

```
ana@desk:~$ python3 fakedata.py > clientes.csv; head -4 clientes.csv; wc -l clientes.csv
name;cpf;card
Bruno Alves;881.399.869-41;9999 8797 3091 1410
Heitor Souza;753.645.568-24;9999 1518 8447 2940
Ana Alves;576.169.871-41;9999 6897 6846 9789
21 clientes.csv
```

Twenty clients, every CPF passing the Receita's arithmetic and every card passing Luhn's, and none
of them anybody's. The same seed gives you the same twenty, so your file and this transcript match
line for line.

## The checks, by hand

The scanner of the next section carries the two checks as functions. Ask it about a CPF from the
list and the same CPF with its last digit changed, then the same with a card:

```
ana@desk:~$ python3 -c 'import scan; print(scan.cpf_ok("881.399.869-41"), scan.cpf_ok("881.399.869-42"))'
True False
ana@desk:~$ python3 -c 'import scan; print(scan.luhn_ok("9999 8797 3091 1410"), scan.luhn_ok("9999 8797 3091 1411"))'
True False
```

One digit changed, and both answers flip. That is the check digit doing its job, and it is the
whole reason a scanner can be told to report only numbers that are valid: **an order number that
happens to have eleven digits fails the CPF arithmetic about ninety-nine times in a hundred.** The
hundredth time is the next section's subject.
