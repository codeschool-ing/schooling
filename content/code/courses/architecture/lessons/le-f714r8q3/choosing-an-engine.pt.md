---
title: Elasticsearch, OpenSearch ou Solr
version: 1
---

Os três são construídos sobre o **Apache Lucene**, a biblioteca Java que faz a análise, o índice invertido
e a pontuação. O que muda é tudo em volta: como um cluster é operado, as APIs, a licença e quem vende a
versão gerenciada.

| | Elasticsearch | OpenSearch | Solr |
| --- | --- | --- | --- |
| origem | Shay Banon, 2010; hoje a Elastic | o fork da AWS do Elasticsearch 7.10, 2021 | a Apache Software Foundation, 2006 |
| licença | AGPL, SSPL ou a própria da Elastic, à escolha de quem usa, desde 2024 | Apache 2.0 | Apache 2.0 |
| API | JSON sobre HTTP; as consultas do laboratório são a sintaxe do Elasticsearch | a mesma sintaxe, divergindo devagar desde o fork | API HTTP própria, mais uma linguagem de consulta em JSON |
| gerenciado | Elastic Cloud, nas três nuvens principais | Amazon OpenSearch Service, e outros | menos; muitas vezes operado pela própria equipe |
| forte em | logs e observabilidade (a stack ELK), e busca | o mesmo, especialmente na AWS | busca corporativa e de sites, instalações antigas |

O fork é a parte com história. Em 2021 a Elastic tirou o Elasticsearch da licença Apache para licenças que
proíbem oferecê-lo como serviço gerenciado sem um acordo, mirando os provedores de nuvem; a AWS fez um fork
da última versão com licença Apache como OpenSearch, que hoje é governado pela Linux Foundation. Em 2024 a
Elastic acrescentou a AGPL como opção, tornando o Elasticsearch código aberto de novo no sentido da OSI.
Para uma aplicação a diferença prática é pequena: as consultas desta aula rodam nos dois.

E às vezes a resposta certa é nenhum deles. O catálogo da Quitanda tem algumas centenas de produtos, e a
busca textual do PostgreSQL, com `unaccent` para os acentos e `pg_trgm` para os erros de digitação, o
atenderia a partir do banco que ela já roda, sem cópia para manter em dia. Um motor de busca justifica a
memória e o alimentador quando o catálogo é grande, quando ajustar a relevância importa para as vendas, ou
quando o mesmo cluster também guarda os logs.

Quando terminar, pare o laboratório:

```sh
docker compose down -v
```
