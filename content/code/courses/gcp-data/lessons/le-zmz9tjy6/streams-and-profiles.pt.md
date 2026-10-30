---
title: Connection profiles, um caminho privado e um stream
version: 1
---

**Um stream do Datastream são três objetos, e cada um responde uma pergunta.** Um **connection
profile** de origem diz como alcançar o banco antigo. Um connection profile de destino diz para onde
vão as mudanças. O **stream** diz o que copiar de um para o outro, com ou sem backfill. Eles são
criados nessa ordem, porque o stream nomeia os dois profiles. Nada disso tem emulador, então **nada
nesta seção foi rodado contra o Google**; o que rodou foi a própria ajuda da linha de comando, que
sabe de onde um stream pode ler:

```
ana@laptop:~/gcp$ gcloud datastream streams create --help | grep -oE -- '--[a-z-]+-source-config' | sort -u
--dataverse-source-config
--mongodb-source-config
--mysql-source-config
--oracle-source-config
--postgresql-source-config
--salesforce-marketing-cloud-source-config
--salesforce-source-config
--servicenow-source-config
--spanner-source-config
--sqlserver-source-config
```

**Dez tipos de origem nesta linha de comando, e o PostgreSQL é um deles.** Bancos de dados, MongoDB,
Spanner e alguns produtos SaaS. Todo comando desta seção foi conferido contra a mesma ajuda, então as
opções existem nesta versão do `gcloud`; se uma chamada daria certo é o que só o Google poderia ter
respondido.

## A origem, e o caminho até ela

**O profile de origem nomeia um host, um banco, um usuário e uma senha, e a senha não tem lugar na
linha de comando.** Uma senha digitada depois de `--postgresql-password` fica no histórico do shell e
na lista de processos da máquina em que foi digitada. O profile pode, em vez disso, nomear um segredo
no **Secret Manager**, e o Datastream lê a senha de lá. **Não rodado aqui:**

```sh
gcloud datastream connection-profiles create legacy-shop \
  --location=southamerica-east1 --display-name=legacy-shop --type=postgresql \
  --postgresql-hostname=198.51.100.20 --postgresql-port=5432 \
  --postgresql-database=shop --postgresql-username=datastream_reader \
  --postgresql-secret-manager-stored-password=projects/planner-dev/secrets/legacy-shop/versions/latest \
  --private-connection=quitanda-rack
```

**O `--private-connection` é o caminho, e é a parte que mais demora para montar.** O Datastream roda
na rede do Google, e o banco da loja está num rack em São Paulo sem motivo nenhum para estar na
internet. Uma *conexão privada* pareia o Datastream com uma rede VPC da Quitanda, e essa rede alcança
o rack por uma VPN ou um Interconnect, que é assunto do `gcp-foundations`. A ajuda lista outros dois
jeitos, `--static-ip-connectivity`, em que o firewall do banco admite um punhado de endereços do
Google, e `--forward-ssh-hostname`, por um bastion; os dois põem o banco mais perto da internet do que
o banco de uma loja deveria ficar.

**O usuário é um leitor e mais nada.** O `datastream_reader` precisa do atributo `REPLICATION`, para
ler o log por um slot, e de `SELECT` nas tabelas que copia, para o backfill. Ele não precisa de
direito de escrever nada, e um usuário de CDC que escreve é um usuário que pode mudar o histórico a
partir do qual o warehouse é construído.

## O destino

```sh
gcloud datastream connection-profiles create warehouse \
  --location=southamerica-east1 --display-name=warehouse --type=bigquery
```

Um profile do BigQuery não nomeia nada além do tipo; o dataset é escolhido pelo stream. Um profile
do Cloud Storage nomeia um bucket e um caminho raiz, `--bucket=quitanda-raw-prod --root-path=/cdc`,
e o stream escreve abaixo dele.

## O stream, e os dois arquivos que ele lê

**A configuração de origem nomeia o slot e a publicação**, as duas peças do PostgreSQL que a próxima
seção cria à mão. A ajuda mostra os campos que o Datastream espera:

```
ana@laptop:~/gcp$ gcloud datastream streams create --help | grep -E '"(replicationSlot|publication)"'
                    "replicationSlot": "SAMPLE_REPLICATION_SLOT",
                    "publication": "SAMPLE_PUBLICATION"
```

Salve a da Quitanda como `source.json`, nomeando a única tabela que este stream acompanha:

`source.json`:

```json
{
  "includeObjects": {
    "postgresqlSchemas": [
      {"schema": "public", "postgresqlTables": [{"table": "orders"}]}
    ]
  },
  "replicationSlot": "datastream_orders",
  "publication": "datastream_pub"
}
```

E a do destino como `destination.json`, um dataset em São Paulo, modo merge e no máximo um quarto de
hora de defasagem:

`destination.json`:

```json
{
  "singleTargetDataset": {"datasetId": "planner-dev:shop_cdc"},
  "merge": {},
  "dataFreshness": "900s"
}
```

**O `dataFreshness` é uma decisão de custo tanto quanto de frescor.** O Datastream escreve as
mudanças no BigQuery continuamente, e o BigQuery as aplica à tabela numa frequência não maior que
essa, então um valor menor significa merges mais frequentes, que a captura de mudanças do BigQuery
cobra na página dele. Quinze minutos é fresco para um relatório e barato para um merge.

O stream, com backfill da única tabela, **não rodado aqui**:

```sh
gcloud datastream streams create shop-orders --location=southamerica-east1 \
  --display-name=shop-orders \
  --source=legacy-shop --postgresql-source-config=source.json \
  --destination=warehouse --bigquery-destination-config=destination.json \
  --backfill-all
```

**Criar um stream não o inicia.** Um stream é criado, validado e depois iniciado com `gcloud
datastream streams update shop-orders --location=southamerica-east1 --state=RUNNING
--update-mask=state`, e o `--validate-only` no create roda as checagens sem criar nada: que o profile
alcança o banco, que o usuário pode ler o log, que o slot e a publicação existem. Um stream que falha
na validação diz qual delas falhou, e a resposta mais comum é a que esta aula pratica a seguir.
