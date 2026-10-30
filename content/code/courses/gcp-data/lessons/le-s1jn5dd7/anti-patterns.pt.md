---
title: Quatro jeitos de escolher errado, e quanto cada um custa
version: 1
---

**Cada um destes funciona no primeiro dia**, e é por isso que são comuns. O armazenamento responde,
a funcionalidade sai, e o custo chega depois, como uma fatura, uma página lenta ou uma queda, quando
o dado já está no lugar errado e tirá-lo de lá é um projeto.

## Um banco relacional como fila

**O padrão é uma tabela `jobs`**: os produtores inserem linhas, os workers a consultam a cada
segundo com `SELECT … WHERE status = 'pending' … FOR UPDATE SKIP LOCKED` e marcam cada linha como
feita. Funciona, e falha em todos os eixos das seis perguntas ao mesmo tempo. Cada consulta é uma
consulta no banco com que o negócio funciona, haja trabalho ou não. Cada job terminado é um update,
e no PostgreSQL um update deixa uma linha morta para o vacuum, então uma tabela de fila movimentada
incha mais rápido do que o vacuum limpa e as consultas ficam mais lentas à medida que ela cresce. Os
workers disputam travas nas mesmas poucas linhas. **Uma fila é um padrão de acesso próprio**,
acrescentar e tirar, e tem um armazenamento construído para ele: o Pub/Sub, com uma assinatura por
consumidor, uma confirmação por mensagem e um tópico de dead letter para as que continuam falhando,
como as aulas 19 e 20 mostraram. O banco guarda o registro do que foi feito, não a lista do que está
esperando.

## Um armazenamento chave-valor sem padrões de acesso

**O padrão é uma tabela do Bigtable cuja chave de linha é o timestamp**, porque os eventos chegam em
ordem de tempo e "os mais novos" é a pergunta óbvia. Toda escrita cai no fim do espaço de chaves, no
único nó que o guarda, que fica limitado enquanto o resto do cluster está ocioso; a aula 11 desenhou
esse ponto quente. O Firestore tem a mesma falha numa forma mais branda: uma coleção desenhada como
uma tabela relacional, com as consultas descobertas depois, encontra a primeira consulta que precisa
de um índice composto que ninguém criou, e depois a seguinte, cada uma um índice que custa
armazenamento e uma escrita para cada documento. **Um armazenamento desenhado em torno das chaves é
barato e rápido para as consultas para as quais foi desenhado, e para nada mais**; um time que não
consegue escrever as leituras antes de escolher a chave está no ramo relacional da árvore, por mais
que esperasse outra coisa.

## Um warehouse como armazenamento de uma aplicação

**O padrão é uma aplicação escrevendo as linhas direto no BigQuery**, um `INSERT` ou `UPDATE` de cada
vez, porque os analistas estão lá e isso poupa um pipeline. O BigQuery é construído para varrer
colunas em bilhões de linhas, e uma mudança de uma linha só é o contrário: cada comando DML é um job,
com o próprio tempo de partida, que reescreve o armazenamento por baixo, e as cotas de comandos DML
concorrentes por tabela fazem uma aplicação movimentada entrar em fila atrás de si mesma. As chaves
primárias e estrangeiras dele são declaradas e não impostas, então as duplicatas que uma aplicação
teria sido impedida de escrever são escritas. **A aplicação pertence a um banco que impõe as regras
dela e responde em milissegundos**, e o warehouse é alimentado a partir dele, por um fluxo de
mudanças como o da aula 25.

## Uma consulta que lê tudo, toda vez

**O padrão é um painel construído sobre `SELECT *` numa tabela sem filtro de partição**, atualizado a
cada poucos minutos. Cada atualização é cobrada por cada byte de cada coluna que cita, em todos os
dias que a tabela guarda, porque nada disse ao BigQuery que ele podia ler menos: as aulas 15 e 16
mediram essa diferença. A mesma falha numa tabela externa são milhões de arquivos pequenos no Cloud
Storage, onde cada arquivo aberto é uma operação de Classe B e uma quantidade fixa de trabalho antes
de um byte ser lido. **Nomeie as colunas, filtre pela partição e mantenha os arquivos grandes**; e
ponha um limite nos bytes que uma consulta pode cobrar, para que o erro custe uma mensagem de erro em
vez de uma fatura.

## O que os quatro têm em comum

**Cada um pede a um armazenamento que sirva a um padrão de acesso para o qual não foi construído,
porque ele já estava lá.** A cura nunca é uma máquina maior; é a primeira pergunta desta aula, feita
à carga de trabalho em vez de ao inventário.
