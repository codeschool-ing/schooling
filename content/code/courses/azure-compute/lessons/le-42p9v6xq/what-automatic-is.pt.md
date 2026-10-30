---
title: O que o Automatic é, e o que ele já decidiu
version: 1
---

O nome sugere outro produto: um Kubernetes sem nodes, do jeito que os Container Apps da aula 8 são
contêineres sem cluster. **O AKS Automatic é o mesmo AKS com outro SKU.** O API server, o
`kubectl`, um Deployment e um PodDisruptionBudget são os que a aula 11 usou, e funcionam do mesmo
jeito. O que muda é quem toma as decisões que a aula 11 deixou com você, e se você pode mudá-las
depois. Quase todo o `aks.bicep` daquela aula descrevia pools, canais e configurações de surge; um
cluster Automatic não tem nada disso para escrever, porque a Microsoft já escolheu.

## Preconfigured, default, optional

A documentação da Microsoft, lida em 30 de outubro de 2026, classifica cada funcionalidade dos dois
SKUs com três palavras, e a primeira é a que pede leitura cuidadosa:

- preconfigured: sempre ligada, e você não consegue nem desligá-la nem mudar as configurações;
- default: configurada para você, e você pode mudá-la;
- optional: disponível, desligada até você configurar.

No AKS Standard, o SKU que a aula 11 declarou, quase tudo é optional ou default. No Automatic,
boa parte é preconfigured. Estas são as decisões que a aula 11 tomou à mão, e o que o Automatic faz
com cada uma:

| a aula 11 decidiu | no Automatic |
|---|---|
| o tier: Free, Standard ou Premium | **Standard, preconfigured**, com até 5.000 nodes |
| um pool system: tamanho, quantidade, zonas, taint | managed system node pools: o AKS cria, escala e atualiza esses pools, e os hospeda nas assinaturas do próprio AKS |
| pools de usuário: `vmSize`, `count`, `maxPods` | nada a declarar: o node auto-provisioning cria nodes a partir do que os pods pedem, a próxima seção |
| o sistema operacional | Azure Linux nos nodes de sistema, preconfigured; Azure Linux ou Ubuntu nos seus |
| `upgradeChannel` | `stable`, preconfigured: o patch mais recente da versão minor N-1 |
| `nodeOSUpgradeChannel` | `NodeImage`, preconfigured |
| as janelas de manutenção | um default: você ainda define a manutenção planejada |
| o node resource group | totalmente gerenciado e trancado contra mudanças |

**Os nodes de sistema nem estão na sua assinatura.** Na aula 11 eram três máquinas
`Standard_D4s_v5` no node resource group, cobradas de você. No Automatic, a documentação da
Microsoft diz que as máquinas virtuais dos managed system node pools não são cobradas na sua
assinatura, e você não controla cota para elas. Elas rodam o CoreDNS, o metrics server, o KEDA, o
Vertical Pod Autoscaler, o webhook de workload identity e o image cleaner, e você não consegue
agendar um pod seu nelas.

## O que a aula 11 nunca precisou decidir

O resto da lista é o entorno do cluster, e cada item é uma opção no Standard. Num cluster
Automatic, como a documentação descreve:

- rede: uma rede virtual gerenciada com Azure CNI Overlay powered by Cilium, como default; uma
  rede virtual sua, do tipo que a aula 16 de `azure-foundations` construiu, é a opção. O tráfego de
  saída passa por um NAT gateway gerenciado, e o LocalDNS, um proxy de DNS em cada node, é
  preconfigured;
- entrada: a partir do AKS 1.36, clusters novos recebem a Kubernetes Gateway API pelo add-on de
  application routing. Clusters mais antigos recebiam NGINX gerenciado pelo mesmo add-on, e a troca
  acompanha a aposentadoria do Ingress NGINX no projeto original. A aula 14 trata dos dois;
- identidade: o Azure RBAC decide quem pode fazer o quê dentro do cluster, o API server fica
  integrado à rede virtual, e a workload identity com o seu emissor OIDC está ligada. A aula 13 é
  sobre essa última;
- escala de pods: o Horizontal Pod Autoscaler, o KEDA, que a aula 8 usou dentro dos Container
  Apps, e o Vertical Pod Autoscaler estão habilitados;
- política: as deployment safeguards e o Pod Security Standard baseline, ambos aplicados, que
  são o assunto da seção depois da próxima;
- imagens: o image cleaner, que remove dos nodes imagens sem uso com vulnerabilidades
  conhecidas;
- monitoramento: Managed Prometheus para métricas e Container insights para logs, como
  defaults quando o cluster é criado pela CLI ou pelo portal.

## Duas promessas em vez de uma

O tier Standard da aula 11 prometia uma coisa: que o API server responde. O Automatic mantém essa,
99,95%, e acrescenta uma segunda, que só o Automatic tem: **um SLA de prontidão de pods, pelo qual
99,9% das operações qualificadas de prontidão de pod terminam em até cinco minutos**, incluindo o
node que precisa ser criado para elas. Ponha números: se os deployments e a escala do shop pedem
2.000 pods prontos num mês, a promessa vale enquanto no máximo 2 deles demorarem mais de cinco
minutos. Quais operações se qualificam está definido no documento de SLA da Microsoft, não na
documentação do AKS que este curso lê, e por isso esta aula não diz mais do que isso.

## A declaração

O SKU é uma propriedade do cluster, `sku.name`, e os dois valores dela são `Base`, que o
`aks.bicep` da aula 11 escreveu, e `Automatic`. Salve isto como `automatic.bicep`:

```bicep
// automatic.bicep
param location string = 'brazilsouth'

resource aks 'Microsoft.ContainerService/managedClusters@2026-02-01' = {
  name: 'shop-auto'
  location: location
  sku: {
    name: 'Automatic'
    tier: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hostedSystemProfile: {
      enabled: true
    }
  }
}
```

É só isso. `tier: 'Standard'` é o tier que o Automatic escolheria de qualquer jeito, e
`hostedSystemProfile` pede managed system node pools, que um cluster Automatic novo recebe por
padrão; os dois ficam escritos para que quem lê não precise saber os padrões. A versão da API é
`2026-02-01`, a que o quickstart da Microsoft usa; os tipos do compilador para `2026-01-01`, a da
aula 11, não conhecem `hostedSystemProfile` e avisam. O arquivo da aula 11 declarava dois pools com
mais de uma dúzia de linhas cada, e este não declara pool nenhum.

```
ana@laptop:~/azure$ bicep build automatic.bicep
ana@laptop:~/azure$ jq -c '.resources[0] | [.sku, .properties]' automatic.json
[{"name":"Automatic","tier":"Standard"},{"hostedSystemProfile":{"enabled":true}}]
```

Três deslizes de quem escreve de memória: o nome do SKU em minúsculas, como a linha de comando
escreve, o tier Free da tabela da aula 11, e `true` escrito como string. O `sed` grava os três numa
cópia:

```
ana@laptop:~/azure$ sed -e "s/name: 'Automatic'/name: 'automatic'/" -e "s/tier: 'Standard'/tier: 'Free'/" -e "s/enabled: true/enabled: 'true'/" automatic.bicep > slip.bicep
ana@laptop:~/azure$ bicep build slip.bicep
/home/ana/azure/slip.bicep(16,16) : Warning BCP036: The property "enabled" expected a value of type "bool | null" but the provided value is of type "'true'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

Um aviso, para a string no lugar de um booleano. **Os outros dois compilaram em silêncio**: os
tipos de `sku.name` e de `sku.tier` aceitam qualquer string. Se o Azure recusa um cluster
Automatic no tier Free, ou o transforma em Standard sem dizer nada, quem decide é o serviço, e nada
num laptop consegue perguntar a ele. A regra da aula 1 vale aqui como valeu na aula 11: trate todo
aviso como uma recusa, e leia uma compilação limpa como o mínimo de que um arquivo precisa.

## A linha de comando

Numa assinatura, o mesmo cluster é um comando. Ele não rodou aqui, porque precisa de uma:

```sh
az aks create --resource-group shop --name shop-auto --sku automatic --enable-hosted-system
```

A linha de comando escreve o SKU em minúsculas e lista os valores que aceita:

```
ana@laptop:~/azure$ az aks create --help | grep -A5 -- "^    --sku "
    --sku                                                         : Specify SKU name for managed
                                                                    clusters. Use '--sku base'
                                                                    enables a base managed cluster.
                                                                    Use '--sku automatic' enables an
                                                                    automatic managed cluster.
                                                                    Allowed values: automatic, base.
```

O quickstart da Microsoft pede a versão 2.86.0 da CLI ou mais nova, e a 2.91.0 da aula 1 é mais
nova. Ele também pede que você registre antes o resource provider `Microsoft.PolicyInsights` na
assinatura, porque um cluster Automatic liga o Azure Policy, e é de Azure Policy que são feitas as
salvaguardas da seção depois da próxima.
