---
title: O que é um teste de fumaça
version: 1
---

O teste de fumaça às vezes é descrito como alguns minutos clicando por uma versão nova para ver se
ela parece estar bem, e às vezes como uma pequena suíte de regressão. As duas descrições perdem o
que o torna útil. **Um teste de fumaça é uma lista curta e fixa de checagens, rodada em toda versão
nova antes de qualquer outro teste, que toca cada parte principal do produto uma vez, no caminho
principal. Ele responde a uma pergunta: esta versão está estável o bastante para valer a pena
testá-la?** Ele não procura defeitos em detalhe. Procura o tipo de falha que desperdiçaria todos os
outros testes rodados nessa versão.

O nome costuma ser atribuído ao hardware: ligue uma placa de circuito nova, e se sair fumaça não há
por que medir mais nada. A mesma ideia tem outros nomes em times de software, teste de verificação
de build ou teste de recebimento, e a forma é a mesma em todos eles.

## Largo, raso e rápido

Três propriedades fazem de uma lista de checagens um teste de fumaça.

Ele é **largo**: toda área principal do produto é tocada, porque uma versão que quebrou uma área
inteira não vale uma rodada completa de testes, mesmo que o resto funcione. No boxoffice as áreas
são o próprio servidor, a lista de espetáculos, o cadastro, a reserva e a caixa de saída.

Ele é **raso**: cada área é tocada uma vez, no caminho principal, com dados comuns. A fumaça reserva
dois ingressos como membro; não tenta seis, nem um estudante, nem um espetáculo cujas reservas já
fecharam. Isso são casos, e as aulas 4 e 5 tratam de escolhê-los.

Ele é **rápido**, medido em minutos à mão e em segundos como script, porque roda em toda versão,
inclusive na terceira versão de uma tarde ruim. Um teste de fumaça que leva uma hora é pulado
justamente no dia em que era necessário.

O resultado dele é um portão, não uma nota. Todas as checagens passam, e o teste começa; uma falha,
e o teste espera. Nada no meio.

## O que ele economiza

Imagine uma versão do boxoffice em que a reserva quebra, e nenhum teste de fumaça. Ana começa onde
o plano da aula 1 manda, no risco A, o preço. O primeiro caso de desconto falha no primeiro passo,
com uma página de erro. O segundo também, e o terceiro. Quando ela percebe o padrão, já escreveu
três relatórios de defeito sobre uma falha só, e Rui tem três relatórios para ler e fechar como
duplicados, assunto da aula 16.

A mesma versão com um teste de fumaça: um minuto depois de ela chegar, a linha da reserva diz
`FAIL`, Ana manda a Rui uma mensagem com essa linha e vai cuidar de outra coisa até chegar uma versão
nova. **A fumaça custa um minuto em cada versão boa para economizar uma hora em cada versão ruim**,
e num projeto com uma versão por dia as ruins aparecem com frequência suficiente para pagá-la muitas
vezes.

## Onde ele fica no plano

O plano da aula 1 para o boxoffice tem um critério de entrada, "a versão inicia e o `/health`
responde", e um critério de suspensão, "a versão não inicia, ou um quarto dos casos de uma área
falha". O teste de fumaça é como essas duas frases são conferidas na prática a cada versão: a
primeira checagem dele é o critério de entrada palavra por palavra, e uma rodada de fumaça que falha
é o caso mais claro do critério de suspensão que existe. A seção 05 desta aula acompanha uma rodada
que falhou por esse caminho.

Dois vizinhos se confundem facilmente com ele. O **teste de sanidade** é estreito e fundo onde a
fumaça é larga e rasa: ele confere que uma mudança específica, como uma correção, faz o que devia, e
a aula 9 trata dele. A **suíte de regressão** é larga e funda, roda de novo os casos que já passaram
para achar o que uma mudança quebrou, e a aula 10 trata dela. A fumaça roda antes das duas, porque
nenhuma delas vale a pena numa versão que não sobe.
