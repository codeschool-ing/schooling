---
title: SEERRO, e os erros que ele não deveria esconder
version: 1
---

**`SEERRO` (`IFERROR` no Excel em inglês) troca qualquer erro por um valor que você escolhe, e
"qualquer" é ao mesmo tempo a utilidade e o perigo dele.** Um erro numa célula é o Excel dizendo que
algo que lhe pediram não pôde ser feito. Alguns são esperados e inofensivos; a maioria é sintoma de
algo errado nos dados ou na fórmula. O `SEERRO` não distingue uns dos outros, então quem o escreve
precisa distinguir.

## Os erros

| erro | o que o Excel não conseguiu fazer | um exemplo nestes dados |
|---|---|---|
| `#DIV/0!` | dividir por zero, ou por uma célula vazia | `=H3/L3` na aula 2 seção 03 |
| `#VALOR!` | usar um valor do tipo errado | um preço vezes o texto `Wholesale` |
| `#N/D` | achar algo que mandaram procurar | um código de produto que não está em `Products`, aula 4 |
| `#REF!` | alcançar uma célula que foi excluída | aula 2 seção 06 |
| `#NOME?` | reconhecer um nome na fórmula | um nome de função digitado errado |

Todos eles se espalham: uma fórmula que usa uma célula com erro também dá erro. Isso é de propósito.
Um total sobre uma coluna com um `#VALOR!` mostra `#VALOR!`, e não um total que ficou baixo em
silêncio.

## Um erro que você espera

Receita dividida por sacos devolve o preço, então uma coluna de `=H2/E2` é uma conferência barata de
que a coluna H está inteira: em toda linha ela deve ser igual a `Price`. Em J2:

```localised
=H2/E2
```

J2 mostra **104**, o preço da S1001. Agora suponha que a coluna seja preenchida uma linha além, até
J110, pronta para a próxima venda. A linha 110 está vazia, e J110 mostra `#DIV/0!`. Esse erro é
esperado e não quer dizer nada: ainda não há venda ali. Isto o esconde:

```localised
=SEERRO(H110/E110;"")
```

e J110 não mostra nada.

## O erro que você não esperava

A próxima venda é digitada na linha 110, e alguém escreve `5 bags` em `Bags`. Isso é texto, e
`=H110/E110` mostraria `#VALOR!`, um sinal de que a linha precisa de conserto. Sob o `SEERRO`, J110
não mostra nada, exatamente como quando a linha estava vazia. A venda está na planilha e invisível
para toda conferência.

A mesma cegueira transforma um erro de digitação num zero silencioso. Digite `E2O`, com a letra O,
onde queria `E2`:

```localised
=SEERRO(H2/E2O;0)
```

`E2O` não é uma célula, então o Excel procura um nome `E2O`, não acha, e a fórmula de dentro dá
`#NOME?`. O `SEERRO` transforma isso em 0 em toda linha da coluna. Toda conferência calculada a
partir dela agora é zero, e nada na planilha diz por quê.

## Teste o que você espera

O conserto é fazer a pergunta que você queria fazer, em vez de pegar tudo. O caso esperado era uma
linha vazia, então teste se a linha está vazia:

```localised
=SE(E110="";"";H110/E110)
```

Uma linha vazia não mostra nada, como antes. Uma linha com `5 bags` mostra `#VALOR!`, porque nada o
pegou. A fórmula fica alguns caracteres mais longa, e todo erro inesperado continua chegando aos
seus olhos.

Quando o erro esperado é uma busca que falhou, `SENÃODISP` (`IFNA`) é a versão estreita: troca
`#N/D` e deixa passar todos os outros erros. `=SENÃODISP(H110/E110;"")` continua mostrando `#DIV/0!`
na linha vazia, porque divisão por zero não é valor ausente. A aula 4 usa o `SENÃODISP` onde ele
cabe, em volta de buscas.

Uma regra prática que cobre a maioria dos casos: **pegue o erro que você sabe nomear, e mostre-o como
algo visível.** `"não encontrado"` numa célula é informação; `0` num total é um número errado.
