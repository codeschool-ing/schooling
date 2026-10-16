---
title: Tabelas nesta pasta de trabalho, e outras pastas de trabalho
version: 1
---

**Dentro da sua própria pasta de trabalho, o Power Query lê uma tabela do Excel pelo nome; de outra
pasta de trabalho, lê o arquivo como ele foi salvo pela última vez.** O primeiro caso é como uma
tabela que você já mantém entra nas consultas da aula 14. O segundo é como a pasta de trabalho de um
colega vira uma fonte que você atualiza, em vez de um intervalo que você copia.

## Uma tabela nesta pasta de trabalho

A aula 7 transformou `Sales!A1:H109` numa tabela chamada `Sales`. Clique em qualquer célula dentro
dela e escolha **Dados › Da Tabela/Intervalo**. O editor abre numa consulta também chamada `Sales`,
com as **108 linhas** e as oito colunas da tabela, `Revenue` incluída. A primeira etapa diz:

```powerquery
Source = Excel.CurrentWorkbook(){[Name="Sales"]}[Content]
```

Se a coluna `Date` mostrar a hora `00:00:00` ao lado de cada dia, ela foi tipada como **Data/Hora**;
defina-a como **Data** com o ícone de tipo à esquerda do cabeçalho, já que uma venda tem dia e não
hora.

Essa linha é o motivo para usar uma tabela e não um intervalo. Ela nomeia a tabela, não as células,
então quando uma venda é acrescentada abaixo da última linha e a tabela cresce até a linha 110, a
consulta lê 109 linhas na próxima atualização sem ninguém mexer nela. Apontado para um intervalo
comum, o mesmo comando primeiro pede para transformá-lo em tabela, pela mesma caixa **Criar Tabela**
da aula 7, exatamente por esse motivo.

Esta consulta **não** deve ser carregada numa planilha: isso faria uma segunda cópia de `Sales`, que
então teria de ser mantida em dia com a primeira. Feche o editor com **Página Inicial › Fechar e
Carregar Para…**, escolha **Apenas Criar Conexão** (Only Create Connection) e clique em **OK**. A
consulta aparece em **Consultas e Conexões** marcada como *Somente conexão*, pronta para a aula 14
usar.

Faça o mesmo com a tabela `Products`: clique dentro dela, **Dados › Da Tabela/Intervalo**, depois
**Fechar e Carregar Para… › Apenas Criar Conexão**. Agora você tem duas consultas só de conexão,
`Sales` e `Products`, e a pasta de trabalho continua com a mesma cara. `Customers` funciona do mesmo
jeito; a aula 14 não precisa dela.

## Outra pasta de trabalho

A aula 1 pediu que você guardasse uma cópia intocada dos dados, `cafe-serra-original.xlsx`. Ela é uma
boa segunda fonte, porque você sabe exatamente o que tem dentro.

Vá em **Dados › Obter Dados › De Arquivo › Da Pasta de Trabalho** (em algumas versões, **Da Pasta de
Trabalho do Excel**) e escolha esse arquivo. Abre-se um **Navegador** listando o que o arquivo
contém: três planilhas, `Sales`, `Products` e `Customers`, cada uma com um ícone de planilha. Se o
arquivo tivesse tabelas, elas apareceriam também, com um ícone de tabela. Marque `Sales` e clique em
**Transformar Dados**.

A consulta lê **108 linhas** e sete colunas: a cópia original foi salva na aula 1, antes de a aula 2
acrescentar `Revenue`. As etapas são diferentes das da tabela:

```powerquery
Source = Excel.Workbook(File.Contents("C:\Users\you\Documents\cafe-serra-original.xlsx"), null, true),
Sales_Sheet = Source{[Item="Sales",Kind="Sheet"]}[Data],
#"Promoted Headers" = Table.PromoteHeaders(Sales_Sheet, [PromoteAllScalars=true])
```

Uma planilha não é uma tabela, então a primeira linha chega como dado e uma etapa **Cabeçalhos
Promovidos** a transforma em nomes de colunas. E uma planilha traz toda célula que alguém já usou
nela, que é a diferença que importa: uma anotação digitada em `J1` daquela planilha chega como uma
coluna a mais, quase vazia, e a consulta não tem como saber que aquilo não é dado. Uma tabela traz o
próprio retângulo e mais nada; então, quando a outra pasta de trabalho é sua para organizar,
transforme os dados em tabela antes de apontar uma consulta para eles.

Duas coisas sobre o arquivo em si valem saber:

- **A consulta lê o arquivo salvo.** Mudanças que alguém digitou e não salvou não estão lá. A
  surpresa comum é uma atualização que "não pegou" uma correção feita um minuto antes numa janela
  ainda aberta.
- **O caminho fica escrito na consulta.** Mova ou renomeie o arquivo e a próxima atualização falha
  com uma mensagem que nomeia o caminho que não encontrou. **Dados › Obter Dados › Configurações da
  Fonte de Dados** lista todo arquivo que as consultas da pasta de trabalho leem, e **Alterar
  Fonte…** ali aponta um deles para o lugar novo sem abrir a consulta.

Esta consulta serviu para ver o Navegador, e nada depois a usa. Feche o editor e apague a consulta em
**Consultas e Conexões**. Se você a carregou, apague a planilha dela também.
