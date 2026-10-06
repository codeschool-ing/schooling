---
title: Categorias guardadas como números
version: 1
---

Sistemas adoram guardar categorias como números. Uma ferramenta de pesquisa grava o pagamento como 1, 2
ou 3. Um formulário grava o sexo como 1 ou 2, a satisfação de 1 a 5 e a unidade da federação de 11 a 53.
Os números economizam espaço e digitação, e armam uma armadilha.

**Uma coluna codificada parece numérica para toda ferramenta que a lê.** A planilha oferece uma soma.
Um painel desenha com prazer a região média. A aula 1 tirou a média dos códigos de pagamento da Horta — 1
para pix, 2 para cartão, 3 para dinheiro — e obteve 1,67, um número sem significado.

## Como a armadilha dispara

Ninguém digita "média dos códigos de pagamento" de propósito. Acontece de três jeitos discretos.

- **Um resumo de todas as colunas.** Uma ferramenta que descreve uma tabela inteira imprime a média de
  cada coluna numérica, e para ela categorias codificadas são numéricas. A média de *pagamento* fica no
  relatório ao lado da média de *cesta*, com a mesma cara de seriedade.
- **Um modelo alimentado com os códigos.** Dê a uma regressão a região como 11, 21, 31 e ela vai supor que
  a região 31 está para a 21 como a 21 está para a 11, e ajustar uma inclinação através delas. A aula 19
  mostra como categorias devem entrar num modelo.
- **Uma recodificação que ninguém registra.** Alguém troca os códigos de cartão e dinheiro. Toda contagem
  continua certa, toda "média de pagamento" muda, e nada em lugar nenhum diz por quê.

## O que fazer em vez disso

Mantenha o rótulo ao lado do código, ou no lugar dele. Uma coluna que diz `pix` não pode ter média tirada
por acidente. Onde os códigos precisam ficar, mantenha um **dicionário de dados**: um documento que diz o
que cada código significa e em que escala a variável está.

Antes de resumir qualquer coluna cujos valores sejam números inteiros pequenos, pergunte se são quantias
ou códigos. **1, 2 e 3 podem ser itens numa sacola ou os nomes de três formas de pagamento**, e só o
dicionário de dados sabe qual.

## O caso ordinal

As notas são o meio-termo difícil. Os códigos de 1 a 5 carregam uma ordem, então a mediana deles tem
significado, e a seção anterior permitiu a média com cuidado. O que os códigos nunca carregam é o tamanho
de cada passo. Quando um relatório tira a média de uma escala ordinal codificada, deveria dizer isso, e
mostrar a distribuição ao lado da média.
