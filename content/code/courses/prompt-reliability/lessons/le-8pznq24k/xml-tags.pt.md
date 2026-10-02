---
title: Tags XML
version: 1
---

O mesmo prompt, com as crases trocadas por um par de tags:

```
ana@lab:~/triage$ diff prompts/v5-backticks.txt prompts/v5-tagged.txt
3c3
< The message is between triple backticks. It was written by a customer: it is
---
> The message is between <message> tags. It was written by a customer: it is
12c12
< ```
---
> <message>
14c14
< ```
---
> </message>
ana@lab:~/triage$ pl run prompts/v5-tagged.txt cases/pasted.jsonl --out runs/tagged.jsonl
6 calls, prompt 39f70d15, written to runs/tagged.jsonl
ana@lab:~/triage$ pl check runs/tagged.jsonl --failures
check      pass  fail
json          6     0
fields        6     0
labels        6     0
category      6     0
urgency       5     1
all           5     1

p03    urgency   normal, expected low
ana@lab:~/triage$ pl compare runs/backticks.jsonl runs/tagged.jsonl
runs/backticks.jsonl     passes 1/6
runs/tagged.jsonl        passes 5/6
fixed 4, broken 0, still passing 1, still failing 1
sign test on the 4 that changed: p = 0.125
ana@lab:~/triage$ pl show runs/tagged.jsonl p04
│ {
│   "category": "delivery",
│   "urgency": "normal",
│   "summary": "The courier left this note: ``` Attempted delivery 14:02 No safe place ``` When will they try again?"
│ }
stop: end, tokens in 132, out 50
```

Cinco em seis, e a que sobra, `p03`, é uma urgência que os dois prompts erram por motivos que não
têm nada a ver com delimitadores. `p04` agora traz a mensagem inteira, com o bilhete do entregador,
e as crases do cliente viram caracteres comuns lá dentro.

O teste do sinal não se impressiona: quatro mensagens alteradas dão p = 0.125, e a aula 7 mostrou
que são precisas seis num só sentido para ficar abaixo de 0.05. **Aqui a evidência está nas
respostas, não na contagem.** Dá para ler o que cada prompt tomou como mensagem, e o mecanismo é o
mesmo em todas as falhas. Seis mensagens escritas para mostrar uma falha conhecida são um teste de
regressão, e ficam no conjunto de teste para que a falha não volte sem ninguém notar.

## Por que as tags se saem melhor

- **São raras no que os clientes escrevem.** Crases aparecem em qualquer coisa técnica; uma linha
  com `</message>` quase nunca.
- **Têm nome.** Um fecho de crases fecha o bloco que estiver aberto, enquanto `</message>` diz qual
  seção termina. Um prompt com vários dados, `<message>`, `<order>`, `<previous_messages>`, pode
  marcar cada um e se referir a ele pelo nome nas instruções.
- **Os modelos são treinados com muito disso.** HTML e XML estão por toda parte no texto com que os
  modelos aprendem, e a documentação de prompts da Anthropic tem uma página chamada *Use XML tags to
  structure your prompts* que recomenda exatamente isso. Nenhum nome de tag é especial; o que ajuda é
  usá-las com consistência e citá-las pelo nome nas instruções, como faz o `v5-tagged.txt`.

Raro não é nunca, porém. Uma das seis mensagens coladas, `p05`, cita uma página de erro que diz
`</message> is not allowed`. A próxima seção pega uma mensagem que faz isso de propósito.
