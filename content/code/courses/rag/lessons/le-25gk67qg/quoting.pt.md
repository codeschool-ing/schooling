---
title: Citação literal, para respostas que obrigam
version: 1
---

A aula 2 disse que um leitor jurídico precisa do texto que obriga, localizado com exatidão, na versão que
estava em vigor. Quase tudo isso já existe: a busca pode ser filtrada para os documentos certos, toda
fonte leva a data, e o verificador confirma que uma frase foi citada palavra por palavra. Falta uma peça,
o número da cláusula, e a aula 2 viu por que ele some: o extract-1 descarta um número no começo de uma
linha quando separa frases, e o caminho do pedaço nomeia a seção, não a cláusula.

O número continua no texto da fonte, logo antes da frase. O `clause.py` o encontra ali:

```
ana@lab:~/rag$ python clause.py "When is the contract of sale formed?"
"The contract is formed when we send the email confirming that your order has been dispatched."
  Terms of sale > 2. Placing an order, clause 2.2, updated 2026-01-05
```

**Cláusula 2.2 dos termos de venda, atualizados em 2026-01-05**: tudo de que um advogado precisa para
achar o texto e conferi-lo. O programa olha o texto da fonte antes da frase citada e pega o último número
de cláusula que encontra ali. É um código pequeno, e funciona porque os documentos numeram as cláusulas
de modo consistente; em documentos que não numeram, o número tem de ser acrescentado aos metadados do
pedaço quando o documento é cortado, do jeito que a aula 5 acrescenta o caminho.

## Literal, e conferido

Para um uso em que a redação importa, o prompt pede citações em vez de respostas: *cite literalmente a
cláusula que responde à pergunta, com o número dela*. Um modelo real em geral obedece, e de vez em quando
troca uma palavra ao citar, *may* por *must*, *delivered* por *dispatched*, porque a paráfrase é o que o
treinamento dele recompensa. Então a verificação de antes nesta aula fica estrita: **uma resposta
jurídica só passa se toda frase citada aparecer na fonte caractere por caractere**, e uma frase só
próxima é uma falha, não uma paráfrase.

## Suporte do provedor a citações

A Messages API da Anthropic consegue fazer parte disso sozinha. Fontes mandadas como blocos `document`
com citações ativadas voltam com cada parte da resposta presa a um intervalo de caracteres num
documento, então o programa recebe o trecho exato em vez de um número para procurar. O labgen implementa
esse formato, e a aula 9 o usa pelo SDK da Anthropic. A verificação não some com isso: um intervalo diz
de onde o provedor afirma que o texto veio, e um programa que importa ainda confirma que o texto está lá.
