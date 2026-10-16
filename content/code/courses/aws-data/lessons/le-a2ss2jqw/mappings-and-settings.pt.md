---
title: Mapeamento de tabelas, LOBs e validação
version: 1
---

**O mapeamento de tabelas decide o que atravessa, e as configurações da tarefa decidem como.** Os
dois são documentos JSON ligados à tarefa, e os dois são onde uma migração costuma dar errado: uma
tabela que ninguém selecionou, uma coluna que nunca deveria ter saído do banco antigo, um campo de
texto grande cortado sem aviso. Os dois arquivos desta seção são o que a tarefa de verdade da Quitanda
levaria.

## Mapeamento: selecionar, depois transformar

**As regras são de dois tipos.** Regras `selection` dizem quais tabelas são levadas, com `%` como
curinga e `include` ou `exclude` como ação; regras `transformation` mudam o que é levado, renomeando
um schema ou uma tabela, tirando ou acrescentando uma coluna. A Quitanda leva todas as tabelas do
schema `public` menos a de sessões, que não vale nada fora da loja, e tira a coluna do CPF dos
clientes, que o lake não tem motivo para guardar. Salve isto como `mappings-full.json`:

`mappings-full.json`:

```json
{
  "rules": [
    {
      "rule-type": "selection", "rule-id": "1", "rule-name": "all-public",
      "object-locator": {"schema-name": "public", "table-name": "%"},
      "rule-action": "include"
    },
    {
      "rule-type": "selection", "rule-id": "2", "rule-name": "not-sessions",
      "object-locator": {"schema-name": "public", "table-name": "web_sessions"},
      "rule-action": "exclude"
    },
    {
      "rule-type": "transformation", "rule-id": "3", "rule-name": "drop-tax-id",
      "rule-target": "column",
      "object-locator": {"schema-name": "public", "table-name": "customers", "column-name": "tax_id"},
      "rule-action": "remove-column"
    },
    {
      "rule-type": "transformation", "rule-id": "4", "rule-name": "schema-name",
      "rule-target": "schema",
      "object-locator": {"schema-name": "public"},
      "rule-action": "rename", "value": "shop"
    }
  ]
}
```

**A exclusão vence o curinga**, então `web_sessions` fica para trás enquanto todas as outras tabelas
de `public` atravessam. **A coluna é tirada no caminho**, que é o lugar mais barato para tirar um dado
pessoal: ele nunca chega ao destino, então nunca precisa ser apagado de lá, e as regras do próprio
lake sobre quem pode ler o quê, assunto da lição 18, têm uma coluna a menos para proteger. A última
regra chama o schema de `shop` no destino, o que no S3 vira a primeira pasta dentro de `cdc/`.

## Configurações: LOBs e validação

**Um LOB é um objeto grande: um valor `text`, `bytea` ou `jsonb` sem tamanho fixo**, e é o único tipo
de coluna que o DMS não consegue tratar como os outros, porque não tem como saber que tamanho de
buffer dar a ele antes de lê-lo. Ele oferece três modos. O **full LOB mode** lê todo LOB inteiro, por
maior que seja, pedaço por pedaço, e é o mais lento. O **limited LOB mode** lê cada LOB até
`LobMaxSize` kilobytes, rápido, e **trunca o que for maior**; na AWS o log da tarefa registra isso com
um aviso, e nada para a tarefa. **Sem LOBs** deixa essas colunas de fora. Os pedidos da Quitanda têm
uma coluna `notes` que os entregadores preenchem, nunca mais que umas poucas linhas, então o modo
limitado em 64 KB é seguro; a suposição precisa ser medida na origem antes, com `SELECT
max(octet_length(notes)) FROM orders`, porque a falha é silenciosa.

**A validação compara o destino com a origem, linha a linha**, depois da carga completa e depois
continuamente durante o CDC, e informa cada tabela como validada, divergente ou não comparável. Ela
custa leituras a mais na origem, e é a única coisa no DMS que diz que a cópia está certa, e não só que
a cópia rodou. Salve as configurações como `task-settings.json`:

`task-settings.json`:

```json
{
  "TargetMetadata": {
    "SupportLobs": true,
    "FullLobMode": false,
    "LimitedSizeLobMode": true,
    "LobMaxSize": 64
  },
  "FullLoadSettings": {"TargetTablePrepMode": "DROP_AND_CREATE"},
  "ValidationSettings": {"EnableValidation": true, "ThreadCount": 5}
}
```

Crie a tarefa com os dois arquivos:

```
ana@laptop:~/aws$ aws dms create-replication-task --replication-task-identifier shop-to-lake --source-endpoint-arn arn:aws:dms:sa-east-1:123456789012:endpoint:GE4E4H18LLSZ4S5CLI4PY4BXH3G --target-endpoint-arn arn:aws:dms:sa-east-1:123456789012:endpoint:XKD63514ZWORV4H3HTCYH492I13 --replication-instance-arn arn:aws:dms:sa-east-1:123456789012:rep:quitanda-cdc --migration-type full-load-and-cdc --table-mappings file://mappings-full.json --replication-task-settings file://task-settings.json --query ReplicationTask.ReplicationTaskSettings --output text
{
  "TargetMetadata": {
    "SupportLobs": true,
    "FullLobMode": false,
    "LimitedSizeLobMode": true,
    "LobMaxSize": 64
  },
  "FullLoadSettings": {"TargetTablePrepMode": "DROP_AND_CREATE"},
  "ValidationSettings": {"EnableValidation": true, "ThreadCount": 5}
}

ana@laptop:~/aws$ cat broken.json
{"rules": [
ana@laptop:~/aws$ aws dms create-replication-task --replication-task-identifier broken --source-endpoint-arn arn:aws:dms:sa-east-1:123456789012:endpoint:GE4E4H18LLSZ4S5CLI4PY4BXH3G --target-endpoint-arn arn:aws:dms:sa-east-1:123456789012:endpoint:XKD63514ZWORV4H3HTCYH492I13 --replication-instance-arn arn:aws:dms:sa-east-1:123456789012:rep:quitanda-cdc --migration-type cdc --table-mappings file://broken.json --query 'ReplicationTask.[ReplicationTaskIdentifier,Status,TableMappings]'
[
    "broken",
    "creating",
    "{\"rules\": [\n"
]
```

**O moto guardou os dois documentos como texto e não julgou nenhum.** As configurações voltaram byte
a byte, que é aquilo em que o moto é bom. O segundo comando é o aviso: um arquivo de mapeamento que nem
JSON válido é, com uma linha, e o moto criou uma tarefa com ele. Na AWS essa chamada é recusada com um
erro que aponta o mapeamento de tabelas, antes de qualquer tarefa existir. Neste laboratório, confira
você mesmo um arquivo JSON antes de entregá-lo ao DMS:

```
ana@laptop:~/aws$ python3 -m json.tool broken.json
Expecting value: line 2 column 1 (char 12)
ana@laptop:~/aws$ python3 -m json.tool mappings-full.json > /dev/null && echo valid
valid
```

**`python3 -m json.tool` lê um arquivo e o imprime, ou diz a linha em que ele deixa de fazer
sentido**, que é a conferência que o moto não faz. Ela prova que o arquivo é JSON; se as regras nele
selecionam as tabelas que você queria é uma pergunta que só uma execução contra a origem de verdade
responde, e essa execução não é possível aqui.
