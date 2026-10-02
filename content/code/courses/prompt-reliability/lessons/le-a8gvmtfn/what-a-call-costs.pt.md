---
title: Quanto custa uma chamada
version: 1
---

Os provedores cobram por token, com um preço para tokens lidos e outro, mais alto, para tokens
escritos. Os preços do laboratório estão em `prices.json`:

```
ana@lab:~/triage$ cat prices.json
{
  "model": "standin-1",
  "note": "cents per million tokens; written by the course, not any provider's price list",
  "input": 300,
  "cache_read": 30,
  "cache_write": 375,
  "output": 1500
}
```

**Esses preços foram escritos pelo curso**, como o arquivo diz, e estão em centavos inteiros por
milhão de tokens: 300 centavos por um milhão de tokens de entrada, 1500 por um milhão de tokens de
saída. Os dois preços de `cache` são da aula 17. Tabelas de preço reais têm a mesma forma, um preço
por milhão de tokens com a saída mais cara que a entrada, e mudam com tanta frequência que qualquer
número copiado para uma aula estaria errado em menos de um ano.

## A aritmética

O `pl cost` soma os tokens de uma execução e multiplica:

```
ana@lab:~/triage$ pl cost runs/v3.jsonl
tokens          count   per call
input            9539      238.5
cache_read          0        0.0
cache_write         0        0.0
output           1497       37.4

cost of these 40 calls: 5.1072 cents
cost of a million calls like them: 127,680 cents
```

As quarenta chamadas leram 9539 tokens e escreveram 1497. A 300 e 1500 centavos o milhão, isso dá
9539 × 300 + 1497 × 1500 = 2.861.700 + 2.245.500 = 5.107.200 milionésimos de centavo, que são os
5.1072 centavos da linha de baixo. Divida por quarenta para uma chamada, 0,12768 centavo, e
multiplique por um milhão para a última linha. **A saída foi menos de 14% dos tokens e 44% do
custo**, porque cada token de saída custa cinco vezes mais. É a mesma lição da seção anterior, em
dinheiro.

A última linha é a que se põe na frente de quem decide se o prompt vai para produção: 127.680
centavos por um milhão de chamadas como estas. Um custo por chamada parece nada; um custo por milhão
é um orçamento.

## Por que dinheiro nunca é float

A bancada não toca num número fracionário no caminho até esse total. O comentário dela diz por quê:

```
ana@lab:~/triage$ grep -n -A1 "Prices are whole cents" promptlab/cli.py
357:    # Prices are whole cents per million tokens, so tokens times price is in
358-    # millionths of a cent: an integer, and nothing is rounded until the end.
```

Tokens são inteiros, preços são centavos inteiros por milhão, então o produto é um número inteiro de
milionésimos de centavo, exato. **Nada é arredondado até o final**, uma vez, para cima na metade, na
última casa impressa. A alternativa parece inofensiva e não é:

```
ana@lab:~/triage$ python3 -c 'print(0.1 + 0.2)'
0.30000000000000004
```

Um número binário de ponto flutuante não guarda a maioria das frações decimais com exatidão, então
`0.1` é guardado como o valor mais próximo que ele consegue, e somas desses valores se desviam. Um
desvio é invisível; a mesma conta sobre todas as chamadas de um mês, comparada com uma fatura
calculada de outro jeito, produz uma diferença que alguém vai ter de explicar. **Guarde dinheiro como
uma contagem inteira da menor unidade que você cobra**, multiplique inteiros e arredonde uma vez, com
uma regra que você escreveu.
