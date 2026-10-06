---
title: Números que na verdade são nomes
version: 1
---

Uma coluna escrita em dígitos não é necessariamente numérica. A pergunta nunca é "é um número?", e sim
**"a aritmética sobre isso significa alguma coisa?"**

O *CEP* da Horta é o caso mais claro. `13025-320` está escrito em dígitos, mas dá nome a um trecho de
rua. Tire o hífen e calcule a média dos doze CEPs e você obtém 13.044.475,83, que não é um CEP, não é
um lugar e não é coisa nenhuma. Dois pedidos com o mesmo CEP dizem que foram para a mesma rua.
Subtrair dois CEPs não diz nada.

## O teste, aplicado

Pergunte o que a média significaria, numa frase que um gerente pudesse usar.

| coluna | escrita como | a média significa | tipo |
|---|---|---|---|
| cesta | 86,40 | o valor típico gasto | numérica |
| itens | 7 | o número típico de coisas compradas | numérica |
| CEP | 13025-320 | nada | categórica |
| pedido | H-1041 | nada | um identificador |
| telefone | 19 3255-0000 | nada | um identificador |

O mesmo teste pega os códigos que os sistemas inventam. Uma pesquisa que grava "1 = pix, 2 = cartão,
3 = dinheiro" transformou uma categoria em dígitos. Tire a média desses códigos nos doze pedidos e você
obtém 1,67, que a planilha imprime com quatro casas decimais e que não descreve nada: não existe forma
de pagamento a dois terços do caminho entre pix e cartão. A aula 2 volta a essas colunas codificadas,
porque é nelas que os relatórios reais erram.

## Identificadores são um tipo à parte

Um **identificador** dá nome a uma observação e a mais nada: um número de pedido, um número de cliente,
um CPF. Nem como categoria ele serve, porque cada valor aparece exatamente uma vez. Conte as categorias
e você terá tantas quanto linhas.

Identificadores importam por outro motivo: são eles que ligam uma tabela a outra. Nunca tire a média
deles, nunca agrupe por eles e nunca os jogue fora.

## A exceção útil: sim e não

Uma variável de **sim/não** é categórica, com duas categorias. O pedido chegou atrasado, sim ou não? Foi
usado um cupom? Codifique *sim* como 1 e *não* como 0, e acontece algo útil: **a média da coluna é a
proporção de sins**.

Suponha que três dos doze pedidos da Horta tenham chegado depois do horário prometido. Codificada com 1
para atrasado e 0 para no prazo, a coluna soma 3, e a média dela é 3 ÷ 12 = 0,25. Esse 0,25 é uma
resposta de verdade: um quarto dos pedidos atrasou. Esse truque é a ponte entre contar e tirar média, e
a aula 12 se apoia nele para construir um intervalo de confiança para uma proporção.
