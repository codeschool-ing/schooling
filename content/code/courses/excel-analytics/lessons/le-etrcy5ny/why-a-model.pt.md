---
title: Por que um modelo, e não mais uma coluna de busca
version: 1
---

**Uma busca copia um fato para cada linha que precisa dele; uma relação diz uma vez onde o fato
mora.** Até aqui, uma pergunta sobre algo que `Sales` não guarda, como a origem do café, foi
respondida indo buscar o dado. A aula 4 pôs um `PROCX` (`XLOOKUP` no Excel em inglês) ao lado de
cada venda para trazer a origem de `Products`, e uma tabela dinâmica da aula 10 pôde então agrupar
por ela.

Isso funciona, e tem um custo que cresce a cada pergunta. Receita por origem pede uma coluna de
busca. Receita por tipo de cliente pede uma segunda, vinda de `Customers`. Receita por trimestre pede
uma terceira, calculada a partir da data. Cada uma são mais 108 fórmulas, cada uma copia um valor
que já existe em outra tabela, e cada uma alarga `Sales` com colunas que não são fatos sobre uma
venda. A próxima pessoa a abrir a pasta não consegue distinguir as colunas registradas das buscadas.

## O que é o modelo de dados

O **modelo de dados** é um pequeno banco de dados que mora dentro da pasta de trabalho. Você põe
tabelas nele e diz qual coluna de uma tabela aponta para qual coluna de outra. Daí em diante, uma
tabela dinâmica criada sobre o modelo pode tirar as linhas de `Products`, as colunas de um
calendário e os números de `Sales`, tudo ao mesmo tempo. Nada é copiado: o modelo segue os
ponteiros cada vez que soma uma célula.

O **Power Pivot** é a parte do Excel que cuida do modelo. Ele tem uma janela própria, onde as
tabelas aparecem como grades e as relações como linhas, e uma linguagem de fórmulas própria, o
**DAX**, que é a aula 16. As tabelas do modelo não são células numa planilha. Você não digita nelas;
você as carrega de algum lugar, e nesta aula esse lugar são as três tabelas do Excel da aula 7.

## O que muda, e o que custa

Com um modelo, as perguntas acima não pedem nenhuma coluna nova em `Sales`:

| pergunta | colunas de busca, aulas 4 e 10 | modelo de dados |
|---|---|---|
| receita por origem | um `PROCX` em cada venda | `Origin` de `Products`, por uma relação |
| receita por tipo de cliente | outro `PROCX` em cada venda | `Type` de `Customers`, por uma segunda |
| receita por trimestre | uma fórmula em cada venda, ou agrupar na tabela dinâmica | `Quarter` de um calendário, por uma terceira |

Em troca, três coisas ficam para trás, e é melhor conhecê-las agora:

- **O Power Pivot existe só no Excel para Windows.** A aula 1 seção 03 disse isso, e a aula 1 seção
  04 diz como ativá-lo. No Mac ou no navegador, esta aula pode ser lida, mas não feita.
- **Uma tabela dinâmica criada sobre o modelo não tem campos calculados.** O campo calculado da aula
  11 vira uma **medida** escrita em DAX, e o agrupamento de datas da aula 10 dá lugar às colunas de
  um calendário que você monta nesta aula.
- **As fórmulas do modelo são DAX, não fórmulas de planilha.** Elas se parecem e não funcionam do
  mesmo jeito, e é por isso que a aula 16 gasta a primeira seção com a diferença.

**Nada nesta aula nem na próxima foi executado no Excel.** O Power Pivot não tem motor fora dele, e
este curso foi escrito sem um, como explica a aula 1 seção 02. Cada número de modelo que esta aula
cita foi calculado aplicando as mesmas relações às mesmas linhas que você colou, e onde uma planilha
consegue conferir um número, uma planilha conferiu.
