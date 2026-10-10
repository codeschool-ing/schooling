---
title: Acrescentar, uma tabela embaixo da outra
version: 1
---

**Acrescentar empilha as linhas de duas ou mais consultas numa só, e alinha as colunas pelos nomes,
não pela posição.** Colunas com o mesmo nome viram uma coluna; um nome que só existe de um lado vira
uma coluna própria, vazia nas linhas do outro lado. Por isso o trabalho de um acréscimo quase sempre
é feito antes dele: fazer os nomes concordarem.

## A pergunta

`Sales` termina em junho de 2026. `WebOrders` tem julho a setembro da loja virtual. Uma tabela com as
duas deixaria uma tabela dinâmica ver a história inteira do canal web, e é isso que um acréscimo faz.

## A primeira tentativa, e o que ela mostra

Escolha **Página Inicial › Acrescentar Consultas › Acrescentar Consultas como Novas**, escolha `Sales`
como primeira tabela e `WebOrders` como segunda, e clique em **OK**. O resultado tem **130 linhas**,
108 e 22, o que está certo, e **nove** colunas, o que não está.

| coluna | nas 108 linhas vindas de `Sales` | nas 22 linhas vindas de `WebOrders` |
|---|---|---|
| `Date`, `Product`, `Bags`, `Price`, `Revenue` | preenchidas | preenchidas: os nomes concordam, então são uma coluna só |
| `Sale`, `Customer`, `Channel` | preenchidas | **vazias**: `WebOrders` não tem colunas com esses nomes |
| `Order` | **vazia** | preenchida: `Sales` não tem `Order` |

O código do pedido está em `Order` de um lado e em `Sale` do outro, então fica em duas colunas, cada
uma meio vazia. Nada falhou, e uma tabela dinâmica por `Channel` mostraria em silêncio os 22 pedidos
da web sob um rótulo vazio. A renomeação da seção 02 é o motivo de cinco das colunas já se alinharem;
as outras três precisam do mesmo tratamento.

Apague essa consulta e faça de novo, direito.

## Fazendo os nomes concordarem

As etapas ficam numa consulta própria, para que `WebOrders` continue como está para `WebMargin` e
qualquer outra coisa que a leia.

1. Na lista **Consultas**, à esquerda do editor, clique em `WebOrders` com o botão direito e escolha
   **Referência**. Aparece uma consulta nova cuja única etapa é a própria `WebOrders`, então ela
   acompanha toda mudança feita lá. Renomeie-a para `WebAsSales`.
2. Renomeie `Order` para `Sale`.
3. **Adicionar Coluna › Coluna Personalizada**, nome `Customer`, fórmula `"C00"`. Todo pedido da web
   é de um cliente sem cadastro, que é o que `C00` significa em `Customers`, da aula 1.
4. **Adicionar Coluna › Coluna Personalizada**, nome `Channel`, fórmula `"Online"`.

Agora **Acrescentar Consultas como Novas** com `Sales` e `WebAsSales`. O resultado tem **130 linhas**
e as oito colunas de `Sales`, todas preenchidas em todas as linhas. A ordem das colunas em
`WebAsSales` não importou; só os nomes importaram. Defina `Price` e `Revenue` como **Número Decimal**,
já que a promoção de setembro tem centavos, e renomeie a consulta para `AllSales`.

`AllSales` soma **649 sacos** e uma receita de **R$ 54.619,50**: os R$ 51.494 de `Sales` e os
R$ 3.125,50 dos pedidos pagos da web. As linhas `Online` são **69**, as 47 de `Sales` e as 22 novas.

Carregue `WebAsSales` e `AllSales` com **Fechar e Carregar Para… › Apenas Criar Conexão**. As aulas
15 e 16 montam o modelo sobre a tabela `Sales` como ela é, terminando em junho de 2026, para que os
números delas batam com os das aulas 1 a 12; `AllSales` é como o próximo trimestre se juntaria a ela.

## Acrescentar ou De Pasta

As duas coisas empilham linhas, e servem a trabalhos diferentes:

- **De Pasta**, seção 04 da aula 13, empilha **arquivos de um formato só** de um lugar só, e um
  arquivo novo entra sendo salvo ali.
- **Acrescentar** empilha **consultas**, que podem vir de fontes diferentes: uma tabela e uma pasta
  aqui, ou uma pasta de trabalho e um banco de dados. Cada lado pode ser moldado pelas próprias etapas
  antes, que é para isso que `WebAsSales` existe.

Nas duas, o empilhamento é pelo nome, e uma coluna renomeada de um lado vira uma coluna própria.
