---
title: Blueprints, e o que os substituiu
version: 1
---

**O Azure Blueprints foi a primeira resposta da Microsoft a "uma assinatura que já começa certa", e
está sendo aposentado.** Um blueprint empacotava um conjunto de artefatos, atribuições de política,
atribuições de papel, grupos de recursos e templates, numa definição com versões, e uma *atribuição*
dele carimbava o conjunto inteiro numa assinatura e podia travar o que criava. Ele nunca saiu de
preview.

A página de aposentadoria da Microsoft, de junho de 2026, dá o cronograma. A data original era julho
de 2026; ela foi estendida e tornada gradual:

| data | o que para |
|---|---|
| 31 de julho de 2026 | criar novas definições e versões de blueprint |
| 31 de outubro de 2026 | mudar definições existentes, e criar novas atribuições |
| 31 de dezembro de 2026 | mudar atribuições existentes |
| 31 de janeiro de 2027 | o próprio serviço: a API, os comandos e as páginas do portal saem, definições não exportadas são apagadas, e as travas de blueprint param de funcionar |

**Este curso foi escrito em 30 de outubro de 2026**, na véspera de as novas atribuições pararem. Os
recursos que um blueprint criou ficam onde estão quando ele sai, destravados. Qualquer coisa num
curso, num artigo antigo ou num script herdado que mande montar uma landing zone com Blueprints está
descrevendo um serviço que, quando você ler isto, não aceita nada novo.

## Dois recursos onde havia um

O Blueprints fazia dois trabalhos, e o substituto da Microsoft os separa:

- **guardar e versionar a definição** vai para os **template specs**, ou simplesmente para um
  repositório Git. Um template spec é um template Bicep ou ARM guardado no Azure como recurso
  próprio, com versões, para que uma equipe possa implantar *a versão 1.2 da rede da plataforma* pelo
  id sem ter o arquivo, e o acesso a ele é controlado por papéis como em qualquer outro recurso;
- **atribuir, gerir o ciclo de vida e travar** vai para os **deployment stacks**.

## Deployment stacks

**Um deployment stack é uma implantação que se lembra do que criou.** Uma implantação comum manda um
template e o esquece: tire um recurso do arquivo e implante de novo, e o recurso fica no Azure, agora
descrito por nada. Um stack guarda a lista dos recursos que gerencia, e duas configurações decidem
para que serve essa lista:

| configuração | valores | decide |
|---|---|---|
| `--action-on-unmanage` | `detachAll`, `deleteResources`, `deleteAll` | o que acontece com um recurso que sai do template, ou com todos quando o stack é apagado: fica no lugar, é apagado, ou é apagado junto com os grupos de recursos que o stack gerencia |
| `--deny-settings-mode` | `none`, `denyDelete`, `denyWriteAndDelete` | se os recursos gerenciados são protegidos por uma **deny assignment**, que recusa apagá-los, ou mudá-los, a todos menos até cinco principais que você nomeia |

A segunda é a trava do Blueprints, feita direito. Uma deny assignment se sobrepõe às atribuições de
papel, que a lição 9 explica: um Owner que não está na lista curta de principais excluídos do stack
ainda assim não consegue apagar o que o `denyDelete` protege.

Stacks existem em três escopos, **um grupo de recursos, uma assinatura e um grupo de
gerenciamento**, e não no tenant. Então a árvore da seção anterior, feita de recursos do nível do
tenant, é implantada do jeito comum, e um stack no grupo de gerenciamento gerencia o que vai nela,
como as atribuições de política da lição 4. A linha de comando conhece toda opção sem conta, como o
`az stack mg create --help` mostra; fazer, não:

```
ana@laptop:~/azure/alz$ az stack mg create --name shop-guardrails --management-group-id shop --location brazilsouth --template-file ../policy/policy.bicep --action-on-unmanage detachAll --deny-settings-mode denyDelete
ERROR: Please run 'az login' to setup account.
```

E um template spec da árvore, para que a equipe de plataforma a publique uma vez, por versão:

```
ana@laptop:~/azure/alz$ az ts create --name ts-shop-alz --version 1.0 --resource-group rg-shop-platform --location brazilsouth --template-file alz.bicep
ERROR: Please run 'az login' to setup account.
```

**Nenhum dos dois foi executado**, pelo motivo de sempre. `detachAll` é a escolha cautelosa para um
primeiro stack: um erro no template deixa recursos sem gestão em vez de apagados, e o stack pode
ficar mais rígido depois de ganhar confiança.
