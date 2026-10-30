---
title: Listas de controle de acesso em diretórios
version: 1
---

**Com o espaço de nomes hierárquico, cada diretório e cada arquivo pode ter sua própria lista de
controle de acesso.** Um principal pode então entrar em `curated/` e ficar fora de `raw/` dentro do
mesmo contêiner. Numa conta plana a menor unidade de permissão é o contêiner; a lição 6 mostra as
ferramentas para isso, chaves compartilhadas e URLs assinadas. Quem conhece Linux espera que as listas
do lake se comportem como as de um sistema de arquivos Linux, e quase sempre se comportam, com duas
diferenças que causam a maior parte das surpresas: um papel atribuído no Azure é conferido antes de
qualquer lista, e uma lista padrão é copiada uma vez, quando um filho é criado, e nunca mais.

Esta seção foi escrita a partir da documentação da Microsoft sobre controle de acesso no Data Lake
Storage e não foi rodada. O Azurite não tem listas, e nenhum emulador confere uma identidade do
Microsoft Entra ID.

## Duas camadas, conferidas em ordem

**Primeiro, o controle de acesso baseado em papéis do Azure.** Um papel como Storage Blob Data Reader,
atribuído na conta ou no contêiner, concede a permissão em tudo abaixo. Se um papel concede a
operação, as listas nem são consultadas. **Depois, as listas**, só para quem nenhum papel deixou
passar. Essa ordem tem uma consequência direta: um papel atribuído amplo demais não pode ser estreitado
por uma lista. Alguém com Storage Blob Data Contributor na conta consegue escrever num diretório cuja
lista diz que não pode. O desenho que funciona dá papéis aos jobs da própria plataforma e põe as
pessoas, em grupos, nas listas.

## O que uma lista guarda

Cada entrada diz quem e o quê, nas três letras que o Linux usa:

| entrada | significa |
|---|---|
| usuário dono, grupo dono | definidos quando o item é criado, como o dono de um arquivo no Linux |
| um usuário, grupo ou service principal nomeado | qualquer um no Microsoft Entra ID, pelo object id |
| mask | o máximo que qualquer entrada nomeada ou o grupo dono pode ter |
| other | todo o resto que chegou ao item |

`r` é ler, `w` é escrever e `x` é executar, que num diretório quer dizer *pode atravessá-lo*. Essa
última letra é a que as pessoas esquecem: **para ler `curated/orders/2026/10.parquet`, um principal
precisa de `x` em `curated`, `orders` e `2026`, e de `r` no arquivo.** Uma lista que dá `r` no arquivo
e nada nos diretórios acima não dá nada.

Todo diretório tem duas listas. A lista de **acesso** decide quem pode usar o próprio diretório. A
lista **padrão** é um modelo: quando um arquivo ou diretório é criado lá dentro, ele começa com uma
cópia dela. Uma cópia, feita uma vez. Mudar a lista padrão depois não muda nada do que já existe, e
pôr os analistas em `curated/` hoje não os deixa entrar nos dez mil arquivos escritos lá ontem. A
Microsoft oferece uma operação recursiva para isso, que percorre a árvore e muda cada item, e ela custa
tempo e operações na proporção dos arquivos. A documentação da Microsoft limita uma lista de acesso a
32 entradas, que é o motivo prático para pôr grupos nas listas em vez de pessoas.

## Declarando uma

O recurso de caminho da seção anterior aceita blocos `ace`, um por entrada. Este arquivo fica ao lado
do `main.tf` em `~/azure/tf/lake`, e o Terraform lê os dois. O id é o object id do grupo dos analistas
no Microsoft Entra ID; o de baixo foi inventado para a lição.

`acl.tf`:

```hcl
resource "azurerm_storage_data_lake_gen2_path" "curated" {
  path               = "curated"
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.lake.name
  storage_account_id = azurerm_storage_account.lake.id
  resource           = "directory"

  ace {
    type        = "group"
    id          = "6f1c2a4e-0b7d-4c55-9e3a-2d8f1b6a7c90"
    permissions = "r-x"
  }
  ace {
    scope       = "default"
    type        = "group"
    id          = "6f1c2a4e-0b7d-4c55-9e3a-2d8f1b6a7c90"
    permissions = "r-x"
  }
}
```

```
ana@laptop:~/azure/tf/lake$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/lake$ sed -i '0,/"r-x"/s//"read"/' acl.tf && terraform validate -no-color

Error: value of ace.1.permissions not valid: Permissions must be of the form [r-][w-][x-]

  with azurerm_storage_data_lake_gen2_path.curated,
  on acl.tf line 1, in resource "azurerm_storage_data_lake_gen2_path" "curated":
   1: resource "azurerm_storage_data_lake_gen2_path" "curated" {

ana@laptop:~/azure/tf/lake$ sed -i '0,/"group"/s//"role"/' acl.tf && terraform validate -no-color

Error: expected ace.1.type to be one of ["user" "group" "mask" "other"], got role

  with azurerm_storage_data_lake_gen2_path.curated,
  on acl.tf line 1, in resource "azurerm_storage_data_lake_gen2_path" "curated":
   1: resource "azurerm_storage_data_lake_gen2_path" "curated" {
```

**Duas entradas para um grupo é o padrão, não repetição.** A primeira, sem `scope`, é a entrada de
acesso: os analistas podem listar `curated/` e atravessá-lo. A segunda é a entrada padrão, para que
todo diretório e arquivo criado lá dentro depois comece com a mesma permissão. Tire a segunda e os
analistas abrem o diretório e nada do que o job noturno escreve nele.

As recusas são conferências do próprio provedor. Permissões são três caracteres na ordem `r`, `w`,
`x`, com um hífen para cada uma negada, e a palavra `read` não é uma delas. O tipo de uma entrada é um
dos quatro que a tabela acima lista. Nada disso diz se o grupo existe ou se o Azure aceitaria a lista,
que é uma pergunta que só uma conta responde.
