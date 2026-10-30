---
title: Node auto-provisioning, o Karpenter rodado pelo AKS
version: 1
---

É natural ler "o Automatic gerencia os nodes" como o cluster autoscaler ligado para você. Essa é
outra máquina. Na aula 11 o pool `apps` fixou o tamanho das suas máquinas, `Standard_D4s_v5`, antes
de alguém saber o que ia rodar ali; o cluster autoscaler, uma opção no Standard, só consegue mudar
quantas delas existem. **O node auto-provisioning começa pela outra ponta: ele olha os pods que não
conseguem ser agendados, calcula um tamanho de máquina virtual que os comportaria, e cria essa
máquina.** A documentação da Microsoft diz que ele é construído sobre o projeto de código aberto
Karpenter e o provider dele para o Azure, e que o AKS implanta, configura e administra o Karpenter
no cluster para você. No Automatic ele é preconfigured; no Standard é uma opção que você liga.

## Três objetos

A documentação nomeia três:

| objeto | quem escreve | o que ele diz |
|---|---|---|
| `NodePool` | você, ou os padrões do AKS | que máquinas podem ser criadas, quantas no total, e quando podem ser removidas |
| `AKSNodeClass` | você, ou os padrões do AKS | a metade Azure de um node: família de imagem, tamanho do disco do SO, `maxPods`, subnet |
| `NodeClaim` | o NAP | um por node que ele criou, o registro do que ele pediu ao Azure |

Os dois primeiros são custom resources, objetos do Kubernetes de tipos que o Kubernetes não traz e
que uma CustomResourceDefinition, um CRD, acrescenta ao API server. Com a configuração padrão, o NAP
cria um NodePool chamado `default`, cujos requisitos permitem máquinas sob demanda da família D,
`amd64`, Linux, e um segundo pool, `system-surge`, para add-ons de sistema que toleram o taint
`CriticalAddonsOnly` da aula 11. **Não existe `vmSize` em lugar nenhum**, e a ideia é exatamente
essa.

## O que o lab consegue mostrar

O kind não roda Karpenter, e nada nele vai criar um node, nunca. Duas metades do mecanismo são
Kubernetes, porém, e essas rodam aqui. Uma é o evento que o NAP espera, um pod que o scheduler não
consegue encaixar. A outra é o API server checando um NodePool contra a definição dele, o que ele
faz do mesmo jeito em qualquer cluster, depois que o CRD está instalado.

O cluster desta aula não tem pools para imitar, então os workers não levam rótulos. Os dois
patches são os da aula 11, pelo mesmo motivo: são necessários numa máquina com cgroup v1, e no
cgroup v2, que é toda distribuição atual e o Docker Desktop, não fazem mal nenhum. Salve por cima do
arquivo da aula 11:

```yaml
# cluster.yaml: one control plane and two workers, with no pools.
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
- role: worker
```

```
ana@laptop:~/azure$ kind create cluster --name shop --config cluster.yaml --quiet
ana@laptop:~/azure$ kubectl wait --for=condition=Ready nodes --all --timeout=120s
node/shop-control-plane condition met
node/shop-worker condition met
node/shop-worker2 condition met
```

A imagem do shop da aula 7 é copiada para os nodes, como na aula 11, para os pods abaixo terem o
que rodar:

```
ana@laptop:~/azure$ kind load docker-image shop:1.0 --name shop
Image: "shop:1.0" with ID "sha256:9d01a6c28e4e4350855a86b4caa7609bef7aed47ab29e015f8c8b0c6def4a254" not yet present on node "shop-worker2", loading...
Image: "shop:1.0" with ID "sha256:9d01a6c28e4e4350855a86b4caa7609bef7aed47ab29e015f8c8b0c6def4a254" not yet present on node "shop-worker", loading...
Image: "shop:1.0" with ID "sha256:9d01a6c28e4e4350855a86b4caa7609bef7aed47ab29e015f8c8b0c6def4a254" not yet present on node "shop-control-plane", loading...
```

## Um pod sem lugar para ir

O relatório noturno de vendas é o trabalho mais pesado do shop. Aqui ele é um pod que pede 12 vCPUs
e 48 GiB, com a imagem do shop no lugar da do relatório, porque é a imagem que estes nodes têm.
Salve como `report.yaml`:

```yaml
# report.yaml: a stand-in for the nightly sales report, which needs a big machine.
apiVersion: v1
kind: Pod
metadata:
  name: report
spec:
  restartPolicy: Never
  containers:
  - name: report
    image: shop:1.0
    imagePullPolicy: IfNotPresent
    resources:
      requests:
        cpu: "12"
        memory: 48Gi
      limits:
        cpu: "12"
        memory: 48Gi
```

```
ana@laptop:~/azure$ kubectl apply -f report.yaml
pod/report created
ana@laptop:~/azure$ kubectl get pod report
NAME     READY   STATUS    RESTARTS   AGE
report   0/1     Pending   0          5s
ana@laptop:~/azure$ kubectl get events --field-selector involvedObject.name=report,reason=FailedScheduling -o custom-columns=REASON:.reason,MESSAGE:.message
REASON             MESSAGE
FailedScheduling   0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu, 2 Insufficient memory. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.
```

**Esse `Pending`, e o evento ao lado, é tudo a que o NAP reage.** O scheduler não achou node com 12
vCPUs e 48 GiB livres, e disse isso: os dois workers são pequenos demais, e o terceiro node é o
control plane, com taint contra todo mundo como na aula 11. Os números da mensagem são deste
laptop, que tem 4 núcleos e 15 GB; numa máquina com mais, o mesmo pod talvez coubesse. No cluster
da aula 11 a resposta seria a mesma. O cluster autoscaler testa um pod pendente no tamanho de cada
pool antes de adicionar um node, e um `Standard_D4s_v5` tem 4 vCPUs, então ele não adicionaria nada
e o relatório esperaria. No Automatic, o NAP lê o request, guarda os tamanhos que os NodePools
permitem e que comportariam o pod com folga para os daemons do próprio node, e cria um, uma série D
com 16 vCPUs, por exemplo. Quando o relatório termina e o node fica vazio, a consolidação o remove.
Aqui ninguém responde, e o pod espera para sempre:

```
ana@laptop:~/azure$ kubectl delete pod report
pod "report" deleted from default namespace
```

## Um NodePool só do shop

O pool do shop, como a API `karpenter.sh/v1` do Karpenter o descreve. Salve como `nodepool.yaml`:

```schooling-example
{"language": "yaml", "file": "nodepool.yaml", "parts": [{"code": "apiVersion: karpenter.sh/v1\nkind: NodePool\nmetadata:\n  name: shop\n", "note": "**Um NodePool é um objeto do Kubernetes, não um recurso do Azure.** Você o escreve com `kubectl`, e nada no Resource Manager sabe que ele existe."}, {"code": "spec:\n  template:\n    spec:\n      nodeClassRef:\n        group: karpenter.azure.com\n        kind: AKSNodeClass\n        name: default\n", "note": "A metade Azure de cada node vem do `AKSNodeClass` chamado `default`, o que o NAP cria junto com os pools padrão."}, {"code": "      requirements:\n      - key: kubernetes.io/arch\n        operator: In\n        values: [\"amd64\"]\n      - key: karpenter.azure.com/sku-family\n        operator: In\n        values: [\"D\", \"E\"]\n      - key: karpenter.azure.com/sku-cpu\n        operator: Lt\n        values: [\"33\"]\n      - key: karpenter.sh/capacity-type\n        operator: In\n        values: [\"on-demand\"]\n", "note": "**Uma faixa de tamanhos, não um tamanho.** Qualquer máquina `amd64` da família D, de uso geral, ou da família E, otimizada para memória, com menos de 33 vCPUs, em capacidade comum. Acrescentar `spot` à última lista permitiria a capacidade despejável da aula 5, e o NAP tenta spot primeiro quando os dois estão permitidos."}, {"code": "      expireAfter: Never\n", "note": "Nenhum node é trocado só por ser velho. A expiração é a única interrupção que os orçamentos abaixo não conseguem segurar, então desligá-la deixa os orçamentos no comando."}, {"code": "  limits:\n    cpu: \"64\"\n    memory: 256Gi\n", "note": "Um teto para tudo o que este pool cria, todos os nodes juntos. É a proteção contra um deployment com um erro de digitação no número de réplicas comprando máquinas a noite toda."}, {"code": "  disruption:\n    consolidationPolicy: WhenEmptyOrUnderutilized\n    consolidateAfter: 0s\n    budgets:\n    - nodes: \"20%\"\n    - nodes: \"0\"\n      schedule: \"0 12 * * *\"\n      duration: 12h\n", "note": "**Quando o NAP pode remover ou trocar um node**: quando ele está vazio ou caberia nos outros, assim que perceber, como está no pool padrão do próprio AKS. No máximo um quinto dos nodes do pool por vez, e nenhum das 12:00 às 24:00 UTC, que são 09:00 às 21:00 em São Paulo, quando o shop está vendendo."}]}
```

O CRD que define esse tipo vem do repositório do próprio provider do Karpenter para o AKS. Esta é a
release `v1.15.1` dele; um cluster AKS traz a versão que o AKS roda nele, que pode ser mais nova.
Baixe e instale, e depois peça ao API server que cheque o pool sem gravá-lo. A definição é
instalada com `kubectl create`, porque é posta ali uma vez e nada aqui a edita:

```
ana@laptop:~/azure$ curl -sLO https://raw.githubusercontent.com/Azure/karpenter-provider-azure/v1.15.1/pkg/apis/crds/karpenter.sh_nodepools.yaml
ana@laptop:~/azure$ kubectl create -f karpenter.sh_nodepools.yaml
customresourcedefinition.apiextensions.k8s.io/nodepools.karpenter.sh created
ana@laptop:~/azure$ kubectl wait --for=condition=Established crd/nodepools.karpenter.sh --timeout=60s
customresourcedefinition.apiextensions.k8s.io/nodepools.karpenter.sh condition met
ana@laptop:~/azure$ kubectl apply --dry-run=server -f nodepool.yaml
nodepool.karpenter.sh/shop created (server dry run)
```

O `--dry-run=server` passa o objeto pela validação e pelo preenchimento de padrões do API server e
não guarda nada. O pool foi aceito, e nada vai agir sobre ele: não há Karpenter aqui para lê-lo.

## O que a definição recusa

Três deslizes, cada um vindo de um lugar por onde quem lê este curso já passou: o rótulo de pool da
aula 11 usado como requisito, o nome da política de consolidação de uma API mais antiga do
Karpenter, e um orçamento acima de 100%.

```
ana@laptop:~/azure$ sed -e 's#karpenter.azure.com/sku-family#kubernetes.azure.com/agentpool#' -e 's/WhenEmptyOrUnderutilized/WhenUnderutilized/' -e 's/"20%"/"120%"/' nodepool.yaml > slips.yaml
ana@laptop:~/azure$ kubectl apply --dry-run=server -f slips.yaml
The NodePool "shop" is invalid: 
* spec.disruption.budgets[0].nodes: Invalid value: "120%": spec.disruption.budgets[0].nodes in body should match '^((100|[0-9]{1,2})%|[0-9]+)$'
* spec.disruption.consolidationPolicy: Unsupported value: "WhenUnderutilized": supported values: "WhenEmpty", "WhenEmptyOrUnderutilized", "Balanced"
* <nil>: Invalid value: null: some validation rules were not checked because the object was invalid; correct the existing errors to complete validation
ana@laptop:~/azure$ sed -e 's#karpenter.azure.com/sku-family#kubernetes.azure.com/agentpool#' nodepool.yaml > slips.yaml
ana@laptop:~/azure$ kubectl apply --dry-run=server -f slips.yaml
The NodePool "shop" is invalid: spec.template.spec.requirements[1].key: Invalid value: "kubernetes.azure.com/agentpool": label domain "kubernetes.azure.com" is restricted
```

A primeira resposta apontou dois dos três, e a última linha dela diz por que parou. As regras
estruturais do CRD, uma lista de valores permitidos e um padrão, são checadas primeiro; as regras
escritas como expressões só rodam num objeto que passou nelas. Com o rótulo como único deslize
restante, a regra de expressão respondeu. **O domínio de rótulos `kubernetes.azure.com` é do próprio
AKS**, e um NodePool só pode exigir o punhado de chaves dele que o NAP conhece; `agentpool` não é
uma delas, porque um node do NAP não pertence a agent pool nenhum. Ao contrário do Bicep, que deixa
passar muitas strings, um CRD pode carregar as regras do próprio serviço, e o API server as aplica a
todo objeto daquele tipo.

Ele não pega tudo. Uma série no lugar de uma família, `Dpls_v6` em vez de `D`, é uma string válida
para a definição:

```
ana@laptop:~/azure$ sed -e 's/\["D", "E"\]/["Dpls_v6"]/' nodepool.yaml > series.yaml
ana@laptop:~/azure$ kubectl apply --dry-run=server -f series.yaml
nodepool.karpenter.sh/shop created (server dry run)
```

Aceito. No AKS esse pool nunca criaria um node. `Dpls_v6` é o nome de uma série, que outra chave
casa, e nenhuma máquina tem isso como família, então os pods que pedissem esse pool ficariam
`Pending` como o relatório ficou. A documentação lista os valores que cada chave aceita; o CRD só
checa se a chave é permitida.

## Quando os nodes vão embora

Um pool que só crescesse seria um cluster autoscaler com mais bom gosto. O Karpenter também remove,
por três métodos que a documentação nomeia:

- consolidação apaga nodes vazios, e apaga ou troca nodes cujos pods caberiam em menos nodes ou
  em nodes mais baratos, com `consolidationPolicy` em `WhenEmpty` ou `WhenEmptyOrUnderutilized`;
- drift troca um node cujo NodePool ou AKSNodeClass mudou desde que ele foi criado: uma família
  de imagem nova, outra subnet, outro disco do SO. Uma configuração mudada num AKSNodeClass nunca é
  aplicada no lugar aos nodes que já rodam;
- expiração troca um node mais velho que o `expireAfter`. É a forçada, e os orçamentos do pool
  não a seguram.

**A consolidação move os seus pods, e é assim que ela economiza.** Um node recebe cordon e drain do
jeito que a aula 11 drenou o `shop-worker2`, e o PodDisruptionBudget do shop é respeitado durante
esse drain, a não ser que o pool defina um `terminationGracePeriod`, que passa por cima dele. Um pod
que não pode ser movido leva a anotação `karpenter.sh/do-not-disrupt: "true"`, que segura a
consolidação e o drift, mas não a expiração.

Os orçamentos limitam quantos nodes podem ser interrompidos ao mesmo tempo. A documentação dá a
conta: as interrupções permitidas são o número de nodes do pool vezes a porcentagem, arredondado
para cima, menos os nodes já sendo apagados e os que não estão prontos. Com 10 nodes e o orçamento
de `20%` acima, um node já sendo apagado e nenhum fora de prontidão, isso dá ceil(10 × 0,2) − 1 − 0
= 1 node a mais. Quando vários orçamentos estão ativos, vence o mais restritivo, e é assim que o
orçamento `0` fecha o horário de vendas do shop. **O horário de um orçamento é em UTC e não pode ser
outra coisa**, a mesma armadilha do `utcOffset` da aula 11, sem um campo para corrigir.

## Comparado com a aula 11

O pod do relatório, respondido por cada máquina:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Duas linhas de quatro passos, um pod pendente respondido de dois jeitos. Linha de cima, um pool fixo com o cluster autoscaler, como na aula 11: o report fica Pending, pedindo 12 CPUs e 48 GiB; o autoscaler o testa no tamanho do pool, Standard_D4s_v5; um node desse tamanho tem 4 vCPUs e não o comporta; ele não adiciona nada, e o report espera até você criar um pool. Linha de baixo, node auto-provisioning: o report fica Pending; o NAP lê os requests e a faixa do NodePool, famílias D e E; ele cria uma máquina que cabe, 16 vCPUs e 64 GiB por exemplo; o report roda, e quando o node fica vazio, a consolidação o remove.\"><text x=\"16\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">um pool fixo, com o cluster autoscaler: aula 11</text><rect x=\"16\" y=\"32\" width=\"160\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"96.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o report fica Pending</text><text x=\"96.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">cpu 12, memory 48Gi</text><line x1=\"176\" y1=\"71.0\" x2=\"188\" y2=\"71.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><path d=\"M187 67.0 L194 71.0 L187 75.0 Z\" fill=\"var(--wire)\"></path><rect x=\"194\" y=\"32\" width=\"160\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"274.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o autoscaler o testa</text><text x=\"274.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">no tamanho do pool</text><text x=\"274.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Standard_D4s_v5</text><line x1=\"354\" y1=\"71.0\" x2=\"366\" y2=\"71.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><path d=\"M365 67.0 L372 71.0 L365 75.0 Z\" fill=\"var(--wire)\"></path><rect x=\"372\" y=\"32\" width=\"160\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"452.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um node desse tamanho</text><text x=\"452.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tem 4 vCPUs e</text><text x=\"452.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">não o comporta</text><line x1=\"532\" y1=\"71.0\" x2=\"544\" y2=\"71.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><path d=\"M543 67.0 L550 71.0 L543 75.0 Z\" fill=\"var(--wire)\"></path><rect x=\"550\" y=\"32\" width=\"160\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"630.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ele não adiciona nada,</text><text x=\"630.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">e o report espera até</text><text x=\"630.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">você criar um pool</text><text x=\"16\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">node auto-provisioning: esta aula</text><rect x=\"16\" y=\"154\" width=\"160\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"96.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o report fica Pending</text><text x=\"96.0\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">cpu 12, memory 48Gi</text><line x1=\"176\" y1=\"193.0\" x2=\"188\" y2=\"193.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><path d=\"M187 189.0 L194 193.0 L187 197.0 Z\" fill=\"var(--wire)\"></path><rect x=\"194\" y=\"154\" width=\"160\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"274.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o NAP lê os requests</text><text x=\"274.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">e a faixa do NodePool</text><text x=\"274.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">sku-family: D, E</text><line x1=\"354\" y1=\"193.0\" x2=\"366\" y2=\"193.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><path d=\"M365 189.0 L372 193.0 L365 197.0 Z\" fill=\"var(--wire)\"></path><rect x=\"372\" y=\"154\" width=\"160\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"452.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ele cria uma máquina</text><text x=\"452.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">que cabe: 16 vCPUs,</text><text x=\"452.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">64 GiB, por exemplo</text><line x1=\"532\" y1=\"193.0\" x2=\"544\" y2=\"193.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><path d=\"M543 189.0 L550 193.0 L543 197.0 Z\" fill=\"var(--wire)\"></path><rect x=\"550\" y=\"154\" width=\"160\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o report roda; quando o</text><text x=\"630.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">node fica vazio, a</text><text x=\"630.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">consolidação o remove</text></svg>", "caption": "Um pod pendente, duas respostas. O autoscaler só consegue adicionar mais do tamanho que o pool já tem, e não adiciona o que não ajudaria; o NAP escolhe o tamanho a partir do pod. O lab rodou a primeira caixa de cada linha e nada depois dela."}
```

| | pools fixos, com o cluster autoscaler | node auto-provisioning |
|---|---|---|
| o tamanho da máquina | um por pool, escolhido de antemão | uma faixa, escolhida para cada leva de pods pendentes |
| o que muda quando há pods pendentes | o número de nodes do pool | quais máquinas existem |
| um pod que nenhum tamanho de pool comporta | fica `Pending` até você criar um pool | ganha uma máquina, se um NodePool permitir |
| remover nodes | nodes que ficaram quase vazios | nodes vazios, e nodes que ele consegue arrumar melhor |
| o que você escreve | pools, em Bicep ou com `az aks nodepool` | NodePools e AKSNodeClasses, com `kubectl` |

A última linha é a que muda o seu dia de trabalho. **O tamanho das suas máquinas sai do Resource
Manager e vai para objetos do Kubernetes**, então ele é revisado, aplicado e quebrado do jeito que um
Deployment é, e não do jeito que um scale set é.
