---
title: Karpenter, que escolhe a máquina para os pods
version: 1
---

Um node group fixa a máquina antes de alguém saber o que vai rodar nela: `m7g.large`, entre 2 e 6
delas. Quando chegam pods que precisam de outra coisa, o grupo só consegue acrescentar mais do mesmo.
**O Karpenter começa pela outra ponta. Ele olha os pods que não conseguem ser agendados, calcula que
máquina os comportaria e pede essa máquina direto ao EC2**, sem Auto Scaling group no meio. É um
projeto open source que a AWS começou, e roda dentro do cluster como um Deployment comum.

Nada nesta seção foi rodado contra um cluster, porque o moto não roda Kubernetes e o Karpenter não
tem onde rodar. Os dois arquivos aparecem inteiros, como a documentação do Karpenter os descreve, e a
única chamada à AWS que o Karpenter faz é rodada contra o moto mais abaixo.

## O que ele pode comprar: o NodePool

```schooling-example
{"language": "yaml", "file": "nodepool.yaml", "parts": [{"code": "apiVersion: karpenter.sh/v1\nkind: NodePool\nmetadata:\n  name: general\n", "note": "Um NodePool é um objeto do Kubernetes que o Karpenter lê, no grupo de API `karpenter.sh/v1`. Um cluster pode ter vários, um para cada tipo de node que um time quer manter separado."}, {"code": "spec:\n  template:\n    metadata:\n      labels:\n        role: general\n    spec:\n      nodeClassRef:\n        group: karpenter.k8s.aws\n        kind: EC2NodeClass\n        name: shop\n", "note": "Como vai ser cada node que ele cria: o rótulo `role: general`, e uma referência ao EC2NodeClass abaixo, que guarda a metade AWS da descrição."}, {"code": "      requirements:\n        - key: kubernetes.io/arch\n          operator: In\n          values: [\"arm64\"]\n        - key: karpenter.k8s.aws/instance-category\n          operator: In\n          values: [\"c\", \"m\", \"r\"]\n        - key: karpenter.k8s.aws/instance-generation\n          operator: Gt\n          values: [\"6\"]\n", "note": "**Os requirements são uma faixa, não um tipo.** Qualquer instância Arm das famílias de computação, de uso geral ou de memória, da sétima geração em diante. O Karpenter escolhe dentro dessa faixa para cada leva de pods pendentes."}, {"code": "        - key: karpenter.sh/capacity-type\n          operator: In\n          values: [\"spot\", \"on-demand\"]\n", "note": "Spot e sob demanda são ambos permitidos. O Karpenter tenta spot primeiro, e cai para sob demanda quando o spot não consegue fornecer o que os pods precisam."}, {"code": "      expireAfter: 720h\n", "note": "Todo node é substituído depois de 30 dias, então nenhum node vive o bastante para se afastar muito da imagem atual."}, {"code": "  limits:\n    cpu: \"64\"\n", "note": "Um teto: o pool nunca passa de 64 vCPUs no total, esteja pendente o que estiver. É a proteção contra um deployment descontrolado comprando máquinas a noite inteira."}, {"code": "  disruption:\n    consolidationPolicy: WhenEmptyOrUnderutilized\n    consolidateAfter: 1m\n    budgets:\n      - nodes: \"10%\"\n", "note": "**Consolidação** é o Karpenter removendo ou substituindo nodes vazios ou subutilizados, um minuto depois de perceber. O budget o deixa perturbar no máximo um décimo dos nodes de uma vez."}]}
```

A diferença para a lição 11 está na terceira parte. Um node group cita o tipo de instância; um
NodePool cita **um conjunto de tipos aceitáveis**, e deixa a escolha para o momento em que há pods a
posicionar. Dez pods pedindo 250 milicores cada podem ganhar uma `c7g.xlarge`. Um pod pedindo 30 GiB
pode ganhar uma `r7g.xlarge`. As duas escolhas saem do mesmo arquivo.

## Como ele é montado: o EC2NodeClass

```schooling-example
{"language": "yaml", "file": "ec2nodeclass.yaml", "parts": [{"code": "apiVersion: karpenter.k8s.aws/v1\nkind: EC2NodeClass\nmetadata:\n  name: shop\nspec:\n", "note": "O EC2NodeClass é o lado AWS: a role, a imagem, as subnets e os security groups que um node recebe. É a parte de um launch template de que o Karpenter precisa da sua mão."}, {"code": "  role: KarpenterNodeRole-shop\n", "note": "A role do IAM com que os nodes dele rodam, a role dos nodes da lição 11 com outro nome."}, {"code": "  amiSelectorTerms:\n    - alias: al2023@latest\n", "note": "A imagem: o Amazon Linux 2023 mais recente que o EKS publica para a versão do cluster. Um alias que cita uma versão específica no lugar de `latest` é como um time impede que nodes novos peguem uma imagem nova sozinhos."}, {"code": "  subnetSelectorTerms:\n    - tags:\n        karpenter.sh/discovery: shop\n  securityGroupSelectorTerms:\n    - tags:\n        karpenter.sh/discovery: shop\n", "note": "Subnets e security groups são achados por tag em vez de listados por id, então acrescentar uma subnet é pôr a tag nela, e nada neste arquivo muda."}]}
```

Os dois arquivos dividem uma descrição: o NodePool diz para que servem os nodes e até onde o
Karpenter pode ir, e o EC2NodeClass diz como montar um na AWS. Um cluster pode combinar vários
NodePools com um EC2NodeClass.

## A chamada que ele faz

Para ver no que dá "um conjunto de tipos aceitáveis", pergunte ao catálogo do EC2, que o moto
carrega. Esta é a fatia da faixa do NodePool com até quatro vCPUs, só a sétima geração; a faixa em
si vai além, para tamanhos maiores e gerações mais novas:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --filters Name=processor-info.supported-architecture,Values=arm64 Name=instance-type,Values='c7g.*,m7g.*,r7g.*' Name=bare-metal,Values=false --query 'InstanceTypes[?VCpuInfo.DefaultVCpus<=`4`].[InstanceType,VCpuInfo.DefaultVCpus,MemoryInfo.SizeInMiB]' --output text | sort -k2n -k3n
c7g.medium	1	2048
m7g.medium	1	4096
r7g.medium	1	8192
c7g.large	2	4096
m7g.large	2	8192
r7g.large	2	16384
c7g.xlarge	4	8192
m7g.xlarge	4	16384
r7g.xlarge	4	32768
```

O Karpenter filtra uma lista como esta contra os pedidos dos pods pendentes, fica com os tipos que os
comportariam e então lança com **uma chamada ao EC2, o `CreateFleet` do tipo `instant`**, oferecendo
vários desses tipos de uma vez e deixando o EC2 escolher por preço e capacidade sobrando. A mesma
chamada contra o moto, com três tipos oferecidos e capacidade spot pedida:

```
ana@laptop:~/aws$ aws ec2 create-launch-template --launch-template-name karpenter-shop --launch-template-data '{"ImageId":"ami-0c55b159cbfafe1f0"}' --query LaunchTemplate.LaunchTemplateName
"karpenter-shop"
ana@laptop:~/aws$ SUBNET=$(aws ec2 describe-subnets --query 'Subnets[0].SubnetId' --output text)
ana@laptop:~/aws$ aws ec2 create-fleet --type instant --target-capacity-specification TotalTargetCapacity=3,DefaultTargetCapacityType=spot --spot-options AllocationStrategy=price-capacity-optimized --launch-template-configs '[{"LaunchTemplateSpecification":{"LaunchTemplateName":"karpenter-shop","Version":"$Latest"},"Overrides":[{"InstanceType":"c7g.large","SubnetId":"'$SUBNET'"},{"InstanceType":"m7g.large","SubnetId":"'$SUBNET'"},{"InstanceType":"c7g.xlarge","SubnetId":"'$SUBNET'"}]}]' --query 'Instances[].[InstanceType,Lifecycle,InstanceIds[0]]' --output text
c7g.large	spot	i-cf2c912e0dda2e6ec
c7g.large	spot	i-20478a7be6e9ca369
c7g.large	spot	i-0165628e333d62bf3
ana@laptop:~/aws$ aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceType,InstanceLifecycle,Placement.AvailabilityZone]' --output text
c7g.large	spot	sa-east-1a
c7g.large	spot	sa-east-1a
c7g.large	spot	sa-east-1a
```

**Na AWS a estratégia `price-capacity-optimized` escolhe entre os três tipos**, pesando o preço spot
de cada um contra quanta capacidade sobrando o pool dele tem, que é como a lição 6 disse que as
interrupções do spot são mais bem evitadas. O moto deu às três instâncias o primeiro tipo da lista e
as pôs numa zona só. Ele aceitou o pedido e devolveu instâncias; a escolha que fez não é uma escolha
que a AWS faria, e nada aqui mede uma.

## Consolidação, e spot

Um Cluster Autoscaler remove um node só quando ele está quase vazio. **O Karpenter também substitui
nodes que estão apenas mal arrumados.** Com `consolidationPolicy: WhenEmptyOrUnderutilized` ele
continua perguntando se os pods de dois nodes meio vazios caberiam num só, ou num tipo mais barato, e
quando caberiam, inicia o node novo, move os pods e termina os antigos. A linha `budgets` limita
quanto do pool é perturbado de uma vez, e um PodDisruptionBudget, da lição 11, limita isso por carga.
Então a consolidação economiza movendo pods, e uma carga que não aguenta ser movida precisa dizer
isso.

As interrupções do spot são a outra fonte de pods movidos. O Karpenter pode escutar uma fila SQS
alimentada pelos eventos do EventBridge da lição 6, entre eles o aviso de dois minutos, e drenar um
node antes que o EC2 o tome de volta. Essa fila é montada quando o Karpenter é instalado, ao lado da
role do IAM que ele usa para chamar o EC2.

## Onde ele roda, e o EKS Auto Mode

Os pods do próprio Karpenter precisam de um node, e um node que o Karpenter administra poderia ser
consolidado debaixo deles. Então ele roda em capacidade que não administra: um managed node group
pequeno da lição 11, ou um Fargate profile da seção anterior que selecione o namespace dele.

**O EKS Auto Mode**, que a AWS lançou em dezembro de 2024, é o Karpenter operado pela AWS: o cluster
vem com NodePools já definidos, e a AWS opera o controller, as imagens dos nodes e os add-ons da
lição 11 que rodam nesses nodes. Ela cobra uma taxa por instância além do preço do EC2, que não está
na tabela de preços do curso. O NodePool acima é o mesmo tipo de objeto que o Auto Mode usa, então o
que esta seção descreve é o que o Auto Mode faz em seu nome.
