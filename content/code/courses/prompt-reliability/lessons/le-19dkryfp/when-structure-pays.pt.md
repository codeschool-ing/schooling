---
title: Quando a estrutura compensa
version: 1
---

`prompt-engineering` apresentou saída estruturada na aula 18 e esquemas na aula 19. Esta aula
retoma os dois de propósito, com a pergunta que este curso faz a toda técnica: **com que frequência
a estrutura chega de fato, e o que faz o programa que a lê quando ela não chega?**

A ideia que precisa sair primeiro é a de que JSON é o jeito cuidadoso e profissional de
pedir uma resposta, e prosa o jeito desleixado. **Estrutura é para um leitor que é um programa.** A
mesma mensagem, classificada pelo prompt nu e pelo que pede JSON:

```
ana@lab:~/triage$ pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl
40 calls, prompt a4ffc4b1, written to runs/v1.jsonl
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, written to runs/v2.jsonl
ana@lab:~/triage$ pl show runs/v1.jsonl t17
│ Type: Shipping
│ Priority: urgent
│ Summary: Their order was dispatched ten days ago and still hasn't arrived.
stop: end, tokens in 45, out 22
ana@lab:~/triage$ pl show runs/v2.jsonl t17
│ {
│   "category": "delivery",
│   "urgency": "high",
│   "summary": "Their order was dispatched ten days ago and still hasn't arrived."
│ }
stop: end, tokens in 87, out 38
```

Uma pessoa da equipe de atendimento lê a primeira resposta num segundo e sabe o que fazer.
`Shipping` e `urgent` não são as palavras da loja, e a pessoa não liga. Um programa que encaminha a
mensagem para a fila do depósito não liga para outra coisa: precisa de um campo que encontre pelo
nome e de um valor que possa comparar com `delivery`. **Se quem lê a resposta é uma pessoa, o prompt
nu já estava pronto.** A aula 1 reprovou esse prompt em todas as verificações porque o leitor deste
curso é um programa, e as verificações são as necessidades desse programa por escrito.

## O que a estrutura custa

Pedir JSON é mais instrução, e JSON é mais saída, porque as aspas, as chaves e os nomes dos campos
são tokens que o modelo escreve:

```
ana@lab:~/triage$ pl tokens prompts/v1-bare.txt
27 tokens, 20 words, 114 characters
ana@lab:~/triage$ pl tokens prompts/v2-json.txt
69 tokens, 46 words, 295 characters
ana@lab:~/triage$ pl latency runs/v1.jsonl
calls 40
p50 840 ms   p95 1015 ms   max 1072 ms
output tokens: mean 22.7, max 36
ana@lab:~/triage$ pl latency runs/v2.jsonl
calls 40
p50 1186 ms   p95 1397 ms   max 1468 ms
output tokens: mean 39.9, max 50
```

O prompt foi de 27 tokens para 69, e a resposta média de 22,7 tokens para 39,9. A chamada mediana
levou 1.186 ms em vez de 840, nas latências calculadas do laboratório, porque os tokens escritos são
os lentos. Para um roteador é um preço justo. Para uma nota que uma pessoa lê, é pago à toa.

## O que a estrutura restringe

Um campo guarda o que o formato deixa. O resumo aqui tem uma frase porque o formato manda, e um
cliente com dois problemas tem um deles resumido. A prosa tem espaço para *"quase tudo é cobrança,
mas também falam de um livro danificado"*; um campo `category` tem espaço para uma palavra de uma
lista de cinco. **Cada campo que você acrescenta é uma decisão tirada do modelo.** É exatamente o
que você quer para um valor em que um programa se baseia para decidir, e exatamente o que você não
quer para algo que uma pessoa ia ler e julgar.

Então a regra depende do leitor. Peça estrutura quando um programa consome a resposta, e peça o
quanto esse programa precisa, que neste curso são dois rótulos e uma frase.
