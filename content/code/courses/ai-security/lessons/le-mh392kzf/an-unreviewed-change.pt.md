---
title: Uma frase simpática, e as respostas que ela quebrou
version: 1
---

Alguém da equipe de suporte acha o assistente frio e acrescenta uma linha ao prompt pedindo que ele
cumprimente os clientes com calor. É um desejo razoável, digitado direto no arquivo:

```
ana@lab:~/guard$ echo "Always greet the client warmly and thank them for their patience." >> data/prompts/classify.txt
ana@lab:~/guard$ guard prompts status; echo "exit status $?"
data/prompts/classify.txt    06390ce0eb  NOT APPROVED
data/helpdesk/hc-fees.md     ff40a81202  approved by ana.lima on 2026-10-01
data/helpdesk/hc-payouts.md  0fe2b8eec1  approved by ana.lima on 2026-10-01
data/helpdesk/hc-refunds.md  f32fa16253  approved by ana.lima on 2026-10-01
data/model.json              3138932013  approved by ana.lima on 2026-10-01
exit status 1
```

O `status` percebe na hora: o prompt está numa versão que ninguém aprovou, e o status de saída volta a
ser 1. No build, isso é um pull request que não pode ser integrado até alguém revisar a mudança. Num
servidor em que alguém editou o arquivo à mão, é a verificação que avisa a equipe de que o assistente
em produção não é o que ela aprovou.

O que a mudança faz é uma medida, não uma opinião. Os mesmos doze tickets:

```
ana@lab:~/guard$ guard route data/tickets.jsonl
prompt version 06390ce0eb, model llama3.2:3b: 9 of 12 right, missed t5, t6, t8
ana@lab:~/guard$ guard route data/tickets.jsonl
prompt version 06390ce0eb, model llama3.2:3b: 9 of 12 right, missed t5, t6, t8
```

**Nove certos em vez de dez**, duas vezes, por causa de uma frase que ninguém quis que mexesse na
classificação, e a lista de erros diz que ticket ela custou: o `t6` é novo. A versão nova está em cada
linha de log dessas execuções, então as respostas podem ser separadas depois. O programa que lê o log
de volta é curto. Salve-o como `~/guard/tools/trace.py`:

```python
# trace.py: which prompt, which version and which model produced a reply.
#
#   guard trace CALL
#
# It finds the call in data/prompt-log.jsonl and prints what produced it, and
# whether that version of the prompt was ever approved, and by whom.
import argparse
import json
import os

from prompts import approved, load

p = argparse.ArgumentParser(prog="guard trace")
p.add_argument("call")
a = p.parse_args()

with open(os.path.expanduser("~/guard/data/prompt-log.jsonl"), encoding="utf-8") as f:
    line = next((r for r in map(json.loads, f) if r["call"] == a.call), None)
if line is None:
    p.exit(1, "trace: no call %s in the log\n" % a.call)
e = approved(load(), line["prompt"], line["version"])
print("call     %s (ticket %s)" % (line["call"], line["ticket"]))
print("prompt   %s, version %s" % (line["prompt"], line["version"]))
print("model    %s" % line["model"])
print("approved %s" % ("by %s on %s: %s" % (e["by"], e["on"], e["reason"]) if e else "NEVER"))
print("reply    %s" % line["reply"].replace("\n", " / ")[:70])
```

```
ana@lab:~/guard$ guard trace c18
call     c18 (ticket t6)
prompt   data/prompts/classify.txt, version aa32449d3f
model    llama3.2:3b
approved by ana.lima on 2026-10-01: reviewed, tickets measured
reply    {"category": "account"}
ana@lab:~/guard$ guard trace c30
call     c30 (ticket t6)
prompt   data/prompts/classify.txt, version 06390ce0eb
model    llama3.2:3b
approved NEVER
reply    Dear client, I must say, / Your patience is appreciated each day. / A 
```

O `c18` e o `c30` são o mesmo ticket, o `t6`, antes e depois da edição. Antes, a resposta é o JSON que o
código lê, de um prompt que `ana.lima` aprovou em 1º de outubro. Depois, o modelo escreveu um poema,
cumprimentando o cliente com calor como pedido, de uma versão **aprovada por ninguém**. Sem a versão no
log, o poema seria um mistério no log de chamadas: o mesmo assistente, o mesmo modelo, uma resposta
diferente, e nada para dizer por quê. Com ela, o `T10` da aula 13 tem seu controle. Uma reclamação
sobre qualquer resposta é ligada ao prompt e ao modelo exatos que a produziram, e à pessoa que os
aprovou.

## Por que um modelo pequeno mostra isso em voz alta

Um modelo maior talvez tivesse cumprimentado o cliente dentro de um objeto JSON válido, ou ignorado o
cumprimento. Ainda assim teria sido um programa diferente, e os doze tickets são o que mostraria quão
diferente. **O efeito do prompt sobre a saída não se lê no prompt**; ele é medido, nos casos que
importam, toda vez que o prompt muda. A aula 23 transforma esta execução num teste que o build faz em
todo pull request que toca um arquivo sob revisão.
