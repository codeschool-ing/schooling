---
title: O que é o Power BI, e o que esta aula consegue mostrar dele
version: 1
---

O **Power BI** é o produto de business intelligence da Microsoft, e em muitas empresas ele é
simplesmente o que BI quer dizer: anúncios de vaga para analista o citam mais do que qualquer outra
ferramenta. Ele tem duas metades fáceis de confundir:

| | o que é | onde roda |
|---|---|---|
| **Power BI Desktop** | o programa onde um modelo é construído: dados importados, relacionamentos desenhados, medidas escritas, relatórios montados | só Windows, download gratuito |
| **o serviço do Power BI** | o site onde relatórios prontos são publicados, compartilhados, atualizados num horário e lidos | um navegador, e uma licença por pessoa que publica ou compartilha |

Um arquivo feito no Desktop tem a extensão `.pbix`. Dentro dele há um **modelo semântico** — as
tabelas, os relacionamentos entre elas e as medidas — e um ou mais **relatórios** desenhados a partir
dele. A Microsoft chamava o modelo de *dataset* até 2023, e boa parte do que você vai ler na internet
ainda chama.

## O que esta aula consegue e não consegue mostrar

O Power BI Desktop só roda no Windows, e este curso foi gravado no Ubuntu. **Nenhuma fórmula desta
aula rodou no Power BI.** Cada uma foi escrita a partir da documentação da Microsoft, e cada uma
aparece ao lado do SQL que calcula o número que ela está definida para calcular — e esse SQL rodou,
na camada da aula 3, então todo número citado aqui é real. Onde uma fórmula e o SQL dela poderiam
discordar, a aula diz por quê.

Esse arranjo é menos concessão do que parece. A linguagem de fórmulas do Power BI, o **DAX**, é fácil
de digitar e difícil de raciocinar, e o que a torna difícil — o *contexto de filtro* da sétima seção
— é exatamente um `WHERE` e um `GROUP BY` que você escreve desde a aula 1. Ver os dois lado a lado é
como a maioria das pessoas que aprendem DAX depois de SQL acaba entendendo.

Se você tem um computador Windows, a próxima seção instala o Power BI Desktop e todo passo da aula
pode ser seguido nele. Se não tem, leia as fórmulas como especificações e rode o SQL.
