---
title: Os workloads da Quitanda, cada um com o seu store
version: 1
---

**A Quitanda roda em vários stores, e cada um deles está lá porque um workload pediu.** Esta seção
passa pelos workloads que o curso encontrou, faz a cada um as seis perguntas e dá a resposta com o
motivo. Onde dois stores ficaram perto, ela diz qual pergunta decidiu.

## Checkout e pedidos: Aurora PostgreSQL

**Um pedido é uma transação em várias tabelas**: o pedido, os itens dele, o estoque de cada produto,
o registro do pagamento. Tudo dá certo ou nada dá, e o cliente que acabou de pagar espera ver o pedido
na tela seguinte, então a primeira e a terceira perguntas apontam para um banco relacional. A carga é
de algumas centenas de pedidos por hora no pico da noite, que um escritor aguenta com folga. A lição 8
defendeu o Aurora contra o RDS comum pela camada de armazenamento e pelo failover; com uma madrugada
quieta e uma noite movimentada, o Aurora Serverless v2 é a versão cujo preço acompanha a curva.
**Decidido por: padrão de acesso e consistência.**

## Carrinhos e sessões: DynamoDB, com time to live

**Um carrinho é lido e escrito por uma chave, o cliente, muitas vezes em poucos minutos, e depois
abandonado.** Nada o junta a coisa nenhuma até ele virar pedido, e nesse momento ele é copiado para o
Aurora. Esse é exatamente o ramo do DynamoDB: uma chave, poucos milissegundos, uma carga com picos na
sexta à noite, e um atributo de expiração que apaga sozinho os carrinhos abandonados depois de um dia,
sem custo de escrita. Pôr os carrinhos no Aurora funcionaria, e encheria o banco com que o negócio
funciona de linhas que ninguém guarda. **Decidido por: padrão de acesso e escala.**

## A página do catálogo de produtos: ElastiCache na frente do Aurora

**Os mesmos poucos milhares de produtos são lidos milhões de vezes por dia e mudam poucas vezes.** O
store de registro continua sendo o Aurora, onde os produtos ficam com preços e estoque; um cache Valkey
na frente dele responde à página em menos de um milissegundo e tira as leituras do banco. Quando um
preço muda, a aplicação apaga a entrada do cache, e a próxima leitura a preenche de novo a partir do
Aurora. **Decidido por: latência, com o store de registro intacto.**

## As exportações noturnas e o fluxo de cliques: S3, pelo Kinesis e pelo Firehose

**Arquivos que precisam ser guardados por anos, lidos em lote por jobs, nunca atualizados linha a
linha**, são do S3, e as lições 1 a 5 montaram para eles o layout dos buckets, as classes e o ciclo de
vida. O fluxo de cliques do aplicativo são eventos que nunca param: a lição 20 os pôs num stream do
Kinesis para os consumidores que precisam deles em segundos, e a lição 21 fez o Firehose entregá-los
ao lake sem uma linha de código. O stream é por onde eles viajam; o S3 é onde ficam guardados.
**Decidido por: padrão de acesso, e o preço de guardar anos de dados.**

## O arquivo legal: S3 Glacier Deep Archive, sob Object Lock

**Registros fiscais que precisam ser guardados por anos, quase nunca lidos e nunca alterados**, vão
para a classe mais fria, com um período de retenção que ninguém consegue encurtar, como as lições 2 e
3 montaram. A 0.00320 por GB-mês é o armazenamento mais barato da tabela, e a recuperação leva horas,
o que é aceitável para um documento que um auditor pede uma vez. **Decidido por: preço, depois que o
padrão de acesso permitiu.**

## As perguntas dos analistas: Athena, e Redshift quando as perguntas viram um painel

**As perguntas são varreduras e agregações sobre meses de pedidos e cliques**, que é o ramo analítico,
e a escolha dentro dele é entre pagar por pergunta e pagar por hora. O Athena cobra 9.00 por terabyte
varrido e nada entre as consultas; o Redshift Serverless cobra 0.59760 por RPU-hora enquanto as
consultas rodam. Uma pergunta que varre 20 GB de Parquet custa 0.02 × 9.00 = 0.18 no Athena.
Quinhentas delas por dia, a carga de um painel atualizado por quarenta analistas, varrem 10 TB e
custam 90.00 por dia. O mesmo dia num workgroup do Redshift Serverless a 8 RPUs, ocupado por dez
horas, custa 8 × 0.59760 × 10 = 47.81, com os dados carregados e ordenados para essas consultas.
**Perguntas de vez em quando são do Athena; um painel que faz as mesmas perguntas o dia todo é do
Redshift.** **Decidido por: preço, no volume que o padrão de acesso produz.**

## Uma regra acima de todos

**Um store de registro por fato, e toda outra cópia derivada dele.** O pedido mora no Aurora; a cópia
do lake veio do DMS na lição 26, a do cache de uma leitura, a do warehouse de uma carga. Quando dois
stores discordam, o store de registro está certo por definição, e um desenho que não consegue dizer
qual é esse store para um dado fato ainda não terminou de ser desenhado.
