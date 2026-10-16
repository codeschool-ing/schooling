---
title: Uma linha por registro, uma coluna por campo
version: 1
---

**Uma planilha que vai ser analisada tem uma forma só, e todo o resto deste curso parte dela.** Cada
linha é um registro do mesmo tipo. Cada coluna é um campo, com o nome na linha 1. Cada célula guarda
um valor. Nada mais mora no intervalo: nenhum título em cima, nenhum total no meio, nenhuma linha em
branco para descansar a vista.

A planilha `Sales` que você colou tem essa forma, e vale dizer exatamente o que a faz ter:

- **um tipo de registro**: toda linha de 2 a 109 é uma venda, e nada além disso;
- **uma linha de cabeçalho**: a linha 1 dá nome aos sete campos, e todos os nomes são diferentes;
- **um valor por célula**: `14` em `Bags`, não `14 sacos` e não `14 + 3`;
- **nenhum buraco**: nenhuma linha ou coluna vazia interrompe o bloco, então o Excel acha as bordas.

## Diga o que é uma linha antes de qualquer coisa

A frase mais útil sobre uma tabela é a que completa *cada linha é um(a)…*. Para `Sales`, é **uma
venda**, e uma venda aqui é um produto, numa quantidade, num dia. Essa frase se chama o **grão** da
tabela, e errar o grão é como um total dobra. Se a linha fosse um *pedido*, um pedido com dois
produtos precisaria de duas colunas `Product`, e toda pergunta sobre produtos teria de olhar nas
duas. Se fosse um *saco*, uma venda de atacado de 20 sacos seria 20 linhas idênticas.

As outras duas planilhas também têm grão: um produto por linha em `Products`, um cliente por linha
em `Customers`. Três tabelas, três tipos de registro, e cada fato mora em exatamente uma delas.

## Chaves: como uma tabela aponta para outra

`Sales` não diz como se chama `CER1K` nem quanto custa produzi-lo. Ela diz `CER1K`, e a planilha
`Products` tem uma linha cujo `Code` é `CER1K`. Uma coluna cujos valores identificam uma linha cada
é uma **chave**: `Sale` em `Sales`, `Code` em `Products`, `Customer` em `Customers`. Uma coluna que
guarda a chave de outra tabela, como `Product` e `Customer` em `Sales`, aponta para uma linha de lá.

É por esse arranjo que o nome do produto aparece escrito uma vez e não 28. Se a Café Serra mudar o
nome do saco de 1 kg do Cerrado, muda uma célula, e todas as vendas dele acompanham. A aula 4 segue
esses ponteiros com fórmulas de busca, e a aula 15 deixa o próprio Excel segui-los.

## Por que tudo depende dessa forma

Toda ferramenta do resto do curso lê um intervalo nessa forma, e só nessa forma:

- o `SOMASES` e a família dele, na aula 5, comparam uma coluna com uma condição, linha a linha;
- uma **tabela do Excel**, na aula 7, é essa forma com um nome;
- uma **tabela dinâmica**, na aula 10, transforma cada coluna num campo que dá para arrastar;
- o **Power Query**, nas aulas 13 e 14, gasta quase todo o esforço transformando outras formas nesta;
- o **modelo de dados**, na aula 15, é um conjunto de tabelas nesta forma ligadas pelas chaves.

Uma planilha arrumada para uma pessoa ler, que é o assunto da próxima seção, derruba as cinco.
