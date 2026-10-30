---
title: O control plane, e a linha que o AKS traça
version: 1
---

"Kubernetes gerenciado" soa como um cluster que outra pessoa roda para você, inteiro. **O AKS
gerencia uma metade: o control plane.** O API server, o etcd onde fica o estado do cluster, o
scheduler, o controller manager e o cloud controller manager rodam em máquinas que a Microsoft
opera, e a Microsoft os mantém corrigidos e respondendo. Os nodes onde os seus pods rodam são
máquinas virtuais na sua assinatura, cobradas como máquinas virtuais. Qual versão do Kubernetes eles
rodam, quando passam para a próxima e o que acontece com os seus pods enquanto passam são decisões
suas. Esta lição é sobre essa linha, e as três seções depois desta são a metade do seu lado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 410\" role=\"img\" aria-label=\"Duas caixas. À esquerda, máquinas que a Microsoft opera, com o control plane: API server, etcd, scheduler, controller manager e cloud controller manager, cujo tier, Free, Standard ou Premium, decide o que é prometido. À direita, a sua assinatura: o resource group shop com o recurso do cluster, e o node resource group com dois node pools, cada um um scale set de máquinas virtuais cobradas como máquinas virtuais; o pool system tem o taint CriticalAddonsOnly e o pool apps roda o shop. Embaixo, a mesma divisão neste lab: o node shop-control-plane do kind à esquerda, e os workers shop-worker, shop-worker2 e shop-worker3 à direita, que são contêineres do Docker sem scale set por trás.\"><rect x=\"12\" y=\"12\" width=\"250\" height=\"300\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">máquinas que a Microsoft opera</text><rect x=\"28\" y=\"48\" width=\"218\" height=\"186\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"137\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">o control plane</text><rect x=\"40\" y=\"78\" width=\"194\" height=\"24\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"137\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API server</text><rect x=\"40\" y=\"108\" width=\"194\" height=\"24\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"137\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">etcd</text><rect x=\"40\" y=\"138\" width=\"194\" height=\"24\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"137\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">scheduler</text><rect x=\"40\" y=\"168\" width=\"194\" height=\"24\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"137\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">controller manager</text><rect x=\"40\" y=\"198\" width=\"194\" height=\"24\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"137\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cloud controller manager</text><text x=\"137\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o tier decide o que é prometido</text><text x=\"137\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Free · Standard · Premium</text><rect x=\"282\" y=\"12\" width=\"426\" height=\"300\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"296\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">a sua assinatura</text><rect x=\"298\" y=\"48\" width=\"394\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">resource group shop</text><text x=\"680\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o recurso do cluster</text><rect x=\"298\" y=\"100\" width=\"394\" height=\"196\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">node resource group</text><text x=\"680\" y=\"116\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">MC_shop_shop-aks_brazilsouth</text><rect x=\"310\" y=\"132\" width=\"178\" height=\"136\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"399\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um node pool: um scale set</text><text x=\"399\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">system</text><rect x=\"320\" y=\"180\" width=\"50\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"345\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VM</text><rect x=\"374\" y=\"180\" width=\"50\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"399\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VM</text><rect x=\"428\" y=\"180\" width=\"50\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"453\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VM</text><text x=\"399\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">com o taint CriticalAddonsOnly</text><text x=\"399\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">vmss</text><rect x=\"502\" y=\"132\" width=\"178\" height=\"136\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"591\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um node pool: um scale set</text><text x=\"591\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">apps</text><rect x=\"512\" y=\"180\" width=\"50\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"537\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VM</text><rect x=\"566\" y=\"180\" width=\"50\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"591\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VM</text><rect x=\"620\" y=\"180\" width=\"50\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"645\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VM</text><text x=\"591\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">os pods do shop</text><text x=\"591\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">vmss</text><text x=\"495\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cobradas como máquinas virtuais</text><text x=\"12\" y=\"336\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">neste lab, o kind</text><rect x=\"28\" y=\"348\" width=\"218\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"137\" y=\"363\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-control-plane</text><rect x=\"298\" y=\"348\" width=\"126\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"361\" y=\"363\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-worker</text><rect x=\"432\" y=\"348\" width=\"126\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"495\" y=\"363\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-worker2</text><rect x=\"566\" y=\"348\" width=\"126\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"629\" y=\"363\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-worker3</text><text x=\"495\" y=\"394\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">contêineres do Docker, sem scale set por trás</text></svg>", "caption": "A linha que o AKS traça. A caixa da esquerda é da Microsoft para rodar e manter respondendo, pelo tier que você escolheu; a da direita está na sua assinatura e na sua conta. No kind, as duas metades são contêineres no seu laptop, e a da esquerda é sua para quebrar.", "same": ["API server", "scheduler", "controller manager", "cloud controller manager", "Free · Standard · Premium", "resource group shop", "node resource group"]}
```

## O que o tier compra

O control plane tem três tiers de preço, e o que os separa é uma promessa, não uma lista de
funcionalidades. A documentação da Microsoft, lida em 30 de outubro de 2026, os descreve assim:

| tier | para que serve | nodes | SLA de disponibilidade do API server |
|---|---|---|---|
| Free | desenvolvimento, teste e estudo; recomendado abaixo de 10 nodes | até 1.000 | nenhum com garantia financeira, melhor esforço |
| Standard | produção | até 5.000 | 99,95% com availability zones, 99,9% sem |
| Premium | produção que precisa ficar dois anos numa versão do Kubernetes | até 5.000 | como o Standard, mais suporte de longo prazo |

**No tier Free o control plane não custa nada e não promete nada.** Toda funcionalidade do AKS está
lá; o que falta é um compromisso, com dinheiro por trás, de que o API server responde. Standard e
Premium são cobrados por cluster e por hora, e este curso não cita preço do Azure: a página de
preços, ou a Retail Prices API da lição 1, é onde ler.

O SLA cobre o API server e mais nada. Um cluster Standard com todos os nodes numa zona tem um control
plane que continua respondendo enquanto essa zona está apagada e todo pod nela está fora, e a
promessa foi cumprida. A aritmética da lição 6 vale para o que ele promete: 99,95% de um mês de 730
horas deixa 0,05% × 730 = 0,365 hora, uns 22 minutos, em que o API server pode ficar inacessível sem
que a promessa seja quebrada.

A linha de comando descreve os tiers na própria ajuda, que é texto real desta versão da CLI e não
precisa de conta:

```
ana@laptop:~/azure$ az aks upgrade --help | grep -A4 -- "^    --tier"
    --tier                         : Specify SKU tier for managed clusters. '--tier standard'
                                     enables a standard managed cluster service with a financially
                                     backed SLA. '--tier free' does not have a financially backed
                                     SLA. '--tier premium' is required for '--k8s-support-plan
                                     AKSLongTermSupport'.  Allowed values: free, premium, standard.
```

A última frase é a ligação com a seção sobre upgrades: o suporte de longo prazo, um segundo ano
numa versão do Kubernetes, só existe no Premium.

## O que continua seu

Quando o AKS cria um cluster, cria também um segundo resource group, o **node resource group**, e
põe nele a infraestrutura do cluster: os scale sets, as máquinas virtuais deles, os discos. O nome
de exemplo da Microsoft para um é `MC_aks_myAKSCluster_westus2`, o prefixo `MC_` seguido do
resource group do cluster, do nome dele e da região. Essas máquinas são cobradas como as máquinas
virtuais das lições 1 a 4. Acima delas fica tudo o que o Kubernetes deixa para quem roda a carga:
quantas réplicas o shop tem, se ele avisa quando está pronto e quanto dele pode ser parado de uma
vez. **Um upgrade administrado pela Microsoft ainda move cada um dos seus pods**, e se o shop percebe
é decidido por essas três coisas, que são suas.

## O lab: o kind, que não é o AKS

As lições 11 a 14 rodam um cluster Kubernetes na sua máquina com o kind e falam com ele pelo
`kubectl`, os dois como o curso `kubernetes` os instalou na lição 1 dele. Se você guardou aquela
máquina, não há nada a instalar; se não, a seção de instalação daquela lição é o lugar para voltar.
As transcrições foram gravadas com este kind:

```
ana@laptop:~/azure$ kind version
kind v0.33.0 go1.24.7 linux/amd64
```

Mantenha o `kubectl` a no máximo uma versão minor do cluster, o que a lição 5 do curso `kubernetes`
explica; o cluster abaixo roda a 1.37.

**O kind não é o AKS.** É o Kubernetes que o AKS roda, o mesmo API server, scheduler e kubelet, em
contêineres do Docker no seu laptop. O control plane da Microsoft não está lá, nem os node pools e os
scale sets por trás deles, a orquestração de um upgrade ou a maintenance configuration. O que ele
deixa praticar é a metade que o próprio Kubernetes faz: nodes com rótulos e taints como o AKS os
escreve, o cordon e o drain que o AKS faz em cada node que atualiza, e um PodDisruptionBudget
respondendo sim ou não. Tudo o que a Microsoft acrescenta em volta disso é ensinado pela
documentação dela, e as seções dizem o que é o quê.

O cluster tem um control plane e três workers. Os rótulos nos workers são o assunto da próxima
seção; salve o arquivo como `cluster.yaml`:

```yaml
# cluster.yaml: one control plane and three workers, labelled the way AKS
# labels the nodes of two node pools.
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri"]
    restrict_oom_score_adj = true
kubeadmConfigPatches:
- |
  kind: KubeletConfiguration
  failCgroupV1: false
nodes:
- role: control-plane
- role: worker
  labels:
    kubernetes.azure.com/agentpool: system
    kubernetes.azure.com/mode: system
- role: worker
  labels:
    kubernetes.azure.com/agentpool: apps
    kubernetes.azure.com/mode: user
- role: worker
  labels:
    kubernetes.azure.com/agentpool: apps
    kubernetes.azure.com/mode: user
```

Os dois patches perto do topo são necessários numa máquina com cgroup v1, que é onde estas
transcrições foram gravadas. No cgroup v2, que é toda distribuição atual e o Docker Desktop, os dois
patches não fazem mal, e as lições do curso `kubernetes` carregam os mesmos dois. Crie o cluster e
espere pelos nodes:

```
ana@laptop:~/azure$ kind create cluster --name shop --config cluster.yaml --quiet
ana@laptop:~/azure$ kubectl wait --for=condition=Ready nodes --all --timeout=120s
node/shop-control-plane condition met
node/shop-worker condition met
node/shop-worker2 condition met
node/shop-worker3 condition met
```

## A metade pela qual você pagaria

No kind, o control plane é um node como os outros, e o que roda nele pode ser listado:

```
ana@laptop:~/azure$ kubectl get pods -n kube-system --field-selector spec.nodeName=shop-control-plane -o name
pod/coredns-559f6c778d-v7jcw
pod/coredns-559f6c778d-z7hpf
pod/etcd-shop-control-plane
pod/kindnet-zvdxs
pod/kube-apiserver-shop-control-plane
pod/kube-controller-manager-shop-control-plane
pod/kube-proxy-n2jzw
pod/kube-scheduler-shop-control-plane
```

O etcd, o API server, o controller manager e o scheduler são pods no `shop-control-plane`, ao lado
dos dois DaemonSets que todo node roda, e nesta execução também o CoreDNS, que tolera o taint do
control plane. **No AKS, nenhum daqueles quatro está num node que você possa listar.** Eles rodam do
lado da Microsoft da linha, o `kubectl get nodes` mostra só as máquinas virtuais dos seus node pools,
e o tier é o que você paga para que continuem respondendo. Neste lab o control plane é seu para
quebrar, e é também por isso que nada aqui consegue mostrar o que faz a versão da Microsoft.

O cluster AKS que esta lição declara se chama `shop-aks`, num resource group `shop`. Perguntar ao
Azure sobre ele dá a resposta que a lição 1 explicou:

```
ana@laptop:~/azure$ az aks show --resource-group shop --name shop-aks
ERROR: Please run 'az login' to setup account.
```

Essa recusa é o que todo comando `az aks` que precisa de uma assinatura responde neste curso. Esses
comandos aparecem onde cabem, marcados como não executados, sem saída.
