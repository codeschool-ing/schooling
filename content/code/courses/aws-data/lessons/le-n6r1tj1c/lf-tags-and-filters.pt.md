---
title: LF-tags, e filtros em linhas e células
version: 1
---

**Uma concessão por tabela por time é o problema do IAM de novo, um nível acima.** Quarenta tabelas e
seis times são até 240 concessões, cada uma escrita à mão, e a quadragésima primeira tabela não pode
ser lida por ninguém até alguém lembrar de concedê-la. As LF-tags invertem isso: as tabelas e
colunas carregam rótulos, um time recebe um rótulo, e uma tabela nova fica coberta no momento em que
é rotulada.

## Rótulos no catálogo

**Uma LF-tag é uma chave com uma lista fixa de valores**, definida uma vez por um administrador. A
Quitanda precisa de uma, `sensitivity`, com três valores. A tabela `orders` é `internal`, e a coluna
`phone` substitui isso por `pii`:

```
ana@laptop:~/aws$ aws lakeformation create-lf-tag --tag-key sensitivity --tag-values public internal pii
ana@laptop:~/aws$ aws lakeformation add-lf-tags-to-resource --resource '{"Table":{"DatabaseName":"curated","Name":"orders"}}' --lf-tags TagKey=sensitivity,TagValues=internal
{
    "Failures": []
}
ana@laptop:~/aws$ aws lakeformation add-lf-tags-to-resource --resource '{"TableWithColumns":{"DatabaseName":"curated","Name":"orders","ColumnNames":["phone"]}}' --lf-tags TagKey=sensitivity,TagValues=pii
{
    "Failures": []
}
ana@laptop:~/aws$ aws lakeformation get-resource-lf-tags --resource '{"Table":{"DatabaseName":"curated","Name":"orders"}}'
{
    "LFTagsOnTable": [
        {
            "CatalogId": "123456789012",
            "TagKey": "sensitivity",
            "TagValues": [
                "internal"
            ]
        }
    ]
}
```

**Uma tag desce pela hierarquia**: uma tabela herda as tags do banco e uma coluna as da tabela, a
menos que receba um valor próprio para a mesma chave, como `phone` recebeu. Então a tabela é
`internal` exceto por uma coluna, sem ninguém listar as outras quatro.

**A resposta do moto deixa a coluna de fora.** A AWS documenta que o `get-resource-lf-tags` numa
tabela devolve `LFTagsOnColumns` ao lado de `LFTagsOnTable`, e a segunda chamada acima apareceria lá
como `phone`, `pii`. O moto aceitou a tag na coluna, não relatou falha, e não a devolve. A tag na
coluna está na requisição que você mandaria; se a AWS a guardou é algo que este laboratório não
consegue mostrar.

## Concedendo uma tag

**Uma concessão baseada em tags nomeia uma expressão em vez de um recurso**: toda tabela cujas tags
combinam com ela. O time de atendimento cuida das entregas e precisa dos telefones, então recebe
`SELECT` em tudo que tenha a tag `internal` ou `pii`:

```
ana@laptop:~/aws$ aws lakeformation grant-permissions --principal DataLakePrincipalIdentifier=arn:aws:iam::123456789012:role/support --permissions SELECT --resource '{"LFTagPolicy":{"ResourceType":"TABLE","Expression":[{"TagKey":"sensitivity","TagValues":["internal","pii"]}]}}'
ana@laptop:~/aws$ aws lakeformation list-permissions --query 'PrincipalResourcePermissions[].[Principal.DataLakePrincipalIdentifier,Permissions[0],keys(Resource)[0]]' --output text
arn:aws:iam::123456789012:role/analyst	SELECT	TableWithColumns
arn:aws:iam::123456789012:role/analyst	DESCRIBE	Database
arn:aws:iam::123456789012:role/support	SELECT	LFTagPolicy
```

**Três concessões agora: a do papel de atendimento numa política de tags, e as duas do analista em
recursos nomeados.** Na AWS, o papel de atendimento lê todas as colunas de `orders`, telefone
incluído, porque os dois valores estão na expressão dele. Um analista que recebesse só `internal`
leria a tabela sem `phone`, já que a tag dessa coluna é `pii`. E uma tabela que o pipeline crie na
semana que vem, com a tag `internal`, pode ser lida pelo atendimento no dia em que aparece, sem
nenhuma concessão nova escrita. Esse é o objetivo das tags, e também o risco delas: quem pode rotular
uma tabela decide quem a lê, então a permissão de atribuir tags é concedida com tanto cuidado quanto
os próprios dados.

## Filtros em linhas e células

**Um filtro de dados estreita uma concessão a algumas linhas, algumas colunas, ou às duas coisas**,
que juntas são células. Ele é escrito sobre uma tabela: um filtro de linhas é uma condição SQL, e as
colunas são uma lista a incluir ou a excluir. Conceder `SELECT` no filtro, em vez de na tabela, dá ao
principal só o que o filtro deixa passar. O time de atendimento de um bairro deve ver os pedidos, com
o telefone, dos clientes daquele bairro e de mais ninguém. O filtro, `support-filter.json`:

```json
{
  "TableCatalogId": "123456789012",
  "DatabaseName": "curated",
  "TableName": "orders",
  "Name": "support-own-district",
  "RowFilter": {"FilterExpression": "customer_id IN ('c-03', 'c-17')"},
  "ColumnNames": ["order_id", "customer_id", "phone"]
}
```

```
ana@laptop:~/aws$ aws lakeformation create-data-cells-filter --table-data file://support-filter.json

aws: [ERROR]: An error occurred (404) when calling the CreateDataCellsFilter operation: <!doctype html>
<html lang=en>
<title>404 Not Found</title>
<h1>Not Found</h1>
<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try again.</p>
ana@laptop:~/aws$ aws lakeformation list-data-cells-filter
{
    "DataCellsFilters": []
}
```

**O moto não implementa filtros de dados**: criar um respondeu 404, e a lista está vazia. Na AWS,
este filtro deixaria o atendimento ler três colunas das linhas de `c-03` e `c-17` e nada sobre
`c-22`, e o Athena o aplicaria a toda consulta que o atendimento rodasse em `orders`. Um filtro de
verdade testaria uma coluna de bairro em vez de listar clientes à mão; o CSV desta lição não tem
bairro, e a lista mantém o exemplo nas colunas que ele tem. Filtragem por linha e por célula é
comportamento documentado da AWS e não foi rodada.
