---
title: O Excel na prática, e as duas regras que evitam quase tudo
version: 1
---

## O cifrão, que é a única sintaxe

Uma referência como `C1` **se move quando a fórmula se move.** Copie `=B2*C1` por uma coluna
abaixo e ela vira `=B3*C2`, depois `=B4*C3` — o que está certo para a primeira parte e errado para
a segunda, se `C1` for a alíquota por que tudo é multiplicado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Dois painéis mostrando a mesma fórmula copiada por três linhas. À esquerda, sem cifrões, as duas referências se movem: B2 vezes C1 vira B3 vezes C2 e depois B4 vezes C3, então a taxa se afasta da célula que a guarda. À direita, com cifrões em volta de C1, só a primeira referência se move e toda linha multiplica pela mesma taxa.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">A mesma fórmula, copiada por três linhas</text><rect x=\"24\" y=\"36\" width=\"322\" height=\"182\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"44\" y=\"58\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">copiada como foi escrita</text><text x=\"44\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">=B2*C1</text><text x=\"44\" y=\"122\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">=B3*C2</text><text x=\"44\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">=B4*C3</text><text x=\"44\" y=\"196\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a taxa se afasta da célula dela</text><rect x=\"374\" y=\"36\" width=\"322\" height=\"182\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"394\" y=\"58\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">copiada com dois cifrões</text><text x=\"394\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">=B2*$C$1</text><text x=\"394\" y=\"122\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">=B3*$C$1</text><text x=\"394\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">=B4*$C$1</text><text x=\"394\" y=\"196\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">toda linha usa a taxa em C1</text><text x=\"24\" y=\"242\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Um cifrão congela o que vem depois dele. A referência para de se mover quando a fórmula se move.</text></svg>", "caption": "É isso tudo que o cifrão faz, e é a diferença entre uma coluna de totais e uma coluna de absurdos com cara de plausível."}
```

O `F4` passa uma referência pelas quatro formas enquanto você a digita: `C1`, `$C$1`, `C$1`,
`$C1`. As duas do meio congelam uma direção e são o que você quer numa tabuada.

## As duas regras

**Nunca digite um número dentro de uma fórmula.** `=B2*0,17` é uma planilha em que a alíquota está
escrita em oitenta lugares e não dá para achar. Ponha a alíquota numa célula, rotule a célula, e
faça referência a ela. Quando a alíquota mudar você muda uma coisa, e qualquer um enxerga o que a
planilha está supondo.

**Uma coisa por coluna, um registro por linha.** Uma coluna chamada `endereço` guardando rua,
cidade e CEP não dá para ordenar por cidade nem filtrar por CEP. Separar depois é uma manhã; pôr
em três colunas desde o início é de graça.

## As funções que cobrem quase tudo

| | o que faz |
|---|---|
| `SOMA`, `MÉDIA`, `CONT.NÚM` | as três que todo mundo já conhece |
| `SE` | um valor que depende de uma condição. A burra de carga |
| `CONT.SE`, `SOMASE` | contar ou somar só as linhas que casam com algo |
| `PROCX` | achar uma linha por um valor e trazer de volta uma coluna dela |
| `TEXTO`, `ESQUERDA`, `DIREITA`, `ARRUMAR` | tirar um pedaço de uma coluna bagunçada |
| `SEERRO` | mostrar algo sensato em vez de `#N/D` |

**O `PROCX` substitui o `PROCV`** e vale aprender no lugar dele: ele procura em qualquer direção,
não quebra quando uma coluna é inserida, e aceita um valor de "não achei" em vez de um erro. Se
você aprendeu `PROCV`, a única coisa a guardar dele é a ideia.

## Tabelas, que é o recurso que as pessoas pulam

Selecione um intervalo e aperte `Ctrl+T`. O intervalo vira uma **tabela**, e quatro coisas mudam:

- **Fórmulas se preenchem para baixo sozinhas** quando uma linha é acrescentada.
- **Filtros e ordenação** aparecem em cada coluna.
- **Referências viram nomes** — `=SOMA(Vendas[Valor])` em vez de `=SOMA(D2:D847)`, que continua
  certo quando linhas são acrescentadas.
- **O intervalo cresce** quando você digita embaixo dele, então todo gráfico e toda fórmula que
  apontam para ele crescem também.

Essa última propriedade é a que importa, porque o erro de planilha mais comum é uma fórmula ainda
cobrindo as primeiras oitocentas linhas de uma planilha que hoje tem novecentas.

## Três hábitos que aparecem como correção

- **Congele a primeira linha** — *Exibir, Congelar Painéis* — para os cabeçalhos ficarem visíveis.
  Rolar para dentro de colunas anônimas é como se edita a coluna errada.
- **Nunca ordene uma coluna sozinha.** Selecione o intervalo inteiro, ou use uma tabela. Ordenar
  uma coluna só a separa das linhas que ela descrevia, em silêncio e sem volta.
- **Confira o total contra alguma coisa.** Um `CONT.NÚM` ao lado de uma `SOMA` pega o problema de
  texto numa coluna de números da seção anterior, e é a única conferência que não custa nada.
