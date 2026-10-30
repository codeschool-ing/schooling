---
title: Node pools, system e user, e o scale set por trás de cada um
version: 1
---

Um cluster de laptop tem nodes, e é fácil levar essa imagem adiante: um cluster é um conjunto de
máquinas intercambiáveis. **No AKS os nodes vêm em node pools, e o pool é a unidade de toda decisão
sobre eles.** Um pool tem um tamanho de máquina virtual, um sistema operacional, um conjunto de
rótulos e taints, uma configuração de upgrade e um scale set por trás. A documentação da Microsoft
diz que os node pools usam Virtual Machine Scale Sets por padrão, os scale sets da lição 4, com o
AKS administrando-os por você. O nome de node de exemplo dela mostra o arranjo:
`aks-nodepool1-12345678-vmss000001` é a instância `000001` do scale set por trás do pool
`nodepool1`. Para dar máquinas maiores ao shop você não redimensiona um node; você adiciona um pool.

## System e user

Todo pool tem um **modo**. Um pool *system* existe para rodar os pods do próprio cluster, entre eles
o CoreDNS e o metrics server; um pool *user* roda as suas aplicações. Um cluster precisa de pelo menos
um pool system, e o pool criado junto com o cluster é system. A documentação da Microsoft, lida em 30
de outubro de 2026, impõe mais restrições a um pool system do que a um user:

- ele roda Linux, Ubuntu ou Azure Linux, nunca Windows;
- ele tem pelo menos dois nodes, e três são o recomendado;
- as máquinas virtuais dele têm pelo menos 4 vCPUs e 4 GB de memória, e a série B da lição 1 não é
  permitida;
- ele tem espaço para pelo menos 30 pods;
- ele não pode rodar em capacidade Spot, o que só um pool user pode.

O AKS rotula cada node com o pool e o modo dele, `kubernetes.azure.com/agentpool` e
`kubernetes.azure.com/mode`, e prefere agendar pods de sistema em nodes rotulados `system`. Uma
preferência é tudo o que isso é. **O rótulo não mantém os seus pods fora de um pool system; um taint
mantém**, e a documentação dá o nome dele: `CriticalAddonsOnly=true:NoSchedule`. O Kubernetes então
agenda nesse pool só os pods que toleram o taint, e os pods de sistema toleram.

## Os dois pools, no kind

O `cluster.yaml` da seção anterior deu ao primeiro worker os rótulos de um pool system e aos outros
dois os de um pool chamado `apps`, em modo user. Essa é a metade que o kind consegue reproduzir: os
rótulos são rótulos comuns do Kubernetes, e o API server não se importa com quem os escreveu.

```
ana@laptop:~/azure$ kubectl get nodes -L kubernetes.azure.com/agentpool,kubernetes.azure.com/mode
NAME                 STATUS   ROLES           AGE   VERSION   AGENTPOOL   MODE
shop-control-plane   Ready    control-plane   32s   v1.37.0               
shop-worker          Ready    <none>          19s   v1.37.0   system      system
shop-worker2         Ready    <none>          18s   v1.37.0   apps        user
shop-worker3         Ready    <none>          19s   v1.37.0   apps        user
```

O que o kind não consegue reproduzir é o pool em si. Os três workers são contêineres do Docker que o
kind subiu, não instâncias de um scale set, e não existe em lugar nenhum um objeto `apps` que possa
ser redimensionado ou atualizado como um só. No AKS o taint seria declarado no pool quando ele é
criado e escrito pelo AKS em cada node que ele adiciona; aqui ele é posto à mão no único node:

```
ana@laptop:~/azure$ kubectl taint nodes shop-worker CriticalAddonsOnly=true:NoSchedule
node/shop-worker tainted
ana@laptop:~/azure$ kubectl get nodes -o custom-columns=NODE:.metadata.name,TAINTS:.spec.taints[*].key
NODE                 TAINTS
shop-control-plane   node-role.kubernetes.io/control-plane
shop-worker          CriticalAddonsOnly
shop-worker2         <none>
shop-worker3         <none>
```

O `shop-control-plane` tem um taint próprio, que é como o kind mantém as cargas fora do control
plane dele. No AKS não existe esse node para receber taint. O CoreDNS, que o kind instala, já tolera
o taint do pool system, do mesmo jeito que os pods de sistema no AKS toleram:

```
ana@laptop:~/azure$ kubectl get deployment coredns -n kube-system -o jsonpath='{range .spec.template.spec.tolerations[*]}{.key}{" "}{.operator}{"\n"}{end}'
CriticalAddonsOnly Exists
node-role.kubernetes.io/control-plane 
```

## O shop, no pool user

A imagem do shop é a que a lição 7 construiu, `shop:1.0`. Um node do kind não enxerga as imagens da
sua máquina, então o primeiro passo a copia para cada node; no AKS os nodes a baixariam do registry
da lição 10:

```
ana@laptop:~/azure$ kind load docker-image shop:1.0 --name shop
Image: "shop:1.0" with ID "sha256:37ebdc55856893f0e92d36aa5e2f2d3dfe9562b28b868f95e3915a03f99beb8f" not yet present on node "shop-control-plane", loading...
Image: "shop:1.0" with ID "sha256:37ebdc55856893f0e92d36aa5e2f2d3dfe9562b28b868f95e3915a03f99beb8f" not yet present on node "shop-worker2", loading...
Image: "shop:1.0" with ID "sha256:37ebdc55856893f0e92d36aa5e2f2d3dfe9562b28b868f95e3915a03f99beb8f" not yet present on node "shop-worker", loading...
Image: "shop:1.0" with ID "sha256:37ebdc55856893f0e92d36aa5e2f2d3dfe9562b28b868f95e3915a03f99beb8f" not yet present on node "shop-worker3", loading...
```

Antes de o shop chegar, o `shop-worker3` recebe cordon, que o marca como não agendável e não move
nada. Na seção sobre upgrades ele faz o papel do node de surge que o AKS adiciona no começo de um
upgrade, e até lá nada deve rodar nele:

```
ana@laptop:~/azure$ kubectl cordon shop-worker3
node/shop-worker3 cordoned
```

O manifesto é o Deployment do curso `kubernetes` com três linhas a mais. Salve como `shop.yaml`:

```yaml
# shop.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 3
  selector:
    matchLabels:
      app: shop
  template:
    metadata:
      labels:
        app: shop
    spec:
      nodeSelector:
        kubernetes.azure.com/agentpool: apps
      containers:
      - name: shop
        image: shop:1.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8080
          periodSeconds: 2
```

O `nodeSelector` manda cada réplica para um node do pool `apps`, pelo rótulo que o AKS escreve; é
assim que uma carga pede um pool no AKS também, e a lição 29 do curso `kubernetes` ensina o seletor
por inteiro. O `imagePullPolicy: IfNotPresent` usa a cópia que foi carregada em vez de pedir a um
registry. A readiness probe pergunta ao `/healthz` do shop a cada dois segundos, e importa mais do
que parece: um pod só conta como disponível depois de pronto, e é isso que o orçamento da próxima
seção conta.

```
ana@laptop:~/azure$ kubectl apply -f shop.yaml
deployment.apps/shop created
ana@laptop:~/azure$ kubectl rollout status deployment/shop --timeout=120s
Waiting for deployment "shop" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "shop" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "shop" rollout to finish: 2 of 3 updated replicas are available...
deployment "shop" successfully rolled out
ana@laptop:~/azure$ kubectl get pods -o custom-columns=POD:.metadata.name,NODE:.spec.nodeName,READY:.status.containerStatuses[0].ready
POD                     NODE           READY
shop-7d76d574f5-9q8dk   shop-worker2   true
shop-7d76d574f5-qbm4n   shop-worker2   true
shop-7d76d574f5-zdmpb   shop-worker2   true
```

**As três réplicas estão no `shop-worker2`**: o node system tem taint contra elas, o control plane tem
taint contra todo mundo e o `shop-worker3` está com cordon.

## Os mesmos pools em Bicep

No Azure, os dois pools fazem parte da declaração do cluster. Salve isto como `aks.bicep`:

```schooling-example
{"language": "bicep", "file": "aks.bicep", "parts": [{"code": "// aks.bicep\nparam location string = 'brazilsouth'\n\nresource aks 'Microsoft.ContainerService/managedClusters@2026-01-01' = {\n  name: 'shop-aks'\n  location: location\n", "note": "**O cluster, como o Resource Manager o nomeia**: `Microsoft.ContainerService/managedClusters`, chamado `shop-aks`, em São Paulo. A primeira linha é um comentário com o nome do arquivo."}, {"code": "  sku: {\n    name: 'Base'\n    tier: 'Standard'\n  }\n", "note": "**O tier da seção anterior.** `Standard` compra o SLA de disponibilidade do API server; `Free` e `Premium` são os outros dois valores."}, {"code": "  identity: {\n    type: 'SystemAssigned'\n  }\n", "note": "**A identidade do próprio cluster**, uma managed identity da lição 8 de `azure-foundations`, que o AKS usa para criar os scale sets e os discos no node resource group."}, {"code": "  properties: {\n    kubernetesVersion: '1.36'\n    dnsPrefix: 'shop'\n    autoUpgradeProfile: {\n      upgradeChannel: 'stable'\n      nodeOSUpgradeChannel: 'NodeImage'\n    }\n", "note": "**A versão, e quem a move.** `1.36` é a versão minor em que o cluster começa; os dois canais são o assunto da última seção desta lição, e decidem se o AKS atualiza o cluster e as imagens dos nodes por conta própria."}, {"code": "    agentPoolProfiles: [\n      {\n        name: 'system'\n        mode: 'System'\n        count: 3\n        vmSize: 'Standard_D4s_v5'\n        osType: 'Linux'\n        osSKU: 'AzureLinux'\n        availabilityZones: [ '1', '2', '3' ]\n        nodeTaints: [ 'CriticalAddonsOnly=true:NoSchedule' ]\n        upgradeSettings: {\n          maxSurge: '1'\n        }\n      }\n", "note": "**O pool system**: três nodes de 4 vCPUs, um em cada zona, em Azure Linux, com o taint que mantém o shop fora. `maxSurge` é um node a mais durante um upgrade, o padrão, escrito para que quem lê não precise sabê-lo."}, {"code": "      {\n        name: 'apps'\n        mode: 'User'\n        count: 3\n        vmSize: 'Standard_D4s_v5'\n        osType: 'Linux'\n        osSKU: 'Ubuntu'\n        maxPods: 110\n        availabilityZones: [ '1', '2', '3' ]\n", "note": "**O pool user `apps`**, onde o shop roda: Ubuntu, e `maxPods` fixo em 110 enquanto o pool existir."}, {"code": "        upgradeSettings: {\n          maxSurge: '33%'\n          drainTimeoutInMinutes: 30\n          nodeSoakDurationInMinutes: 5\n          undrainableNodeBehavior: 'Cordon'\n        }\n      }\n    ]\n  }\n}\n", "note": "**Como este pool é atualizado**, uma configuração por linha, cada uma explicada na próxima seção: quantos nodes a mais, quanto tempo um drain pode levar, quanto esperar depois de um, e o que fazer com um node que não pode ser drenado."}]}
```

Ele compila sem avisos, e o template carrega os dois pools:

```
ana@laptop:~/azure$ bicep build aks.bicep
ana@laptop:~/azure$ jq -c '.resources[0].properties.agentPoolProfiles[] | [.name, .mode, .count, .osSKU]' aks.json
["system","System",3,"AzureLinux"]
["apps","User",3,"Ubuntu"]
```

**O compilador confere algumas regras de um pool e outras não.** Aqui está o mesmo arquivo com três
deslizes que uma pessoa comete: um nome de pool com hífen, o modo em minúsculas e mais pods por node
do que o AKS permite. O `sed` escreve os deslizes numa cópia, então o `aks.bicep` fica como estava:

```
ana@laptop:~/azure$ sed -e "s/name: 'apps'/name: 'shop-apps'/" -e "s/mode: 'System'/mode: 'system'/" -e 's/maxPods: 110/maxPods: 300/' aks.bicep > slip.bicep
ana@laptop:~/azure$ bicep build slip.bicep
/home/ana/azure/slip.bicep(36,15) : Warning BCP416: The supplied string does not match the expected pattern of /$^[a-z][a-z0-9]{0,11}$/. [https://aka.ms/bicep/core-diagnostics#BCP416]
```

Um aviso, o do nome: o tipo carrega o padrão `^[a-z][a-z0-9]{0,11}$`, que é a regra documentada de
letras minúsculas e dígitos, doze no máximo. Os outros dois passaram em silêncio. O tipo de `mode`
é qualquer string, sem lista de valores, e o tipo de `maxPods` é um número sem teto,
enquanto o máximo documentado é 250, como diz o fim desta seção. Se o Azure aceita `system` no lugar
de `System` é o serviço quem decide, e um laptop não tem como descobrir. Então a regra da lição 1
continua valendo, e tem uma segunda metade: **compilar limpo é o mínimo de que uma declaração
precisa, não a prova de que ela está certa.**

A linha de comando lista os valores que aceita, e o padrão:

```
ana@laptop:~/azure$ az aks nodepool add --help | grep -A4 -- "--mode "
    --mode                               : The mode for a node pool which defines a node pool's
                                           primary function. If set as "System", AKS prefers system
                                           pods scheduling to node pools with mode `System`. Learn
                                           more at https://aka.ms/aks/nodepool/mode.  Allowed
                                           values: Gateway, System, User.  Default: User.
```

## O que um pool fixa quando é criado

Algumas configurações pertencem ao pool para sempre. A mais clara é o `maxPods`, o máximo de pods que
um node vai rodar, que não pode ser mudado depois que o pool existe. O padrão depende do plugin de
rede do cluster, a peça que dá a cada pod um endereço na rede da lição 16 de `azure-foundations`:

| plugin de rede | `maxPods` padrão |
|---|---|
| Azure CNI Overlay | 250 |
| Azure CNI com subnet de pods | 110 |
| Azure CNI, o modo legado | 30 |
| kubenet | 110 |

A faixa documentada vai de 10 a 250, e **aumentá-lo significa um pool novo**: adicione um com o
valor que você quer, mova as cargas, apague o antigo. O sistema operacional é escolhido com o
`osSKU`: `Ubuntu` é o padrão e `AzureLinux` é a distribuição da própria Microsoft, feita para rodar
contêineres. A capacidade Spot, o eviction da lição 5, é um pool user com o `scaleSetPriority` em
`Spot`, e um pool desse tipo nunca pode ser o pool system.
