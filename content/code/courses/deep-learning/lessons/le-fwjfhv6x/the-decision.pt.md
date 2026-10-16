---
title: A decisão, como uma lista de verificação
version: 1
---

A aula se resume a algumas perguntas, feitas em ordem, antes que alguém escreva um laço de treino.
**Cada uma tem uma medição por trás, desta aula ou de uma anterior**, então a resposta pode ser
conferida em vez de discutida.

| pergunta | se sim | onde foi medido |
| --- | --- | --- |
| Os dados são linhas e colunas, cada coluna uma grandeza que alguém escolheu? | Comece pelo boosting, e faça a rede superá-lo | as tabelas de câncer e de clientes, nesta aula |
| As colunas têm buracos, categorias, escalas muito diferentes? | O boosting as aceita como estão; uma rede precisa de cada uma preparada | `baseline.py`, nesta aula |
| A entrada é crua e estruturada: pixels, áudio, texto? | Uma rede, porque os atributos precisam ser aprendidos | `moved.py`, nesta aula; aulas 11 e 16 |
| Há só dezenas de exemplos por classe? | Um modelo simples, ou uma rede pré-treinada com uma cabeça nova | `small.py`, nesta aula; aulas 13 e 17 |
| A vantagem da rede é menor que a dispersão entre sementes? | Ela não venceu; fique com o modelo mais barato | aula 18 |
| O ganho paga as horas e o hardware? | Treine; senão, não | aula 19 |

**A primeira linha é a mais pulada.** Uma equipe que começa com uma rede numa tabela descobre quão
boa a rede é, e nunca descobre se um modelo treinado em um ou dois segundos teria se saído igual.
Rode a linha de base primeiro, e o resultado da rede terá com o que ser comparado no dia em que
chegar.

As perguntas não são um argumento contra o deep learning. A mesma lista manda imagens, som e texto
para uma rede toda vez, e com um modelo pré-treinado manda poucos dados para lá também. O que ela
recusa é o hábito de escolher o modelo antes de olhar os dados.

## O fim do curso

Isso fecha o curso. Ele começou com um perceptron falhando no XOR na aula 1. Depois construiu à mão, em NumPy, cada
peça de uma rede: o gradiente, a retropropagação, as perdas, os otimizadores, as regularizações e as
normalizações. A partir da aula 9, o PyTorch fez o mesmo em poucas linhas. Vieram convoluções, sequências, atenção e tokens, depois transferência e ajuste
fino, e as três últimas aulas foram sobre saber quanto vale um resultado: a dispersão, o preço e,
aqui, se uma rede era a ferramenta certa.

**Tudo o que você rodou está na sua própria máquina**, em `~/dl`, e todo programa pode ser rodado de
novo, alterado e quebrado de propósito. Essa é a melhor maneira de guardar o que o curso ensinou.
