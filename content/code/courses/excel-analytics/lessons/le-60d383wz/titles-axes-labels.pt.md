---
title: Títulos, eixos e rótulos que dizem a verdade
version: 1
---

**Cada elemento de um gráfico ou ajuda o leitor a ver a resposta ou fica no caminho dela.** Os
padrões do Excel são feitos para servir a qualquer dado: um título que repete o cabeçalho da coluna,
uma legenda para uma série só, linhas de grade atrás de tudo. Cada um é uma decisão que o Excel tomou
sem conhecer a pergunta, e esta seção as toma de novo, de propósito.

## Um gráfico para trabalhar

Crie uma planilha chamada `Mix`. Digite `Channel`, `Revenue` e `Share` em A1:C1, e `Wholesale`,
`Online` e `Shop` em A2:A4. Depois, em B2 e C2, arrastadas até a linha 4:

```localised
=SOMASES(Sales[Revenue]; Sales[Channel]; A2)
=B2/SOMA($B$2:$B$4)
```

Dê à coluna C o formato de porcentagem. A planilha fica assim:

| `Channel` | `Revenue` | `Share` |
|---|---|---|
| `Wholesale` | 38.731 | 75,2% |
| `Online` | 11.143 | 21,6% |
| `Shop` | 1.620 | 3,1% |

Selecione A1:B4 e escolha **Inserir › Inserir Gráfico de Colunas ou de Barras › Colunas Agrupadas**.

## Um título que diz a conclusão

O Excel dá ao gráfico o título `Revenue`, que o leitor já via no eixo. Clique no título e digite o
que o gráfico mostra: **O atacado traz três quartos da receita**. Um título que afirma a conclusão diz
ao leitor o que procurar, e quem discordar pode conferir nas barras. Quando o gráfico é para explorar,
e não para afirmar, cabe uma descrição simples: *Receita por canal, janeiro de 2025 a junho de 2026*.
De um jeito ou de outro ele diz o período, porque um gráfico sem período é um número sem data.

## Um eixo que começa no zero

**O comprimento de uma barra é o valor dela, então o eixo de um gráfico de barras começa no zero.**
Veja o que acontece quando não começa. Dê um clique duplo no eixo vertical e, em **Formatar Eixo ›
Opções de Eixo › Limites**, ponha o **Mínimo** em 10000:

| | a partir do zero | a partir de 10.000 |
|---|---|---|
| barra de `Wholesale` | 38.731 | 28.731 |
| barra de `Online` | 11.143 | 1.143 |
| quantas vezes mais alta | 3,48 | 25,1 |
| barra de `Shop` | 1.620 | sumiu, abaixo do eixo |

O atacado fatura 3,48 vezes o online, e o eixo cortado o desenha 25 vezes mais alto. O balcão sumiu
de vez. Nada no gráfico é falso: cada barra termina no seu valor. A mentira está no que o olho mede.
Clique em **Redefinir** (*Reset*) ao lado de **Mínimo** para devolver o eixo ao zero.

Um gráfico de linhas é diferente. Quem o lê acompanha posições e inclinações, não comprimentos, então
a linha mensal da seção anterior pode começar acima do zero para mostrar o movimento, desde que os
rótulos do eixo deixem claro o valor inicial.

## Unidades, e rótulos no lugar da poluição

- **Diga a unidade uma vez.** Acrescente um título de eixo com **Design do Gráfico › Adicionar
  Elemento Gráfico › Títulos dos Eixos** e digite *R$*. Em **Formatar Eixo › Número**, um formato com
  separador de milhar transforma `38731` em `38.731`.
- **Rotule as barras e tire o que os rótulos substituem.** **Adicionar Elemento Gráfico › Rótulos de
  Dados › Extremidade Externa** escreve cada valor na sua barra. Com os três valores escritos, as
  linhas de grade não dizem mais nada: clique numa e tecle Delete.
- **Uma série só não precisa de legenda.** O Excel põe uma para `Revenue`; o título já diz o que está
  desenhado. Apague-a.

## Uma cor, e um destaque

Todas as barras são uma série, então têm uma cor. Para apontar uma delas, clique nas barras uma vez,
depois clique só em `Wholesale`, e dê a ela outro preenchimento em **Formatar › Preenchimento da
Forma**. Use uma segunda cor por um motivo só, e deixe o título nomeá-lo, porque uma cor que só parte
dos leitores distingue é a falha contra a qual a aula 9 avisou: o título e os rótulos levam o
sentido, e a cor só o repete.
