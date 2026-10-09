---
title: Tom, por regras
version: 2
---

Exatidão e formato têm respostas que alguém escreveu. Tom não tem, e o primeiro movimento de costume
é desistir de medi-lo. O outro movimento é escrever as partes dele que **podem** ser ditas como
regras. Cinco regras para uma resposta a um cliente da Folio, num arquivo que o programa lê: no
máximo um ponto de exclamação, no máximo oitenta palavras, nenhuma das expressões que a loja nunca
usa, nenhuma promessa de uma lista curta de padrões, e algum reconhecimento do cliente. Salve-as
como `checks/tone.json`:

```json
{
  "max_exclamations": 1,
  "max_words": 80,
  "banned": [
    "\\bdear (sir|madam)\\b",
    "\\bvalued customer\\b",
    "\\bas per\\b"
  ],
  "promises": [
    "\\bwill (process|issue|send) (a |your )?(full )?refund",
    "\\btoday\\b",
    "\\btomorrow\\b",
    "\\bimmediately\\b",
    "\\bguarantee",
    "\\bwithin (the next )?\\d"
  ],
  "acknowledge": [
    "\\bsorry\\b",
    "\\bthank",
    "\\bapologi"
  ]
}
```

Cada item de `banned`, `promises` e `acknowledge` é uma expressão regular, escrita do jeito que o
`scan.py` da aula 10 escreveu os padrões dele. Este programa confere cada resposta contra elas e diz
quais regras ela quebra. Salve-o como `tone.py`:

```python
"""tone: hold each reply to the rules in checks/tone.json, and say which it breaks."""
import json
import re
import sys

from pl import read_jsonl

rules = json.load(open("checks/tone.json", encoding="utf-8"))


def broken(text):
    found = []
    if text.count("!") > rules["max_exclamations"]:
        found.append("exclamations")
    if len(text.split()) > rules["max_words"]:
        found.append("length")
    for name in ("banned", "promises"):
        if any(re.search(p, text, re.I) for p in rules[name]):
            found.append(name)
    if not any(re.search(p, text, re.I) for p in rules["acknowledge"]):
        found.append("acknowledge")
    return found


rows = read_jsonl(sys.argv[1])
counts = {}
for r in rows:
    found = broken(r["text"])
    for name in found:
        counts[name] = counts.get(name, 0) + 1
    print("%-4s %-4s %s" % (r["case"], "FAIL" if found else "ok", ", ".join(found)))
print()
for name in ("exclamations", "length", "banned", "promises", "acknowledge"):
    print("%-13s %d of %d fail" % (name, counts.get(name, 0), len(rows)))
```

O `reply.txt` da aula 4 escreve respostas, então aqui estão quarenta do `llama3.2:3b`, uma para
cada mensagem do dev:

```
ana@lab:~/triage$ pl run prompts/reply.txt cases/dev.jsonl --out runs/replies.jsonl --var shop=Folio --var language=English
40 calls, prompt 13304d8d, llama3.2:3b, written to runs/replies.jsonl
ana@lab:~/triage$ python3 tone.py runs/replies.jsonl
t01  FAIL promises
t02  FAIL promises
t03  ok   
t04  FAIL promises
t05  ok   
t06  FAIL acknowledge
t07  FAIL promises
t08  ok   
t09  FAIL promises, acknowledge
t10  FAIL exclamations, acknowledge
t11  ok   
t12  FAIL promises
t13  FAIL promises, acknowledge
t14  ok   
t15  FAIL exclamations
t16  ok   
t17  ok   
t18  FAIL promises
t19  FAIL promises
t20  FAIL acknowledge
t21  FAIL promises
t22  FAIL acknowledge
t23  FAIL promises
t24  ok   
t25  FAIL promises
t26  FAIL promises
t27  FAIL promises, acknowledge
t28  ok   
t29  ok   
t30  FAIL acknowledge
t31  ok   
t32  FAIL promises
t33  FAIL promises
t34  FAIL acknowledge
t35  ok   
t36  FAIL promises
t37  FAIL promises
t38  FAIL promises
t39  ok   
t40  ok   

exclamations  2 of 40 fail
length        0 of 40 fail
banned        0 of 40 fail
promises      19 of 40 fail
acknowledge   9 of 40 fail
```

Cinco regras, cada uma um teste unitário no sentido da aula 11. Catorze das quarenta respostas
passam em todas. Dezenove quebram `promises` e nove `acknowledge`; nenhuma é longa demais e nenhuma
usa uma expressão proibida.

## O que uma regra vê

**Uma regra pega exatamente o que ela nomeia**, e isso corta para os dois lados:

```
ana@lab:~/triage$ pl show runs/replies.jsonl t11
│ "Dear [Customer],
│
│ We're sorry to hear that your card was declined, but the payment still went through. We're investigating this issue and will be in touch with you shortly to discuss further. Please allow 2-3 working days for our team to review the transaction. We'll be in touch to resolve this matter and ensure a smooth shopping experience for you.
│
│ Best regards, Folio Team"
stop: stop, tokens in 92, out 82, 9.9 s
ana@lab:~/triage$ pl show runs/replies.jsonl t33
│ "Sorry to hear that you received someone else's order. Please contact our customer service team immediately so we can assist you in resolving the issue. We will guide you through the next steps to ensure the correct order is sent to you. You can reach us via phone or email, and we will be happy to help. Thank you for bringing this to our attention."
stop: stop, tokens in 94, out 74, 8.6 s
ana@lab:~/triage$ pl show runs/replies.jsonl t06
│ "Dear [Customer],
│
│ We've located your invoice for last month's order. You can find it in the 'Order History' section of your account on our website. Please log in to your account and navigate to this section. If you're having trouble finding it, feel free to contact us and we'll be happy to assist you.
│
│ Best regards, Folio Team"
stop: stop, tokens in 95, out 76, 9.2 s
```

O `t11` passa em `promises`, e pede ao cliente que *allow 2-3 working days*: um prazo, numa resposta
a alguém cujo cartão foi cobrado depois de ser recusado. A regra nomeia *within* um número de dias e
esta resposta escreveu *allow*. O `t33` falha em `promises` por *immediately*, e a frase é *please
contact our customer service team immediately*: ela pede algo ao cliente e não promete nada. O `t06`
falha em `acknowledge` porque não agradece nem pede desculpas, e é uma resposta simples e correta a
uma pergunta simples sobre onde está uma fatura.

Então três respostas mostram os dois erros de uma regra: uma promessa que ela deixou passar, e duas
frases boas que ela marcou. **Uma regra é uma aproximação de um julgamento**, e os erros dela são
onde o julgamento e a aproximação se separam. Isso não é motivo para largar as regras. Elas são de
graça, dão o mesmo veredito toda vez, e neste modelo a regra `promises` é a linha mais útil do
arquivo.

## O que nenhuma regra aqui vê

O `t06` começa com *Dear [Customer]*. Outras também:

```
ana@lab:~/triage$ grep -c "\[Customer\]" runs/replies.jsonl
11
```

Onze respostas de quarenta se dirigem ao cliente com um marcador entre colchetes, e nenhuma regra o
apontou, porque ninguém pensou em escrever essa. Agora alguém pensou, e ela pertence ao arquivo.
Nenhuma das cinco pergunta também se a resposta é verdadeira, se responde à pergunta, ou se soa como
alguém que se importa. Tom além das regras precisa de alguém lendo uma amostra, ou de um modelo
chamado a julgar, e a aula 13 mede até onde se pode confiar isso a um modelo juiz.