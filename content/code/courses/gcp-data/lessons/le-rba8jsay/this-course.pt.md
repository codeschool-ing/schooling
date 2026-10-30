---
title: O que este curso é, e o que ele pressupõe
version: 1
---

**Este curso é sobre onde o dado cai no Google Cloud, onde ele mora e onde ele é perguntado**, e
sobre a fatura que cada uma dessas escolhas escreve. Ele acompanha os dados de uma empresa, a
Quitanda, um serviço de entrega de mercado em São Paulo: os arquivos que a loja exporta toda noite, o
banco de dados em que os pedidos moram, os cliques que o aplicativo manda a cada segundo e o
warehouse que os analistas consultam.

Ele corre em seis partes:

| aulas | o quê | a pergunta que cada parte responde |
|---|---|---|
| 1 a 5 | Cloud Storage | onde um arquivo mora, por quanto tempo, quem pode lê-lo e quanto custa lê-lo |
| 6 a 9 | Cloud SQL, AlloyDB e Spanner | três respostas para "preciso de um banco relacional", e o que cada uma cobra |
| 10 a 12 | Firestore, Bigtable e Memorystore | um banco desenhado em torno das consultas, e o cache na frente de tudo |
| 13 a 18 | BigQuery | o warehouse, e as duas decisões que definem quanto custa uma consulta |
| 19 a 22 | Pub/Sub e Dataflow | dados que não param de chegar, atrasados e fora de ordem, e o que "entregue" quer dizer |
| 23 a 27 | Dataproc, Composer, Datastream, Dataplex e a escolha | os jobs que rodam à noite, o banco de onde você copia, o mapa de tudo e como escolher o armazenamento |

**Ele pressupõe dois cursos.** Do `gcp-foundations`, a hierarquia de recursos e os projetos, os
principals e os papéis do IAM, regiões e zonas, e a própria linha de comando `gcloud`. Do
`sql-databases`, o vocabulário relacional: tabela, chave primária, índice, transação. Uma aula que
se apoia num deles diz qual aula de qual curso, e nenhuma explica um papel do IAM ou um `JOIN` do
começo.

## Três tipos de aula

**O Google Cloud não pode ser imitado inteiro num notebook, e este curso não finge que pode.** A
seção sobre o que são os emuladores, mais adiante nesta aula, diz exatamente o que responde no seu
laboratório. A consequência para as aulas é que cada seção é de um de três tipos:

- **praticada contra um emulador**, onde o Google ou outra pessoa publica um: Cloud Storage,
  Pub/Sub, Firestore, Bigtable e Spanner;
- **praticada contra o motor que está por baixo**, onde o serviço gerenciado é construído sobre um
  software de código aberto que você consegue rodar: PostgreSQL para o Cloud SQL e o AlloyDB, Redis
  para o Memorystore, Apache Beam para o Dataflow, Spark para o Dataproc, e o DuckDB rodando SQL sobre
  os arquivos que o BigQuery leria;
- **lida**, onde nada local responde: criar uma instância, uma reserva, um cluster ou um job, e tudo
  sobre projetos, IAM e faturamento. Uma seção lida mostra o comando e diz que ele não foi rodado, e
  nunca mostra uma resposta que não recebeu.

Toda transcrição numa cerca foi gravada no laboratório que a próxima seção monta, e você pode
reproduzi-la lá. O que você não pode reproduzir está marcado onde aparece.
