---
title: Cortando custo
version: 2
---

Uma chamada tem duas contagens de tokens e um preço para cada, então há poucos jeitos de deixá-la
mais barata: mandar menos tokens, fazer escrever menos, pagar menos por token, ou pagar menos por
chamada esperando. **Cada um muda o que o modelo vê ou faz, então cada um é uma mudança a testar**,
que é o assunto da próxima seção.

## Menos tokens de entrada

A entrada é o que o prompt leva em toda chamada: instruções, exemplos e a mensagem. A mensagem é do
cliente, então os cortes vêm do resto. Instruções mais curtas, menos exemplos e, para a parte que
nunca muda, o cache da aula 17.

O `v4-only-json.txt` é o prompt dos exemplos sem os três exemplos e com uma linha pedindo só o JSON:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl
40 calls, prompt 651820d7, llama3.2:3b, written to runs/v4.jsonl
ana@lab:~/triage$ python3 cost.py runs/v4.jsonl
runs/v4.jsonl, 40 calls
  input       4846 tokens      121.2 a call
  output      1153 tokens       28.8 a call
  these calls      3.1833 cents
  a million calls  79582.5000 cents
```

A entrada caiu de 248,2 tokens por chamada para 121,2, e o custo de um milhão de chamadas de 120.420
centavos para 79.582,5, um terço a menos. A saída quase não mexeu, 28,8 tokens contra 30,6. Se os
exemplos valiam 40.837,5 centavos por milhão é uma pergunta sobre o que eles faziam, e a próxima
seção responde.

## Menos tokens de saída

A saída é mais cara e mais lenta, então é a alavanca melhor, e há dois jeitos de puxá-la. O primeiro
é **pedir menos**: um resumo com menos de doze palavras em vez de uma frase, nenhuma explicação que
ninguém lê, chaves curtas. A aula 6 mediu o que pedir faz. O segundo é pôr um teto, com o
`num_predict`, o tamanho máximo de saída da aula 6. Um teto não é um jeito de pedir menos, como mostra
um teto posto abaixo da resposta:

```
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --set num_predict=20 --out runs/cap.jsonl
40 calls, prompt 1d9c6ec4, llama3.2:3b, written to runs/cap.jsonl
ana@lab:~/triage$ python3 stats.py runs/cap.jsonl
runs/cap.jsonl, 40 calls
  tokens in    mean  248.2   total   9926
  tokens out   mean   20.0   total    800   max 20
  seconds      p50   2.8   p95   3.1   total  115.7
ana@lab:~/triage$ pl check runs/cap.jsonl --failures | grep -c "cut off at num_predict"
40
ana@lab:~/triage$ pl check runs/v3.jsonl | tail -n 1
all          28    12
ana@lab:~/triage$ pl show runs/cap.jsonl t01
│ {"category": "billing", "urgency": "normal", "summary": "Wants a
stop: length, tokens in 250, out 20, 5.5 s
```

O p95 caiu de 5,0 segundos para 3,1, e as quarenta respostas foram cortadas, onde sem teto o mesmo
prompt aprovava 28. Todas tinham mais de vinte tokens, então todas foram cortadas onde estavam, no
meio de uma string, e o `stop: length` diz isso. **Um teto é um limite para a resposta que dispara,
posto acima da resposta boa mais longa**, que para este prompt tinha 38 tokens. Ele economiza só em
respostas que já estavam dando errado.

## Um modelo mais barato para os casos fáceis

Provedores vendem vários modelos a preços diferentes, e um menor muitas vezes basta para as mensagens
simples: *"I can't log in"* não precisa do modelo mais capaz que existe. **Rotear** manda cada
mensagem para o modelo barato ou para o caro por uma regra decidida antes, como o tamanho da
mensagem, uma palavra-chave, ou a confiança do próprio modelo barato. A regra agora faz parte do
prompt, e é medida como uma: rode o pipeline roteado inteiro sobre os mesmos conjuntos de teste que o
modelo único, e compare mensagem a mensagem.

Este laboratório tem as peças para isso e a primeira aula as pôs na balança: o `llama3.2:1b` aprovou
9 de 40 no dev onde o `llama3.2:3b` aprovou 28, em dois terços da memória. Uma rota que mandasse as
mensagens fáceis para o modelo pequeno seria mais uma versão, e o `pl compare` contra o modelo único
diria se a economia custou alguma resposta.

## Mandar em lote o que pode esperar

Nem toda chamada tem alguém esperando. Reclassificar o arquivo do ano passado com um prompt novo, ou
rodar os conjuntos de teste durante a noite, pode levar horas. Vários provedores vendem uma interface
de lote exatamente para isso: você manda muitas requisições de uma vez, recolhe os resultados depois,
e paga menos por token do que pelas mesmas requisições uma a uma. A Message Batches API da Anthropic
e a Batch API da OpenAI são duas; a documentação delas dá o desconto e quanto tempo um lote pode
levar. **Um lote é para trabalho que ninguém está olhando**, nunca para o cliente cuja mensagem está
sendo classificada agora.
