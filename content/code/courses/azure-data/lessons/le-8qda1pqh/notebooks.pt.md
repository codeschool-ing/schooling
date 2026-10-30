---
title: "Notebooks: o mesmo Spark, escrito como código"
version: 1
---

**Um notebook é um documento de células, código e a saída dele, ligado a uma sessão Spark.** Cada
célula roda no cluster por trás da sessão, em Python, SQL, Scala ou R, e a saída fica embaixo dela.
Escrito para o job da noite, um notebook é o programa da próxima seção rodado pelo Spark em vez do
DuckDB: ler os arquivos crus, aplicar as regras, gravar a tabela curada. Esta seção é ensinada a
partir da documentação da Microsoft e do Databricks e não foi executada.

## Três lugares onde um notebook roda no Azure

| | o que o roda | pelo que é cobrado |
|---|---|---|
| **Synapse** | um pool Apache Spark do workspace, com tamanho de nó, autoescala e pausa automática depois de minutos ociosos | vCore-horas do pool enquanto ele roda |
| **Fabric** | uma sessão Spark iniciada a partir do pool do workspace, com starter pools quentes por padrão | unidades de capacidade da capacidade da lição 17 |
| **Azure Databricks** | um cluster ou computação serverless num workspace do Databricks | DBUs mais, nos clusters clássicos, as máquinas virtuais; lição 21 |

**O código é o mesmo Spark nos três**, com pequenas diferenças em como cada um lê o armazenamento e
que bibliotecas tem. Um notebook escrito contra tabelas Delta e caminhos `abfss://` muda de um para o
outro com mudanças na primeira célula, e isso explica em parte por que times que esperam trocar de
plataforma escrevem código em vez de desenhar caixas.

## O que o código dá, e o que pede

**O que ele dá é tudo o que um programa tem.** Um notebook vive no Git como arquivo, e uma mudança
nele é um diff que um colega revisa linha a linha. As regras dele podem ser funções, testadas em
quatro linhas como faz a seção de testes. Ele pode usar qualquer biblioteca que o cluster consiga
instalar, chamar uma API ou tratar um formato de arquivo que nenhuma caixa de data flow conhece. E o
mesmo notebook roda no editor enquanto é escrito e no pipeline da lição 19 à noite, por uma atividade
de notebook, sem ser reescrito.

**O que ele pede é uma pessoa que escreva e leia código, e a disciplina de escrevê-lo bem.** Um
notebook fica ilegível tão fácil quanto qualquer programa: uma célula longa que lê, limpa e grava,
com valores colados durante a exploração e nunca removidos. Notebooks também carregam as saídas, que
podem incluir linhas de dados; um notebook enviado ao Git com os clientes de ontem nas células pôs
dados pessoais num lugar onde eles nunca deveriam estar, e limpar as saídas antes do commit é o
hábito que evita isso.

## Rodado por quem

**Às três da manhã ninguém abre um notebook.** Ele roda como job: a atividade de notebook de um
pipeline no Data Factory ou no Fabric, ou um job do Databricks, lição 21. O job passa parâmetros, a
data da noite entre eles, para a primeira célula do notebook, que é o mesmo contrato do parâmetro
`day` do pipeline na lição 19. Um notebook que só funciona quando alguém roda as células em ordem, à
mão, ainda não é um job, por melhor que tenha rodado ontem.
