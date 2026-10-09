---
title: Quanto custa avaliar
version: 2
---

Toda chamada ao juiz nesta aula passou pelo `judge.py`, que a envolve num span chamado
`chat llama3.2:3b` com o modelo e os tokens, exatamente como as chamadas do próprio assistente. Então
o preço de avaliar vem do mesmo lugar que o preço de servir, pelo mesmo `costs.py` que a aula 3
escreveu, com os mesmos preços escritos pelo curso:

```python
"""judge_cost.py: what the grading cost, from the judge's own spans, beside what the assistant cost."""
import costs

judged = costs.requests("judge-spans.jsonl")
served = costs.requests("spans.jsonl")
cost = lambda rs: sum(r["cost"] for r in rs)
print(f"judge calls  {len(judged):5}   input {sum(r['input'] for r in judged):7}   output {sum(r['output'] for r in judged):6}"
      f"   US$ {cost(judged):.6f}   per call {cost(judged) / len(judged):.8f}")
print(f"assistant    {len(served):5}   input {sum(r['input'] for r in served):7}   output {sum(r['output'] for r in served):6}"
      f"   US$ {cost(served):.6f}   per request {cost(served) / len(served):.8f}")
```

```
ana@dev:~/obs$ python judge_cost.py
judge calls    510   input  112728   output  23391   US$ 0.309438   per call 0.00060674
assistant      311   input   53240   output   8005   US$ 0.143428   per request 0.00046118
```

As 510 chamadas são tudo o que esta aula avaliou: a semana inteira uma vez (275), as três amostras (23,
120 e 90) e os dois critérios da primeira resposta. Juntas custaram **US$ 0,31**, contra **US$ 0,14**
das 311 requisições que o assistente serviu na mesma semana. Avaliar custou o dobro de servir.

Por chamada a história é a mesma. **Um julgamento custa 0,00060674 dólar; uma requisição custou
0,00046118.** Avaliar uma resposta num critério custa um terço a mais que escrevê-la. Duas coisas
definem esse número, e as duas podem mudar:

- **O preço por token do juiz.** Aqui o juiz é o modelo que ele avalia, pelo mesmo preço. Um juiz mais
  barato por token que o assistente, um modelo menor ou um fornecedor mais barato, baixa a razão na
  mesma proporção, e um juiz maior, que lê uma rubrica com mais cuidado, a sobe.
- **O prompt do juiz.** Ele leva a pergunta, a resposta e todas as fontes, então é longo: 221 tokens de
  entrada por chamada em média, contra 171 de uma requisição inteira do assistente. A rubrica de
  relevância nunca pergunta pelas fontes, e elas viajam mesmo assim em toda chamada de relevância.
  Mandar só o que a rubrica lê é a economia mais barata que existe.

E na sua própria máquina o preço é **tempo**. Cinco segundos e meio por julgamento, um de cada vez, no
processador de que o assistente também precisa: avaliar a semana inteira levou 25,6 minutos, durante os
quais o assistente teria respondido mais devagar.

## Para onde vai o dinheiro

A conta de servir da semana foi US$ 0,14, e um julgamento custa 0,00060674. A aritmética de uma
política é curta:

| Política | Chamadas ao juiz na semana | Avaliar como parte de servir |
| --- | --- | --- |
| Toda resposta, três critérios | 825 | cerca de 350% |
| Toda resposta, um critério | 275 | cerca de 115% |
| Estratificada, 30 por grupo, três critérios | 360 | cerca de 150% |
| Dirigida, um critério | 90 | cerca de 40% |

Só a segunda e a quarta linhas foram executadas; as outras são o mesmo preço por chamada multiplicado.
Os resumos nunca são avaliados aqui, e é por isso que toda resposta num critério dá um pouco mais que a
conta, e não um terço a mais que ela. Com um juiz tão caro quanto o assistente, toda política que cobre a
semana inteira custa mais que a semana custou, e as únicas baratas são as amostras pequenas. A tabela
mostra a forma da escolha: decida para que serve cada número, e então avalie o menor número de respostas
que o responde.

## O juiz também é uma funcionalidade

Os spans do juiz levam `app.criterion` e nada os marca como do assistente, então aqui eles ficam num
arquivo próprio. Em produção eles dividem o armazenamento de traces com todo o resto, e deveriam levar
uma funcionalidade própria, como `evaluation`, para que o custo por funcionalidade da aula 3 mostre a
avaliação como uma linha ao lado de help, order e summary. Um custo que ninguém vê cresce sem que
ninguém decida que deve crescer: uma taxa de amostragem aumentada para uma investigação e nunca mais
baixada é o caminho de costume.

A aula 16 aponta a nota amostrada do juiz como um sinal que vale um alerta próprio, sempre com o seu
n.