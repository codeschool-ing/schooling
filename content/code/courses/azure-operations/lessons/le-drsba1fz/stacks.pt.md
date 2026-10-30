---
title: Deployment stacks: os recursos que um arquivo possui
version: 1
---

**Um deploy ARM comum esquece o que criou.** Ele é um evento: o próximo deploy do mesmo arquivo compara o template
com o que existe, mas nada lembra que um recurso veio deste arquivo e depois foi tirado dele. É o Ignore da seção
anterior, e é assim que um grupo de recursos se enche de coisas que ninguém sabe explicar.

**Uma deployment stack é um recurso que lembra.** Ela implanta um template como qualquer deploy e depois guarda a
lista dos recursos que gerencia. Implante de novo com um recurso tirado do arquivo, e a stack sabe que aquele
recurso agora está **fora de gestão**, e faz o que você mandou. O comando **não foi executado**, porque uma stack é
ela mesma um recurso numa assinatura:

```sh
az stack group create --name shop --resource-group rg-shop \
  --template-file main.bicep --parameters main.prod.bicepparam \
  --action-on-unmanage deleteResources \
  --deny-settings-mode denyDelete
```

**`--action-on-unmanage`** diz o que acontece com um recurso que sai do arquivo: `detachAll` o deixa no Azure e
para de gerenciá-lo, que é o padrão seguro e o mesmo comportamento de um deploy comum; `deleteResources` o apaga;
`deleteAll` apaga também grupos de recursos. A loja usa `deleteResources` no grupo de recursos da aplicação, onde
tudo deve vir do arquivo, e nunca no que guarda a conta do estado do Terraform.

**`--deny-settings-mode`** protege os recursos gerenciados de mudanças por fora da stack. `denyDelete` recusa
apagá-los por qualquer outro caminho, o portal incluído; `denyWriteAndDelete` recusa também alterá-los. Uma lista
de principais excluídos, como a identidade da esteira, mantém os deploys da própria stack funcionando. Essa é a
defesa contra o desvio que o what-if aponta: a mudança à mão é recusada na porta, em vez de descoberta depois.

Stacks se sobrepõem ao estado do Terraform, que é o assunto das lições 6 e 7, e a comparação vale a pena. Os dois
guardam uma lista do que uma configuração possui. O Terraform a guarda num arquivo que você armazena e protege;
uma stack a guarda no Azure, como recurso. Nenhum está errado, e uma equipe escolhe um dos dois por grupo de
recursos, e não os dois.
