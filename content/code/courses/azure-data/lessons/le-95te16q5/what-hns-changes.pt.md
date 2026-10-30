---
title: O que o espaço de nomes hierárquico muda
version: 1
---

**O Azure Data Lake Storage Gen2 não é um serviço separado. É uma conta de armazenamento com uma
configuração ligada, o espaço de nomes hierárquico**, e essa configuração transforma a lista plana de
nomes da lição 2 numa árvore de diretórios de verdade. O nome engana as pessoas em duas direções.
Umas esperam um segundo produto, com contas e tabela de preços próprias, herança do primeiro Data Lake
Store que a Microsoft aposentou. Outras esperam só um endereço novo para os mesmos blobs. A conta, os
contêineres, os blobs e os tiers de acesso são os das duas últimas lições; o que muda é que um
diretório vira uma coisa com identidade, pai e permissões próprias.

Esta seção foi escrita a partir da documentação da Microsoft sobre o Data Lake Storage e não foi
rodada: o Azurite não tem espaço de nomes hierárquico, como mostra a seção depois da próxima.

## Diretórios viram objetos

Numa conta plana, `clicks/2026/10/29/part-0001.json` é um nome com três barras dentro. Numa conta com
espaço de nomes hierárquico, é um arquivo chamado `part-0001.json` dentro de um diretório `29`, dentro
de `10`, dentro de `2026`, dentro de `clicks`, cada um deles uma entrada que o serviço mantém. Três
coisas decorrem disso, e são o motivo de a configuração existir:

| operação | espaço de nomes plano | espaço de nomes hierárquico |
|---|---|---|
| renomear um diretório | copiar e apagar cada blob debaixo dele | uma operação numa entrada, atômica |
| apagar um diretório | apagar cada blob debaixo dele | uma operação, atômica |
| permissões | o contêiner é a menor unidade | uma lista de controle de acesso em cada diretório e arquivo |

**Atômica é a palavra que importa para análise de dados.** Um job Spark, uma consulta do Synapse ou
um notebook do Databricks termina o trabalho escrevendo num diretório temporário e renomeando-o para o
lugar certo. Num espaço de nomes plano essa renomeação é a cópia de mil arquivos que a próxima seção
conta, e um job que morre no meio deixa meia tabela. Num hierárquico é um passo só, que aconteceu ou
não aconteceu.

## O segundo endpoint

Uma conta com espaço de nomes hierárquico responde em dois endereços para os mesmos dados. O endpoint
de blob da lição 1, `https://stquitandalakeprd.blob.core.windows.net`, continua funcionando, e toda
ferramenta das lições 2 a 7 continua a usá-lo. O endpoint do Data Lake,
`https://stquitandalakeprd.dfs.core.windows.net`, fala outro protocolo, com operações para
diretórios, renomeações e listas de controle de acesso, e é contra ele que os motores de análise são
escritos. No vocabulário dele um contêiner é um **file system**, e é por isso que a linha de comando
tem um grupo de comandos chamado `az storage fs`.

O Spark e as ferramentas construídas sobre ele nomeiam um caminho no lake com uma URI própria:

```
abfss://lake@stquitandalakeprd.dfs.core.windows.net/clicks/date=2026-10-29/part-0001.json
```

Leia de dentro para fora: o file system `lake`, na conta `stquitandalakeprd`, no endpoint do Data
Lake, e depois o caminho. `abfss` nomeia o driver Azure Blob File System sobre TLS, que é como os
motores da família Hadoop chegam à conta. O Synapse e o Databricks, nas lições 16 e 21, aceitam
caminhos nesse formato.

**Pelo endpoint de blob, um diretório parece um blob.** A Microsoft documenta que um programa que
lista uma conta com espaço de nomes hierárquico pela interface de blob vê cada diretório como um blob
de tamanho zero com o metadado `hdi_isfolder=true`. Um programa escrito para conta plana que copia
todo blob que lista vai copiar esses marcadores também. É inofensivo depois de conhecido, e um
mistério na primeira vez que uma contagem de arquivos sai maior do que o esperado.
