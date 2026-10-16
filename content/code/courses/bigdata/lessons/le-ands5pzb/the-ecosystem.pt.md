---
title: Um ecossistema, não um programa
version: 1
---

**"Hadoop" é o nome de um sistema de arquivos, um gerenciador de cluster, um modelo de programação e
uns vinte projetos construídos sobre eles**, e qual deles uma pessoa quer dizer depende de quando
aprendeu. Em 2008 queria dizer HDFS e MapReduce juntos. Em 2014 o MapReduce já tinha sido separado da
parte que distribui as máquinas, o YARN, e em volta dos três cresceram projetos que respondiam, cada
um, a uma queixa sobre o MapReduce:

| projeto | o que respondia | onde está |
|---|---|---|
| **HDFS** | onde guardar dados grandes demais para uma máquina | aula 3; ainda comum em servidores próprios, substituído por object stores na nuvem |
| **YARN** | dividir um cluster entre muitos programas e equipes | esta aula; ainda comum em servidores próprios, Kubernetes na aula 13 |
| **MapReduce** | como processar esses dados em paralelo | aula 4; substituído pelo Spark em trabalho novo |
| **Hive** | escrever SQL em vez de Java | esta aula; o seu metastore sobreviveu ao seu motor |
| **HBase** | ler e gravar linhas avulsas depressa | esta aula; um banco de dados para um caso estreito |
| **ZooKeeper** | combinar quem está no comando | roda dentro do HBase aqui, e dentro do Kafka até pouco tempo atrás |
| **Pig, Oozie, Sqoop, Flume** | scripts, agendamento, importação, coleta | quase todos aposentados, substituídos por Spark, Airflow e Kafka |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l12-stack\" aria-label=\"A pilha do Hadoop em três camadas. Embaixo, o armazenamento: HDFS, e o HBase por cima dele. No meio, o YARN, que distribui as máquinas. Em cima, os motores que rodam no YARN: MapReduce, Hive, Spark. Ao lado, o metastore do Hive, que todo motor consulta para os nomes das tabelas.\"><rect x=\"120.0\" y=\"20.0\" width=\"128.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"184.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">MapReduce</text><rect x=\"260.0\" y=\"20.0\" width=\"128.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"324.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Hive</text><rect x=\"400.0\" y=\"20.0\" width=\"128.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"464.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Spark</text><rect x=\"120.0\" y=\"96.0\" width=\"408.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"324.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">YARN</text><text x=\"324.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">contêineres e filas</text><rect x=\"120.0\" y=\"172.0\" width=\"260.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">HDFS</text><text x=\"250.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">blocos, três cópias</text><rect x=\"392.0\" y=\"172.0\" width=\"136.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">HBase</text><text x=\"460.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">linhas por chave</text><text x=\"108.0\" y=\"47.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">motores</text><text x=\"108.0\" y=\"123.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">recursos</text><text x=\"108.0\" y=\"199.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">armazenamento</text><rect x=\"552.0\" y=\"20.0\" width=\"156.0\" height=\"206.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">metastore do Hive</text><text x=\"630.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nomes, esquemas, partições</text></svg>", "caption": "Armazenamento embaixo, o YARN distribuindo máquinas, motores em cima, e um catálogo ao lado de todos.", "same": ["HBase", "HDFS", "Hive", "MapReduce", "Spark", "YARN"]}
```

Esta aula roda os três que um engenheiro de dados ainda encontra: o YARN, porque muitíssimos clusters
ainda são clusters YARN; o metastore do Hive, porque quase todo catálogo de tabelas fala o seu
protocolo; e o HBase, porque o problema que ele resolve não foi embora.

O cluster standalone da aula 1 e o YARN distribuiriam os mesmos quatro cores, então o cluster
standalone fica parado enquanto o YARN roda, e é iniciado de novo depois:

```sh
stop-worker.sh
stop-master.sh
sh hdfs.sh start
```

A última linha inicia o HDFS da aula 3, de onde os jobs do YARN leem.
