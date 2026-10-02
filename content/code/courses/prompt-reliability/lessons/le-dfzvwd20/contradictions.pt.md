---
title: Duas instruções que discordam
version: 1
---

Duas linhas do `v2-long.txt` falam do tamanho do resumo. Foram escritas para reclamações
diferentes e as duas parecem razoáveis:

```
ana@lab:~/triage$ grep -n -e brief -e detail prompts/v2-long.txt
4:Keep the summary brief so the team can scan the queue quickly.
16:The team reads the summary instead of the message, so describe the problem in full detail.
```

A linha 4 quer um resumo que a equipe consiga percorrer de olho. A linha 16, acrescentada depois por
alguém cuja reclamação era que o resumo deixava coisas de fora, quer o problema em detalhe. **Ninguém
consegue obedecer às duas, então o modelo escolhe, e você não tem voz nessa escolha.**

O jeito de escolher do substituto está escrito no comentário de abertura dele: entre uma instrução
para ser breve e outra para ser minucioso, vence a que vem escrita por último. A linha 16 vem depois
da 4, então ela decide todos os resumos. Uma mensagem com duas frases mostra isso:

```
ana@lab:~/triage$ grep t17 cases/dev.jsonl
{"id": "t17", "message": "My order was dispatched ten days ago and still hasn't arrived. I need it for a birthday on Saturday.", "expect": {"category": "delivery", "urgency": "high"}}
ana@lab:~/triage$ pl show runs/v2.jsonl t17
│ {
│   "category": "delivery",
│   "urgency": "high",
│   "summary": "Their order was dispatched ten days ago and still hasn't arrived."
│ }
stop: end, tokens in 87, out 38
ana@lab:~/triage$ pl show runs/long.jsonl t17
│ {
│   "category": "delivery",
│   "urgency": "high",
│   "summary": "Their order was dispatched ten days ago and still hasn't arrived. They need it for a birthday on Saturday."
│ }
stop: end, tokens in 185, out 47
```

Com o `v2-json.txt`, que pede uma frase, o resumo é a primeira frase da mensagem. Com o prompt longo
é a mensagem inteira, passada para a terceira pessoa. A linha 16 deu um motivo: a equipe lê o resumo
em vez da mensagem. **O resumo que ela produziu é a mensagem**, então a equipe agora lê tudo duas
vezes, e a fila que a linha 4 queria manter fácil de percorrer ficou do tamanho da caixa de entrada.

## O que isso custa

Os resumos mais longos são pagos como saída, e a saída é o que o modelo escreve um token de cada
vez:

```
ana@lab:~/triage$ pl latency runs/v2.jsonl
calls 40
p50 1186 ms   p95 1397 ms   max 1468 ms
output tokens: mean 39.9, max 50
ana@lab:~/triage$ pl latency runs/long.jsonl
calls 40
p50 1306 ms   p95 1475 ms   max 1504 ms
output tokens: mean 42.7, max 54
```

A resposta média cresceu de 39,9 tokens para 42,7, e a mais longa de 50 para 54. A chamada mediana
levou 1.306 ms em vez de 1.186. As diferenças são pequenas porque as mensagens do conjunto de teste
são curtas, de uma ou duas frases cada, então o detalhe completo acrescenta no máximo uma frase. Uma
caixa de entrada com parágrafos aumentaria a distância, e as latências do laboratório são números do
curso, calculados e não cronometrados. O que importa é o sentido: **uma contradição não se resolve
uma vez, ela se resolve de novo em cada chamada, e é paga a cada vez.**

## Num modelo real

Um modelo real não tem uma regra escrita como a do substituto. Qual de duas instruções em conflito
ele segue depende do modelo, das palavras e de onde cada uma está, e isso pode mudar quando o
fornecedor atualiza o modelo. É uma observação de quem trabalha com isso, não uma taxa medida, e é o
motivo de uma contradição ser pior do que cada uma das metades. **Cada instrução sozinha dá uma
resposta que você escolheu; as duas juntas dão uma que o modelo escolheu**, e você descobre qual
lendo as respostas.

Os guias que a Anthropic e a OpenAI publicam sobre escrever prompts começam pelo mesmo conselho:
seja claro e direto sobre o que você quer. Um prompt que pede duas coisas incompatíveis é o jeito
mais evidente de não ser claro, e a correção não é uma terceira linha dizendo qual vence. É decidir,
e apagar a outra.
