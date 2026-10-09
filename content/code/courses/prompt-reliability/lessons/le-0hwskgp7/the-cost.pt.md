---
title: Quanto custa uma votação
version: 2
---

Um ensemble de n membros faz n chamadas para cada mensagem. **A conta é a soma das contas dos
membros**, e o ganho é o que a votação mediu. Ponha os dois lado a lado antes de ficar com um. O
`cost.py` da aula 16 põe preço numa execução com o `prices.json`, os preços inventados do curso:

```
ana@lab:~/triage$ python3 cost.py runs/v3.jsonl runs/v4.jsonl runs/v6.jsonl runs/s5.jsonl
runs/v3.jsonl, 70 calls
  input      17381 tokens      248.3 a call
  output      2156 tokens       30.8 a call
  these calls      8.4483 cents
  a million calls  120690.0000 cents
runs/v4.jsonl, 70 calls
  input       8491 tokens      121.3 a call
  output      2039 tokens       29.1 a call
  these calls      5.6058 cents
  a million calls  80082.8571 cents
runs/v6.jsonl, 70 calls
  input      10381 tokens      148.3 a call
  output      2021 tokens       28.9 a call
  these calls      6.1458 cents
  a million calls  87797.1429 cents
runs/s5.jsonl, 350 calls
  input      51905 tokens      148.3 a call
  output      9995 tokens       28.6 a call
  these calls      30.5640 cents
  a million calls  87325.7143 cents
```

A última linha de cada execução é o preço de um milhão de chamadas iguais às dela. No ensemble de
três prompts uma mensagem é uma chamada a cada membro, então um milhão de mensagens custa 120.690 +
80.083 + 87.797 = 288.570 centavos. O melhor membro sozinho, o `v3-examples`, custa 120.690 e acertou
cinco mensagens a mais que a votação. **O ensemble custou 2,4 vezes o melhor prompt para ser pior que
ele.**

As cinco amostras são um prompt cinco vezes. Cada chamada custou o que custa uma chamada do
`v6-escaped`, 148,3 tokens de entrada e uns 29 de saída, e uma mensagem são cinco delas: 5 × 87.326 =
436.629 centavos por milhão de mensagens, cinco vezes o `v6-escaped` sozinho, por uma resposta certa
a mais em setenta.

O tempo é a outra conta:

```
ana@lab:~/triage$ python3 stats.py runs/v6.jsonl runs/s5.jsonl
runs/v6.jsonl, 70 calls
  tokens in    mean  148.3   total  10381
  tokens out   mean   28.9   total   2021   max 37
  seconds      p50   3.2   p95   4.4   total  263.7
runs/s5.jsonl, 350 calls
  tokens in    mean  148.3   total  51905
  tokens out   mean   28.6   total   9995   max 45
  seconds      p50   2.9   p95   3.7   total 1042.8
```

Cada chamada amostrada foi um pouco mais rápida que uma chamada da execução simples, p50 de 2,9
segundos contra 3,2, provavelmente pelo cache da aula 17: o `pl` manda as cinco amostras de uma
mensagem uma atrás da outra, com o mesmo prompt toda vez. Cinco chamadas por mensagem levaram
1.042,8 segundos contra 263,7. Um provedor que roda as cinco ao mesmo tempo faz você esperar a mais
lenta delas em vez de todas, e ainda cobra as cinco.

## Quando compensa

Três coisas decidem, e cada uma é algo que você pode medir:

- **O quanto os membros são diferentes.** A conta só compensa quando os membros erram coisas
  diferentes. Conte do jeito que a seção dos três prompts contou, caso a caso, antes de contar
  dinheiro. Aqui doze casos erraram nos três prompts.
- **Quanto custa um erro.** Uma resposta certa a mais em setenta pode valer cinco vezes a conta
  quando um rótulo errado deixa uma conta sequestrada na fila errada. Não vale quando um rótulo
  errado significa uma pessoa reclassificando uma pergunta sobre a newsletter.
- **Quanto custa uma chamada.** Um ensemble de três chamadas a um modelo pequeno e barato pode custar
  menos que uma chamada a um grande. É uma comparação que vale rodar com o `cost.py` nos dois.

A ordem dessas verificações importa. **Meça o ganho da votação contra a melhor chamada única
primeiro**; se for negativo, como foi para os três prompts, o custo nem precisa ser calculado.
