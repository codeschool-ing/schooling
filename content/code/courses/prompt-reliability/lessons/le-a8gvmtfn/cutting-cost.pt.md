---
title: Cortando custo
version: 1
---

Uma chamada tem duas contagens de tokens e um preço para cada uma, então há poucas formas de deixá-la
mais barata: enviar menos tokens, receber menos tokens escritos, pagar menos por token, ou pagar menos
por chamada aceitando esperar. **Cada uma muda o que o modelo vê ou faz, então cada uma é uma mudança
a testar**, que é o assunto da próxima seção.

## Menos tokens de entrada

A entrada é o que o prompt carrega em toda chamada: instruções, exemplos e a mensagem. A mensagem é
do cliente, então os cortes vêm do resto. Instruções mais curtas, menos exemplos e, para a parte que
nunca muda, o cache da aula 17.

O `v4-only-json.txt` é o prompt de exemplos sem os três exemplos e sem nenhuma outra mudança:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl
40 calls, prompt 651820d7, written to runs/v4.jsonl
ana@lab:~/triage$ pl cost runs/v4.jsonl
tokens          count   per call
input            3739       93.5
cache_read          0        0.0
cache_write         0        0.0
output           1520       38.0

cost of these 40 calls: 3.4017 cents
cost of a million calls like them: 85,043 cents
```

A entrada caiu de 238,5 tokens por chamada para 93,5, e o custo de um milhão de chamadas de 127.680
centavos para 85.043, um terço a menos. A saída quase não mexeu, 38,0 tokens contra 37,4. Se os
exemplos valiam 42.637 centavos por milhão é uma pergunta sobre o que eles faziam, e a próxima seção
responde.

## Menos tokens de saída

A saída é mais cara e mais lenta, então é a alavanca melhor, e há dois jeitos de puxá-la. O primeiro
é **pedir menos**: um resumo em menos de doze palavras em vez de uma frase, nenhuma explicação que
ninguém lê, chaves curtas. O segundo é limitá-la, com o tamanho máximo de saída da aula 6. Um limite
não é um jeito de pedir menos, como mostra um limite abaixo da resposta:

```
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --set max_tokens=30 --out runs/cap.jsonl
40 calls, prompt 1d9c6ec4, written to runs/cap.jsonl
ana@lab:~/triage$ pl latency runs/cap.jsonl
calls 40
p50 1068 ms   p95 1138 ms   max 1143 ms
output tokens: mean 30.0, max 30
ana@lab:~/triage$ pl check runs/cap.jsonl | tail -n 1
all           1    39
ana@lab:~/triage$ pl show runs/cap.jsonl t01
│ {"category": "billing", "urgency": "high", "summary": "They were charged twice for order 4471.
stop: max_tokens, tokens in 238, out 30
```

O p95 caiu de 1341 ms para 1138, e a nota de 36 para 1. Toda resposta com mais de trinta tokens foi
cortada onde estava, no meio de uma string, e o `stop: max_tokens` avisa. **Um limite é um teto para
a resposta que dispara, posto acima da resposta boa mais longa**, que para este prompt tinha 46
tokens. Ele só economiza nas respostas que já estavam dando errado.

## Um modelo mais barato para os casos fáceis

Os provedores vendem vários modelos a preços diferentes, e um menor muitas vezes basta para as
mensagens simples: *"I can't log in"* não precisa do modelo mais capaz que existe. **Roteamento**
manda cada mensagem para o modelo barato ou para o caro por uma regra decidida antes, como o tamanho
da mensagem, uma palavra-chave ou a confiança do próprio modelo barato. A regra agora faz parte do
prompt, e é medida como ele: rode o pipeline roteado inteiro sobre os mesmos conjuntos de teste que o
modelo único e compare os dois mensagem por mensagem.

O laboratório não consegue mostrar isso. O substituto é um modelo só, com um preço só, então não há
entre o que rotear, e qualquer número aqui seria inventado. O que vale é o método: o pipeline roteado
é uma versão, o modelo único é outra, e o `pl compare` entre eles é o que diz se a economia custou
alguma resposta.

## Lotes para o que pode esperar

Nem toda chamada tem alguém esperando por ela. Reclassificar o arquivo do ano passado com um prompt
novo, ou rodar os conjuntos de teste durante a noite, pode levar horas. Vários provedores vendem uma
interface de lotes exatamente para isso: você envia muitos pedidos de uma vez, recolhe os resultados
depois e paga menos por token do que pelos mesmos pedidos um a um. A Message Batches API da Anthropic
e a Batch API da OpenAI são duas; a documentação delas dá o desconto e quanto um lote pode demorar.
**Um lote é para trabalho que ninguém está olhando**, nunca para o cliente cuja mensagem está sendo
classificada agora.
