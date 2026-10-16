---
title: O Cost and Usage Report, entregue como arquivos
version: 1
---

**O Cost and Usage Report é a fatura como tabela: uma linha por linha da fatura, centenas de
colunas, gravadas como arquivos num bucket S3 seu.** O Cost Explorer (lição 13) responde às perguntas
para as quais as telas dele foram feitas. O relatório responde a qualquer pergunta, porque é o dado
de onde essas telas são desenhadas, e é o único lugar em que cada linha da lição 14 fica ao lado da
conta que a usou, do recurso que a causou e das tags que ela tinha. Nada o lê por você: você o
consulta, e por isso esta lição termina com uma consulta e não com um gráfico.

## CUR 2.0, feito pelo Data Exports

A versão atual é o **CUR 2.0**, e ele é criado como uma **exportação de dados** (*data export*) no
Billing and Cost Management. Uma exportação é três decisões por escrito: quais colunas, de qual
tabela, com qual granularidade; para onde os arquivos vão; e como são atualizados. Escrita como o
arquivo que a linha de comando da AWS recebe:

```sh
cat > export.json <<'EOF'
{
  "Name": "shop-cur2",
  "DataQuery": {
    "QueryStatement": "SELECT bill_payer_account_id, line_item_usage_account_id, line_item_line_item_type, line_item_product_code, line_item_usage_type, line_item_resource_id, line_item_usage_amount, line_item_unblended_cost, pricing_term, savings_plan_savings_plan_effective_cost, reservation_effective_cost, resource_tags FROM COST_AND_USAGE_REPORT",
    "TableConfigurations": {
      "COST_AND_USAGE_REPORT": {
        "TIME_GRANULARITY": "DAILY",
        "INCLUDE_RESOURCES": "TRUE",
        "INCLUDE_SPLIT_COST_ALLOCATION_DATA": "FALSE",
        "INCLUDE_MANUAL_DISCOUNT_COMPATIBILITY": "FALSE"
      }
    }
  },
  "DestinationConfigurations": {
    "S3Destination": {
      "S3Bucket": "shop-logs",
      "S3Prefix": "billing",
      "S3Region": "sa-east-1",
      "S3OutputConfigurations": {
        "OutputType": "CUSTOM",
        "Format": "PARQUET",
        "Compression": "PARQUET",
        "Overwrite": "OVERWRITE_REPORT"
      }
    }
  },
  "RefreshCadence": {"Frequency": "SYNCHRONOUS"}
}
EOF
```

A **consulta** é SQL sobre uma tabela, `COST_AND_USAGE_REPORT`, e escolher colunas é o ponto: um
relatório completo tem centenas, a maioria vazia na maioria das linhas. `INCLUDE_RESOURCES`
acrescenta `line_item_resource_id`, sem o qual nenhuma linha nomeia a instância ou o bucket que a
causou. O **destino** é um bucket, aqui o `shop-logs` da loja sob o prefixo `billing`, em
**Parquet**, um formato colunar que motores de consulta leem uma coluna por vez, ou em CSV
comprimido; `OVERWRITE_REPORT` substitui os arquivos do mês a cada atualização em vez de guardar
toda versão. Uma exportação pertence à **conta de gerenciamento** quando deve cobrir a organização,
pelo mesmo motivo que as tags de alocação de custos da lição 13. Reinicie o moto no primeiro terminal
(Ctrl+C, depois `moto_server -p 4567`) para que esta lição comece de uma AWS vazia, e mande-a:

```
ana@laptop:~/aws$ aws bcm-data-exports create-export --export file://export.json 2>&1 | grep ERROR
aws: [ERROR]: An error occurred (500) when calling the CreateExport operation (reached max retries: 2): <!doctype html>
ana@laptop:~/aws$ aws cur describe-report-definitions 2>&1 | grep ERROR
aws: [ERROR]: An error occurred (500) when calling the DescribeReportDefinitions operation (reached max retries: 2): <!doctype html>
```

**O moto não tem nem o Data Exports nem a API antiga do CUR**; os dois respondem com erro de
servidor. O que o laboratório mostra é mais estreito e ainda assim útil: a linha de comando confere os
nomes dos campos do `export.json` com a API da AWS antes de enviar qualquer coisa, e recusa um nome
errado com `Unknown parameter`, então a forma acima chegou até o moto. Os valores, como `PARQUET` e
`OVERWRITE_REPORT`, vêm da documentação da AWS e nada no laboratório os julgou. Contra a AWS, o bucket
também precisa de uma política que deixe o serviço de faturamento gravar nele, e a documentação da
AWS diz que os arquivos são atualizados pelo menos uma vez por dia e regravados até a fatura do mês
ficar final.

## As colunas que respondem "quem gastou o quê"

Os nomes das colunas são longos porque cada um diz a que grupo do relatório pertence. Estas são as
que as duas próximas seções usam, e as que quase toda pergunta precisa:

| coluna | o que ela guarda |
|---|---|
| `bill_payer_account_id` | a conta que paga: a conta de gerenciamento, numa fatura consolidada (lição 3) |
| `line_item_usage_account_id` | a conta que usou, que é a que um time possui |
| `line_item_line_item_type` | `Usage`, `SavingsPlanCoveredUsage`, `Tax` e os outros tipos da lição 14 |
| `line_item_product_code` | o serviço, como `AmazonEC2` ou `AmazonVPC` |
| `line_item_usage_type` | a coisa exata, como `SAE1-NatGateway-Hours` |
| `line_item_resource_id` | a instância, o bucket ou o gateway, quando os recursos são incluídos |
| `line_item_unblended_cost` | o custo como foi cobrado, o não combinado da lição 13 |
| `pricing_term` | `OnDemand` ou `Reserved` nas linhas de uso |
| `savings_plan_savings_plan_effective_cost`, `reservation_effective_cost` | quanto uma linha coberta custou pela tarifa do compromisso, o custo amortizado dela |
| `resource_tags` | as tags de alocação de custos ativadas, como um mapa: `user_team`, `user_env` |

**`resource_tags` é uma coluna só no CUR 2.0, um mapa de chave para valor.** O relatório antigo dava
a cada tag ativada uma coluna própria, como `resource_tags_user_team`, então acrescentar uma tag mudava
a forma da tabela; um mapa não muda. O prefixo `user_` marca uma tag que alguém escreveu, em oposição
a uma que a AWS gerou, e só tags ativadas no Billing aparecem nele, que é a segunda porta da lição 13.

Os **dados de alocação dividida de custos** (*split cost allocation data*) são a única opção de
tabela que esta exportação deixa desligada. Quando contêineres no ECS ou no EKS dividem uma instância
do EC2, a instância é uma linha e o custo dela pertence a vários times. Ligada, ela acrescenta colunas
`split_line_item_*` que dividem o custo de cada instância compartilhada entre os contêineres nela,
pelo processador e pela memória que reservaram ou usaram, para que um time que roda contêineres possa
ser cobrado pela parte dele de uma máquina que nunca foi só dele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l15-pipeline\" aria-label=\"Dois caminhos para a mesma pergunta. Em cima, o jeito da AWS, não rodado neste curso: o uso em toda conta vira a fatura; uma exportação de dados na conta de gerenciamento grava arquivos CUR 2.0, em Parquet, no bucket shop-logs sob billing; o Amazon Athena roda SQL sobre esses arquivos; o Amazon QuickSight desenha painéis a partir das respostas. Embaixo, este laboratório: make_cur.py grava cur.csv, linhas inventadas nas mesmas colunas; ask.py o carrega no sqlite3 e roda o mesmo SQL; a resposta é uma tabela no terminal.\"><defs><marker id=\"l15-pipeline-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l15-pipeline-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">o jeito da AWS: não rodado neste curso</text><rect x=\"20.0\" y=\"42.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"80.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uso em toda</text><text x=\"80.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">conta</text><rect x=\"162.0\" y=\"42.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"222.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">exportação de dados</text><text x=\"222.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">CUR 2.0</text><path d=\"M142.0 72.0 L159.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-pipeline-af-ah-paper-dim)\"></path><rect x=\"304.0\" y=\"42.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"364.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-logs/billing</text><text x=\"364.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Parquet</text><path d=\"M284.0 72.0 L301.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-pipeline-af-ah-paper-dim)\"></path><rect x=\"446.0\" y=\"42.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"506.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Amazon Athena</text><text x=\"506.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">SQL sobre o S3</text><path d=\"M426.0 72.0 L443.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-pipeline-af-ah-paper-dim)\"></path><rect x=\"588.0\" y=\"42.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"648.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Amazon QuickSight</text><text x=\"648.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">painéis</text><path d=\"M568.0 72.0 L585.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-pipeline-af-ah-paper-dim)\"></path><text x=\"20.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">este laboratório: na sua máquina</text><rect x=\"20.0\" y=\"182.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">make_cur.py</text><text x=\"95.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">linhas inventadas</text><rect x=\"197.0\" y=\"182.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"272.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cur.csv</text><text x=\"272.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">as mesmas colunas</text><path d=\"M172.0 212.0 L194.0 212.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-pipeline-af-ah-phosphor)\"></path><rect x=\"374.0\" y=\"182.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"449.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ask.py</text><text x=\"449.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sqlite3</text><path d=\"M349.0 212.0 L371.0 212.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-pipeline-af-ah-phosphor)\"></path><rect x=\"551.0\" y=\"182.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"626.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma tabela</text><text x=\"626.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no terminal</text><path d=\"M526.0 212.0 L548.0 212.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-pipeline-af-ah-phosphor)\"></path><text x=\"360.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">o mesmo SQL pergunta aos dois</text><path d=\"M506.0 104.0 L449.0 180.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"360.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">o laboratório troca os dados, não o método</text></svg>", "caption": "Em cima, o que uma organização real roda. Embaixo, as mesmas perguntas contra um arquivo que você fez.", "same": ["Amazon Athena", "Amazon QuickSight", "CUR 2.0", "Parquet"]}
```
