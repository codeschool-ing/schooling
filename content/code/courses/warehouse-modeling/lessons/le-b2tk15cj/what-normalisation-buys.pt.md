---
title: O que a normalização compra, e para quem
version: 1
---

A lição 2 de `sql-databases` desmontou uma tabela até cada fato morar num só lugar, e chamou o
resultado de terceira forma normal. O argumento dela era sobre **anomalias**, três jeitos de uma
tabela com valores repetidos dar errado quando alguém grava nela:

- **Anomalia de atualização.** O nome de um departamento está escrito em mil linhas. Renomeá-lo
  significa atualizar mil linhas, e se a atualização parar no meio, a tabela fica com dois nomes para
  um departamento.
- **Anomalia de inserção.** Um fato não pode ser registrado sem outro sem relação. Se os nomes de
  departamento só existem nas linhas de livro, um departamento novo não pode ser criado antes de ter um
  livro.
- **Anomalia de exclusão.** Apagar o último livro de um departamento apaga o único registro de que o
  departamento existiu.

**Todas elas são sobre gravar.** A normalização é um projeto para um banco que muita gente altera, uma
linha de cada vez, em momentos imprevisíveis, onde qualquer comando pode ser o que falha. É exatamente o
banco operacional da lição 1, e nele a normalização está certa.

O warehouse é gravado de outro jeito:

- **Um só escritor.** A carga é a única coisa que o altera. Ninguém atualiza o nome de um departamento à
  mão, e nenhum caixa grava nele.
- **Em lotes, a partir de uma única origem.** A `dim_book` é reconstruída a partir da cópia única de cada
  nome no banco operacional, então toda linha recebe o mesmo nome no mesmo comando.
- **Dentro de uma transação.** Uma carga que falha é desfeita, e o warehouse fica como estava, em vez de
  meio antigo e meio novo.

Então as anomalias que a normalização evita não acontecem do jeito que acontecem num banco operacional.
O que sobra da troca é o lado da leitura, e no lado da leitura a repetição é barata e as junções não são
de graça. As próximas seções põem números nos dois.
