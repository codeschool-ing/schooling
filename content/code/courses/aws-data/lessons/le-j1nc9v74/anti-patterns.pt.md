---
title: Quatro jeitos de escolher errado, e quanto cada um custa
version: 1
---

**Cada um destes funciona no primeiro dia**, e é por isso que são comuns. O store responde, a
funcionalidade sai, e o custo chega depois, como uma conta, uma página lenta ou uma queda, quando os
dados já estão no lugar errado e mudá-los de lugar é um projeto.

## Um banco relacional como fila

**O padrão é uma tabela `jobs`**: produtores inserem linhas, workers a consultam a cada segundo com
`SELECT … WHERE status = 'pending' … FOR UPDATE SKIP LOCKED`, e marcam cada linha como feita.
Funciona, e falha em todos os eixos das seis perguntas de uma vez. Cada consulta é feita no banco com
que o negócio funciona, haja trabalho ou não. Cada job terminado é uma alteração, e no PostgreSQL uma
alteração deixa uma linha morta para o vacuum, então uma tabela de fila movimentada incha mais rápido
do que o vacuum a limpa e as consultas ficam mais lentas conforme ela cresce. Os workers disputam
locks nas mesmas poucas linhas. **Uma fila é um padrão de acesso próprio**, acrescentar e tirar, e
tem stores feitos para ela: um stream como o Kinesis quando a ordem importa e vários consumidores
leem, um serviço de fila quando cada mensagem vai para um worker. O banco guarda o registro do que foi
feito, não a lista do que está esperando.

## DynamoDB sem padrões de acesso

**O padrão é uma tabela desenhada como uma relacional**, com um id como chave, e as consultas
descobertas depois. A primeira consulta que não é pelo id vira um `Scan` com filtro, que lê, e cobra,
todo item da tabela para devolver um punhado, como a lição 10 mostrou. A seguinte vira um índice
secundário global acrescentado às pressas, e a outra, mais um. Ou a chave é um valor com poucos
valores distintos, um status ou uma data, e toda escrita cai na mesma partição, que é estrangulada
enquanto o resto da tabela fica parado. **O DynamoDB é barato e rápido para as consultas para as
quais foi desenhado, e para nada mais**; uma equipe que não consegue escrever as consultas antes de
criar a tabela está no ramo relacional da árvore, por mais que esperasse outra coisa.

## Um warehouse como store de uma aplicação

**O padrão é uma aplicação escrevendo as suas linhas direto no Redshift**, uma inserção ou alteração
de cada vez, porque os analistas estão lá e isso poupa um pipeline. O Redshift é feito para varrer
colunas em bilhões de linhas, e uma escrita de uma linha é o oposto: cada uma é um pequeno commit no
armazenamento colunar, e muitas delas fazem fila umas atrás das outras. As chaves primárias e
estrangeiras dele são declaradas e não impostas, então as duplicatas que uma aplicação teria sido
impedida de escrever são escritas. **A aplicação pertence a um banco que impõe as regras dela e
responde em milissegundos**, e o warehouse é carregado a partir dele em lotes, por um pipeline como o
da lição 26.

## Athena sobre milhões de arquivos minúsculos

**O padrão é um produtor escrevendo um arquivo pequeno por evento**, ou por segundo, no lake, e o
Athena consultando a pasta. Cada arquivo é pelo menos uma requisição ao S3 e uma quantidade fixa de
trabalho para o motor abrir, então um dia de arquivos pequenos é uma consulta que gasta o tempo abrindo
arquivos em vez de lendo dados. A conta de requisições é a parte visível: a 0.00056 por 1.000
requisições `GET`, uma consulta que abre dois milhões de objetos paga 2,000,000 × 0.00056 ÷ 1,000 = 1.12
só em requisições, toda vez que roda, antes de um byte ser varrido. E roda devagar o bastante para as pessoas notarem. **Escreva menos arquivos, e maiores**: a lição 19 explica por quê, o Firehose junta
eventos neles, e um job de compactação consegue juntar o que foi escrito pequeno.

## O que os quatro têm em comum

**Cada um pede a um store que sirva um padrão de acesso para o qual ele não foi feito, porque ele já
estava lá.** A cura nunca é uma máquina maior; é a primeira pergunta desta lição, feita ao workload e
não ao inventário.
