---
title: As cargas da Quitanda, cada uma com seu armazenamento
version: 1
---

**A Quitanda roda sobre vários armazenamentos, e cada um está lá porque uma carga pediu.** Cada título
abaixo nomeia a carga e o armazenamento dela, e cada parágrafo termina com a pergunta da primeira seção
desta lição que decidiu.

## Checkout e pedidos: Azure SQL Database

**Um pedido é uma transação entre várias tabelas**: o pedido, os itens, o estoque de cada produto, o
registro do pagamento. Ou todos mudam ou nenhum muda, e a loja os lê de volta juntados. Esse é o ramo
relacional, e o Azure SQL Database, lição 8, é o padrão gerenciado dele. A camada General Purpose basta
no tamanho da Quitanda; a Business Critical compra failover mais rápido e uma réplica legível, e vale a
pena no dia em que um minuto de checkout fora do ar custar mais que a diferença. **Decidido por: o
padrão de acesso, e a consistência.**

## Carrinhos e sessões: Cosmos DB

**Um carrinho é lido e gravado por uma chave, o cliente, muitas vezes em poucos minutos, e depois é
abandonado ou vira um pedido.** Um item por chave, na escala do pico da noite, sem junções: Cosmos DB,
lição 11, particionado pelo cliente, com um time to live para que carrinhos abandonados se apaguem
sozinhos. A consistência de sessão, o padrão da lição 12, é exatamente a promessa de que um carrinho
precisa: um cliente sempre vê a própria última mudança. **Decidido por: o padrão de acesso, e a
escala.**

## A página de produto: Azure Cache for Redis na frente do SQL

**Os mesmos poucos milhares de produtos são lidos milhões de vezes por dia e mudados poucas vezes.** O
armazenamento de registro continua sendo o banco SQL; o cache da lição 15 responde às leituras, com um
time to live curto o bastante para que uma mudança de preço apareça em minutos. **Decidido por: a
latência.**

## As exportações noturnas, o stream de cliques e o lake: Blob Storage

**Arquivos guardados por anos, lidos em bloco por jobs e nunca atualizados linha a linha**, são do
Blob Storage, numa conta com o namespace hierárquico. As exportações chegam na camada hot e uma regra
de ciclo de vida as leva para cool e archive, lições 4 e 5. Os cliques chegam pelo Event Hubs, lição
22, e o Capture os grava como Avro no mesmo lake, onde um pipeline os transforma em tabelas Delta,
lição 18. **Decidido por: o padrão de acesso, e o preço.**

## A checagem de fraude: Event Hubs e um leitor próprio

**Segundos importam, e o padrão que interessa abrange os últimos dez minutos de um cliente.** A
checagem de fraude lê `clicks` pelo próprio grupo de consumidores e mantém uma janela sliding por
cliente, o que é um job do Stream Analytics da lição 23 ou um programa da Quitanda; o que ela marca é
gravado no Cosmos DB para a loja ler pelo id do cliente, de forma idempotente, como a lição 24 exigiu.
**Decidido por: a latência, e o padrão de acesso.**

## As perguntas dos analistas: o lake, consultado no lugar, depois um warehouse

**As perguntas são varreduras e agregações sobre meses de pedidos e cliques**, o ramo do warehouse.
Enquanto são ocasionais, um pool SQL serverless ou um lakehouse do Fabric lê os arquivos Delta no lugar
e cobra pelo que lê, lições 16 e 17. Quando as mesmas perguntas viram um painel atualizado a cada hora
por trinta pessoas, uma capacidade comprada por hora fica mais barata que pagar por consulta, e a
decisão é revista. **Decidido por: o preço, no volume que o padrão de acesso produz.**

## Uma regra acima de todas

**Um armazenamento de registro por fato, e toda outra cópia derivada dele.** O pedido mora no Azure
SQL Database; a cópia do lake, a do cache e as tabelas dos analistas são derivadas dele e podem ser
reconstruídas a partir dele. Quando dois armazenamentos aceitam gravações para o mesmo fato, no dia em
que discordarem não há como dizer qual está certo. A linhagem do Purview, lição 25, é como uma equipe
prova, meses depois, que cópia veio de onde.
