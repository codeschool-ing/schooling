---
title: Segmentações, um filtro que se vê
version: 1
---

**Uma segmentação de dados é o filtro de uma tabela dinâmica desenhado como uma fileira de botões, e
o que ela acrescenta em relação à área Filtros é mostrar o que está selecionado.** Um campo em
**Filtros** com dois itens escolhidos mostra `(Vários Itens)` e obriga quem lê a abri-lo para
descobrir quais. Uma segmentação acende os botões escolhidos, e quem olha a planilha sabe de que são
os números.

## Inserindo uma

Esta seção e as três seguintes trabalham sobre uma única tabela dinâmica. Monte-a a partir da tabela
`Sales` numa **Nova Planilha**, renomeie a planilha para `Report` e ponha `Product` em **Linhas** e
`Revenue` em **Valores**. Depois:

1. Clique numa célula da tabela dinâmica.
2. Escolha **Análise da Tabela Dinâmica › Inserir Segmentação de Dados** (*PivotTable Analyze ›
   Insert Slicer* no Excel em inglês).
3. Marque `Channel` e clique em **OK**.

Aparece sobre a planilha uma caixa com três botões, `Online`, `Shop` e `Wholesale`. Ela flutua como
uma imagem: arraste-a para o lado da tabela dinâmica, onde não cubra nada. Agora clique em
`Wholesale`.

| `Product` | `Soma de Revenue` |
|---|---|
| `CER1K` | 17.168 |
| `DEC250` | 1.330 |
| `MOG250` | 2.397 |
| `SUL1K` | 17.836 |
| Total Geral | 38.731 |

Duas coisas mudaram além dos números. `CER250` e `SUL250` saíram da tabela, porque nenhum cliente de
atacado jamais os comprou. E `SUL1K` passou à frente de `CER1K`: somando todos os canais o saco do
Cerrado lidera, 21.356 a 21.082, e no atacado fica em segundo. As fórmulas da aula 5 dizem o mesmo:

```localised
=SOMASES(Sales[Revenue]; Sales[Product]; "SUL1K"; Sales[Channel]; "Wholesale")
=SOMASES(Sales[Revenue]; Sales[Product]; "CER1K"; Sales[Channel]; "Wholesale")
```

Elas, com `SOMASES` (`SUMIFS` no Excel em inglês), respondem 17.836 e 17.168.

`Channel` não está em nenhuma das quatro áreas da tabela dinâmica, e filtra mesmo assim. **Uma
segmentação filtra por qualquer campo da origem**, esteja esse campo no layout ou não.

## Escolhendo mais de um

Segure Ctrl e clique num segundo botão para somá-lo à seleção, ou clique no botão **Seleção
Múltipla** (*Multi-Select*) no cabeçalho da segmentação, e a partir daí cada clique liga ou desliga
um botão. Com `Online` e `Shop` acesos, o total geral é **12.763**: a receita `Direct` da seção
anterior, alcançada sem acrescentar linha nenhuma.

Para mostrar tudo de novo, clique em **Limpar Filtro** (*Clear Filter*), o funil com um X no
cabeçalho da segmentação, ou selecione a segmentação e tecle Alt+C.

## Botões sem dados

Insira uma segunda segmentação, de `Product`, e mantenha `Wholesale` aceso na primeira. Na
segmentação de `Product`, `CER250` e `SUL250` aparecem esmaecidos e vão para o fim. Continuam lá e
continuam clicáveis, mas nada na seleção atual os contém. As duas segmentações conversam: cada
segmentação de uma tabela dinâmica mostra quais dos seus botões ainda têm o que mostrar depois do
que as outras escolheram.

Esse comportamento é uma configuração. Clique com o botão direito numa segmentação e escolha
**Configurações da Segmentação de Dados** (*Slicer Settings*) para mudá-lo, para renomear o título
sobre os botões ou para ordená-los. Na guia **Segmentação de Dados**, **Colunas** põe os botões lado a
lado, o que serve a um campo de poucos valores curtos como `Channel`.

Apague a segmentação de `Product` antes de seguir: clique nela e tecle Delete. Mantenha a de
`Channel`, com todos os botões acesos.
