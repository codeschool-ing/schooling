---
title: Upgrades, uma versão minor e um node por vez
version: 1
---

Duas imagens de um upgrade no AKS são comuns, e as duas estão erradas. Uma é que um serviço
gerenciado se mantém atualizado sozinho; a outra é que um upgrade é um evento só, que acontece com o
cluster. **No AKS Standard, nada atualiza a versão do Kubernetes até você pedir, ou um canal que você
escolheu pedir por você. E um upgrade é um evento por node: um node novo adicionado, o antigo com
cordon e drain, depois refeito na versão nova.** O drain é onde os seus pods encontram o upgrade, e é
a parte que o kind consegue mostrar exatamente.

## A janela de versões com suporte

A documentação da Microsoft, lida em 30 de outubro de 2026, enuncia a política como **N-2**: o AKS
dá suporte à versão minor mais recente em disponibilidade geral e às duas anteriores. O calendário
dela dá a 1.37 como disponível desde outubro de 2026 e o fim da vida da 1.34 em novembro, depois do
que as versões minor com suporte são a 1.35, a 1.36 e a 1.37. Cada uma tem cerca de um ano desse
*suporte da comunidade*. Depois disso uma versão é *N-3* e recebe só suporte de plataforma: ajuda com
o lado do Azure e nenhuma com o Kubernetes. Sessenta dias depois do fim da vida dela, o AKS atualiza o
cluster por conta própria, uma versão minor por vez, no que a documentação chama de upgrade iniciado
pela plataforma. Esse upgrade não espera a sua janela de manutenção e, se um drain falhar, passa por
cima dos seus PodDisruptionBudgets para que o cluster chegue a uma versão com suporte.

O **suporte de longo prazo** acrescenta um segundo ano: cerca de 24 meses numa versão minor no total,
com correções de segurança trazidas de volta. Ele exige o tier Premium da primeira seção e o plano de
suporte `AKSLongTermSupport`, escolhido explicitamente; a adesão nunca é automática.

Duas regras dão forma a todo upgrade. **Um cluster fora do suporte de longo prazo não pode pular uma
versão minor**: a 1.35 chega à 1.37 passando pela 1.36, em dois upgrades. E os node pools seguem o
control plane, nunca vão à frente dele; desde o Kubernetes 1.28 eles podem ficar até três versões
minor atrás, o que torna possível atualizar o control plane sozinho.

## O control plane primeiro, depois os pools

Nada disto rodou aqui, porque cada comando precisa de uma assinatura. No Azure a sequência é:

```sh
az aks get-upgrades --resource-group shop --name shop-aks --output table
az aks upgrade --resource-group shop --name shop-aks --kubernetes-version 1.37 --control-plane-only
az aks nodepool upgrade --resource-group shop --cluster-name shop-aks --name apps --kubernetes-version 1.37
```

O primeiro lista as versões para as quais este cluster pode ir. O segundo move só o control plane, o
que deixa você descobrir se as cargas ainda conversam com a API nova antes de qualquer node mudar;
sem `--control-plane-only`, o `az aks upgrade` move o control plane e depois todos os pools. O
terceiro move um pool, e o pool system recebe o mesmo comando com o nome dele.

**Um upgrade de Kubernetes e um upgrade de imagem de node são coisas diferentes.** Uma imagem de node
é o disco de sistema operacional que o AKS monta para os nodes dele. A documentação da Microsoft
diz que sai uma nova de Linux toda semana, com a mesma versão do Kubernetes dentro e as últimas
correções em volta. O `az aks nodepool upgrade --node-image-only` troca a imagem e deixa a versão em
paz. Todo upgrade da versão do Kubernetes traz a imagem mais recente junto. Os dois chegam aos nodes
do mesmo jeito, um por vez, logo abaixo.

E voltar atrás é estreito. A documentação diz que um upgrade de control plane não pode ser desfeito.
Um node pool pode voltar à versão e à imagem anteriores, a partir da versão de API `2026-04-01`, por
sete dias depois que o upgrade terminou, e só uma versão para trás.

## Um node por vez

A sequência documentada para todo pool, com as configurações que o `aks.bicep` declarou:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 306\" role=\"img\" aria-label=\"Cinco linhas, uma por passo de um upgrade com surge no AKS de um pool de três nodes na 1.36. Linha 1: um node de surge na 1.37 é adicionado, conforme o maxSurge. Linha 2: o node 1 recebe cordon e drain no ritmo que o PodDisruptionBudget permite, dentro do drainTimeoutInMinutes, e os pods dele vão para o node de surge. Linha 3: o node 1 está vazio e o AKS espera, pelo nodeSoakDurationInMinutes. Linha 4: o node 1 é reimageado na 1.37 e vira a folga do node 2. Linha 5: os nodes 2 e 3 seguem o mesmo caminho, todos ficam na 1.37 e o node de surge é removido.\"><rect x=\"12\" y=\"14\" width=\"696\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">1</text><text x=\"48\" y=\"31\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">adiciona um node de surge</text><text x=\"48\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">maxSurge</text><rect x=\"386\" y=\"19\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"421\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 1</text><text x=\"421\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.36</text><rect x=\"466\" y=\"19\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"501\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 2</text><text x=\"501\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.36</text><rect x=\"546\" y=\"19\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"581\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 3</text><text x=\"581\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.36</text><rect x=\"626\" y=\"19\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"661\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">surge</text><text x=\"661\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.37</text><rect x=\"12\" y=\"72\" width=\"696\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">2</text><text x=\"48\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cordon e drain do node 1, no ritmo do orçamento</text><text x=\"48\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">drainTimeoutInMinutes</text><rect x=\"386\" y=\"77\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"421\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 1</text><text x=\"421\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">cordoned</text><rect x=\"466\" y=\"77\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"501\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 2</text><text x=\"501\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.36</text><rect x=\"546\" y=\"77\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"581\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 3</text><text x=\"581\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.36</text><rect x=\"626\" y=\"77\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"661\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">surge</text><text x=\"661\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.37</text><rect x=\"12\" y=\"130\" width=\"696\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">3</text><text x=\"48\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">espera antes de seguir</text><text x=\"48\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">nodeSoakDurationInMinutes</text><rect x=\"386\" y=\"135\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"421\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 1</text><text x=\"421\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">vazio</text><rect x=\"466\" y=\"135\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"501\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 2</text><text x=\"501\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.36</text><rect x=\"546\" y=\"135\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"581\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 3</text><text x=\"581\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.36</text><rect x=\"626\" y=\"135\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"661\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">surge</text><text x=\"661\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.37</text><rect x=\"12\" y=\"188\" width=\"696\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">4</text><text x=\"48\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reimagem do node 1 na versão nova</text><text x=\"48\" y=\"223\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ele é a folga do node 2</text><rect x=\"386\" y=\"193\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"421\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 1</text><text x=\"421\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.37</text><rect x=\"466\" y=\"193\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"501\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 2</text><text x=\"501\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.36</text><rect x=\"546\" y=\"193\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"581\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 3</text><text x=\"581\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.36</text><rect x=\"626\" y=\"193\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"661\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">surge</text><text x=\"661\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.37</text><rect x=\"12\" y=\"246\" width=\"696\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"271\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">5</text><text x=\"48\" y=\"263\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nodes 2 e 3 do mesmo jeito, e o node de surge sai</text><rect x=\"386\" y=\"251\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"421\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 1</text><text x=\"421\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.37</text><rect x=\"466\" y=\"251\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"501\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 2</text><text x=\"501\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.37</text><rect x=\"546\" y=\"251\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"581\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">node 3</text><text x=\"581\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.37</text><rect x=\"626\" y=\"251\" width=\"70\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"661\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">surge</text><text x=\"661\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">removido</text></svg>", "caption": "Um pool, um node por vez. As configurações em mono são as que o aks.bicep declarou para o pool apps; o passo 2 é a parte que o lab rodou, com o shop-worker3 no papel do node de surge.", "same": ["node 1", "node 2", "node 3", "surge"]}
```

`maxSurge` é quantos nodes a mais o AKS adiciona antes de mexer nos antigos. O padrão é um; uma
porcentagem é do número de nodes do pool, arredondada para cima, e a Microsoft recomenda 33% para
pools de produção: um pool de 10 nodes faz surge de ceil(3,3) = 4 por vez. Cada node de surge
precisa de cota e, no Azure CNI, de endereços na subnet. `maxUnavailable` é o caminho inverso, para
uma assinatura sem espaço para surge: ele drena os nodes existentes no lugar, o padrão é 0 e um pool
system não pode usá-lo. `drainTimeoutInMinutes` é quanto tempo o drain de um node pode levar, 30
minutos por padrão, entre 5 minutos e 24 horas. `nodeSoakDurationInMinutes` espera depois de um drain
antes da reimagem, de 0, o padrão, a 30, para que alguém possa olhar um painel antes de o próximo
node ir.

## O drain, no kind

As três réplicas do shop estão no `shop-worker2`. Um PodDisruptionBudget diz quantas delas precisam
continuar disponíveis enquanto algo as despeja de propósito. Salve como `pdb.yaml`:

```yaml
# pdb.yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: shop
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: shop
```

```
ana@laptop:~/azure$ kubectl apply -f pdb.yaml
poddisruptionbudget.policy/shop created
ana@laptop:~/azure$ kubectl get pdb shop
NAME   MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
shop   2               N/A               1                     1s
```

`ALLOWED DISRUPTIONS` é a conta do orçamento feita para você: três pods prontos, dois exigidos, então
um pode sair. Agora os passos que o AKS segue para um node de um upgrade com surge. O node de surge
chega, o que aqui significa o uncordon do `shop-worker3`, e o node antigo é drenado:

```
ana@laptop:~/azure$ kubectl uncordon shop-worker3
node/shop-worker3 uncordoned
ana@laptop:~/azure$ kubectl drain shop-worker2 --ignore-daemonsets
node/shop-worker2 cordoned
Warning: ignoring DaemonSet-managed Pods: kube-system/kindnet-x6s98, kube-system/kube-proxy-fdg8r
evicting pod default/shop-7d76d574f5-rgn8q
evicting pod default/shop-7d76d574f5-8wfqp
evicting pod default/shop-7d76d574f5-l2w4c
error when evicting pods/"shop-7d76d574f5-rgn8q" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"shop-7d76d574f5-l2w4c" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod default/shop-7d76d574f5-rgn8q
evicting pod default/shop-7d76d574f5-l2w4c
error when evicting pods/"shop-7d76d574f5-l2w4c" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod default/shop-7d76d574f5-l2w4c
pod/shop-7d76d574f5-8wfqp evicted
pod/shop-7d76d574f5-rgn8q evicted
pod/shop-7d76d574f5-l2w4c evicted
node/shop-worker2 drained
ana@laptop:~/azure$ kubectl get pods -o custom-columns=POD:.metadata.name,NODE:.spec.nodeName,READY:.status.containerStatuses[0].ready
POD                     NODE           READY
shop-7d76d574f5-hxdv2   shop-worker3   true
shop-7d76d574f5-q5zrp   shop-worker3   true
shop-7d76d574f5-tvfsz   shop-worker3   true
ana@laptop:~/azure$ kubectl get nodes
NAME                 STATUS                     ROLES           AGE    VERSION
shop-control-plane   Ready                      control-plane   2m1s   v1.37.0
shop-worker          Ready                      <none>          107s   v1.37.0
shop-worker2         Ready,SchedulingDisabled   <none>          107s   v1.37.0
shop-worker3         Ready                      <none>          107s   v1.37.0
ana@laptop:~/azure$ kubectl uncordon shop-worker2
node/shop-worker2 uncordoned
```

**Isso é o orçamento funcionando.** O `kubectl drain` deu cordon no node e pediu o eviction dos três
pods de uma vez. O API server concedeu um e recusou dois, com *Cannot evict pod as it would violate
the pod's disruption budget*, e o drain pediu de novo a cada cinco segundos. Cada recusa caiu quando
uma substituta no `shop-worker3` ficou pronta, porque só então havia de novo três pods prontos e um
de folga. O shop nunca teve menos de dois pods respondendo. No AKS é aqui que o `shop-worker2` seria
reimageado na versão nova e voltaria ao pool, pronto para ser a folga do próximo node. Aqui, o
uncordon dele faz esse papel.

## Um drain que não consegue terminar

Um orçamento que pede os três de três nunca permite uma interrupção. Aqui está ele, num node que tem
para onde mandar os pods:

```
ana@laptop:~/azure$ kubectl patch pdb shop --type merge -p '{"spec":{"minAvailable":3}}'
poddisruptionbudget.policy/shop patched
ana@laptop:~/azure$ kubectl get pdb shop
NAME   MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
shop   3               N/A               0                     45s
ana@laptop:~/azure$ kubectl drain shop-worker3 --ignore-daemonsets --timeout=10s
node/shop-worker3 cordoned
evicting pod default/shop-7d76d574f5-tvfsz
evicting pod default/shop-7d76d574f5-hxdv2
evicting pod default/shop-7d76d574f5-q5zrp
Warning: ignoring DaemonSet-managed Pods: kube-system/kindnet-ws2wl, kube-system/kube-proxy-mhfsg
error when evicting pods/"shop-7d76d574f5-hxdv2" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"shop-7d76d574f5-q5zrp" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"shop-7d76d574f5-tvfsz" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod default/shop-7d76d574f5-q5zrp
evicting pod default/shop-7d76d574f5-tvfsz
evicting pod default/shop-7d76d574f5-hxdv2
error when evicting pods/"shop-7d76d574f5-q5zrp" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"shop-7d76d574f5-hxdv2" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"shop-7d76d574f5-tvfsz" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod default/shop-7d76d574f5-q5zrp
evicting pod default/shop-7d76d574f5-tvfsz
evicting pod default/shop-7d76d574f5-hxdv2
There are pending pods in node "shop-worker3" when an error occurred: [error when evicting pods/"shop-7d76d574f5-q5zrp" -n "default": global timeout reached: 10s, error when evicting pods/"shop-7d76d574f5-tvfsz" -n "default": global timeout reached: 10s, error when evicting pods/"shop-7d76d574f5-hxdv2" -n "default": global timeout reached: 10s]
pod/shop-7d76d574f5-hxdv2
pod/shop-7d76d574f5-q5zrp
pod/shop-7d76d574f5-tvfsz
error: unable to drain node "shop-worker3" due to error: [error when evicting pods/"shop-7d76d574f5-q5zrp" -n "default": global timeout reached: 10s, error when evicting pods/"shop-7d76d574f5-tvfsz" -n "default": global timeout reached: 10s, error when evicting pods/"shop-7d76d574f5-hxdv2" -n "default": global timeout reached: 10s], continuing command...
There are pending nodes to be drained:
 shop-worker3
error when evicting pods/"shop-7d76d574f5-q5zrp" -n "default": global timeout reached: 10s
error when evicting pods/"shop-7d76d574f5-tvfsz" -n "default": global timeout reached: 10s
error when evicting pods/"shop-7d76d574f5-hxdv2" -n "default": global timeout reached: 10s
ana@laptop:~/azure$ kubectl get nodes
NAME                 STATUS                     ROLES           AGE     VERSION
shop-control-plane   Ready                      control-plane   2m12s   v1.37.0
shop-worker          Ready                      <none>          118s    v1.37.0
shop-worker2         Ready                      <none>          118s    v1.37.0
shop-worker3         Ready,SchedulingDisabled   <none>          118s    v1.37.0
```

Havia espaço no `shop-worker2`, e não fez diferença: **o orçamento recusa antes de o scheduler ser
consultado.** O drain do kind desistiu quando o próprio tempo limite acabou e deixou o node com
cordon. O AKS desiste quando o `drainTimeoutInMinutes` acaba, e o que acontece depois é o
`undrainableNodeBehavior` do pool. As orientações de diagnóstico da Microsoft mostram um upgrade que
parou num drain assim: o erro é `UpgradeFailed`, com a mesma frase sobre o orçamento de interrupção
dentro, e uma operação posterior no cluster retoma o upgrade. Com `Cordon`, a configuração que o
`aks.bicep` escolheu, o AKS em vez disso deixa o node com cordon, põe nele o rótulo
`kubernetes.azure.com/upgrade-status=Quarantined`, segue com o resto do pool e deixa esse node para
você resolver. A linha de comando conhece os dois valores:

```
ana@laptop:~/azure$ az aks nodepool upgrade --help | grep -A2 -- "--undrainable-node-behavior"
    --undrainable-node-behavior          : Define the behavior for undrainable nodes during upgrade.
                                           The value should be "Cordon" or "Schedule". The default
                                           value is "Schedule".
```

A ajuda dá `Schedule` como padrão, e a documentação diz pouco demais sobre o que ele faz para este
curso dizer mais. O `--enable-force-upgrade` do `az aks upgrade` ignora os orçamentos por completo. O
conselho da documentação é consertar o orçamento primeiro, e a conta do orçamento é o conserto: três
réplicas e `minAvailable: 2`, nunca três de três.

## A cerca do compilador e a do serviço

Duas das configurações de upgrade têm faixas documentadas, e o compilador conhece só parte delas:

```
ana@laptop:~/azure$ sed -e 's/drainTimeoutInMinutes: 30/drainTimeoutInMinutes: 2/' -e 's/nodeSoakDurationInMinutes: 5/nodeSoakDurationInMinutes: 45/' aks.bicep > short.bicep
ana@laptop:~/azure$ bicep build short.bicep
/home/ana/azure/short.bicep(47,38) : Warning BCP327: The provided value (which will always be greater than or equal to 45) is too large to assign to a target for which the maximum allowable value is 30. [https://aka.ms/bicep/core-diagnostics#BCP327]
```

Um soak de 45 minutos foi recusado contra o máximo de 30 do tipo. Um tempo limite de drain de 2
minutos compilou sem uma palavra, embora a documentação da Microsoft dê 5 minutos como o mínimo: o
tipo diz de 1 a 1.440, e o 5 é regra do serviço.

Isso é tudo para o que o cluster é necessário nesta lição. Apague-o:

```
ana@laptop:~/azure$ kind delete cluster --name shop
Deleting cluster "shop" ...
Deleted nodes: ["shop-worker" "shop-worker3" "shop-control-plane" "shop-worker2"]
```
