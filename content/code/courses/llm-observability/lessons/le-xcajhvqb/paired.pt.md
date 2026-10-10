---
title: Uma comparação pareada
version: 2
---

As duas versões responderam às mesmas 32 perguntas. Comparar suas taxas de acerto como dois números
separados, como a aula 9 comparou amostras, joga isso fora: 25 certas contra 20, dois intervalos de
cerca de ±15 pontos cada, sobrepostos quase por inteiro, e o relatório honesto seria "não dá para
saber".

**Uma comparação pareada usa o fato de as perguntas serem as mesmas.** Os 23 casos que as duas versões
acertaram, ou que as duas erraram, não dizem nada sobre a diferença entre elas. Toda a informação está
nos casos que mudaram de veredito, e a pergunta é se eles mudaram numa direção mais do que o acaso
explicaria.

**O teste de McNemar** responde a isso. Se a mudança não fizesse diferença, cada caso que mudou teria a
mesma chance de ter ido para qualquer lado, como uma moeda. O teste exato pergunta com que frequência
uma moeda honesta, lançada uma vez por caso que mudou, sairia pelo menos tão desequilibrada. O
`regress.py` o calcula em quatro linhas.

Para a versão do piso: nove casos mudaram, sete quebrados e dois consertados. Uma moeda honesta lançada
nove vezes dá duas caras ou menos 46 vezes em 512, e o teste conta a outra direção também: **p = 0.18**.
Longe dos 0.05 que os livros usam, e a versão do piso continua sem condições de ir ao ar.

Isso não é contradição, porque os dois respondem a perguntas diferentes:

- **O p-valor é sobre a média**: se a candidata é pior em perguntas como estas, em geral. Com nove
  casos mudados em 32, o conjunto é pequeno demais para dizer isso com confiança, como a aritmética da
  aula 13 previa.
- **Os casos quebrados são fatos**: estas sete perguntas, que o assistente respondia, ele não responde
  mais. Elas não precisam de estatística. Cada uma é uma pergunta que um cliente faz, e o relatório de
  regressão a nomeia.

Então uma equipe usa os dois, para decisões diferentes. **Um caso quebrado bloqueia uma versão até
alguém tê-lo lido** e decidido que é aceitável, qualquer que seja o p-valor. **O p-valor decide
afirmações sobre a média**, como "o modelo novo é melhor", em que a resposta honesta de um conjunto
pequeno muitas vezes é que não dá para saber.
