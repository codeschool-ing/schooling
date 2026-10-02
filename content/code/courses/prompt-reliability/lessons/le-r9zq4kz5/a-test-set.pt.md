---
title: O que é um conjunto de teste
version: 1
---

O conjunto de teste é a única parte de uma avaliação que não dá para automatizar. **Cada caso é uma
entrada e a resposta que uma pessoa decidiu ser a certa**, anotada antes de qualquer execução:

```
ana@lab:~/triage$ head -n 1 cases/dev.jsonl
{"id": "t01", "message": "I was charged twice for order 4471. Please refund the second payment.", "expect": {"category": "billing", "urgency": "high"}}
```

`message` é o que o prompt recebe e `expect` é o julgamento de uma pessoa. Tudo o que o `pl check`
faz depois disso é aritmética, e a aritmética só é tão boa quanto os quarenta julgamentos embaixo
dela.

## De onde vêm os casos

O instinto errado é sentar e escrevê-los. Mensagens inventadas são mais arrumadas que as reais, o
que a aula 1 disse sobre exemplos, e em casos de teste isso pesa mais: **um conjunto de mensagens
arrumadas mede uma caixa de entrada que não existe.** Tire os casos do tráfego que o prompt vai de
fato receber. Remova o que pertence a um cliente, nomes, endereços e números de pedido, e mantenha
todo o resto: o erro de digitação, as duas perguntas numa mensagem só, as três linhas de desculpas
antes do assunto.

Tire-os de mais de uma tarde, também. Uma semana em que a transportadora teve uma segunda-feira
ruim é uma semana de mensagens de entrega, e um conjunto tirado dela vai dizer que o prompt é bom
em delivery.

## Rotule antes de olhar

**Escreva cada rótulo antes de rodar o prompt nele.** Quem lê primeiro a resposta do modelo deixou
de decidir do que a mensagem trata; está decidindo se a resposta do modelo é aceitável, que é uma
prova mais fácil de passar. `t37`, o pedido ainda aguardando despacho, é delivery para qualquer
pessoa que o rotule a frio. Vendo a palavra *billing* ao lado primeiro, um leitor apressado pode
deixar passar.

Quando duas pessoas rotulam a mesma mensagem de jeitos diferentes, isso é uma descoberta sobre as
categorias, e não um incômodo. Escreva a regra que resolve, porque o prompt precisa da mesma regra.

## Quantos

Quarenta bastam para ver um efeito grande e são poucos para ver um pequeno:

```
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, written to runs/v2.jsonl
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3.jsonl
40 calls, prompt 1d9c6ec4, written to runs/v3.jsonl
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl
40 calls, prompt 651820d7, written to runs/v4.jsonl
ana@lab:~/triage$ pl compare runs/v2.jsonl runs/v3.jsonl
runs/v2.jsonl            passes 24/40
runs/v3.jsonl            passes 36/40
fixed 13, broken 1, still passing 23, still failing 3
broken: t37
sign test on the 14 that changed: p = 0.002
ana@lab:~/triage$ pl compare runs/v4.jsonl runs/v3.jsonl
runs/v4.jsonl            passes 34/40
runs/v3.jsonl            passes 36/40
fixed 3, broken 1, still passing 33, still failing 3
broken: t37
sign test on the 4 that changed: p = 0.625
```

Entre a `v2` e a `v3`, catorze mensagens mudaram e treze foram para o mesmo lado; uma moeda honesta
faz isso duas vezes em mil. Entre a `v4` e a `v3` os totais estão a dois de distância, quatro
mensagens mudaram, e o teste do sinal diz que uma moeda as dividiria de forma ao menos tão desigual
em mais da metade das vezes. **Quarenta mensagens enxergam treze falhas de formato e não distinguem
34 de 36.**

Ver uma diferença com metade do tamanho exige cerca de quatro vezes mais casos, porque o ruído de
uma proporção diminui com a raiz quadrada da contagem. É sobre essa troca que um conjunto de teste
é construído: um caso custa um minuto de uma pessoa, e o tamanho da mudança que você quer detectar
decide quantos minutos.
