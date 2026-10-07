---
title: Que resumo cada escala aguenta
version: 1
---

Tudo até aqui se resume a uma tabela. Ache a escala da coluna, e a tabela diz quais resumos a descrevem
com honestidade.

| escala | exemplo | contagem, moda | mediana, percentis | média, desvio padrão | razões |
|---|---|---|---|---|---|
| nominal | pagamento | sim | não | não | não |
| ordinal | nota | sim | sim | com cuidado | não |
| intervalar | °C | sim | sim | sim | não |
| razão | cesta | sim | sim | sim | sim |

Leia como um conjunto de permissões. Descer uma linha nunca tira uma permissão.

## Usando a tabela

Diante de uma coluna nova, os passos são curtos:

1. Pergunte se os valores são nomes ou quantias. Nomes são nominais ou ordinais; quantias são
   intervalares ou de razão.
2. Para nomes, pergunte se têm ordem. Se têm, a mediana está disponível.
3. Para quantias, pergunte se o zero significa nada daquilo. Se significa, as razões estão disponíveis.

Aplique às colunas da Horta. *bairro*: nomes sem ordem, então **nominal**: informe contagens e
proporções. *nota*: nomes com ordem, então **ordinal**: informe a mediana e a distribuição, e a média
com uma ressalva. A temperatura na porta, que o sistema da Horta também registra em °C: quantias com
zero arbitrário, então **intervalar**: informe médias e diferenças. *cesta*: quantias com zero
verdadeiro, então **razão**: tudo está disponível.

## Um resumo permitido ainda pode enganar

A tabela responde *posso?*, e não *devo?*. Uma coluna de cestas permite média, e a aula 4 mostra um caso
em que a média é o pior número que se poderia informar. Ser permitido é o primeiro teste que um resumo
precisa passar, não o último.

## E o software não sabe

Nada disso fica guardado numa planilha. Uma coluna de dígitos é, para o software, uma coluna de números,
guarde ela cestas, notas ou CEPs. O software calcula a média de qualquer coisa para que você aponte. A
escala vive na sua cabeça e na sua documentação, e é por isso que a próxima seção existe.
