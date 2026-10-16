---
title: Uma lista antes de alguém relatar uma nota
version: 1
---

Cada vazamento desta lição produziu uma nota que parecia melhor que a verdade, e nenhum produziu um
erro. Então a defesa é um conjunto de perguntas feitas sobre todo conjunto de treino antes que a
nota dele seja levada a sério. **São perguntas sobre dados, e quem montou os dados é quem consegue
respondê-las.**

| pergunte | o vazamento que ela pega | onde ele apareceu aqui |
| --- | --- | --- |
| O valor de cada atributo poderia ter sido calculado na data do corte, com dados que existiam então? | uma coluna da tabela de hoje | `leak.py`: uma recência negativa, AUC 0,994 |
| Alguma entidade aparece dos dois lados da divisão, e deveria? | o mesmo membro duas vezes | `splits.py`: 0,766 contra 0,750 |
| O conjunto de teste é posterior ao de treino, por pelo menos a janela do rótulo? | treinar com um futuro que o modelo não vai ter | os 90 dias de distância antes de 30 de novembro |
| A janela de todo rótulo já fechou? | rótulos inacabados | `maturity.py`: 17% vira 65,5% |
| Algo foi ajustado antes da divisão? | pré-processamento que viu as linhas de teste | o pipeline do `classify.py` |
| O conjunto de teste foi usado para escolher alguma coisa? | um conjunto de teste que virou validação | o `overfit.py` o abre uma vez |

**E uma pergunta que pega o resto: a nota está boa demais?** Uma AUC de 0,994 prevendo comportamento
humano 90 dias à frente não é um triunfo, é um sintoma. Quando um modelo de repente fica muito
melhor, o primeiro suspeito são os dados, não o algoritmo.

A lição 5 transforma várias destas em verificações que um pipeline roda toda vez, e a lição 6
constrói a junção no ponto do tempo que torna a primeira linha desta tabela verdadeira por
construção.
