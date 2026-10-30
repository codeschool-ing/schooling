---
title: Restaurando o estado a partir da própria história
version: 1
---

**A recuperação mais rápida é uma cópia do estado de antes do acidente.** O snapshot é uma. Baixe, olhe antes de
confiar e devolva:

```
ana@laptop:~/azure/tf/release$ az storage blob download --container-name tfstate --name shop.tfstate --snapshot 2026-10-30T18:22:54.9190000Z --file restored.tfstate --no-progress -o none
ana@laptop:~/azure/tf/release$ jq '{serial, lineage, resources: [.resources[].type]}' restored.tfstate
{
  "serial": 1,
  "lineage": "e8adb596-3007-ccb8-2df0-fd09af178519",
  "resources": [
    "terraform_data"
  ]
}
ana@laptop:~/azure/tf/release$ az storage blob upload --container-name tfstate --name shop.tfstate --file restored.tfstate --overwrite --no-progress -o none
ana@laptop:~/azure/tf/release$ cp restored.tfstate terraform.tfstate && terraform plan -no-color | grep -m1 "No changes"
No changes. Your infrastructure matches the configuration.
```

O `lineage` é o campo a conferir: o Terraform dá a todo estado um identificador quando ele é criado e se recusa a
substituir um estado por outro de lineage diferente, então um lineage que bate diz que esta é mesmo a história da mesma
configuração. O `serial` conta as escritas; restaurar um serial mais antigo é o que recuperar quer dizer, e o que foi
aplicado depois daquele serial terá de voltar pelo próximo `plan`. Depois do upload, o `plan` concorda com o mundo de
novo.

## Quando os snapshots foram junto

Um blob apagado com os snapshots não deixa nada no contêiner:

```
ana@laptop:~/azure/tf/release$ az storage blob delete --container-name tfstate --name shop.tfstate --delete-snapshots include
ana@laptop:~/azure/tf/release$ az storage blob list --container-name tfstate --include s -o tsv | wc -l
0
```

No Azure, é aqui que a **exclusão reversível** se paga. Ligada, a conta guarda um blob apagado, com snapshots e tudo,
pelos dias que você definir, trinta no módulo da lição 5, e `az storage blob undelete` o traz de volta. O Azurite não
implementa exclusão reversível, e diz isso:

```
ana@laptop:~/azure/tf/release$ az storage blob undelete --container-name tfstate --name shop.tfstate 2>&1 | grep -E "ErrorCode"
ErrorCode:APINotImplemented
```

Então o resto deste parágrafo vem da documentação da Microsoft e não foi executado. O **versionamento de blobs** é a
mais forte das duas proteções: ligado, toda sobrescrita guarda o conteúdo anterior como uma **versão**,
automaticamente, sem snapshot para lembrar. Recuperar o primeiro acidente desta lição vira um
`az storage blob list --include v` para achar a versão de antes da sobrescrita, e uma cópia dessa versão por cima do
blob atual. O versionamento responde à sobrescrita, a exclusão reversível responde à deleção, e a conta de estado da
lição 5 tem as duas.
