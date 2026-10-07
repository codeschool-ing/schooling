---
title: Um objeto válido ainda pode estar errado
version: 2
---

Quando uma resposta passa no schema, é tentador tratá-la como correta. Ela está só bem formada. **O
schema conferiu a forma da resposta; nada até aqui conferiu a resposta.** Um reembolso pode ser um
número, acima de zero, no campo certo, e ainda ser o número errado.

## Uma reclamação, e uma triagem que passa

A reclamação 7, pelo mesmo laço:

```
ana@lab:~/pe$ cat complaints/7.txt
I was charged twice for my lunch today: R$ 140 on my card instead of R$ 70. Please give me back what I paid twice.
ana@lab:~/pe$ python3 triage.py complaints/7.txt
attempt 1
  step 1: parsed as it is
  step 3: valid against schema.json
  {"category": "cold_or_late", "refund": true, "refund_amount": 70, "summary": "Charged twice for lunch"}
```

Uma tentativa, válida, e o valor está certo: o cliente foi cobrado R$ 140 em vez de R$ 70, então o
que ele pagou duas vezes são **R$ 70**, e o modelo leu isso direito. Todo campo tem o tipo certo e um
valor permitido. O esquema não tem mais nada a dizer, e **a categoria está errada**: uma cobrança
dupla é `billing`, e o modelo a arquivou em `cold_or_late`, a fila do chá demorado. É uma das cinco
palavras permitidas. O esquema só conseguia conferir que era uma delas.

O valor podia ter saído errado com a mesma facilidade, já que os dois números estão na reclamação.
Eis uma triagem que o curso escreveu com esse erro, a cobrança inteira em `refund_amount`:

```
ana@lab:~/pe$ cat triage/7.json
{"category": "billing", "refund": true, "refund_amount": 140, "summary": "Charged twice for lunch; wants the double charge back."}
ana@lab:~/pe$ validate schema.json triage/7.json; echo "exit $?"
valid
exit 0
```

Válida também. E esta quebra uma regra do café que o modelo nunca recebeu:

```
ana@lab:~/pe$ grep 100 handbook/refunds.md
A refund above R$ 100 needs the shift manager's approval.
ana@lab:~/pe$ cat rules.py
import json, sys

t = json.load(open(sys.argv[1]))
problems = []
if t["refund"] and "refund_amount" not in t:
    problems.append("refund is true but no refund_amount was given")
if not t["refund"] and t.get("refund_amount", 0) > 0:
    problems.append("refund is false but refund_amount is above zero")
if t.get("refund_amount", 0) > 100:
    problems.append("refund_amount %s is above R$ 100: the shift manager must approve" % t["refund_amount"])
print("\n".join(problems) or "no rule broken")
sys.exit(1 if problems else 0)
ana@lab:~/pe$ python3 rules.py triage/7.json; echo "exit $?"
refund_amount 140 is above R$ 100: the shift manager must approve
exit 1
ana@lab:~/pe$ python3 rules.py triage/good.json; echo "exit $?"
no rule broken
exit 0
```

A lição 11 usou este mesmo manual para ancorar as respostas de um modelo. Aqui ele fornece uma regra
que o programa impõe, escreva o modelo o que escrever.

## Escrevendo as regras do café como uma conferência

Essas regras falam de valores e das relações entre eles, que é o que um schema não expressa bem.
Algumas linhas de código fazem isso:

```
ana@lab:~/pe$ cat rules.py
import json, sys

t = json.load(open(sys.argv[1]))
problems = []
if t["refund"] and "refund_amount" not in t:
    problems.append("refund is true but no refund_amount was given")
if not t["refund"] and t.get("refund_amount", 0) > 0:
    problems.append("refund is false but refund_amount is above zero")
if t.get("refund_amount", 0) > 100:
    problems.append("refund_amount %s is above R$ 100: the shift manager must approve" % t["refund_amount"])
print("\n".join(problems) or "no rule broken")
sys.exit(1 if problems else 0)
ana@lab:~/pe$ python3 rules.py triage/7.json; echo "exit $?"
refund_amount 140 is above R$ 100: the shift manager must approve
exit 1
ana@lab:~/pe$ python3 rules.py triage/good.json; echo "exit $?"
no rule broken
exit 0
```

A triagem que o curso escreveu para a reclamação 7 quebra a regra do manual, e a conferência diz qual regra em palavras que
permitem a uma pessoa agir. A triagem boa da primeira seção de leitura desta lição não quebra
nenhuma. As outras duas regras pegam uma resposta que se contradiz: um reembolso sem valor, ou um
valor sem reembolso.

O que o `rules.py` **não** pega é o erro por baixo, 140 onde se deviam 70, nem o do modelo, uma
cobrança dupla arquivada como atendimento lento. Os dois precisam da entrada:
algo que leia a reclamação e a resposta lado a lado. Parte disso pode ser código, por exemplo uma
conferência de que `refund_amount` é um dos valores que a reclamação menciona, na qual 140 passaria.
O resto precisa de uma pessoa, ou de um segundo modelo encarregado de conferir o primeiro, e a lição
5 já disse por que a confiança de um modelo não é prova de nada. **As conferências que mais importam
são as que o modelo não consegue passar escrevendo texto plausível.**

## Três camadas, em ordem

Uma resposta destinada a um programa passa por três conferências, da mais barata para a mais cara:

| conferência | o que ela pega | nesta lição |
|---|---|---|
| parse | texto que nem é JSON | lição 18, e os passos 1 e 2 do `repair` |
| schema | tipos errados, valores desconhecidos, campos faltando ou sobrando | `validate`, passo 3 do `repair` |
| regras | valores que o café não permite, contradições, valores acima de um limite | `rules.py` |

E uma quarta que não é programa: se a resposta é **fiel à sua entrada**. Cada camada deixa passar
coisas que a seguinte barra. **Uma resposta que passou pelos três programas ganhou mais confiança,
e ainda não toda**: a triagem do modelo para a reclamação 7 passou pelos três e foi para a fila do
chá demorado, e a do curso teria chegado ao gerente em R$ 140, marcada para aprovação pelo motivo
certo e com o valor errado.
