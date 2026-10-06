---
title: Quanto custa avaliar
version: 1
---

Toda chamada ao juiz nesta aula passou pelo `judge.py`, que a envolve num span chamado `chat judge-1`
com o modelo e os tokens, exatamente como as chamadas do próprio assistente. Então o preço de avaliar
vem do mesmo lugar que o preço de servir, pelo mesmo `costs.py` que a aula 3 escreveu:

```
ana@lab:~/obs$ python judge_cost.py
judge calls   1865   input  459293   output  82050   US$ 0.314997   per call 0.00016890
assistant     1345   input  281072   output  46663   US$ 0.822803   per request 0.00061175
```

As 1.865 chamadas são tudo o que esta aula avaliou: a semana inteira uma vez (1.221), as três amostras
(129, 120 e 393) e os dois critérios da primeira resposta. Juntas custaram **US$ 0,31**, contra
**US$ 0,82** das 1.345 requisições que o assistente serviu na mesma semana.

Por chamada a comparação fica mais nítida. **Um julgamento custa 0,00016890 dólar; uma resposta custou
0,00061175.** Avaliar uma resposta num critério acrescenta 28% ao que custou escrevê-la. Duas coisas
fixam esse número, e as duas podem mudar:

- **O preço por token do juiz.** O judge-1 cobra 0,40 e 1,60 dólar por milhão de tokens, contra 1,50 e
  6,00 do extract-1 a partir de 1º de outubro. Um juiz tão caro quanto o modelo que avalia custaria mais
  do que a resposta, porque o seu prompt é mais longo.
- **O prompt do juiz.** Ele leva a pergunta, a resposta e todas as fontes, então é longo: 246 tokens de
  entrada por chamada em média, contra 209 de uma requisição inteira do assistente. A rubrica de
  relevância nunca pergunta pelas fontes, e mesmo assim elas viajam em toda chamada de relevância.
  Mandar só o que a rubrica lê é a economia mais barata que existe.

## Para onde vai o dinheiro

A conta de servir da semana foi US$ 0,82, e um julgamento custa 0,00016890. A aritmética de uma
política é curta:

| Política | Chamadas ao juiz na semana | Avaliar como parte de servir |
| --- | --- | --- |
| Toda resposta, três critérios | 3.663 | cerca de 75% |
| Toda resposta, um critério | 1.221 | cerca de 25% |
| Dirigida, um critério | 393 | cerca de 8% |
| Estratificada, 30 por grupo, três critérios | 360 | cerca de 7% |

Só a segunda e a terceira linhas foram executadas; as outras são o mesmo preço por chamada
multiplicado. Os resumos nunca são avaliados aqui, e é por isso que toda resposta num critério dá um
quarto da conta e não 28% dela. A tabela mostra a forma da escolha: uma amostra estratificada pequena
em todos os critérios custa menos do que um único critério em tudo, e diz mais, porque cobre também
fidelidade e correção.

## O juiz também é uma funcionalidade

Os spans do juiz levam `app.criterion` e nada os marca como do assistente, então neste laboratório
ficam num arquivo próprio. Em produção eles dividem o armazenamento de traces com todo o resto, e
deveriam levar uma funcionalidade própria, como `evaluation`, para que o custo por funcionalidade da
aula 3 mostre a avaliação como uma linha ao lado de help, order e summary. Um custo que ninguém vê cresce
sem que ninguém decida que deve crescer: uma taxa de amostragem aumentada para uma investigação e
nunca mais baixada é o caminho de costume.

A aula 16 põe a avaliação num painel ao lado do tráfego, com o seu custo.
