---
title: O que a amostragem muda
version: 1
---

A mesma verificação, numa execução diferente: um prompt, cinco amostras por mensagem com
temperatura 0,8, a execução da aula 19 cuja votação se saiu pior que a temperatura 0.

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --samples 5 --set temperature=0.8 --out runs/s5.jsonl
350 calls, prompt fbc4c9b1, written to runs/s5.jsonl
ana@lab:~/triage$ pl selfcheck runs/s5.jsonl | tail -n 4
               really wrong  really right
flagged                 102            16
not flagged              19           213
precision 0.86   recall 0.84
```

A revocação vai de 0,57 para **0,84**, e a precisão de 0,73 para 0,86. O verificador não mudou. Os
erros mudaram.

## Deslizes e equívocos

Uma resposta amostrada pode estar errada de dois jeitos. Pode ser um **deslize**: o substituto
favorecia o rótulo certo, e o sorteio caiu em outro. Ou pode ser um **equívoco**: o substituto
favorece o rótulo errado, e o sorteio o encontrou. O revisor lê a mensagem sem amostrar, então vê o
rótulo que o substituto favorece. Duas mensagens mostram os dois tipos:

```
ana@lab:~/triage$ pl selfcheck runs/s5.jsonl | grep -E "^(t37|h27)"
t37  wrong  WRONG: the category should be delivery
t37  wrong  WRONG: the category should be delivery
t37  wrong  WRONG: the category should be delivery
t37  wrong  WRONG: the category should be delivery
t37  right  WRONG: it could also be other
h27  wrong  OK
h27  wrong  OK
h27  wrong  OK
h27  right  WRONG: the category should be billing
h27  wrong  OK
```

`t37` é um deslize repetido quatro vezes. A temperatura 0 responde delivery, que está certo, e quatro
amostras sortearam outra coisa; o revisor diz *the category should be delivery* para cada uma. A
quinta amostra estava certa e mesmo assim foi posta em dúvida, como na execução com temperatura 0.

`h27` é o cartão-presente de novo, e um equívoco. Quatro amostras disseram billing, o rótulo em que
o substituto acredita, e o revisor aprovou as quatro. Uma amostra sorteou account, o rótulo da
pessoa, e o revisor **a empurrou de volta para a resposta errada**: *the category should be
billing*.

Com temperatura 0, todo erro de rótulo é um equívoco, porque a resposta é, por definição, o rótulo
favorecido. É por isso que a revocação era 0,57 lá e é 0,84 aqui. **A autoavaliação pega deslizes e
deixa passar equívocos**, e a proporção de cada um depende da execução, então uma revocação medida
numa configuração diz pouco sobre outra. Meça a verificação nos parâmetros que você vai colocar em
produção.

## Modelos reais

A regra do substituto torna essa divisão exata. Para modelos reais a pesquisa é mista, e vale saber
um resultado pelo nome. *Large Language Models Cannot Self-Correct Reasoning Yet* (Huang e outros,
2023) pediu a modelos que revisassem e corrigissem as próprias respostas a problemas de raciocínio
sem nenhuma informação de fora. O artigo viu que isso muitas vezes não as melhorava e às vezes as piorava,
convencendo o modelo a trocar uma resposta certa por uma errada, como o revisor fez com `h27` acima.
Os autores também apontaram que alguns relatos anteriores de autocorreção bem-sucedida dependiam de
saber, de fora do modelo, quando uma resposta estava errada.

A leitura que esta aula tira dos dois é estreita: um modelo que se confere sem informação nova só
tem a própria visão para conferir. Onde essa visão está certa e a resposta escorregou, ajuda. Onde a
visão está errada, ele concorda.
