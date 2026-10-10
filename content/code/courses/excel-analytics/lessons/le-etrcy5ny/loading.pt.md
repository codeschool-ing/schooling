---
title: Carregando as três tabelas no modelo
version: 1
---

**O modelo é preenchido a partir de tabelas, nunca digitado.** Cada tabela que você carrega mantém o
nome, as colunas e as linhas, e continua ligada à origem. Então o trabalho antes de carregar é o
trabalho da aula 7: `Sales`, `Products` e `Customers` são tabelas do Excel com esses nomes, e `Sales`
traz a coluna `Revenue` da aula 2.

Confira os nomes primeiro. Clique dentro de cada tabela e olhe **Design da Tabela › Nome da Tabela**
(*Table Design › Table Name*). Uma tabela que ainda se chama `Tabela1` entra no modelo como
`Tabela1`, e toda fórmula DAX da aula 16 teria então de dizer `Tabela1[Revenue]`. Dá para renomear
depois, e um nome acertado antes de carregar é uma coisa a menos para quebrar.

## Três portas de entrada no modelo

1. **A partir de uma tabela na planilha.** Clique em qualquer célula de `Sales` e depois em **Power
   Pivot › Adicionar ao Modelo de Dados** (*Add to Data Model*). A janela do Power Pivot abre com
   `Sales` como uma guia na borda de baixo. Volte ao Excel e faça o mesmo com `Products` e
   `Customers`. É a porta que esta aula usa.
2. **A partir de uma tabela dinâmica.** **Inserir › Tabela Dinâmica**, com a caixa **Adicionar
   estes dados ao Modelo de Dados** marcada, põe a tabela no modelo no caminho. Ela carrega uma tabela
   de cada vez, e é assim que muita gente acaba com um modelo sem ter querido montar um.
3. **A partir do Power Query.** Uma consulta da aula 13 carrega no modelo quando você escolhe
   **Fechar e Carregar Para…**, depois **Apenas Criar Conexão** e **Adicionar estes dados ao Modelo de
   Dados**. É a porta para dados que nem moram na pasta de trabalho: um arquivo CSV por mês, um banco
   de dados, uma pasta.

Uma tabela carregada pela primeira porta é uma **tabela vinculada**: a cópia do modelo acompanha a
tabela da planilha. Inclua uma venda na planilha e, depois de **Dados › Atualizar Tudo**, o modelo e
toda tabela dinâmica criada sobre ele passam a tê-la. O caminho nunca é o inverso: a janela do Power
Pivot não deixa editar valor nenhum, e esse é o sentido certo. A planilha é onde os registros são
digitados, e o modelo é onde são lidos.

## Conferindo se chegou inteiro

A aula 1 seção 05 contou as linhas depois de colar, e um modelo merece o mesmo hábito. Abra **Power
Pivot › Gerenciar** (*Manage*). Cada tabela é uma guia na parte de baixo da janela, e a janela mostra
as linhas da tabela como uma grade, com a contagem de registros embaixo:

| guia | linhas |
|---|---|
| `Sales` | 108 |
| `Products` | 6 |
| `Customers` | 11 |

Uma linha faltando costuma ser uma tabela que não chega até o fim dos dados, porque uma linha foi
colada abaixo dela, e não dentro. A aula 7 seção 04 trata disso: uma tabela cresce quando você digita
na linha logo abaixo dela, e não quando um bloco chega duas linhas mais para baixo.

## O tipo de cada coluna

O Power Pivot dá a cada coluna um **tipo de dados**, e lê esse tipo da planilha. Clique no cabeçalho
de uma coluna na janela e olhe **Página Inicial › Tipo de Dados** (*Home › Data Type*). `Date` deve
ser **Data**, `Bags`, `Price` e `Revenue` **Número Inteiro**, e os códigos **Texto**.

O tipo importa mais aqui do que numa planilha. A seção 06 liga `Sales[Date]` a um calendário, e uma
ligação só casa data com data: uma coluna de datas que chegou como texto, a falha da aula 1 seção
08, não casaria com nada. Se um tipo estiver errado, corrija a coluna na planilha, como faz a aula 6,
e não no modelo, para que a próxima atualização não traga o erro de volta.
