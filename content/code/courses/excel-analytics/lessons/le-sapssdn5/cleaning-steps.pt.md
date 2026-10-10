---
title: Limpando, uma etapa de cada vez
version: 1
---

**Cada comando de limpeza acrescenta uma etapa, e as etapas rodam em ordem a cada atualização,
então uma limpeza feita uma vez está feita para todos os meses seguintes.** Esta seção limpa
`WebOrders`, as três exportações da loja virtual que a aula 13 combinou, com cinco etapas. Nenhuma
delas toca nos arquivos.

A aula 13 deixou a consulta com **24 linhas** e sete colunas, e com três coisas erradas nelas: dois
pedidos cancelados, dois códigos de produto em minúsculas (`dec250` e `mog250`) e colunas com os
nomes da plataforma, não os seus. Como na aula 13, **nada aqui foi executado no Excel**: cada número
abaixo é o que a mesma etapa dá quando aplicada às mesmas linhas por um script.

## Abrindo a consulta de novo

Em **Dados › Consultas e Conexões**, dê um clique duplo em `WebOrders`. O editor abre onde a aula 13
o deixou, com a etapa de localidade por último em **Etapas Aplicadas**. Toda etapa que você
acrescentar agora vem depois dela.

## As cinco etapas

**1. Manter os pedidos pagos.** Clique na seta do cabeçalho `Status` e escolha **Filtros de Texto ›
É Igual a…** (Text Filters › Equals…), depois digite `paid`. A consulta cai para **22 linhas**.
Manter o que você quer, em vez de remover o que não quer, é uma escolha com consequência: se um dia a
plataforma criar um status chamado `refunded`, um filtro que mantém `paid` o deixa de fora, e um
filtro que só removesse `cancelled` o deixaria entrar.

**2. Pôr os códigos em maiúsculas.** Selecione a coluna `SKU` e escolha **Transformar › Formatar ›
MAIÚSCULAS**. `dec250` vira `DEC250`, e a coluna passa a ter seis códigos distintos em vez de oito.
No mesmo menu, **Aparar** (Trim) tira espaços nas duas pontas de um texto, que é o outro motivo
comum para dois códigos que parecem iguais não serem.

**3. Remover o que ninguém usa.** Selecione `Source.Name` e `Status` com Ctrl+clique e escolha
**Página Inicial › Remover Colunas**. `Status` já cumpriu o papel, pois toda linha que ficou está
paga, e os meses estão em `Date`.

**4. Renomear as colunas.** Dê um clique duplo num cabeçalho e digite: `SKU` vira `Product`, `Qty`
vira `Bags`, `Unit price` vira `Price`. São os nomes que a tabela `Sales` usa, e a seção 04 depende
disso. Renomear várias colunas uma depois da outra gera uma etapa só.

**5. Acrescentar a receita.** Escolha **Adicionar Coluna › Coluna Personalizada**, dê à coluna o nome
`Revenue` e escreva a fórmula `[Bags] * [Price]`. Um nome entre colchetes é uma coluna da mesma
linha, como `[@Bags]` numa tabela do Excel. Uma coluna personalizada chega sem tipo, então termine
com o ícone de tipo à esquerda do cabeçalho dela: **Número Decimal**.

`WebOrders` agora tem **22 linhas** e seis colunas, `Order`, `Date`, `Product`, `Bags`, `Price` e
`Revenue`, com **58 sacos** e uma receita de **R$ 3.125,50**. Feche com **Página Inicial › Fechar e
Carregar**, e a tabela da planilha é trocada pela limpa.

## Como as cinco etapas ficam em código

Cada comando escreveu uma linha de M. Estas são as linhas que as cinco etapas acrescentaram, depois
da etapa de localidade que a aula 13 fez. Num Excel em português os nomes das etapas saem traduzidos;
as funções são as mesmas:

```schooling-example
{"language": "powerquery", "file": "WebOrders", "parts": [{"code": "    #\"Filtered Rows\" = Table.SelectRows(#\"Changed Type with Locale\", each [Status] = \"paid\"),", "note": "`each` quer dizer \"para cada linha\": a linha fica quando o `Status` dela é igual a `paid`. A etapa lê a anterior pelo nome."}, {"code": "    #\"Uppercased Text\" = Table.TransformColumns(#\"Filtered Rows\", {{\"SKU\", Text.Upper, type text}}),", "note": "Aplica `Text.Upper` a todo valor de uma coluna e deixa as outras em paz."}, {"code": "    #\"Removed Columns\" = Table.RemoveColumns(#\"Uppercased Text\", {\"Source.Name\", \"Status\"}),", "note": "Nomeia as colunas que remove. Se uma delas um dia deixar de existir, é esta etapa que falha, e a seção 07 volta a isso."}, {"code": "    #\"Renamed Columns\" = Table.RenameColumns(#\"Removed Columns\", {{\"SKU\", \"Product\"}, {\"Qty\", \"Bags\"}, {\"Unit price\", \"Price\"}}),", "note": "Nome antigo, nome novo, aos pares. Três renomeações seguidas viraram uma etapa."}, {"code": "    #\"Added Custom\" = Table.AddColumn(#\"Renamed Columns\", \"Revenue\", each [Bags] * [Price]),\n    #\"Changed Type\" = Table.TransformColumnTypes(#\"Added Custom\", {{\"Revenue\", type number}})", "note": "A fórmula é calculada uma vez por linha. O tipo vem numa etapa própria, porque a coluna personalizada foi criada sem tipo."}]}
```

Dá para ler uma consulta assim sem nunca ter escrito uma. Cada linha começa com o nome da etapa como
ele aparece em **Etapas Aplicadas**, e cada uma nomeia a etapa anterior, que é como a lista vira uma
corrente. A seção 07 desta aula trata dessa corrente.

## Outras etapas de limpeza que valem saber

Os mesmos menus guardam o resto do kit do dia a dia, e cada item também é uma etapa:

| comando | onde | o que faz |
|---|---|---|
| **Substituir Valores** | Transformar | troca um valor por outro numa coluna, como `n/a` por nada |
| **Remover Duplicatas** | Página Inicial › Remover Linhas | mantém a primeira de linhas iguais nas colunas selecionadas |
| **Preenchimento › Para Baixo** | Transformar | copia um valor nas células vazias abaixo dele, o conserto dos rótulos de grupo de um relatório da seção 07 da aula 1 |
| **Dividir Coluna** | Transformar | a versão do Power Query da divisão da aula 6, por delimitador ou por número de caracteres |
| **Tipo de Dados** | o ícone à esquerda de um cabeçalho | define o tipo; uma coluna de datas com hora vira só dias quando o tipo dela é **Data** |

Nenhum deles muda a origem, e todos rodam de novo nas linhas do mês seguinte.
