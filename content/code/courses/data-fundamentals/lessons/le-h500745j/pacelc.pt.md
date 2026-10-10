---
title: PACELC, a troca de um dia comum
version: 1
---

**O CAP só fala enquanto a rede está quebrada, e na maioria dos dias ela não está; o PACELC
acrescenta a troca que se paga no resto do tempo.** O nome é a frase que ele resume, em inglês: se há
uma partição (P), escolha disponibilidade (A) ou consistência (C); senão (E, de *else*), escolha
latência (L) ou consistência (C). Daniel Abadi o propôs em 2010 e o publicou em 2012,
argumentando que a segunda metade moldou os bancos reais mais do que a primeira.

## Por que a segunda metade existe

Volte à linha do meio da tabela da seção 04. Uma escrita que precisa ser
confirmada por uma maioria espera uma mensagem ir até outra máquina e voltar. Nada está quebrado;
essa espera é simplesmente o preço de ter certeza. Se as outras máquinas estão no mesmo prédio, a
espera é curta. Se uma cópia fica em outra cidade para que um incêndio não leve todas, toda escrita
paga a ida e a volta até essa cidade.

A alternativa é responder na hora a partir da cópia mais próxima e deixar as outras alcançarem
depois. Isso é mais rápido em toda requisição, e abre mão exatamente do que um sistema AP abre mão
durante uma partição: por um tempo, dois leitores podem ver dois valores. **Então a escolha que o CAP
descreve durante uma partição está sendo feita, numa forma mais branda, em toda requisição.**

## As quatro combinações

Cada par de letras é uma escolha separada, então existem quatro tipos de sistema. Abadi os usou para
classificar sistemas reais.

| | durante uma partição | num dia comum | um exemplo da classificação de Abadi |
|---|---|---|---|
| **PA/EL** | responde | responde rápido, da cópia mais próxima | Dynamo e Cassandra, como vêm configurados por padrão |
| **PC/EC** | recusa | espera as cópias concordarem | bancos distribuídos com transações completas, e o HBase |
| **PA/EC** | responde | espera as cópias concordarem | o MongoDB, como era em 2012 |
| **PC/EL** | recusa | responde rápido | o PNUTS, um sistema do Yahoo! |

As duas primeiras linhas são os pares coerentes: um sistema que valoriza o acordo a ponto de recusar
durante um corte em geral o valoriza a ponto de esperar por ele num dia normal, e o contrário também.
As outras duas existem, e o raciocínio delas é particular do sistema que as fez.

## Em geral uma configuração, não um rótulo

Muitos sistemas deixam quem chama escolher a cada requisição. O **Cassandra** recebe um *nível de
consistência* em toda leitura e escrita: `ONE` responde quando uma única cópia respondeu, `QUORUM`
espera uma maioria. A aritmética da aula 9 vale diretamente — com três cópias, escritas e leituras em
quórum se cruzam, e a leitura vê a escrita. As leituras do **DynamoDB** são eventualmente
consistentes, a menos que a requisição peça uma leitura fortemente consistente.

É por isso que os quatro rótulos descrevem um padrão, e não um produto. A pergunta útil sobre um
sistema não é "quais letras ele tem", e sim **"pelo que cada operação que me importa espera, e o que
ela devolve quando a rede é cortada?"** A seção 08 faz essa pergunta a sete deles.
