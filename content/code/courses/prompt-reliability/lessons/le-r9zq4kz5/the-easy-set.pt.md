---
title: O conjunto fácil
version: 1
---

O `cases/dev.jsonl` tem a fraqueza que todo primeiro conjunto de teste tem. **Foi escrito pela pessoa
que escreveu o prompt**, ao mesmo tempo, com a mesma imagem da caixa de entrada na cabeça. Depois o
prompt foi melhorado, versão após versão, vendo a nota desse conjunto subir.

O `cases/holdout.jsonl` foi escrito depois, a partir de mensagens mais difíceis, e o prompt nunca o
viu enquanto era alterado:

```
ana@lab:~/triage$ head -n 3 cases/holdout.jsonl
{"id": "h01", "message": "I returned the paperback but you refunded the wrong card.", "expect": {"category": "billing", "urgency": "normal"}}
{"id": "h02", "message": "The delivery driver left my parcel with a neighbour I don't know. Can you find out who has it?", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "h03", "message": "My account shows an order I never placed and my card has been charged for it.", "expect": {"category": "billing", "urgency": "high"}}
ana@lab:~/triage$ pl check runs/v3.jsonl --failures
check      pass  fail
json         40     0
fields       40     0
labels       40     0
category     39     1
urgency      36     4
all          36     4

t14    urgency   normal, expected low
t24    urgency   low, expected normal
t28    urgency   normal, expected low
t37    category  billing, expected delivery
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/holdout.jsonl --out runs/v3-holdout.jsonl
30 calls, prompt 1d9c6ec4, written to runs/v3-holdout.jsonl
ana@lab:~/triage$ pl check runs/v3-holdout.jsonl --failures
check      pass  fail
json         30     0
fields       30     0
labels       30     0
category     17    13
urgency      11    19
all          11    19

h01    category  returns, expected billing
h03    urgency   normal, expected high
h04    category  delivery, expected returns
h06    urgency   normal, expected high
h07    category  account, expected billing
h09    urgency   normal, expected low
h10    urgency   normal, expected low
h11    category  delivery, expected account
h13    category  billing, expected returns
h14    category  billing, expected other
h15    category  billing, expected account
h16    category  other, expected returns
h19    category  billing, expected account
h20    category  billing, expected delivery
h22    urgency   normal, expected high
h24    urgency   normal, expected high
h26    category  billing, expected other
h27    category  billing, expected account
h30    category  billing, expected other
```

O mesmo prompt passa em 36 de 40 no conjunto contra o qual foi escrito, 90%, e em 11 de 30 no outro,
37%. Toda resposta continua sendo JSON válido. O que falha é o julgamento: `h01` é um reembolso no cartão
errado, um problema de billing escrito com as palavras de uma devolução, e `h03`, uma cobrança por um
pedido que ninguém fez, volta com urgência normal. **A nota de dev mediu como o prompt lida com
mensagens parecidas com as que o autor imaginou**, e o autor imaginou as fáceis.

No substituto essa distância é mecânica: ele classifica por palavras-chave, e o holdout foi escrito
com as palavras-chave erradas de propósito. Um modelo real lê melhor que isso, mas o hábito de onde
vem a distância não tem a ver com o modelo. Quem escreveu o prompt e os casos escreveu casos que o
prompt resolve.

## Um conjunto contra o qual você ajusta deixa de medir

Toda mudança que você mantém porque a nota de dev subiu é uma mudança ajustada àquelas quarenta
mensagens. Duas correções para o problema de formato mostram o custo disso:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/holdout.jsonl --out runs/v4-holdout.jsonl
30 calls, prompt 651820d7, written to runs/v4-holdout.jsonl
ana@lab:~/triage$ pl compare runs/v4-holdout.jsonl runs/v3-holdout.jsonl
runs/v4-holdout.jsonl    passes 11/30
runs/v3-holdout.jsonl    passes 11/30
fixed 1, broken 1, still passing 10, still failing 18
broken: h07
sign test on the 2 that changed: p = 1.000
```

Em dev, a `v3` venceu a `v4` por 36 a 34. No holdout elas empatam em 11, uma mensagem corrigida e uma
quebrada. O que tornou a `v3` melhor em dev não aparece em mensagens contra as quais ela não foi
escolhida, e ninguém que escolhesse entre as duas pela nota de dev teria como saber.

## Mantenha um holdout, e olhe para ele raramente

- **Construa-o separado do dev.** Escreva-o depois do dev, a partir de outras mensagens, de
  preferência rotulado por outra pessoa.
- **Rode-o na hora de decidir, não enquanto edita.** Depois que uma versão é escolhida em dev, o
  holdout diz se a escolha se sustenta.
- **Não corrija as falhas dele uma a uma.** No momento em que você lê a resposta de `h01` e muda o
  prompt por causa dela, `h01` virou um caso de dev. **Um holdout contra o qual você ajusta vira um
  segundo dev**, e você precisa de um novo.
