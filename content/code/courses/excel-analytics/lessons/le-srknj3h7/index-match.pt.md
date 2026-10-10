---
title: ÍNDICE e CORRESP
version: 1
---

**`CORRESP` acha a posição de uma chave, e `ÍNDICE` devolve o que estiver numa posição. Juntas, são
uma busca que funciona em qualquer versão do Excel.** `CORRESP` é `MATCH` e `ÍNDICE` é `INDEX` no
Excel em inglês. Antes de o `PROCX` existir, esse par era o jeito de gente cuidadosa evitar as
armadilhas do `PROCV`, e continua sendo o que escrever numa pasta de trabalho que vai ser aberta num
Excel mais antigo.

## CORRESP: onde está?

O `CORRESP` recebe a chave, uma única coluna onde procurar e um tipo de correspondência, e devolve
uma posição. Digite em qualquer célula vazia da linha 2 de `Sales`:

```localised
=CORRESP(D2;Products!$A$2:$A$7;0)
```

A resposta é **4**: `CER1K` é o quarto código de A2:A7. O 0 pede correspondência exata e, como o
quarto argumento do `PROCV`, é opcional e perigoso de omitir, porque o padrão é uma correspondência
aproximada sobre dados ordenados. Sempre escreva o 0 para um código.

## ÍNDICE: o que há ali?

O `ÍNDICE` recebe um intervalo e uma posição e devolve o valor que está nessa posição:

```localised
=ÍNDICE(Products!$G$2:$G$7;4)
```

responde **61**, o quarto custo unitário, que é o do `CER1K`.

## Os dois juntos

Ponha o `CORRESP` onde estava o 4, e a posição passa a ser achada em cada linha em vez de digitada:

```localised
=ÍNDICE(Products!$G$2:$G$7;CORRESP(D2;Products!$A$2:$A$7;0))
```

Troque K2 por ela e preencha para baixo. Todo custo é igual ao que o `PROCX` deu, e `=SOMA(L2:L109)`
continua respondendo **21104**: duas fórmulas, escritas de jeitos diferentes, concordando sobre os
mesmos dados. Essa concordância é a conferência, e vale fazê-la sempre que você reescrever uma
fórmula em que já confia.

Leia o par de dentro para fora, como a aula 3 leu um `SE` aninhado. O `CORRESP` responde "que
linha?", e o `ÍNDICE` responde "o que há nessa linha desta coluna?". A coluna em que se procura e a
coluna que se traz são duas referências separadas, então a segunda pode estar à esquerda da primeira,
e inserir uma coluna em `Products` move cada referência junto com os seus dados. É por isso que o par
não tem nenhuma das três armadilhas do `PROCV`.

## Dois CORRESP: uma linha e uma coluna

O `ÍNDICE` também aceita uma tabela inteira com uma posição de linha e uma de coluna. Ache cada uma
com o seu `CORRESP`, um descendo pelos códigos e outro atravessando os cabeçalhos, e a fórmula busca
um produto e um campo pelo nome:

```localised
=ÍNDICE(Products!$A$1:$G$7;CORRESP("MOG250";Products!$A$1:$A$7;0);CORRESP("Unit cost";Products!$A$1:$G$1;0))
```

A resposta é **30**: o custo unitário do Mogiana Reserve. Os intervalos começam na linha 1 desta vez,
porque o segundo `CORRESP` procura na linha de cabeçalho; as posições são contadas dentro dos
intervalos dados, então os três precisam começar na mesma linha e na mesma coluna. Ponha `MOG250` e
`Unit cost` em células próprias, aponte para essas células em vez de digitar as palavras, e você tem
um pequeno painel de consulta: mude qualquer uma das duas células e a resposta acompanha.

## Qual escrever

| | `PROCX` | `ÍNDICE` e `CORRESP` | `PROCV` |
|---|---|---|---|
| funciona no Excel 2019 e anteriores | não | sim | sim |
| traz uma coluna à esquerda da chave | sim | sim | não |
| sobrevive a uma coluna inserida | sim | sim | não |
| correspondência exata, a menos que se diga outra coisa | sim | não, escreva o 0 | não, escreva `FALSO` |
| mensagem embutida para chave ausente | sim | não, envolva em `SENÃODISP` | não, envolva em `SENÃODISP` |

Escreva `PROCX` quando todo mundo tiver, `ÍNDICE` com `CORRESP` quando alguém talvez não tenha, e
saiba ler o `PROCV` quando o encontrar.
