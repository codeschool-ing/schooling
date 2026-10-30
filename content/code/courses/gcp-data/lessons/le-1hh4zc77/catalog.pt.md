---
title: O catálogo: entradas, aspectos e busca
version: 1
---

**Um catálogo responde "o que temos, e o que isso significa" sem ninguém abrir os dados.** A
Quitanda já tem algumas centenas de tabelas, e a primeira coisa que uma analista pergunta não é uma
consulta mas uma busca: existe uma tabela de entregas, de quem ela é, é a limpa ou a bruta, posso
pô-la num relatório. O catálogo do Dataplex é o índice que responde a isso, e o modelo dele tem três
substantivos.

## Entradas, grupos de entradas e aspectos

**Uma entrada é o registro que o catálogo tem de um ativo de dados**: um dataset ou uma tabela do
BigQuery, um bucket do Cloud Storage, um tópico do Pub/Sub, uma tabela do Spanner, um banco do Cloud
SQL. **As entradas dos próprios serviços do Google Cloud aparecem sozinhas.** O catálogo ingere os
metadados técnicos do BigQuery e dos outros conforme os recursos são criados e mudam, em grupos de
entradas do sistema cujos nomes começam com `@`, como `@bigquery`, e ninguém precisa registrar uma
tabela para ela ser achada. Um **grupo de entradas** é um contêiner de entradas; um time que quer
catalogar algo fora do Google Cloud, as tabelas do ERP antigo por exemplo, cria um grupo de entradas
próprio e grava nele entradas personalizadas, cada uma de um **tipo de entrada** que ele define.

**Um aspecto é um pedaço de metadado estruturado ligado a uma entrada**, e é nele que mora o
significado. Todo aspecto tem um **tipo de aspecto**, que é um esquema: nomes de campos, os tipos
deles, quais são obrigatórios. O sistema liga alguns aspectos por conta própria, o esquema de uma
tabela do BigQuery sendo um deles, e um time define o resto. A Quitanda quer que toda tabela curated
diga de quem é e se guarda dado pessoal, então definiria um tipo de aspecto. O modelo dele,
`ownership.json`, aparece como a documentação descreve o formato, e nada aqui o conferiu:

```json
{
  "name": "ownership",
  "type": "record",
  "recordFields": [
    {"name": "owner_team", "type": "string", "index": 1, "constraints": {"required": true}},
    {"name": "contains_personal_data", "type": "bool", "index": 2, "constraints": {"required": true}},
    {"name": "retention_days", "type": "int", "index": 3}
  ]
}
```

```sh
gcloud dataplex aspect-types create ownership --location=southamerica-east1 \
  --metadata-template-file-name=ownership.json
```

**Um tipo de aspecto com campos `required` é uma regra, não uma sugestão.** Um aspecto que deixa de
fora `owner_team` é recusado quando é gravado, e essa é a diferença entre um catálogo com metadados
estruturados e uma página de wiki por tabela. O antigo Data Catalog chamava a mesma ideia de **tag**,
com um **modelo de tag** (tag template), e a documentação da migração mapeia um no outro: um modelo de
tag vira um tipo de aspecto, e uma tag vira um aspecto.

## A busca, e o que o catálogo não é

**A busca roda sobre nomes, descrições e valores de aspectos ao mesmo tempo.** Não executado:

```sh
gcloud dataplex entries search "orders" --project=planner-dev
```

Ela devolveria a tabela `curated.orders` do BigQuery, o dataset que a contém, e qualquer entrada
personalizada cujo nome ou descrição mencione pedidos, cada uma com seus aspectos.
Ela devolve só as que quem busca pode ver: o catálogo filtra os resultados pelas permissões do IAM nos recursos por baixo, então
nunca revela que uma tabela existe a alguém que não pode ler os metadados dela.

**O catálogo é um índice sobre os metadados dos próprios dados, não o lugar de onde os motores os
leem.** O BigQuery guarda o esquema de cada tabela no BigQuery; a entrada do catálogo para a tabela é
um reflexo disso, mantido em dia pela ingestão. Apagar uma tabela remove a entrada dela, e uma entrada
não cria uma tabela. Onde um motor precisa mesmo de um catálogo externo para saber que arquivos formam
uma tabela, como o Spark e os formatos de tabela abertos, a resposta do Google Cloud é o metastore do
BigLake da aula 17, um serviço diferente deste. **Então um catálogo desatualizado engana pessoas, e
nunca quebra uma consulta.** Isso faz da precisão dele uma questão de disciplina, e é por isso que os
campos obrigatórios acima importam.

## O preço dos metadados

De cloud.google.com/dataplex/pricing, lido em 2026-10-30, o mesmo em toda região: o armazenamento de
metadados custa **US$ 0,002739726 por GiB-hora**, e a página diz que os metadados técnicos ingeridos
automaticamente dos serviços do Google Cloud, como o BigQuery, são guardados sem custo. As chamadas à
API são grátis, a busca inclusive. Então o que a Quitanda paga são os aspectos que ela mesma grava:

```
ana@laptop:~/gcp$ python3 -c 'gib = 0.002739726 * 730; print(round(gib, 4), round(300 * 1024 / 2**30 * gib, 6))'
2.0 0.000572
```

**Um GiB de metadados sai dois dólares por mês.** O próprio exemplo da página põe um aspecto pequeno
em cerca de um kilobyte, então um GiB são cerca de um milhão deles; as poucas centenas de tabelas da
Quitanda, com um aspecto de dono cada, são algumas centenas de kilobytes, e a conta delas arredonda
para nada. O custo do catálogo é a disciplina de mantê-lo verdadeiro, não o armazenamento dele.
