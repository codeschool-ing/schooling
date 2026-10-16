---
title: O log de transações
version: 1
---

**Uma tabela Delta é um diretório de arquivos Parquet e um diretório `_delta_log` de arquivos JSON
numerados, um por commit.** Cada commit lista os arquivos que acrescenta à tabela e os que remove. Ler
a tabela é ler o log desde o início, ou desde o checkpoint mais recente dele, e pegar os arquivos que
foram acrescentados e não removidos depois. Nada mais no diretório faz parte da tabela, seja o que
for que guarde.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l11-log\" aria-label=\"Uma tabela Delta como um log e um diretório. O commit 0 acrescenta os arquivos 1 a 3, o commit 1 acrescenta os arquivos 4 a 6, o commit 2 remove os seis e acrescenta os arquivos 7 a 9. A versão 2 da tabela são os arquivos 7 a 9; a versão 1 são os arquivos 1 a 6, que continuam no disco até um vacuum apagá-los.\"><text x=\"20.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">_delta_log</text><rect x=\"20.0\" y=\"32.0\" width=\"216.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">00000.json</text><text x=\"226.0\" y=\"48.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">janeiro</text><text x=\"30.0\" y=\"74.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">add: 1 2 3</text><rect x=\"252.0\" y=\"32.0\" width=\"216.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"262.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">00001.json</text><text x=\"458.0\" y=\"48.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fevereiro</text><text x=\"262.0\" y=\"74.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">add: 4 5 6</text><rect x=\"484.0\" y=\"32.0\" width=\"216.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"494.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">00002.json</text><text x=\"690.0\" y=\"48.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">DELETE</text><text x=\"494.0\" y=\"74.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">remove: 1 2 3 4 5 6</text><text x=\"494.0\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">add: 7 8 9</text><text x=\"20.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">arquivos de dados no disco</text><rect x=\"20.0\" y=\"166.0\" width=\"64.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"52.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.parquet</text><rect x=\"96.0\" y=\"166.0\" width=\"64.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"128.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2.parquet</text><rect x=\"172.0\" y=\"166.0\" width=\"64.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"204.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3.parquet</text><rect x=\"248.0\" y=\"166.0\" width=\"64.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"280.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4.parquet</text><rect x=\"324.0\" y=\"166.0\" width=\"64.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"356.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5.parquet</text><rect x=\"400.0\" y=\"166.0\" width=\"64.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"432.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6.parquet</text><rect x=\"476.0\" y=\"166.0\" width=\"64.0\" height=\"40.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"508.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">7.parquet</text><rect x=\"552.0\" y=\"166.0\" width=\"64.0\" height=\"40.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"584.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">8.parquet</text><rect x=\"628.0\" y=\"166.0\" width=\"64.0\" height=\"40.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"660.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">9.parquet</text><path d=\"M20.0 222.0 L476.0 222.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"248.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">versão 1</text><path d=\"M476.0 254.0 L704.0 254.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"590.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">versão 2 (atual)</text></svg>", "caption": "A tabela é o que o log diz que ela é: a versão 2 são três arquivos, e os seis que ela removeu ficam no disco para a versão 1.", "same": ["DELETE"]}
```

**Um commit é atômico porque criar um arquivo com um dado nome é.** Quem grava escreve primeiro os
seus arquivos Parquet, onde nenhum leitor olha, e depois cria o próximo arquivo do log, digamos
`00000000000000000003.json`. Se dois escritores disputam o mesmo número, o sistema de arquivos deixa
exatamente um criá-lo; o outro acha o número tomado, lê o que mudou e tenta de novo como número 4 se
os dois não conflitaram. Até o arquivo de log existir, os arquivos de dados novos ficam invisíveis;
quando ele existe, todos ficam visíveis de uma vez. Isso é *concorrência otimista*: sem travas, e uma
checagem no fim. O HDFS e um disco local recusam criar um arquivo que existe; num object store o Delta
conta com as gravações condicionais do próprio store, ou com um serviço coordenador onde o store não
as tem.

O Delta não está no classpath do Spark por padrão. Os seus dois jars vêm do Maven Central, o
repositório em que bibliotecas Java são publicadas. Num diretório só deles:

```sh
mkdir -p ~/jars && cd ~/jars
curl -O https://repo1.maven.org/maven2/io/delta/delta-spark_2.13/4.3.1/delta-spark_2.13-4.3.1.jar
curl -O https://repo1.maven.org/maven2/io/delta/delta-storage/4.3.1/delta-storage-4.3.1.jar
curl -O https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-4.1_2.13/1.12.0/iceberg-spark-runtime-4.1_2.13-1.12.0.jar
curl -O https://repo1.maven.org/maven2/org/apache/hudi/hudi-spark4.1-bundle_2.13/1.2.1/hudi-spark4.1-bundle_2.13-1.2.1.jar
cd ~/big
```

Os dois últimos são para as seções 06 e 07. Cada versão é a mais nova feita para o Spark 4.1, e cada
nome diz para qual Spark e qual Scala foi feito: um jar feito para outro Spark costuma falhar com um
erro sobre uma classe ou um método que falta, e não sobre uma versão. O que chegou:

```
ana@lab:~/big$ ls -l ~/jars
total 136664
-rw-r--r-- 1 ana ana  9021481 Oct 16 03:33 delta-spark_2.13-4.3.1.jar
-rw-r--r-- 1 ana ana   110970 Oct 16 03:33 delta-storage-4.3.1.jar
-rw-r--r-- 1 ana ana 82491267 Oct 16 03:33 hudi-spark4.1-bundle_2.13-1.2.1.jar
-rw-r--r-- 1 ana ana 48309426 Oct 16 03:33 iceberg-spark-runtime-4.1_2.13-1.12.0.jar
```

O `spark-submit --packages io.delta:delta-spark_2.13:4.3.1` buscaria o Delta e o que ele precisa no
Maven Central sozinho, e conferiria de novo no começo de toda execução; os jars no disco fazem cada
execução começar do mesmo jeito sem rede, e o `--jars` os entrega ao driver e a cada executor.
