---
title: O que a cobertura não consegue dizer
version: 1
---

**Um relatório de cobertura é uma das coisas mais úteis que quem testa pode ler, e uma das mais mal
lidas.** Ele responde uma pergunta com grande precisão: *que partes do código estes testes fizeram rodar?*
E é tomado rotineiramente como resposta a outra: *este código está testado?* As duas seções anteriores
mostraram por que elas diferem. Esta dá nome às três coisas que a cobertura não enxerga, para você poder
dizê-las quando alguém apontar para uma porcentagem.

## 1. Se a resposta estava certa

Uma linha roda conferindo o teste o resultado dela ou não. O `cases.py` compara todo resultado com um preço
esperado, então uma resposta errada imprimiria `FAIL`. Tire essa comparação e imprima só os resultados, e o
relatório do `tickets.py` seria idêntico: as mesmas linhas rodam, os mesmos 87%. **A cobertura mede
execução, não conferência.** Uma suíte que roda toda linha e não confere nada tira nota máxima.

Isso não é hipotético. Times julgados por um número de cobertura aprendem, rápido e muitas vezes sem
querer, a escrever testes que rodam código e afirmam pouco, porque esse é o jeito mais barato de mexer no
número. A aula 22 trata desse padrão em geral.

## 2. Se as entradas certas foram escolhidas

O de sessenta e um anos rodou a linha `half = True` depois de `if age > 60`, e a cobertura subiu. Sessenta
a teria pulado: para sessenta a decisão é falsa, o desconto nunca é dado, e o teste teria falhado. **A
cobertura conta que uma linha rodou, não com que valores.** Sessenta e um a satisfez, e ela não tinha por
que pedir sessenta; o defeito inteiro é a diferença entre os dois.

Escolher valores nas bordas de uma decisão é um hábito de caixa preta, da aula 6. A caixa branca diz que
decisões existem; os valores que as testam bem vêm da regra.

## 3. Se falta código

O relatório descreve as linhas do arquivo. Não tem nada a dizer sobre linhas que deveriam estar no arquivo
e não estão:

- nenhuma linha confere se um horário está escrito com dois dígitos, então o defeito das 9:30 não tem linha
  para ficar descoberta;
- nenhuma linha recusa uma idade negativa, então `-5` é cobrado como criança e nenhum relatório mostra
  lacuna;
- nenhuma linha limita os descontos a meia, então o defeito da soma mora na ausência de uma linha.

**Código que falta é invisível para todo critério de cobertura**, de comandos a caminhos, porque todos
medem a estrutura que existe. Defeitos de omissão são achados a partir do requisito, das perguntas que o
requisito deixa abertas e das entradas que ninguém mencionou, ou seja, de fora.

## Para que um relatório de cobertura serve

Lido ao contrário, a cobertura é excelente: **uma linha que nunca rodou é uma linha que ninguém testou**,
com certeza. Esse sentido nunca mente. O `>>>>>>` ao lado de `age > 60` foi um achado verdadeiro e útil, e
não custou nada. Use a cobertura para achar o que não foi testado, nunca para provar o que foi.

As ferramentas que medem cobertura num projeto real, como rodá-las a cada mudança e como ler os relatórios
de desvios, são a aula 4 de `testing-cicd`. O que esta aula te dá é a leitura: uma porcentagem alta é a
ausência de um tipo de lacuna, e não diz nada sobre os outros.
