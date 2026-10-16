---
title: Sobreamostragem e subamostragem
version: 1
---

Reamostrar muda as próprias linhas de treino até as classes ficarem equilibradas. Há duas direções, e as
duas últimas linhas do `rebalance.py` testaram as duas:

- A **sobreamostragem** copia pessoas que saem, sorteadas com reposição, até haver tantas quanto as que
  ficam. Aqui isso quer dizer 36.427 linhas de quem sai feitas a partir de 2.201 reais, cada uma repetida
  umas dezesseis vezes, e um conjunto de treino quase duas vezes maior.
- A **subamostragem** joga fora pessoas que ficam, ao acaso, até haver tão poucas quanto as que saem.
  Aqui isso mantém 2.201 de 36.427, uma em dezesseis, e o conjunto de treino encolhe para 4.402 linhas.

De volta à tabela. **Nenhuma das duas melhorou a ordenação.** A sobreamostragem perdeu um pouco, AUC
0,788 contra 0,804, em parte porque uma árvore que vê a mesma pessoa dezesseis vezes aprende os detalhes
daquela pessoa como se fossem um padrão. A subamostragem perdeu mais na precisão média, 0,285 contra
0,322: jogou fora 34.226 pessoas que ficam, e com elas a maior parte do que o modelo sabia sobre quem
fica. As duas subiram a chance média muito acima da verdade, e as duas perderam dinheiro no corte padrão.

Há um argumento honesto para a subamostragem, e ele não é sobre a classe. **Ela barateia o treino.** Um
arquivo com cem milhões de linhas e um positivo em mil treina numa fração do tempo com os negativos
desbastados. Quando os dados são grandes demais para ajustar, subamostrar é um jeito razoável de ajustar,
desde que as chances sejam corrigidas depois, o que uma seção mais adiante nesta aula faz.

### SMOTE, e outros jeitos de inventar quem sai

A sobreamostragem simples copia linhas. O **SMOTE** (Synthetic Minority Oversampling Technique) inventa
linhas novas: escolhe alguém que sai, escolhe um dos vizinhos mais próximos que também saiu, e cria uma
linha em algum ponto da reta entre os dois. A ideia é preencher o espaço em volta da classe rara em vez
de empilhar cópias nos mesmos pontos. Ele mora numa biblioteca à parte, a `imbalanced-learn`, que este
curso não instala.

Ele tem o mesmo limite de tudo nesta seção, e mais dois. Não acrescenta informação: toda linha inventada
é uma mistura de linhas que o modelo já tinha. Precisa de uma distância entre linhas, o que é estranho
com colunas categóricas como `city` e `plan`. E as linhas inventadas podem nem ser possíveis, um
assinante com 2,6 reclamações e uma forma de pagamento a meio caminho entre cartão e boleto. Em dados
como estes, meça-o contra não fazer nada e escolher o corte, como esta aula faz, antes de confiar nele.

Os três tipos de reamostragem compartilham mais uma armadilha, que não tem nada a ver com se ajudam e
tudo a ver com como são medidos. É a próxima seção.
