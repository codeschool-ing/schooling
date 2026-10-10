---
title: Espaços e maiúsculas
version: 1
---

**Espaços a mais são o defeito mais comum em texto colado, e o que ninguém vê.** Um espaço no fim
de uma palavra é invisível na tela, e para o Excel é um caractere como outro qualquer: `Wholesale`
e `Wholesale ` são tão diferentes quanto `Wholesale` e `Wholesalf`. Maiúsculas são o caso oposto.
Todo mundo as vê, e quase todo o Excel as ignora.

## Medindo um espaço que você não vê

`NÚM.CARACT` (`LEN` no Excel em inglês) conta os caracteres de uma célula, espaços incluídos, então
mostra o que o olho deixa passar. Numa célula vazia de `Old export`, como **P2**:

```localised
=NÚM.CARACT(C3)
=NÚM.CARACT(ARRUMAR(C3))
```

A primeira responde **12**, a segunda **10**. `café aroma` tem dez caracteres, e C3 guarda dois
espaços na frente deles.

## ARRUMAR

`ARRUMAR` (`TRIM`) tira todo espaço do começo e do fim de um texto, e transforma cada sequência de
espaços entre palavras em um só. É a primeira função a aplicar em qualquer coluna de texto vinda de
fora. Em **I1** digite `Customer`, e em **I2**:

```localised
=ARRUMAR(C2)
```

Preencha até I13. A linha 3 vira `café aroma`, e a linha 6, `Padaria  Central` com dois espaços no
meio, vira `Padaria Central`.

`ARRUMAR` conhece um tipo de espaço, o comum, digitado com a barra de espaço. Texto copiado de uma
página da web muitas vezes traz um **espaço não separável** no lugar, que parece idêntico e
sobrevive intacto ao `ARRUMAR`. Quando `NÚM.CARACT` ainda conta um caractere a mais depois do
`ARRUMAR`, esse costuma ser o motivo, e `SUBSTITUIR` (`SUBSTITUTE`), na seção 05, o troca antes por
um espaço comum.

## Maiúsculas: MAIÚSCULA, MINÚSCULA e PRI.MAIÚSCULA

Três funções acertam as maiúsculas de um texto: `MAIÚSCULA` (`UPPER`) põe toda letra em maiúscula,
`MINÚSCULA` (`LOWER`) não deixa nenhuma, e `PRI.MAIÚSCULA` (`PROPER`) põe em maiúscula a primeira
letra de cada palavra. A coluna de canal precisa de `ARRUMAR` para os espaços soltos e de
`PRI.MAIÚSCULA` para as maiúsculas. Em **J1** digite `Channel`, e em **J2**:

```localised
=PRI.MAIÚSCULA(ARRUMAR(F2))
```

Preenchida até J13, toda linha diz `Wholesale`, `Online` ou `Shop`, e a contagem da seção 02 sai
certa:

```localised
=CONT.SES(J2:J13; "Wholesale")
```

responde **8**. Não foi o `PRI.MAIÚSCULA` que consertou, já que as condições ignoram maiúsculas; foi
o `ARRUMAR`. As maiúsculas são para o leitor, que deve ver uma grafia só de cada canal, e para as
aulas que agrupam por esta coluna, onde uma tabela dinâmica mostra toda grafia que encontrar.

`PRI.MAIÚSCULA` é uma ferramenta grosseira para nomes. Na linha 9, `café do largo ` com um espaço no
fim,

```localised
=PRI.MAIÚSCULA(ARRUMAR(C9))
```

responde **Café Do Largo**: ela põe maiúscula em *toda* palavra, e o nome do cliente é
`Café do Largo`. Serve, então, para códigos e canais, e não para nomes de pessoas ou de empresas,
que têm regras próprias que nenhuma função conhece.

## Bate com a lista de clientes?

Limpar um nome quase sempre serve para achá-lo em outra tabela, e as buscas da aula 4 fazem isso.
`CORRESP` (`MATCH`) responde a posição de um valor numa lista e, como toda busca, **ignora
maiúsculas**:

```localised
=CORRESP(ARRUMAR(C3); Customers!B2:B12; 0)
=CORRESP(ARRUMAR(C7); Customers!B2:B12; 0)
```

A primeira responde **2**: `café aroma`, arrumado, casa com `Café Aroma`, o segundo nome da lista,
mesmo em minúsculas. A segunda responde `#N/D`. A linha 7 é `CAFE DO LARGO`, e a lista diz
`Café do Largo`. A diferença não são as maiúsculas; é o **É**. Uma letra com acento e a mesma letra
sem ele são dois caracteres diferentes, e nenhuma função do Excel os trata como iguais.

Esse último defeito não tem fórmula. Ou o sistema antigo é corrigido, ou alguém decide, uma vez e
por escrito, que `CAFE DO LARGO` é o cliente `C04`, em geral numa pequena tabela de grafias
conhecidas que uma busca lê. O `#N/D` da aula 4 é o que avisa que uma linha assim existe, mais um
motivo para nunca escondê-lo.

Use `EXATO` (`EXACT`) quando as maiúsculas **importam**: `EXATO(C2; C13)` é `VERDADEIRO` porque as
duas células dizem `Café Aroma`, enquanto `EXATO(C2; C3)` é `FALSO`. Um `=C2=C3` comum ignora
maiúsculas, e aqui diz `FALSO` só por causa dos dois espaços.
