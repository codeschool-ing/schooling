---
title: O que o compilador pega, e o linter ao lado
version: 1
---

Dois erros de propósito, cada um numa cópia de `shop.bicep`. Em `typo.bicep` o SKU é `Standard_LRSS` e a versão
de TLS é `TLS1_3`, que não é um valor que a API de armazenamento ofereça. Em `typo2.bicep` a saída lê
`primaryEndpoint`, sem o `s` final:

```
ana@laptop:~/azure/bicep$ bicep build typo.bicep
ana@laptop:~/azure/bicep$ echo $?
0
ana@laptop:~/azure/bicep$ bicep build typo2.bicep
/home/ana/azure/bicep/typo2.bicep(26,49) : Warning BCP083: The type "StorageAccountPropertiesCreateParametersOrStorageAccountProperties" does not contain property "primaryEndpoint". Did you mean "primaryEndpoints"? [https://aka.ms/bicep/core-diagnostics#BCP083]
ana@laptop:~/azure/bicep$ echo $?
0
```

**O primeiro compilou limpo, e o segundo compilou com um aviso.** Os dois merecem leitura lenta. O SKU e a
versão de TLS estão tipados como strings no esquema que o Bicep tem para esta versão da API, então qualquer
string passa, e quem vai recusá-los é o Resource Manager, no deploy, depois que a esteira já ficou verde. A
propriedade escrita errado é pega porque a forma das propriedades de uma conta de armazenamento é conhecida, e
o Bicep ainda sugere o nome certo. Mas é um **aviso**, o código de saída continua 0, e uma esteira que só olha o
código de saída a entrega.

Daí saem dois hábitos. Numa esteira, rode o Bicep de modo que avisos façam o passo falhar, e leia cada aviso na
primeira vez que aparecer, em vez de aprender a rolar por cima deles. E nunca tome uma compilação limpa como
prova de que um valor está certo; ela prova que o arquivo tem a forma certa.

## O linter

`bicep lint` roda as verificações do compilador mais um conjunto de regras sobre prática, e não sobre sintaxe.
Este arquivo tem dois problemas com que um compilador não teria motivo para se importar:

```bicep
// lint.bicep
param accountName string
param environment string

resource account 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: accountName
  location: 'brazilsouth'
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
  }
}

output connection string = 'DefaultEndpointsProtocol=https;AccountName=${accountName};AccountKey=${account.listKeys().keys[0].value}'
```

```
ana@laptop:~/azure/bicep$ bicep lint lint.bicep
/home/ana/azure/bicep/lint.bicep(3,7) : Warning no-unused-params: Parameter "environment" is declared but never used. [https://aka.ms/bicep/linter-diagnostics#no-unused-params]
/home/ana/azure/bicep/lint.bicep(15,100) : Warning outputs-should-not-contain-secrets: Outputs should not contain secrets. Found possible secret: function 'listKeys' [https://aka.ms/bicep/linter-diagnostics#outputs-should-not-contain-secrets]
ana@laptop:~/azure/bicep$ echo $?
0
```

`no-unused-params` pegou um parâmetro que ninguém lê, o que num template quer dizer que um dia alguém vai
passar um valor e se perguntar por que nada mudou. **`outputs-should-not-contain-secrets` pegou o grave**: a
saída monta uma connection string com a chave da conta, e as saídas de um deploy ficam guardadas no histórico
de deploys, legíveis por qualquer um com leitura no grupo de recursos. As regras são ligadas, desligadas ou
promovidas a erro num `bicepconfig.json` ao lado dos arquivos, e a loja promove essa segunda regra a erro para
ela quebrar o build.

Repare que o local escrito como literal, `'brazilsouth'`, não levantou nada. A regra para isso,
`no-hardcoded-location`, existe e fica desligada a menos que o `bicepconfig.json` a ligue. Um linter é só as
regras que mandaram ele rodar.
