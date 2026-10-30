---
title: A trava é um lease no blob
version: 1
---

**Dois `apply` escrevendo o mesmo estado ao mesmo tempo é como um arquivo de estado acaba descrevendo nenhum dos
dois.** O Terraform evita isso com uma trava, e a trava do backend `azurerm` é um recurso do próprio Blob Storage: um
**lease**. Um lease é uma posse exclusiva sobre um blob. Enquanto um está ativo, ninguém sem o id dele consegue pegar
outro, sobrescrever o blob ou apagá-lo. Não há tabela de trava separada para criar, como o backend S3 já precisou.

O Azurite implementa leases, então a trava pode ser pega à mão, com as mesmas operações de armazenamento que o backend
emite:

```
ana@laptop:~/azure/tf/release$ az storage blob lease acquire --container-name tfstate --blob-name shop.tfstate --lease-duration -1 -o tsv
4fe580f7-40a3-4ef3-9a24-9acf8ef57588
ana@laptop:~/azure/tf/release$ az storage blob show --container-name tfstate --name shop.tfstate --query properties.lease -o json
{
  "duration": "infinite",
  "state": "leased",
  "status": "locked"
}
ana@laptop:~/azure/tf/release$ az storage blob lease acquire --container-name tfstate --blob-name shop.tfstate --lease-duration -1 -o tsv 2>&1 | grep -E "ErrorCode|already"
ERROR: There is already a lease present.
ErrorCode:LeaseAlreadyPresent
ana@laptop:~/azure/tf/release$ az storage blob upload --container-name tfstate --name shop.tfstate --file terraform.tfstate --overwrite --no-progress -o none 2>&1 | grep -E "ErrorCode|lease"
ERROR: There is currently a lease on the blob and no lease ID was specified in the request.
ErrorCode:LeaseIdMissing
```

O primeiro `acquire` devolveu o id do lease, e o blob agora mostra `leased` e `locked`, sem prazo. O segundo `acquire`
foi recusado com `LeaseAlreadyPresent`: é o que o `terraform plan` de um colega encontra enquanto o seu `apply` roda, e
o Terraform transforma isso na mensagem de que o estado está travado, com quem o segura. O upload sem o id do lease
também foi recusado, e essa é a proteção que de fato importa: **o blob não pode ser sobrescrito por quem não tem o
lease**.

## Quando quem segurava morreu

Uma esteira cancelada no meio de um `apply` pode deixar o lease para trás. A resposta do Terraform é o
`terraform force-unlock` com o id da trava, e neste backend isso **quebra o lease**:

```
ana@laptop:~/azure/tf/release$ az storage blob lease break --container-name tfstate --blob-name shop.tfstate --lease-break-period 0 -o tsv
0
ana@laptop:~/azure/tf/release$ az storage blob show --container-name tfstate --name shop.tfstate --query properties.lease.state -o tsv
broken
```

Quebrar é a ferramenta certa e a perigosa. Ela libera o blob esteja alguém ainda escrevendo nele ou não. Então a
regra da loja é a que o `iac` deu para todo backend: descubra se quem segurava foi mesmo embora (a execução da
esteira, o terminal do colega) antes de quebrar qualquer coisa, e nunca ponha `force-unlock` num retry de esteira.
