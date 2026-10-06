---
title: Uma comparação pareada
version: 1
---

As duas versões responderam às mesmas 42 perguntas. Comparar as taxas de acerto como dois números
separados, como a aula 9 comparou amostras, joga isso fora: 23 certas contra 18 certas, dois intervalos
de cerca de ±15 pontos cada, quase inteiramente sobrepostos, e o relato honesto seria "não dá para
dizer".

**Uma comparação pareada usa o fato de as perguntas serem as mesmas.** Os 37 casos que as duas versões
acertaram, ou que as duas erraram, não dizem nada da diferença entre elas. Toda a informação está nos
casos que mudaram de veredicto, e a pergunta é se eles mudaram mais numa direção do que o acaso
explicaria.

O **teste de McNemar** responde a isso. Se a mudança não fizesse diferença, cada caso que mudou teria a
mesma chance de ter ido para um lado ou para o outro, como uma moeda; o teste exato pergunta com que
frequência uma moeda honesta, jogada uma vez por caso que mudou, sairia pelo menos tão desequilibrada. O
`regress.py` o calcula em cinco linhas.

Para a versão do piso: cinco casos mudaram, os cinco quebraram. Uma moeda honesta dá cinco caras seguidas
uma vez em 32, e o teste conta a outra direção também: **p = 0,0625**. Não está abaixo dos 0,05 que os
livros usam, e a versão do piso continua sem condições de ir ao ar.

Isso não é contradição, porque os dois respondem a perguntas diferentes:

- **O valor-p é sobre a média**: se a candidata é pior em perguntas como estas, em geral. Com cinco casos
  mudados em 42, o conjunto é pequeno demais para dizer isso com confiança, como a aritmética da aula 13
  previu.
- **Os casos quebrados são fatos**: estas cinco perguntas, que o assistente respondia, ele não responde
  mais. Eles não precisam de estatística. Cada um é uma pergunta que um cliente faz, e o relatório de
  regressão a nomeia.

Então uma equipe usa os dois, para decisões diferentes. **Um caso quebrado bloqueia uma versão até alguém
o ler** e decidir que é aceitável, seja qual for o valor-p. **O valor-p decide afirmações sobre a
média**, como "o modelo novo é melhor", em que a resposta honesta de um conjunto pequeno muitas vezes é
que não dá para dizer.
