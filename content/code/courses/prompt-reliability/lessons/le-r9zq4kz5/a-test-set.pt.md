---
title: O que é um conjunto de teste
version: 2
---

Um conjunto de teste é a única parte de uma avaliação que não dá para automatizar. **Cada caso é
uma entrada e a resposta que uma pessoa decidiu que é a certa**, escrita antes de qualquer coisa
rodar:

```
ana@lab:~/triage$ head -n 1 cases/dev.jsonl
{"id": "t01", "message": "I was charged twice for order 4471. Please refund the second payment.", "expect": {"category": "billing", "urgency": "high"}}
```

`message` é o que o prompt recebe e `expect` é o julgamento de uma pessoa. Tudo o que o `pl check`
faz depois disso é aritmética, e a aritmética só vale o que valem os quarenta julgamentos embaixo
dela.

## De onde vêm os casos

O instinto errado é sentar e escrevê-los. Mensagens inventadas são mais arrumadas que as reais, o
que a aula 1 disse sobre exemplos. Para casos de teste isso importa mais: **um conjunto de mensagens
arrumadas mede uma caixa de entrada que não existe.** Tire os casos do tráfego que o prompt vai de
fato ver. Remova o que pertence a um cliente, nomes, endereços e números de pedido, e mantenha todo o
resto: o erro de digitação, as duas perguntas numa mensagem, as três linhas de desculpas antes do
assunto.

Tire-os de mais de uma tarde, também. Uma semana em que a transportadora teve uma segunda-feira ruim
é uma semana de mensagens de entrega, e um conjunto tirado dela vai dizer que o prompt é bom em
entregas.

## Rotule antes de olhar

**Escreva cada rótulo antes de rodar o prompt na mensagem.** Quem lê a resposta do modelo primeiro
já não está decidindo sobre o que a mensagem trata; está decidindo se a resposta do modelo é
aceitável, que é um teste mais fácil de passar. O `t22`, o cliente que quer pagar com um vale-presente
e um cartão de crédito, é billing para qualquer um que o rotule sem ver nada. Mostrada a palavra
*other* ao lado dele primeiro, que é o que o `llama3.2:3b` diz, alguém com pressa poderia deixar
passar.

Quando duas pessoas rotulam a mesma mensagem de jeitos diferentes, isso é uma descoberta sobre as
categorias e não um incômodo. Escreva a regra que resolve o caso, porque o prompt precisa da mesma
regra.

## Quantos

Quarenta bastam para ver um efeito grande e são poucos para ver um pequeno. Aqui estão três prompts
das primeiras aulas, rodados de novo sobre as mesmas quarenta:

```
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, llama3.2:3b, written to runs/v2.jsonl
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3.jsonl
40 calls, prompt 1d9c6ec4, llama3.2:3b, written to runs/v3.jsonl
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl
40 calls, prompt 651820d7, llama3.2:3b, written to runs/v4.jsonl
ana@lab:~/triage$ pl compare runs/v2.jsonl runs/v3.jsonl
runs/v2.jsonl            passes 22/40
runs/v3.jsonl            passes 28/40
fixed 7, broken 1
broken: t01
sign test on the 8 that changed: p = 0.070
ana@lab:~/triage$ pl compare runs/v4.jsonl runs/v3.jsonl
runs/v4.jsonl            passes 20/40
runs/v3.jsonl            passes 28/40
fixed 9, broken 1
broken: t01
sign test on the 10 that changed: p = 0.021
```

Entre o `v2` e o `v3`, oito mensagens mudaram e sete foram para o mesmo lado; uma moeda honesta
divide oito pelo menos tão desigualmente sete vezes em cem, que é o p = 0.070 da aula 1. Entre o
`v4` e o `v3` mudaram dez, nove para um lado, e p = 0.021. **Duas comparações do mesmo prompt, uma
de cada lado da linha que as pessoas traçam em 0,05**, separadas por duas mensagens. Quarenta
mensagens conseguem ver uma diferença de oito; não conseguem dizer muito sobre uma de seis.

Ver uma diferença da metade do tamanho exige mais ou menos quatro vezes os casos, porque o ruído de
uma proporção encolhe com a raiz quadrada da contagem. Essa é a troca sobre a qual um conjunto de
teste é construído: um caso custa um minuto de uma pessoa, e o tamanho da mudança que você quer
detectar decide quantos minutos.
