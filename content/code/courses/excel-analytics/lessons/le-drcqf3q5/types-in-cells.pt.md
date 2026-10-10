---
title: O que a célula guarda, e o que ela mostra
version: 1
---

**Uma célula guarda um valor de um tipo, e o que você vê é só o jeito como ele é desenhado.** Essa
diferença decide se um total está certo, e falha em silêncio: um número guardado como texto parece
número, fica na coluna como número e é deixado de fora de toda soma.

O Excel guarda quatro tipos de valor numa célula, além dos erros:

| tipo | exemplo | como o Excel mostra, sem formatação |
|---|---|---|
| **número** | `14`, `104` | encostado na borda direita da célula |
| **texto** | `CER1K`, `Wholesale` | encostado na borda esquerda |
| **lógico** | `VERDADEIRO`, `FALSO` | centralizado |
| **erro** | `#N/D`, `#DIV/0!` | centralizado, e repassado a toda fórmula que usa a célula |

O alinhamento é um teste de graça. Sales!E2 deve ficar à direita; se uma coluna de números encosta na
borda esquerda, ela guarda texto.

## Uma data é um número com formato

Não existe um quinto tipo para datas. **O Excel guarda uma data como uma contagem de dias, em que 1º
de janeiro de 1900 é o dia 1**, e o formato só decide como esse número é desenhado. Clique em
Sales!B2, que mostra `2025-01-02`, e mude o formato para **Geral** na guia Página Inicial: vira
**45659**. Volte o formato e a data reaparece. Nada na célula mudou além do desenho.

É por isso que `=CONT.NÚM(B:B)` respondeu 108 na seção anterior: as datas são números, e
`CONT.NÚM` conta números. É também por isso que dá para subtrair uma data de outra e obter um número
de dias, e que a aula 6 tira o mês de uma data com uma função só.

## Perguntando à célula o que ela guarda

Três funções respondem a pergunta diretamente, e cada uma devolve `VERDADEIRO` ou `FALSO`. Numa
célula vazia de `Sales`, como J2:

```localised
=ÉNÚM(B2)
=ÉNÚM(D2)
=ÉTEXTO(D2)
```

A primeira, `ÉNÚM` (`ISNUMBER` no Excel em inglês), dá `VERDADEIRO`, porque B2 é uma data e,
portanto, um número. A segunda dá `FALSO` e a terceira, `ÉTEXTO` (`ISTEXT`), dá `VERDADEIRO`:
`CER1K` é texto, como um código de produto deve ser. Na planilha `Customers`,

```localised
=CONTAR.VAZIO(D2:D12)
```

responde **1**: o único cliente sem cidade, `C00`. A função é `CONTAR.VAZIO` (`COUNTBLANK`).

## O número que é texto

Agora a falha. Suponha que alguém tivesse digitado os 14 sacos da venda S1001 com um apóstrofo na
frente, `'14`, que é o que as pessoas fazem para impedir o Excel de mudar um valor. A célula
continua mostrando 14. Mas o apóstrofo a transforma em texto, e:

```localised
=CONT.NÚM(E:E)
```

cai de 108 para **107**, enquanto `=SOMA(E:E)` cai de 591 para **577**, faltando exatamente os 14
sacos que ninguém vê que sumiram. O Excel marca uma célula assim com um triangulozinho verde no canto
e oferece **Converter em Número** quando você clica no aviso ao lado, mas é uma célula de cada vez que
alguém nota, e só se alguém olhar.

Números chegam como texto muito mais vezes de fora do que pela digitação: um arquivo exportado por
outro sistema, uma coluna copiada de uma página da web, códigos com zero à esquerda que alguém
protegeu. A aula 6 é sobre trazê-los de volta. Por ora basta o hábito: **depois de qualquer colagem,
conte os números de uma coluna que deveria ter números** e compare com o número de linhas.

## Formato não é arredondamento

Mais uma armadilha da mesma família. Formate uma célula que guarda `103,5` para mostrar sem casas
decimais e ela exibe `104`, mas uma fórmula que a usa continua recebendo 103,5. O valor exibido e o
guardado podem ser diferentes, e as fórmulas sempre usam o guardado. Quando um total parece um real
diferente da coluna acima, este costuma ser o motivo, e `ARRED` (`ROUND`), que a aula 2 usa, é o
jeito de fazer o valor guardado ser o que você quer dizer.
