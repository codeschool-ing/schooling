---
title: O conjunto fácil
version: 2
---

O `cases/dev.jsonl` tem a fraqueza que todo primeiro conjunto de teste tem. **Foi escrito pela
pessoa que escreveu o prompt**, ao mesmo tempo, com a mesma imagem da caixa de entrada na cabeça. O
prompt depois foi melhorado, versão após versão, olhando a nota desse conjunto subir.

O `cases/holdout.jsonl`, salvo na aula 5, foi escrito depois, a partir de mensagens mais difíceis, e
nenhum prompt deste curso foi mudado olhando para ele:

```
ana@lab:~/triage$ head -n 3 cases/holdout.jsonl
{"id": "h01", "message": "I returned the paperback but you refunded the wrong card.", "expect": {"category": "billing", "urgency": "normal"}}
{"id": "h02", "message": "The delivery driver left my parcel with a neighbour I don't know. Can you find out who has it?", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "h03", "message": "My account shows an order I never placed and my card has been charged for it.", "expect": {"category": "billing", "urgency": "high"}}
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/holdout.jsonl --out runs/v3-holdout.jsonl
30 calls, prompt 1d9c6ec4, llama3.2:3b, written to runs/v3-holdout.jsonl
ana@lab:~/triage$ pl check runs/v3-holdout.jsonl --failures
check      pass  fail
json         30     0
fields       30     0
labels       30     0
category     18    12
urgency      14    16
all          14    16

h01    category  returns, expected billing
h02    urgency   high, expected normal
h03    category  account, expected billing
h05    category  account, expected billing
h06    category  returns, expected delivery
h07    category  account, expected billing
h08    category  billing, expected returns
h11    category  delivery, expected account
h15    urgency   low, expected normal
h16    category  delivery, expected returns
h17    urgency   high, expected normal
h19    category  other, expected account
h21    category  returns, expected delivery
h23    category  billing, expected returns
h27    category  billing, expected account
h29    urgency   high, expected normal
```

O mesmo prompt passa 28 de 40 no conjunto contra o qual foi escrito, 70%, e 14 de 30 no outro, 47%.
Toda resposta continua sendo JSON válido. O que falha é o julgamento: o `h01` é um reembolso no
cartão errado, um problema de cobrança escrito com as palavras de uma devolução, e o `h03`, uma
cobrança por um pedido que ninguém fez, volta como `account`, o substantivo com que a mensagem abre.
Doze categorias erradas em trinta, contra quatro categorias erradas, e uma resposta que não é JSON
válido, em quarenta no dev. **A nota do dev mediu o quanto o prompt lida com mensagens como as que o
autor dele imaginou**, e o autor imaginou as mais fáceis.

## Um conjunto em que você ajusta para de medir

Toda mudança que você mantém porque a nota do dev subiu é uma mudança ajustada àquelas quarenta
mensagens, e o holdout é onde você descobre se ela foi ajustada a mais alguma coisa. Aqui ele recebe
a comparação da primeira seção, `v4` contra `v3`:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/holdout.jsonl --out runs/v4-holdout.jsonl
30 calls, prompt 651820d7, llama3.2:3b, written to runs/v4-holdout.jsonl
ana@lab:~/triage$ pl compare runs/v4-holdout.jsonl runs/v3-holdout.jsonl
runs/v4-holdout.jsonl    passes 4/30
runs/v3-holdout.jsonl    passes 14/30
fixed 10, broken 0
sign test on the 10 that changed: p = 0.002
```

No dev, o `v3` venceu o `v4` por 28 a 20. No holdout vence por 14 a 4, dez mensagens consertadas e
nenhuma quebrada, p = 0.002. **Desta vez o holdout confirma a escolha**: o que quer que os três
exemplos tenham ensinado, não era algo sobre aquelas quarenta mensagens. Essa é a outra metade do
trabalho de um holdout, e a mais comum. Ele não existe para derrubar decisões; existe para que uma
decisão que ele não derruba tenha sido testada em algo com que não foi tomada.

O caso oposto precisa de uma mudança que venceu no dev por se ajustar ao dev, e a próxima seção
constrói exatamente isso.

## Mantenha um holdout, e olhe para ele raramente

- **Construa-o à parte do dev.** Escreva-o depois do dev, a partir de outras mensagens, de
  preferência rotulado por outra pessoa.
- **Rode-o na hora de decidir, não enquanto edita.** Depois que uma versão é escolhida no dev, o
  holdout diz se a escolha se sustenta.
- **Não conserte as falhas dele uma a uma.** No momento em que você lê a resposta do `h01` e muda o
  prompt por causa dela, o `h01` virou um caso de dev. **Um holdout em que você ajusta vira um
  segundo dev**, e você precisa de um novo.
