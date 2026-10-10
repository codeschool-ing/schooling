---
title: Testando por dentro
version: 1
---

**O teste caixa branca escolhe seus testes olhando o código: suas decisões, seus desvios, os caminhos
por dentro dele.** Onde a caixa preta pergunta *o que isto deveria fazer?*, a caixa branca pergunta *o que
isto pode fazer?*, e responde lendo. O nome é o oposto óbvio de caixa preta, e alguns livros preferem
**caixa de vidro** ou **caixa transparente**, que descrevem melhor: você não está pintando a caixa de
branco, está enxergando através dela.

## Você não precisa escrever código para lê-lo

A objeção mais comum de quem testa e não programa é que caixa branca é trabalho de desenvolvedor. Parte
dela é. A parte que esta aula ensina não é, e você a faz desde a aula 1: ler o `tickets.py` com as notas ao
lado, bem o bastante para dizer o que cada parte decide. Isso basta para fazer as perguntas de caixa
branca:

- **que linhas existem que nenhum teste fez rodar?**
- **que decisões só foram para um lado?**
- **que combinações de decisões nada exercitou?**

Respondê-las exige uma ferramenta que observe o programa rodando e registre o que aconteceu, e o Python
tem uma embutida. Ninguém precisa mudar uma linha do `tickets.py`.

## Quatro jeitos de medir o lado de dentro

As perguntas acima têm nomes, cada um mais rigoroso que o anterior. Chamam-se critérios de **cobertura**:
medidas de quanto da estrutura do código um conjunto de testes exercitou.

| critério | coberto quando toda… | para o `tickets.py` |
|---|---|---|
| **comando** (ou linha) | linha rodou pelo menos uma vez | cada uma das linhas de `price` |
| **desvio** (ou decisão) | decisão foi para os dois lados pelo menos uma vez | cada `if` verdadeiro uma vez e falso uma vez |
| **condição** | parte de uma decisão composta foi verdadeira e falsa | nenhuma aqui: todo `if` testa uma coisa só |
| **caminho** | rota do começo da função até um `return` foi percorrida | toda combinação dos seis `if`s que pode acontecer |

Cada um é satisfeito por mais testes que o de cima, e acha defeitos que o de cima não acha. As duas
próximas seções medem o primeiro e raciocinam sobre o segundo e o último.

## Em que a caixa branca é boa

A grande força dela é o espelho da fraqueza da caixa preta. A caixa preta só testa o comportamento em que
alguém pensou; a caixa branca testa **o comportamento que existe**, tenha alguém pensado nele ou não. Se o
`tickets.py` tivesse uma linha que desse desconto numa data específica, nenhuma regra apontaria para ela,
e quem testa como caixa branca acharia a linha lendo, e uma ferramenta de cobertura informaria que nenhum
teste a rodou.

É também a abordagem natural para quem escreveu o código, no momento em que o escreve. O Rafael não
precisa de especificação para saber que o seu `if age < 12` deve ser testado com 11 e com 12. Ele vê a
linha.

## Em que ela é ruim

A fraqueza dela é o espelho da força da caixa preta. **A caixa branca testa o código que existe, e por
isso não enxerga código que falta.** O `tickets.py` não tem linha que confira se um horário está escrito
com zero à esquerda, nem linha que recuse uma idade de menos cinco, nem linha que limite os descontos a
meia. Nenhuma dessas ausências aparece em relatório de cobertura nenhum, porque um relatório só consegue
descrever linhas que estão lá. A aula 6 achou as três de fora.

É por isso que as duas abordagens são usadas juntas, e é por isso que a aula 8 existe.
