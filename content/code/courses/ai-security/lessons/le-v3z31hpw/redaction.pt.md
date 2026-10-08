---
title: Fazer a redação antes de o registro ser gravado
version: 2
---

**A redação acontece na entrada, antes de o registro chegar a qualquer depósito.** Redigir um log
depois de gravado deixa uma janela em que a cópia sem redação existe, e nessa janela ela entra no
backup, é enviada a um fornecedor de logs, é indexada para busca e é lida por quem estava depurando.
Cada uma dessas é uma cópia que a redação posterior não alcança. No `~/guard`, o `tiers.py` faz a
camada com redação com a mesma função que o `guard redact` chama, e numa aplicação de verdade essa
chamada acontece no momento em que o registro é gravado.

Antes de redigir qualquer coisa, meça o que existe. O `guard scan` passa os cinco detectores do
`detect.py` pelo texto de cada registro, o prompt e a resposta. Salve-o como `~/guard/tools/scan.py`:

```python
# scan.py: how many records in a log hold personal data or a secret, by kind.
#
#   guard scan [--show] [--strict] PATH...
#
# PATH is a log file or a directory of them. Both the prompt and the output
# of every record are read. --show lists every match and what was decided:
# redact, or LEAVE for a shape whose check digits are wrong.
import argparse
import json
import os
from collections import Counter

from detect import KINDS, find

p = argparse.ArgumentParser(prog="guard scan")
p.add_argument("paths", nargs="+")
p.add_argument("--show", action="store_true")
p.add_argument("--strict", action="store_true")
a = p.parse_args()

files = []
for path in a.paths:
    if os.path.isdir(path):
        files += sorted(os.path.join(path, n) for n in os.listdir(path) if n.endswith(".jsonl"))
    else:
        files.append(path)

held, shaped, total, hit = Counter(), Counter(), 0, 0
for name in files:
    with open(name, encoding="utf-8") as f:
        for rec in map(json.loads, f):
            total += 1
            kinds, rejected = set(), set()
            for field in ("prompt", "output"):
                for kind, x, y, ok in find(rec[field], a.strict):
                    (kinds if ok else rejected).add(kind)
                    if a.show:
                        print("%s  %-6s  %-6s  %-8s %s" % (rec["request"], field, kind,
                                                          "redact" if ok else "LEAVE", rec[field][x:y]))
            held.update(kinds)
            shaped.update(rejected)
            hit += bool(kinds)
if a.show:
    print()
print("%d records in %d files" % (total, len(files)))
for kind in KINDS:
    line = "  %-7s %2d records" % (kind, held[kind])
    if shaped[kind]:
        line += "   (%d more %s-shaped, check digits wrong)" % (
            shaped[kind], kind.upper() if kind == "cpf" else kind)
    print(line)
print("%d of %d records hold at least one" % (hit, total))
```

```
ana@lab:~/guard$ guard scan logs/raw
22 records in 19 files
  secret   2 records
  email    3 records
  phone    2 records
  card     1 records   (1 more card-shaped, check digits wrong)
  cpf      4 records   (1 more CPF-shaped, check digits wrong)
11 of 22 records hold at least one
```

Metade do log. São registros de um assistente de suporte que nunca pediu número de documento a
ninguém, e a proporção é invenção do curso, mas o formato é o que as equipes encontram quando olham
pela primeira vez: as pessoas colam aquilo sobre o que são perguntadas, e são perguntadas sobre as
próprias contas.

## Um formato, e depois a conta

Cada detector é um padrão para um formato: onze dígitos pontuados como um CPF, de treze a dezenove
dígitos como um cartão. Só o formato é um teste fraco, porque números de pedido e códigos de
rastreio têm os mesmos formatos. **Um CPF e um número de cartão trazem os próprios dígitos
verificadores**, então o detector confere a conta também, e deixa em paz os números que falham nela.
O `--show` lista cada casamento e o que foi decidido:

```
ana@lab:~/guard$ guard scan --show logs/raw
rq-0001  prompt  email   redact   marcos.teixeira@example.com.br
rq-0003  prompt  cpf     redact   529.982.247-25
rq-0004  prompt  cpf     LEAVE    123.456.789-00
rq-0004  output  cpf     LEAVE    123.456.789-00
rq-0005  prompt  card    redact   4111 1111 1111 1111
rq-0006  prompt  phone   redact   +55 11 98765-4321
rq-0008  prompt  secret  redact   sk-lab-EXAMPLE7fQ2mX9pL4vT8nR1wZ6
rq-0010  prompt  card    LEAVE    1234 5678 9012 3456
rq-0011  prompt  email   redact   fernanda.rocha@example.com
rq-0013  prompt  cpf     redact   111.444.777-35
rq-0017  prompt  phone   redact   (21) 99876-5432
rq-0018  prompt  secret  redact   AKIAIOSFODNN7EXAMPLE
rq-0019  prompt  cpf     redact   390.533.447-05
rq-0021  prompt  email   redact   marcos.t@example.org
rq-0021  prompt  cpf     redact   714.602.380-01

22 records in 19 files
  secret   2 records
  email    3 records
  phone    2 records
  card     1 records   (1 more card-shaped, check digits wrong)
  cpf      4 records   (1 more CPF-shaped, check digits wrong)
11 of 22 records hold at least one
```

`123.456.789-00` no `rq-0004` é um número de pedido escrito como CPF, e os dígitos verificadores
estão errados, então ele fica. Mantê-lo importa mais do que parece: o número do pedido é o que quem
depura a conversa precisa para achar o pedido, e um log redigido até virar uma fila de `[CPF]` não
responde pergunta nenhuma. `1234 5678 9012 3456` no `rq-0010` é o código de rastreio de uma
encomenda e falha na conferência de Luhn, que todo número de cartão passa.

Repare que o `rq-0004` casou na resposta além do prompt. **O modelo repete o que lhe dizem**, então a
resposta tem tanta chance de levar dado pessoal quanto o prompt, e um redator que só lê o prompt
protege meio registro.

A conta tem um custo, e o `--strict` o mostra tirando a conferência e redigindo todo formato:

```
ana@lab:~/guard$ guard scan --strict logs/raw
22 records in 19 files
  secret   2 records
  email    3 records
  phone    2 records
  card     2 records
  cpf      5 records
13 of 22 records hold at least one
```

Mais dois registros perdem um número. Neste log os dois eram inofensivos, mas um cliente que digita
o CPF com um dígito errado produz um número que falha na conferência e é quase todo o CPF dele. Para
que lado pender é uma decisão sobre o log: uma camada que só meia dúzia de pessoas lê pode manter os
números de pedido, e uma que vai para um fornecedor de fora pode perdê-los.

## O que um padrão não enxerga

A redação substitui o que reconhece, e ela reconhece formatos. Três registros deste log mostram o
que fica fora de todo formato:

```
ana@lab:~/guard$ guard redact logs/raw/2026-09-29.jsonl
rq-0021  prompt  My new e-mail is [EMAIL] and the CPF on file [CPF] is right
         output  Thanks. The e-mail change needs confirming from the new address; your CPF is unchanged.
rq-0022  prompt  Ok, my number is 21 99876 5432 if the freelancer needs it
         output  Contact details are shared with the freelancer automatically once you accept a proposal, so there's no need to send them here.
ana@lab:~/guard$ guard redact logs/raw/2026-07-28.jsonl
rq-0012  prompt  Write a short bio. Rafael Moreira, backend developer, lives at Rua das Flores 120, Curitiba
         output  Rafael Moreira is a backend developer based in Curitiba who builds reliable APIs...
ana@lab:~/guard$ guard redact logs/raw/2026-04-21.jsonl
rq-0005  prompt  Pay with this card: [CARD], expiry 08/29, CVV 123
         output  Please don't send card details in chat. Use the Payment page, which never shows the number to anybody here.
```

- `rq-0022` é um telefone escrito com espaço onde o padrão espera hífen. O padrão pode ser alargado
  para ele, e o próximo cliente vai escrever de um jeito que ninguém pensou ainda.
- `rq-0012` nomeia uma pessoa e dá o endereço dela. **Nenhum padrão reconhece um nome.** Um modelo de
  reconhecimento de entidades acha muitos, numa taxa que você teria de medir nos seus próprios logs,
  e ainda deixa alguns passarem.
- `rq-0005` perdeu o número do cartão e manteve a validade e o código de segurança. Sem o número eles
  quase não servem para nada, mas este é exatamente o campo que a seção anterior disse que nenhum
  depósito pode guardar, e ele continua em um.

Então a redação é um piso, não uma garantia. **As decisões que protegem as pessoas são as que tratam
do que é gravado**: quais camadas guardam texto, quem pode lê-las e quanto tempo duram. A redação
torna as camadas de vida mais longa mais seguras de guardar. Não as torna seguras para guardar para
sempre, e a próxima seção é sobre o relógio.
