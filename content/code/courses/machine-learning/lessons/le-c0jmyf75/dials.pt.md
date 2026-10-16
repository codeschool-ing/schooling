---
title: Parâmetros e hiperparâmetros
version: 1
---

Todo modelo até aqui teve dois tipos de número dentro, e a diferença decide quem os define.

**Parâmetros são aprendidos pelo `fit`.** Os pesos da reta da aula 5, os cortes e valores de folha da
árvore da aula 7, as centenas de árvores pequenas da aula 8: ninguém os digita, os dados os escolhem,
e muitas vezes são milhares.

**Hiperparâmetros são definidos antes do `fit`, por uma pessoa.** A profundidade de uma árvore, o
número de vizinhos, o `alpha`, o `C`, a taxa de aprendizado, quantas folhas uma árvore de boosting
pode ter. Eles decidem *como* o modelo aprende, e os dados não conseguem escolhê-los direto, porque
cada valor dá um modelo diferente cuja qualidade só se conhece depois de ajustá-lo.

| modelo | seus parâmetros | alguns hiperparâmetros |
|---|---|---|
| regressão linear com ridge | os pesos | `alpha` |
| k vizinhos mais próximos | nenhum: ele guarda as linhas | `n_neighbors`, a padronização |
| árvore de decisão | os cortes e os valores das folhas | `max_depth`, `min_samples_leaf`, `ccp_alpha` |
| HistGradientBoosting | cada árvore da soma | `learning_rate`, `max_iter`, `max_leaf_nodes`, `min_samples_leaf`, `l2_regularization` |

**Otimizar** (*tuning*) é escolher hiperparâmetros testando: ajustar com um valor, medir em dados de
validação, testar outro, ficar com o melhor. É a mesma disciplina que a aula 2 aplicou a uma regra e
que a aula 3 nomeou: a escolha é aprendizado, então é feita em linhas que o teste final nunca vê.

A aula 8 manteve o HistGradientBoosting da aula 2 nos padrões e resolveu a questão de qual biblioteca
usar notando que os ensembles empatam. Esta aula faz a pergunta seguinte. **Os padrões são o palpite
de outra pessoa sobre dados que ela nunca viu. Uma busca vale o que custa?**
