---
title: Cluster Autoscaler ou Karpenter
version: 1
---

Os dois respondem ao mesmo evento, um pod que fica `Pending` porque nenhum node tem espaço para ele.
**Eles diferem no que podem mudar.** O Cluster Autoscaler muda o número desejado de um node group que
você definiu antes. O Karpenter escolhe a máquina. Todo o resto sobre os dois decorre dessa única
diferença:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Dois ciclos de um pod pendente até um pod rodando. O Cluster Autoscaler pergunta que node group comportaria o pod, aumenta o número desejado daquele Auto Scaling group, e o grupo lança o seu único tipo de instância, uma m7i.2xlarge. O Karpenter lê os pedidos e requisitos do pod, chama o CreateFleet do EC2 com uma lista de tipos e recebe o mais barato que serve, uma c7g.large. Os dois terminam com o node entrando e o pod agendado.\"><defs><marker id=\"k8s-loops-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"12\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\" font-weight=\"600\">Cluster Autoscaler</text><rect x=\"12\" y=\"54\" width=\"128\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"76.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um pod está Pending</text><text x=\"76.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nada tem espaço</text><path d=\"M140 86 L152 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#k8s-loops-ah)\"></path><rect x=\"154\" y=\"54\" width=\"128\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"218.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">que grupo</text><text x=\"218.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o comportaria?</text><path d=\"M282 86 L294 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#k8s-loops-ah)\"></path><rect x=\"296\" y=\"54\" width=\"128\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o Auto Scaling group</text><text x=\"360.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">dele: desejado + 1</text><path d=\"M424 86 L436 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#k8s-loops-ah)\"></path><rect x=\"438\" y=\"54\" width=\"128\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"502.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o único tipo do grupo</text><text x=\"502.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">m7i.2xlarge</text><path d=\"M566 86 L578 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#k8s-loops-ah)\"></path><rect x=\"580\" y=\"54\" width=\"128\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"644.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o node entra,</text><text x=\"644.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o pod é agendado</text><text x=\"12\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">Karpenter</text><rect x=\"12\" y=\"184\" width=\"128\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"76.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um pod está Pending</text><text x=\"76.0\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nada tem espaço</text><path d=\"M140 216 L152 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#k8s-loops-ah)\"></path><rect x=\"154\" y=\"184\" width=\"128\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"218.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">lê o pod:</text><text x=\"218.0\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pedidos, requisitos</text><path d=\"M282 216 L294 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#k8s-loops-ah)\"></path><rect x=\"296\" y=\"184\" width=\"128\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">CreateFleet do EC2</text><text x=\"360.0\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">com uma lista de tipos</text><path d=\"M424 216 L436 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#k8s-loops-ah)\"></path><rect x=\"438\" y=\"184\" width=\"128\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"502.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o mais barato que serve</text><text x=\"502.0\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c7g.large</text><path d=\"M566 216 L578 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#k8s-loops-ah)\"></path><rect x=\"580\" y=\"184\" width=\"128\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"644.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o node entra,</text><text x=\"644.0\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o pod é agendado</text></svg>", "caption": "O mesmo pod pendente, dois ciclos. O Cluster Autoscaler muda um número num grupo que você definiu antes; o Karpenter escolhe a máquina para os pods que está vendo, e fala direto com o EC2.", "same": ["Cluster Autoscaler", "Karpenter"]}
```

## O ciclo do Cluster Autoscaler

O Cluster Autoscaler é o autoscaler do próprio projeto Kubernetes, e funciona com node groups em toda
nuvem que os tem. Quando há pods pendentes, ele simula o scheduler contra o tipo de instância de cada
node group e escolhe um grupo cujo node novo os comportaria. Depois aumenta o número desejado daquele
Auto Scaling group em quantos nodes forem necessários. O grupo lança **o seu próprio tipo**, o node
entra e o scheduler posiciona os pods. Quando um node fica subutilizado por um tempo e os pods dele
caberiam em outro lugar, ele diminui o número de novo e o node é drenado e removido.

Esse desenho tem duas consequências. **Os formatos são seus para prever**: um pod que precisa de
30 GiB num cluster cujo único grupo é `m7g.large` fica pendente para sempre. A resposta comum é um
segundo grupo para pods grandes, depois um terceiro para Arm, depois um para spot. E a máquina é a do
grupo, mesmo quando os pods pendentes são pequenos: um pod minúsculo num grupo de `m7i.2xlarge` ganha
uma `m7i.2xlarge` inteira.

## O ciclo do Karpenter

O Karpenter lê os pedidos dos pods pendentes e os requisitos deles, como a arquitetura, a zona ou
spot contra sob demanda. Ele cruza isso com a faixa do NodePool e pede ao EC2 a máquina mais barata
que os comporta, pela chamada `CreateFleet` da seção anterior. Um node group com o seu tipo fixo
nunca entra no ciclo. Depois, a consolidação continua perguntando se os mesmos pods caberiam em menos
máquinas ou em máquinas mais baratas.

## Quanto vale a diferença

Três pods pendentes pedem 1,5 vCPU e 3 GiB juntos. O Cluster Autoscaler, com um grupo de
`m7i.2xlarge`, acrescenta uma dessas. O Karpenter, com o NodePool da seção anterior, pode acrescentar
uma `c7g.large`, duas vCPUs Arm e 4 GiB. Os dois preços são linhas da tabela da lição 1, como
publicados em 16 de outubro de 2026, e estão na captura da primeira seção: `m7i.2xlarge` a 0,6426 USD
por hora e `c7g.large` a 0,1111. **A diferença é 0,5315 USD por hora, ou cerca de 388 USD num mês de
730 horas, por node.** A conta deixa de fora o que todo node também carrega, entre outras coisas os
DaemonSets da lição 11, e supõe que as imagens dos pods rodam em Arm. A segunda é uma condição real:
uma imagem construída só para x86, como a da lição 10, não consegue usar a `c7g`, e o NodePool teria
de permitir tipos x86 também.

## Escolhendo

| | Cluster Autoscaler | Karpenter |
|---|---|---|
| o que ele muda | o número desejado dos seus node groups | quais instâncias existem |
| tipos de instância | um por grupo, escolhido antes | uma faixa, escolhida por leva de pods |
| remover nodes | nodes quase vazios | nodes vazios, e nodes que ele consegue arrumar melhor |
| onde funciona | toda nuvem com node groups | a AWS, e outros provedores que escreveram suporte |
| o que você administra | os grupos, um por formato | NodePools, um EC2NodeClass, uma fila SQS para interrupções |

**O Karpenter serve melhor a clusters cujos pods variam**: jobs batch de tamanhos diferentes, uma
mistura de Arm e x86, uso pesado de spot. O Cluster Autoscaler ainda serve a um cluster com poucos
tipos estáveis de carga, e a um time que quer que toda máquina venha de um grupo que ele lê num só
lugar. Ele também é o que funciona do mesmo jeito em outra nuvem. Os dois não devem administrar os mesmos
nodes: escolha um por grupo de capacidade.

E o Fargate, a resposta da primeira seção, fica ao lado dos dois. Ele tira os nodes da questão de vez
para os pods que um profile seleciona, ao preço das restrições listadas lá e de pagar pelos pedidos
de cada pod.
