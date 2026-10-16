---
title: E, OU e NÃO
version: 1
---

**`E`, `OU` e `NÃO` (`AND`, `OR` e `NOT` no Excel em inglês) combinam comparações numa resposta só,
e é com eles que se escreve uma condição de várias partes.** `E` dá `VERDADEIRO` quando todas as
comparações dentro dele dão; `OU`, quando pelo menos uma dá; `NÃO` troca uma resposta pela outra.
Cada um devolve `VERDADEIRO` ou `FALSO`, então pode ficar sozinho numa célula ou no primeiro
argumento de um `SE`.

## E: todas as partes valem

Quais vendas de atacado foram pequenas, com menos de dez sacos? Duas condições, as duas obrigatórias:

```localised
=E(G2="Wholesale";E2<10)
```

A linha 2 dá `FALSO`: a S1001 é de atacado, mas tem 14 sacos. Preenchida para baixo, 16 linhas dizem
`VERDADEIRO`. O mesmo par de comparações, escrito como intervalo, é o conserto da cadeia da primeira
seção. Entre 4 e 9 sacos é:

```localised
=E(E2>=4;E2<10)
```

e esta dá `VERDADEIRO` em 41 linhas, as 41 vendas `Medium` da seção anterior.

## OU: basta uma parte

Quais vendas foram dos dois sacos especiais, o descafeinado ou o Mogiana Reserve?

```localised
=OU(D2="DEC250";D2="MOG250")
```

Cada argumento precisa ser uma comparação inteira, e esquecer isso é o erro mais comum com `OU`.
Escrita do jeito que se fala, `=OU(G2="Wholesale";"Shop")`, o segundo argumento é só a palavra
`"Shop"`: ela não pergunta nada sobre G2. O Excel não adivinha a sua intenção, e o que quer que a
célula mostre, não é a resposta a "isto é atacado ou loja". Repita a célula em cada parte:
`=OU(G2="Wholesale";G2="Shop")`.

Preenchida para baixo, a fórmula do descafeinado ou Mogiana dá `VERDADEIRO` em 35 linhas.

## NÃO: a outra resposta

`=NÃO(G2="Online")` dá `VERDADEIRO` para toda venda que não foi feita online. Para uma comparação
só, `<>` diz a mesma coisa de um jeito mais simples, `=G2<>"Online"`, e é a escolha melhor. O `NÃO`
se justifica em volta de algo mais longo, como `=NÃO(OU(D2="DEC250";D2="MOG250"))`, toda venda que
não foi de nenhum dos dois.

## Dentro do SE

Os três aparecem mais como teste de um `SE`. Um rótulo para os pedidos pequenos de atacado, e nada
em todas as outras linhas:

```localised
=SE(E(G2="Wholesale";E2<10);"Small trade order";"")
```

Leia uma condição longa do jeito que as seções anteriores leram um `SE` aninhado: de fora para
dentro, uma função de cada vez, e com uma linha dos dados na sua frente para conferir cada parte.

Uma última coisa que essas fórmulas mostram sobre os dados. `=E(G2="Wholesale";E2>=10)` dá
`VERDADEIRO` em 22 linhas, e `=E2>=10` sozinha também: nesta planilha, toda venda de dez sacos ou
mais é de atacado. A segunda condição não acrescenta nada aqui, e perceber isso já é uma descoberta
sobre os clientes da Café Serra.
