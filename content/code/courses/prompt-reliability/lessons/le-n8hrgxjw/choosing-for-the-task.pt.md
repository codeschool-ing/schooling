---
title: Escolher pela tarefa
version: 1
---

A triagem tem uma resposta certa por mensagem. A mesma mensagem deve receber a mesma categoria toda
vez, porque uma pessoa ou um programa age a partir dela. **Numa tarefa com uma resposta certa,
sortear só pode transformar respostas certas em erradas.** Este é o prompt da aula 7 rodado cinco
vezes sobre as setenta mensagens, primeiro com temperatura 0:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --samples 5 --out runs/t0.jsonl
350 calls, prompt fbc4c9b1, written to runs/t0.jsonl
ana@lab:~/triage$ pl check runs/t0.jsonl
check      pass  fail
json        340    10
fields      340    10
labels      340    10
category    280    70
urgency     230   120
all         230   120
```

`--samples 5` chama o modelo cinco vezes por mensagem, 350 chamadas ao todo. Com temperatura 0 as
cinco chamadas são idênticas, então toda contagem é cinco vezes a da execução única: 56 categorias
certas viram 280. Agora a mesma coisa com temperatura 1:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --samples 5 --set temperature=1 --out runs/t1.jsonl
350 calls, prompt fbc4c9b1, written to runs/t1.jsonl
ana@lab:~/triage$ pl check runs/t1.jsonl
check      pass  fail
json        340    10
fields      340    10
labels      340    10
category    194   156
urgency     157   193
all         157   193
ana@lab:~/triage$ pl check runs/t1.jsonl --failures | grep '^t08'
t08    category  other, expected returns
t08#2  category  billing, expected returns
t08#3  category  other, expected returns
ana@lab:~/triage$ grep '"t08"' cases/dev.jsonl
{"id": "t08", "message": "I ordered the hardback and you sent the paperback. I'd like to exchange it.", "expect": {"category": "returns", "urgency": "normal"}}
```

As categorias certas caíram de 280 para 194. O `--failures` identifica cada chamada pela mensagem e
pela amostra, então `t08` é a amostra 0 e `t08#2` é a amostra 2. `t08` foi classificada de três
jeitos diferentes em cinco chamadas: duas vezes certa, duas `other`, uma `billing`. É uma decisão
apertada no substituto, uma troca com poucas palavras-chave, e **o sorteio transforma uma decisão
apertada em cara ou coroa a cada chamada**. A linha `json` não se mexeu, porque no substituto os
hábitos de formatação dependem do prompt e da mensagem, não da temperatura.

Uma temperatura mais baixa não é o mesmo que zero:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --samples 5 --set temperature=0.2 --out runs/t02.jsonl
350 calls, prompt fbc4c9b1, written to runs/t02.jsonl
ana@lab:~/triage$ pl check runs/t02.jsonl
check      pass  fail
json        340    10
fields      340    10
labels      340    10
category    271    79
urgency     224   126
all         224   126
```

Em 0.2 as categorias ainda perderam 9 de 280. As mensagens cujas duas pontuações do topo estão quase
empatadas continuam virando, com quase qualquer temperatura acima de zero.

## Quando a variedade é o objetivo

O outro tipo de tarefa quer uma resposta diferente a cada vez: cinco linhas de assunto para escolher,
uma resposta a um cliente que não deve soar como as últimas cinquenta, uma lista de ideias. Ali,
temperatura 0 dá o mesmo texto cinco vezes, e algum sorteio é o que faz uma segunda chamada valer o
que custa. Este laboratório não consegue medir isso, porque o substituto não escreve respostas; a
aula 12 mede o tom em respostas que o curso escreveu. **Decida por tarefa, e mantenha classificação
e extração em 0.**

A aula 19 sorteia de propósito, várias vezes por mensagem, e faz uma votação. É um jeito de usar a
aleatoriedade em vez de sofrer com ela, e custa uma chamada por amostra.

## Zero não é garantia

Com temperatura 0 o substituto é determinístico, porque são algumas centenas de linhas de Python.
**Um modelo hospedado com temperatura 0 não tem garantia de dar a mesma saída para a mesma
entrada.** A documentação da Anthropic para o parâmetro `temperature` diz isso com todas as letras:
mesmo em 0.0 os resultados não serão totalmente determinísticos. As requisições são agrupadas com as
de outras pessoas, e a aritmética de ponto flutuante do hardware nem sempre soma as coisas na mesma
ordem, então duas candidatas do topo quase empatadas podem trocar de lugar. É mais um motivo para
medir num conjunto de teste e comparar mensagem a mensagem, em vez de confiar numa execução de uma
mensagem.
