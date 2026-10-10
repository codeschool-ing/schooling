---
title: Etapas Aplicadas, e o código por trás delas
version: 1
---

**Uma consulta é uma lista de etapas lida de cima para baixo, e cada etapa trabalha sobre o resultado
da anterior, pelo nome.** Esse fato só explica por que a ordem das etapas muda a resposta, por que
apagar uma etapa do meio quebra as de baixo e como ler o erro quando uma origem muda debaixo de você.

## A consulta inteira de uma vez

**Página Inicial › Editor Avançado** abre a consulta como um bloco só de M, as mesmas linhas que a
barra de fórmulas mostra uma por vez. Abra-o em `WebOrders` e você reconhece a forma das seções 02 e
05: `let`, uma lista de etapas com nome separadas por vírgulas, `in` e o nome da última. Cada linha lê
a etapa de cima, como `Table.SelectRows(#"Changed Type with Locale", …)` lê a etapa de localidade.

Dá para editar ali, e às vezes é o caminho mais rápido, mas os cliques continuam sendo o hábito mais
seguro. Uma etapa feita por um comando é uma que o Excel sabe reabrir: o ícone de engrenagem ao lado
de uma etapa em **Etapas Aplicadas** traz de volta a caixa que a criou, com as escolhas dela, para você
mudá-las sem tocar em código.

## A ordem faz parte da resposta

Três exemplos desta aula, cada um com o número que ele muda:

| esta etapa primeiro | depois esta | dá | ao contrário dá |
|---|---|---|---|
| pôr os códigos em maiúsculas | mesclar com `Products` | **22 de 22** linhas casadas | 20 de 22, dois pedidos sem custo |
| manter os pedidos pagos | agrupar por produto | `SUL250` com **5** sacos | 6, contando um saco cancelado |
| definir `Price` como número | multiplicá-lo por `Bags` | a receita | um erro em toda linha: texto não se multiplica |

**Mova uma etapa arrastando-a** para cima ou para baixo na lista, ou clique nela com o botão direito e
escolha **Mover Antes** ou **Mover Depois** (Move Before, Move After). Para acrescentar uma etapa no
meio, selecione a etapa que ela deve seguir e use o comando: o Excel pergunta antes de inseri-la ali,
já que toda etapa abaixo vai passar a ler outra coisa.

## Apagando, e o que quebra

Botão direito numa etapa e **Excluir** a remove. As etapas seguintes passam a ler o que vinha antes
dela, o que é inofensivo quando não dependiam do que ela fazia, e fatal quando dependiam. Apague a
etapa de renomeação da seção 02, e o `[Bags] * [Price]` da coluna personalizada nomeia duas colunas que
não existem mais com esses nomes: toda linha de `Revenue` vira erro. **Excluir Até o Fim** remove uma
etapa e tudo depois dela, que é o jeito seguro de recomeçar de um ponto.

## O erro que diz que uma coluna não foi encontrada

A seção 04 da aula 13 avisou que uma plataforma pode renomear uma coluna. Suponha que a exportação do
mês seguinte chame `Qty` de `Quantity`. Atualize, e a etapa de localidade, que nomeia `Qty`, para com
uma mensagem desta forma (num Excel em português, o texto vem traduzido):

```
Expression.Error: The column 'Qty' of the table wasn't found.
```

Leia ao pé da letra: uma etapa pediu uma coluna pelo nome, e a tabela que ela recebeu não tem coluna
com esse nome. Clique nas **Etapas Aplicadas** a partir do topo, e a última etapa que funciona é a
anterior à falha; a prévia dela mostra a coluna com o nome novo. O conserto é uma etapa que devolve o
nome antigo, renomeando `Quantity` para `Qty`, inserida antes da etapa que falhou, para que toda etapa
abaixo continue funcionando como está escrita. Quando a mudança é definitiva, editar os nomes na
própria etapa que falhou é o conserto mais limpo.

A etapa automática **Tipo Alterado** (Changed Type), que o Excel acrescenta quando detecta os tipos, é
o lugar mais comum desse erro, porque nomeia todas as colunas do arquivo. É mais um motivo, além da
localidade da aula 13, para você mesmo definir os tipos, e só nas colunas que usa.

## Dando nome às etapas

Nomes de etapa como `Filtered Rows` e `Added Custom` dizem que comando fez a etapa, não por quê.
Botão direito › **Renomear** e chame-a de `Pedidos pagos` ou `Receita`, e toda referência a ela no
código é renomeada junto. Uma consulta lida seis meses depois por outra pessoa, ou por você, se explica
sozinha.

## Que consulta alimenta qual

Esta aula montou uma pequena rede de consultas: `WebOrders` alimenta `WebMargin`, `WebAsSales` e
`WebByProduct`; `WebAsSales` e `Sales` alimentam `AllSales`; `Budget` e `Sales` alimentam
`BudgetVsActual`. **Exibir › Dependências de Consulta** (View › Query Dependencies), no editor, desenha
essa rede, dos arquivos e tabelas à esquerda até os resultados carregados à direita. Antes de apagar ou
renomear uma consulta, olhe ali: tudo o que tiver uma seta saindo dela vai quebrar.
