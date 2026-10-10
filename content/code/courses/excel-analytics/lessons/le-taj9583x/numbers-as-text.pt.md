---
title: Números guardados como texto, e texto que precisa continuar texto
version: 1
---

**Uma coluna é de quantidades ou de identificadores, e o Excel precisa saber qual.** Quantidades são
números: são somadas, tiradas a média e comparadas. Identificadores só parecem números: um número de
pedido, um CEP, um telefone, um código com zero à esquerda. A planilha `Old export` tem um de cada
dando errado. Quatro quantidades chegaram como texto, e todo número de pedido perdeu os zeros por ter
sido lido como número.

## Texto que devia ser número

A seção 08 da aula 1 mostrou o sintoma: um número guardado como texto é ignorado pela `SOMA` e não
entra no `CONT.NÚM`, sem erro nenhum. Aqui a causa está à vista, `6 un`, e a cura são dois passos.
Tire a unidade com `SUBSTITUIR` (`SUBSTITUTE` no Excel em inglês), que troca um pedaço de texto por
outro, aqui por nada; depois transforme o que sobra em número com `VALOR` (`VALUE`). Em **L1**
digite `Bags`, e em **L2**:

```localised
=VALOR(SUBSTITUIR(E2; " un"; ""))
```

Preencha até L13. A linha 3, `6 un`, vira **6**, um número que fica à direita da célula. A linha 2,
que já era o número 12, passa sem estrago: `SUBSTITUIR` não acha nada para trocar e devolve o texto
`12`, e `VALOR` o transforma de volta em 12. Uma fórmula cuida dos dois tipos de linha, e é isso que
deixa preenchê-la pela coluna inteira.

Depois, a conferência, que é a razão de ser da coluna:

```localised
=CONT.NÚM(L2:L13)
=SOMA(L2:L13)
```

**12** e **86**. Doze linhas entraram e doze números saíram, e o total é o 86 que a seção 02
prometeu, não o 48 que a `SOMA` achou quando quatro valores eram texto.

Há quem converta com aritmética: `=--E2`, dois sinais de menos, ou `=E2*1`, ambos arrancam um número
de um texto que parece número. Fazem o mesmo que `VALOR` numa célula como `12` e falham em `6 un`
do mesmo jeito, já que nenhuma conta lê as letras. `VALOR` diz para que serve, e esse é o melhor
motivo para usá-la.

Quando a coluna está limpa a não ser pelo tipo, sem unidade nenhuma, há dois jeitos mais rápidos que
deixam números em vez de fórmulas: o triângulo de aviso da célula, cujo menu oferece **Converter em
Número** para uma seleção inteira; e **Dados › Texto para Colunas** com **Concluir** de cara, que
relê cada célula da coluna como se tivesse acabado de ser digitada.

## Texto que não pode virar número

Os números de pedido deram errado no sentido contrário. O sistema antigo escreveu `00841`, e na
colagem o Excel viu dígitos e guardou o número 841. Para uma quantidade isso estaria certo. Para um
identificador é outro valor: um pedido chamado `00841` e um chamado `841` não são o mesmo para quem
procura por ele no sistema antigo.

`TEXTO` (`TEXT`) transforma um número em texto, arrumado por um padrão, e um padrão de cinco zeros
quer dizer *pelo menos cinco dígitos, completados com zeros à esquerda*. Em **M1** digite `Order`, e
em **M2**:

```localised
=TEXTO(A2; "00000")
```

responde **00841**, como texto, encostado à esquerda da célula. Preenchida para baixo, todo pedido
recupera os cinco dígitos.

Isso conserta a coluna depois do estrago, e só porque o tamanho é conhecido, cinco dígitos em todo
pedido. O conserto melhor é impedir o estrago na entrada. Quando um arquivo é importado em vez de
colado, a importação deixa declarar cada coluna como texto antes de qualquer valor ser lido, e a
aula 13 faz exatamente isso com o Power Query. Um código de tamanho
variável, como um código de produto que pode ou não começar com zero, não tem conserto depois,
porque nada do que sobrou na célula diz quantos zeros havia.

## A regra por baixo

Faça a cada coluna a pergunta da aula 1: o que vai ser feito com ela? Se vai ser somada ou comparada
como quantidade, é número, e o que a transformou em texto precisa ser desfeito. Se só vai ser
casada, buscada ou lida, é texto, mesmo que seja toda de dígitos, e a célula deve saber disso antes
que o Excel adivinhe. `Sale`, `Customer` e `Product` em `Sales` são texto exatamente por isso, e o
mesmo vale para CEPs e telefones em todo lugar.
