---
title: Filtros e a tabela dinâmica, que é a que vale aprender
version: 1
---

Duas ferramentas transformam uma tabela numa resposta, e uma delas faz mais que todo o resto
desta aula somado.

## Filtros, e os dois jeitos de perder dados com um

Um filtro esconde as linhas que não casam. Ele não muda nada e é reversível, o que faz dele a
exploração mais segura que existe — e ele tem exatamente dois perigos.

**O primeiro: uma seleção copiada copia só o que está visível**, o que normalmente é o que você
queria e ocasionalmente é uma perda silenciosa. Uma colagem de um intervalo filtrado para um não
filtrado produz uma tabela com linhas faltando e sinal algum de que alguma foi.

**O segundo: a `SOMA` ignora o filtro.** Um total embaixo de uma coluna filtrada mostra o total de
tudo, incluindo as linhas escondidas, e parece estar descrevendo o que está na tela.

O `SUBTOTAL(109; intervalo)` é o conserto: ele soma **só as linhas visíveis** e se move conforme o
filtro se move. O `109` significa *somar, ignorando linhas ocultas*; `101` é a média, `103` a
contagem. É a função que torna um filtro honesto.

## Ordenar, e a regra da aula nove

**Selecione o intervalo inteiro ou use uma tabela.** Ordenar uma coluna a separa das linhas dela,
sem volta, e é a única operação desta aula que destrói dados em silêncio.

Mais dois fatos:

- **Uma ordenação personalizada aceita vários níveis** — região, depois mês, depois valor — que é
  o que as três ordenações separadas que as pessoas fazem à mão aproximam mal.
- **Ordenar por cor funciona**, o que ocasionalmente é exatamente o que se quer e é um sinal de
  que a cor deveria ter sido uma coluna.

## A tabela dinâmica

Selecione a tabela. Insira uma tabela dinâmica. Arraste um campo para **Linhas**, um campo para
**Colunas**, e um número para **Valores**.

Essa é a interface inteira, e o que ela faz é produzir o resumo que de outro modo seriam quarenta
fórmulas `SOMASE` — agrupado, totalizado, e refeito num segundo quando a pergunta muda.

| você arrasta | e você tem |
|---|---|
| `região` para Linhas, `valor` para Valores | o total por região |
| `mês` para Colunas também | uma grade de região contra mês |
| `produto` para Filtros | a mesma grade, um produto por vez |
| `valor` para Valores duas vezes | o total e a contagem, lado a lado |

**Três coisas sobre ela valem saber antes de depender de uma:**

- **Ela não se atualiza sozinha.** Acrescente linhas aos dados e a dinâmica mostra a resposta de
  ontem até você atualizá-la. Construir a dinâmica sobre uma *tabela* em vez de um intervalo é o
  que faz o intervalo crescer; atualizar continua sendo um clique.
- **Valores assume Contagem quando a coluna tem qualquer texto.** Uma `Contagem de Valor` onde
  você esperava uma `Soma de Valor` é o problema do texto numa coluna de números da aula nove, se
  anunciando.
- **Dois cliques num número da dinâmica produzem uma aba nova com as linhas por trás dele.** Essa é
  a ferramenta de conferência mais útil do produto, e quase ninguém sabe que ela existe.

## Qual das duas buscar

**Filtro para olhar linhas. Dinâmica para olhar grupos.** Uma pergunta com a palavra *cada* dentro
— o total de cada região, a média por mês, quantos de cada tipo — é uma tabela dinâmica, e fazer
isso com fórmulas é uma tarde gasta reproduzindo um recurso.
