---
title: Administradores, locais registrados e concessões
version: 1
---

**O Lake Formation é um sistema de permissões que fica entre os motores de consulta e os arquivos.**
Os dados continuam no S3 e as tabelas continuam no Glue Data Catalog da lição 16. O que o Lake
Formation acrescenta é uma lista de concessões, no vocabulário do SQL, sobre os bancos, tabelas e
colunas do catálogo, e o poder de entregar a um motor as credenciais para ler os arquivos só depois
de conferir essa lista. A imagem errada é a de um armazenamento novo, ou de uma cópia dos dados.
Nada se move, e nada é copiado.

## A tabela que ele governa

Uma concessão nomeia uma tabela do catálogo, então o catálogo precisa de uma. Esta lição monta a
dela, sobre o arquivo da seção anterior. Salve a definição da tabela, `orders-table.json`:

```json
{
  "Name": "orders",
  "TableType": "EXTERNAL_TABLE",
  "Parameters": {"classification": "csv", "skip.header.line.count": "1"},
  "PartitionKeys": [{"Name": "dt", "Type": "string"}],
  "StorageDescriptor": {
    "Location": "s3://quitanda-curated-prod/curated/orders/",
    "Columns": [
      {"Name": "order_id", "Type": "string"},
      {"Name": "customer_id", "Type": "string"},
      {"Name": "total_cents", "Type": "bigint"},
      {"Name": "phone", "Type": "string"}
    ],
    "InputFormat": "org.apache.hadoop.mapred.TextInputFormat",
    "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
    "SerdeInfo": {
      "SerializationLibrary": "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
      "Parameters": {"field.delim": ","}
    }
  }
}
```

```
ana@laptop:~/aws$ aws glue create-database --database-input Name=curated
ana@laptop:~/aws$ aws glue create-table --database-name curated --table-input file://orders-table.json
ana@laptop:~/aws$ aws glue get-table --database-name curated --name orders --query "Table.StorageDescriptor.Columns[].Name" --output text
order_id	customer_id	total_cents	phone
```

A tabela tem as quatro colunas do CSV e uma chave de partição, `dt`, que vem do `dt=2026-10-01` da
chave do objeto. Nada nesta lição lê as linhas dela: o moto guarda a definição, e nenhum motor aqui
rodaria uma consulta sobre ela.

## Os padrões, e o primeiro administrador

```
ana@laptop:~/aws$ aws lakeformation get-data-lake-settings
{
    "DataLakeSettings": {
        "DataLakeAdmins": [],
        "CreateDatabaseDefaultPermissions": [
            {
                "Principal": {
                    "DataLakePrincipalIdentifier": "IAM_ALLOWED_PRINCIPALS"
                },
                "Permissions": [
                    "ALL"
                ]
            }
        ],
        "CreateTableDefaultPermissions": [
            {
                "Principal": {
                    "DataLakePrincipalIdentifier": "IAM_ALLOWED_PRINCIPALS"
                },
                "Permissions": [
                    "ALL"
                ]
            }
        ],
        "TrustedResourceOwners": [],
        "AllowExternalDataFiltering": false,
        "ExternalDataFilteringAllowList": []
    }
}
```

**Os padrões entregam todo banco e toda tabela nova a `IAM_ALLOWED_PRINCIPALS`, com `ALL`.** Esse
grupo quer dizer "quem o IAM já deixa entrar", e a concessão quer dizer que o Lake Formation sai da
frente: até alguém mudar isso, as permissões de uma tabela nova são decididas pelo IAM exatamente
como antes. É assim que o Lake Formation pode ser ligado numa conta que já tem um lake sem quebrar
uma única consulta, e é o assunto da próxima seção.

**A lista de administradores está vazia.** Um administrador do data lake é um principal que pode
conceder e revogar qualquer coisa no lake, e o primeiro precisa ser nomeado por alguém com a
permissão de IAM para mudar estas configurações:

```
ana@laptop:~/aws$ aws lakeformation put-data-lake-settings --data-lake-settings '{"DataLakeAdmins":[{"DataLakePrincipalIdentifier":"arn:aws:iam::123456789012:user/moto"}]}'
ana@laptop:~/aws$ aws lakeformation get-data-lake-settings
{
    "DataLakeSettings": {
        "DataLakeAdmins": [
            {
                "DataLakePrincipalIdentifier": "arn:aws:iam::123456789012:user/moto"
            }
        ]
    }
}
```

**O `put-data-lake-settings` substituiu o documento inteiro**, e as duas concessões padrão sumiram
junto com tudo o mais que não estava na requisição. Aqui o moto se comporta como a API da AWS é
documentada: a chamada define as configurações, não as mescla. Deixar os padrões de fora é, na AWS,
como uma conta para de entregar tabelas novas ao IAM. Então a mesma chamada que nomeia um
administrador também pode mudar quem decide sobre toda tabela criada depois, e merece ser escrita por
inteiro a cada vez, e não de memória.

## Registrando o local

**Um local é registrado para que o Lake Formation possa entregar credenciais para ele.** Registrar um
caminho do S3 nomeia um papel que o Lake Formation vai assumir para lê-lo; com
`--use-service-linked-role`, é um papel que a AWS cria para isso:

```
ana@laptop:~/aws$ aws lakeformation register-resource --resource-arn arn:aws:s3:::quitanda-curated-prod/curated --use-service-linked-role
ana@laptop:~/aws$ aws lakeformation list-resources
{
    "ResourceInfoList": [
        {
            "ResourceArn": "arn:aws:s3:::quitanda-curated-prod/curated"
        }
    ]
}
```

A partir daí, um motor que tem permissão de ler uma tabela naquele caminho não precisa mais de
permissão própria no bucket. Ele pede ao Lake Formation, e o Lake Formation, se as concessões
permitirem, entrega a ele credenciais temporárias feitas a partir daquele papel, válidas para aquele
caminho.

## Concedendo em colunas

**Uma concessão é um principal, uma permissão e um recurso**, e o recurso pode ser um banco, uma
tabela, ou uma tabela com uma lista de colunas. Os analistas precisam achar o banco e ler os pedidos
sem o telefone:

```
ana@laptop:~/aws$ aws lakeformation grant-permissions --principal DataLakePrincipalIdentifier=arn:aws:iam::123456789012:role/analyst --permissions DESCRIBE --resource '{"Database":{"Name":"curated"}}'
ana@laptop:~/aws$ aws lakeformation grant-permissions --principal DataLakePrincipalIdentifier=arn:aws:iam::123456789012:role/analyst --permissions SELECT --resource '{"TableWithColumns":{"DatabaseName":"curated","Name":"orders","ColumnNames":["order_id","customer_id","total_cents","dt"]}}'
ana@laptop:~/aws$ aws lakeformation list-permissions --query "PrincipalResourcePermissions[?Resource.TableWithColumns]"
[
    {
        "Principal": {
            "DataLakePrincipalIdentifier": "arn:aws:iam::123456789012:role/analyst"
        },
        "Resource": {
            "TableWithColumns": {
                "DatabaseName": "curated",
                "Name": "orders",
                "ColumnNames": [
                    "order_id",
                    "customer_id",
                    "total_cents",
                    "dt"
                ]
            }
        },
        "Permissions": [
            "SELECT"
        ],
        "PermissionsWithGrantOption": []
    }
]
```

**`DESCRIBE` no banco deixa o analista vê-lo no catálogo, e `SELECT` em quatro colunas deixa que ele
consulte essas quatro.** A lista de colunas é a metade que o IAM não conseguia dizer: `phone` não
está nela, então uma consulta que pede `phone` é recusada, e um `SELECT *` devolve as outras colunas.
As outras permissões seguem o SQL: `INSERT`, `DELETE`, `ALTER` e `DROP` numa tabela, `CREATE_TABLE`
num banco, e uma opção de concessão que deixa quem recebe conceder a mesma permissão adiante.

## Como um motor pede

**A conferência acontece quando um motor lê, e é o motor que pede.** Quando o analista roda uma
consulta no Athena, o Athena lê a definição da tabela no catálogo e pede ao Lake Formation acesso a
ela como aquele analista. O Lake Formation confere as concessões e, se elas permitirem a consulta,
devolve credenciais temporárias válidas para o local da tabela. O Athena lê os arquivos com elas e
remove as colunas e linhas que a concessão não cobre antes de qualquer coisa chegar ao analista. A
política de IAM do próprio analista precisa das permissões do Athena, de leitura no catálogo e de
`lakeformation:GetDataAccess`, e de nada no bucket.

Os motores que pedem são **o Athena, o Redshift Spectrum, o EMR e os jobs de ETL do Glue**, e os
serviços que consultam através deles, como o QuickSight pelo Athena. O moto não tem parte nenhuma
nesse pedido:

```
ana@laptop:~/aws$ aws lakeformation get-temporary-glue-table-credentials --table-arn arn:aws:glue:sa-east-1:123456789012:table/curated/orders --permissions SELECT

aws: [ERROR]: An error occurred (404) when calling the GetTemporaryGlueTableCredentials operation: <!doctype html>
<html lang=en>
<title>404 Not Found</title>
<h1>Not Found</h1>
<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try again.</p>
```

**A chamada que um motor de terceiros faz para receber credenciais responde 404 no moto**, porque não
está implementada. Esse é o limite honesto desta lição. O moto guarda toda concessão que esta seção
fez, e nada aqui pede por elas, então nada aqui é recusado. O fluxo acima é o comportamento
documentado da AWS e não foi rodado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A entrega de credenciais em seis mensagens entre o analista, o Athena, o Lake Formation e o S3. O analista manda SELECT de curated.orders ao Athena. O Athena pede acesso ao Lake Formation como o analista, e o Lake Formation confere as concessões e devolve credenciais temporárias. O Athena faz GetObject no S3 com elas e recebe todas as colunas, e devolve ao analista só as colunas concedidas. A política do analista não tem nenhum s3:GetObject.\" data-fig=\"l18-vending-pt\"><defs><marker id=\"l18-vending-pt-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-vending-pt-ah-1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"12\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">analista</text><polyline points=\"90,44 90,300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><rect x=\"210\" y=\"12\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Athena</text><polyline points=\"280,44 280,300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><rect x=\"400\" y=\"12\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Lake Formation</text><polyline points=\"470,44 470,300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><rect x=\"570\" y=\"12\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">S3</text><polyline points=\"640,44 640,300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><polyline points=\"90,76 278,76\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l18-vending-pt-ah-0)\"></polyline><text x=\"185.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SELECT ... FROM curated.orders</text><polyline points=\"280,112 468,112\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l18-vending-pt-ah-0)\"></polyline><text x=\"375.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">acesso, como o analista</text><text x=\"478\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">confere as concessões</text><polyline points=\"470,166 282,166\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l18-vending-pt-ah-1)\"></polyline><text x=\"375.0\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">credenciais temporárias</text><polyline points=\"280,202 638,202\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l18-vending-pt-ah-0)\"></polyline><text x=\"460.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">GetObject</text><polyline points=\"640,238 282,238\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l18-vending-pt-ah-1)\"></polyline><text x=\"460.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">todas as colunas</text><polyline points=\"280,274 92,274\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l18-vending-pt-ah-1)\"></polyline><text x=\"185.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">só as colunas concedidas</text><text x=\"90\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">nenhum s3:GetObject na política</text></svg>", "caption": "Quem lê os arquivos é o Athena, com credenciais que o Lake Formation entregou depois de conferir as concessões. Isto é o comportamento documentado da AWS; nada aqui rodou no moto.", "same": ["Athena", "Lake Formation", "S3"]}
```
