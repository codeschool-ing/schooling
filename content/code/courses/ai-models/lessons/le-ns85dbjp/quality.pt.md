---
title: Qualidade, e o que fica no lugar dela
version: 1
---

Qualidade é o critério para o qual as pessoas mais querem um número, e o único que nenhuma tabela
consegue dar. O que fica no lugar dela, antes de qualquer medição, cai em três grupos, do menos ao
mais útil.

**Rankings públicos.** A nota de um modelo num benchmark compartilhado, ou a posição dele onde
pessoas votam entre duas respostas anônimas. São medições reais de alguma coisa, e boas para uma
coisa: perceber que um modelo existe e está no mesmo patamar dos outros. Medem tarefas de outras
pessoas, quase sempre em inglês, com prompts escritos para o benchmark, e um modelo pode ser ajustado
na direção de um benchmark popular até a nota dizer mais sobre o ajuste do que sobre o modelo.

**As faixas do próprio provedor.** Toda família das aulas 6 a 11 vem em tamanhos: um modelo grande,
caro e mais lento, e outros menores, mais baratos e mais rápidos. Dentro de uma família a ordem é
confiável: o grande é melhor em tarefas difíceis. Entre famílias não é: o modelo pequeno de um
provedor pode vencer o médio de outro na sua tarefa, ou perder feio.

**A dificuldade da tarefa.** A referência mais útil das três, e a mais pulada. A tarefa de
classificação da ana é fácil: cinco rótulos, e-mails curtos, casos claros. Um modelo pequeno
provavelmente vai bem, e pagar por um grande compra acurácia nos cinco ou seis casos em que uma
pessoa também hesitaria. A tarefa de rascunho é mais difícil: tom, política, um português que precisa
soar natural. É ali que os modelos maiores justificam o preço, se justificarem.

## O que "bom o bastante" significa

Um limite de qualidade precisa ser escrito como um número sobre um conjunto de casos, senão não dá
para conferir: **"pelo menos 35 de 40 classificados como uma pessoa classificou"**, não "preciso".
Escolha a partir do custo de um erro:

- um e-mail com rótulo errado cai na fila errada e é movido à mão, o que custa um minuto;
- um número de pedido errado numa extração manda o reembolso errado, o que custa dinheiro e um
  cliente;
- um rascunho com a política errada é pego pelo atendente que o lê antes de enviar, se o atendente
  ler.

Custos diferentes, pisos diferentes, e **um modelo pode passar numa tarefa e falhar em outra**. Isso
é motivo para escolher por tarefa, não por empresa, e a aula 5 avalia cada tarefa separadamente.

## O que esta aula faz com qualidade

Nada, ainda, de propósito. A seção 08 monta a matriz com uma coluna de qualidade **vazia**, para ser
preenchida com as medições da aula 5. Uma matriz com a coluna de qualidade preenchida a partir de
rankings pareceria pronta, e estaria respondendo a uma pergunta que ninguém fez.
