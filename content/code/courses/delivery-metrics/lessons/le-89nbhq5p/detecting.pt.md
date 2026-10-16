---
title: Detectando, e tornando inútil
version: 1
---

Burlar a métrica é mais fácil de prevenir do que de flagrar, e mais fácil de tornar inútil do que de prevenir. Os hábitos abaixo fazem as três coisas, mais ou menos nessa ordem de importância.

## Leia as quatro juntas

Todo truque do catálogo desta aula melhora uma ou duas métricas e deixa as outras quietas ou torna uma delas indefinida. **Lidas como um conjunto, as quatro métricas DORA são difíceis de fingir.** Um relatório que melhora a frequência de deploy e a taxa de falha enquanto o lead time e o tempo para restaurar ficam parados está fazendo uma pergunta; um relatório que mostra uma taxa de falha de 0% sem tempo para restaurar já a respondeu.

## Mantenha um registro de definições

Anote o que conta como deploy, falha, início e restauração, como a aula 5 pediu, e **coloque toda mudança de definição no mesmo registro, com a data**. Um gráfico com um degrau pode então ser conferido contra o registro em um minuto. A maioria das mudanças de definição é razoável; todas devem ficar visíveis, porque uma invisível não se distingue de uma melhora.

## Olhe os eventos, não só as taxas

Uma taxa esconde o numerador e o denominador. "3%" pode ser 2 de 72 ou 1 de 38. Mostrar as contagens ao lado da taxa, como o `game.py` faz, deixa visível um salto repentino no denominador. **Sempre que um número melhorar bruscamente, abra os eventos brutos por trás dele**: a lista de deploys, a lista de falhas, os itens que saíram do quadro. Cinco minutos com a lista encontram a maioria dos truques.

## Junte cada métrica com aquela pela qual ela pode ser trocada

| se você acompanha | acompanhe também |
|---|---|
| frequência de deploy | taxa de falha de mudanças, e o número de execuções do pipeline |
| taxa de falha de mudanças | tempo para restaurar; um "-" repentino quer dizer que a definição se moveu |
| vazão | tempo de ciclo, e itens reabertos |
| tempo de ciclo | itens divididos ou tirados do quadro |

## Torne inútil

A defesa mais forte é a que a aula 6 e a aula 20 defendem: **o salário, a avaliação ou a posição de ninguém dependem do número**. Um time que lê as próprias métricas para melhorar o próprio trabalho não ganha nada enganando a si mesmo, e perde o instrumento. Um time ranqueado ou recompensado por elas ganha tudo. A lei de Goodhart não é uma lei da natureza; é o que acontece sob um uso específico de um número, e o uso é uma escolha.

## Quando você encontrar

Você vai encontrar. Quando encontrar, **corrija o incentivo antes de falar das pessoas**. Quem dividiu os deploys estava respondendo a uma pergunta que alguém pediu que respondesse. Mude a pergunta, anote a definição, e o truque deixa de valer a pena. Tratar isso como má conduta ensina todo mundo a esconder melhor o próximo, que é o oposto da cultura generativa que a aula 6 descreveu.
