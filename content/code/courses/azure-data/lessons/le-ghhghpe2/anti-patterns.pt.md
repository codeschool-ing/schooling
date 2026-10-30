---
title: Jeitos de escolher errado que funcionam no primeiro dia
version: 1
---

**Cada um destes funciona no primeiro dia**, e é por isso que são comuns. O armazenamento responde, os
testes passam, a demonstração vai bem. A falha chega com o volume ou com o tempo, quando trocar de
armazenamento custa uma migração em vez de uma decisão.

## Um banco relacional como fila

**O padrão é uma tabela `jobs`**: produtores inserem linhas, workers consultam a tabela a cada segundo
atrás da linha mais antiga não reservada e a marcam como pega. Funciona com um worker e poucos jobs por
minuto. Com dez workers, eles brigam pelas mesmas linhas com locks, a tabela cresce com linhas que
ninguém apaga, e só a consulta repetida mantém o banco ocupado quando não há trabalho. O Event Hubs,
lição 22, ou uma fila feita para isso, as filas do Azure Storage ou o Service Bus, entrega aos leitores
sem consulta repetida e deixa o banco para aquilo em que ele é bom.

## Cosmos DB sem os padrões de acesso

**O padrão é um contêiner desenhado como uma tabela relacional**, particionado por um campo que
ninguém usa nas consultas, ou por um campo com três valores, e consultado com filtros em todo o resto.
Toda consulta então atravessa todas as partições e a cobrança de requisição cresce com o tamanho dos
dados, que é o assunto inteiro da lição 11. O conserto não é uma vazão maior; é uma chave de partição
escolhida a partir das consultas, o que em geral quer dizer um contêiner novo e uma migração.

## O lake como banco de dados

**O padrão é uma aplicação lendo registros avulsos de arquivos Parquet ou Delta**, por um pool SQL
serverless ou direto do Blob Storage, porque os dados já estavam lá. A seção anterior pôs preço nisso:
cada consulta lê muito mais do que devolve e leva segundos. O lake é para varreduras; uma carga que lê
por chave precisa de uma cópia num armazenamento feito para chaves.

## O cache como armazenamento de registro

**O padrão são dados gravados só no Redis**, porque era rápido e o banco ficava "para depois". O Azure
Cache for Redis guarda dados na memória, e a lição 15 mostrou o que as camadas dele prometem e não
prometem sobre persistência; uma remoção por pressão de memória ou um failover pode tirar chaves, por
projeto. Um cache guarda cópias de coisas que moram em outro lugar. Um carrinho talvez aguente ser
perdido; um pedido não.

## Um armazenamento para tudo

**O padrão é escolher um armazenamento e encaixar nele todas as cargas**, para a equipe operar uma
coisa só. É um instinto razoável para uma equipe de três, e a quinta pergunta desta lição o leva a
sério. Dá errado quando o ramo do armazenamento está longe do da carga: as varreduras dos analistas
rodando no banco do checkout ao meio-dia, deixando cada venda mais lenta, ou o stream de cliques
gravado linha a linha no SQL. Menos armazenamentos é um bom objetivo; um armazenamento para cargas de
quatro ramos é uma conta e uma queda esperando para acontecer.

## Uma chave que concentra a carga

**O padrão é uma chave de partição escolhida por conveniência**: a data, para que todas as gravações
de hoje vão para uma partição; a loja, com três lojas; uma constante. Funciona nos testes, onde a
carga é pequena. Em produção, uma partição leva tudo enquanto as outras ficam paradas, e o throttling
da lição 13 chega enquanto a vazão total da conta parece generosa. O mesmo erro num event hub, lição
22, deixa partições sem trabalho para os leitores e a mais movimentada atrasada. Escolher uma chave é
escolher como a carga se espalha, em todo armazenamento que tem uma.
