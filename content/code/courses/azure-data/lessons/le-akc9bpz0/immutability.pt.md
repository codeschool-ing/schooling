---
title: Imutabilidade, a escrita que ninguém desfaz
version: 1
---

**Soft delete e versionamento guardam uma cópia depois de um erro; uma política de imutabilidade
recusa o erro.** Enquanto um blob está sob uma, ele não pode ser sobrescrito nem apagado, por ninguém,
seja qual for o papel ou a chave que a pessoa tenha. O pessoal de armazenamento chama isso de WORM,
write once, read many: escreve uma vez, lê muitas. Existe para registros que uma lei ou um auditor
exige que fiquem exatamente como foram escritos: as regras fiscais brasileiras obrigam a Quitanda a
guardar as notas e os registros por trás delas por anos, e "ninguém mudou" é mais fácil de mostrar
quando ninguém podia.

Esta seção foi escrita a partir da documentação da Microsoft sobre armazenamento imutável e conferida
com o Terraform. O Azurite recusa as duas operações de plano de dados para isso, como mostra a
próxima seção.

## Dois tipos de política

| política | o que faz | como termina |
|---|---|---|
| retenção por tempo | sem sobrescrita e sem exclusão até o blob ter um número de dias | os dias passam |
| legal hold | sem sobrescrita e sem exclusão enquanto a retenção legal estiver posta | alguém a retira |

**Um legal hold não tem data.** É para o processo ou a investigação que vai durar o quanto durar. No
nível do contêiner ele é posto e retirado por tags com nome, para que vários holds possam ficar sobre
os mesmos dados por vários motivos.

**Uma política por tempo é destravada ou travada, e a diferença é tudo.** Destravada, pode ser
encurtada ou apagada, que é como um desenho é testado. Travada, a Microsoft documenta que pode ser
estendida e nunca encurtada nem removida, e que um contêiner ou uma conta com blobs ainda sob uma
política travada não pode ser apagado. É isso que um auditor pede, e é também um compromisso: uma
política travada de sete anos no contêiner errado são sete anos de armazenamento que ninguém consegue
apagar.

Uma política pode ficar sobre um contêiner inteiro, o arranjo mais antigo, ou, com imutabilidade por
versão, sobre versões individuais de blobs. O nível de contêiner basta para um contêiner que só guarda
registros, que é o desenho abaixo.

## O contêiner de auditoria da Quitanda

Salve isto ao lado dos outros dois arquivos:

`audit.tf`:

```hcl
resource "azurerm_storage_container" "audit" {
  name               = "audit"
  storage_account_id = azurerm_storage_account.data.id
}

resource "azurerm_storage_container_immutability_policy" "audit" {
  storage_container_resource_manager_id = azurerm_storage_container.audit.id
  immutability_period_in_days           = 2557
  locked                                = false
}
```

```
ana@laptop:~/azure/tf/protect$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/protect$ sed -i 's/= 2557/= 0/' audit.tf && terraform validate -no-color

Error: expected immutability_period_in_days to be in the range (1 - 146000), got 0

  with azurerm_storage_container_immutability_policy.audit,
  on audit.tf line 8, in resource "azurerm_storage_container_immutability_policy" "audit":
   8:   immutability_period_in_days           = 0
```

**2.557 dias são sete anos**, contando os dois dias bissextos dos próximos sete. O `locked = false` é
de propósito na primeira versão deste arquivo: a política entra destravada, o job de exportação é
testado contra ela, e alguém troca a palavra para `true` numa mudança revisada quando todos
concordarem, porque depois desse apply nada mais volta atrás. A recusa é a faixa do provedor, de 1 a
146.000 dias; zero não é política.

**O que a imutabilidade não faz** é proteger os dados da perda da região da conta, nem da conta a
pagar. Um blob sob uma política continua guardado, continua cobrado e continua onde a replicação da
conta o põe. Travar registros de auditoria também trava o custo deles, mais um motivo para o contêiner
de auditoria guardar os registros e nada mais.
