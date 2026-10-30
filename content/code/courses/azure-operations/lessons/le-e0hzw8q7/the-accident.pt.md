---
title: O acidente, passo a passo
version: 1
---

**O arquivo de estado é a memória do Terraform, e o Azure não sabe nada dele.** Todo recurso que o Terraform gerencia
está mapeado, nesse arquivo, de um endereço na configuração, `azurerm_resource_group.shop`, para um id no Azure. Perca
o arquivo e os recursos continuam rodando; o que se perde é o mapa.

O laboratório refaz a situação da lição 6: um estado real, escrito pelo `terraform apply`, enviado ao contêiner
`tfstate` no Azurite. Esta configuração também guarda uma cópia do estado localmente, então o `plan` dela mostra o que
o Terraform conclui de cada versão do arquivo. No começo, ele concorda com o mundo:

```
ana@laptop:~/azure/tf/release$ terraform plan -no-color | grep -m1 "No changes"
No changes. Your infrastructure matches the configuration.
```

Antes que algo dê errado, um hábito: **um snapshot**, uma cópia somente leitura do blob num ponto do tempo, tirada aqui
à mão e, na prática, pela esteira antes de todo `apply`:

```
ana@laptop:~/azure/tf/release$ az storage blob snapshot --container-name tfstate --name shop.tfstate --query snapshot -o tsv
2026-10-30T18:22:54.9190000Z
```

Agora o acidente. Os reais mais comuns são um `terraform init -migrate-state` apontado para a chave errada, o
diretório de trabalho vazio de um colega empurrando o estado dele por cima do seu, ou um script que "limpa" um
contêiner. Aqui é o segundo, feito à mão: um estado vazio enviado por cima do real.

```
ana@laptop:~/azure/tf/release$ echo '{"version": 4, "serial": 1, "resources": []}' > empty.tfstate
ana@laptop:~/azure/tf/release$ az storage blob upload --container-name tfstate --name shop.tfstate --file empty.tfstate --overwrite --no-progress -o none
ana@laptop:~/azure/tf/release$ az storage blob list --container-name tfstate --include s --query "[].{snapshot:snapshot, size:properties.contentLength}" -o table
Size    Snapshot
------  ----------------------------
45
861     2026-10-30T18:22:54.9190000Z
```

O blob agora tem 45 bytes. O snapshot ainda guarda os 861 bytes do estado real. E é isto que o Terraform conclui do
arquivo vazio:

```
ana@laptop:~/azure/tf/release$ cp terraform.tfstate saved.tfstate && cp empty.tfstate terraform.tfstate
ana@laptop:~/azure/tf/release$ terraform plan -no-color | grep -E "will be created|Plan:"
  # terraform_data.release will be created
Plan: 1 to add, 0 to change, 0 to destroy.
```

**O Terraform propõe criar algo que existe.** Para `terraform_data` isso é inofensivo; para a loja, não. Aplicado
contra o Azure, um plano assim falha no primeiro recurso cujo nome está ocupado, `rg-shop already exists`, e esse é o
caso de sorte. O caso de azar é um recurso de nome gerado, que o Terraform cria uma segunda vez ao lado do primeiro, e
daí em diante os dois são cobrados e só um é gerenciado.
