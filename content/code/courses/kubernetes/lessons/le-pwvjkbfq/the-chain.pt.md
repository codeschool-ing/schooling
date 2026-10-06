---
title: Seis eventos, e ninguém chamando ninguém
version: 1
---

**O palpite natural é que o `kubectl create` manda uma ordem por uma corrente: o API server avisa o
escalonador, o escalonador avisa um kubelet.** Nada no cluster funciona assim. Cada componente
*observa* o API server em busca de objetos num estado pelo qual ele responde, faz o seu único passo
e escreve o resultado de volta. O componente seguinte vê o resultado porque também estava
observando. Os eventos que os componentes deixam mostram a ordem:

```
ana@laptop:~/shop$ kubectl create deployment shop --image=shop:1.0
deployment.apps/shop created
ana@laptop:~/shop$ kubectl get events --sort-by=.metadata.resourceVersion -o custom-columns=SOURCE:.source.component,REASON:.reason,OBJECT:.involvedObject.kind,MESSAGE:.message
SOURCE                  REASON              OBJECT       MESSAGE
deployment-controller   ScalingReplicaSet   Deployment   Scaled up replica set shop-774b84ff8c from 0 to 1
replicaset-controller   SuccessfulCreate    ReplicaSet   Created pod: shop-774b84ff8c-4z28q
default-scheduler       Scheduled           Pod          Successfully assigned default/shop-774b84ff8c-4z28q to shop-worker2
kubelet                 Pulled              Pod          Container image "shop:1.0" already present on machine and can be accessed by the pod
kubelet                 Created             Pod          Container created
kubelet                 Started             Pod          Container started
```

Lido de cima para baixo, um pod passou por quatro mãos:

1. o **controlador de deployments** viu um Deployment novo sem ReplicaSet, e criou um;
2. o **controlador de ReplicaSets** viu um ReplicaSet querendo um pod e sem nenhum, e criou um, sem
   nó nenhum;
3. o **escalonador** viu um pod sem nó, escolheu `shop-worker2` e escreveu isso no pod;
4. o **kubelet** de `shop-worker2` viu um pod atribuído ao seu nó, encontrou a imagem, criou o
   container e o iniciou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Cinco raias de cima para baixo: o API server, o controlador de deployments, o de ReplicaSets, o escalonador e o kubelet. O tempo corre para a direita. Cada componente observa o API server, vê um objeto e escreve uma mudança de volta: um ReplicaSet, um pod sem nó, o nó do pod e, por fim, um container rodando.\"><defs><marker id=\"ch-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"ch-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"ch-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">API server</text><path d=\"M280 30 L700 30\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">controlador de deployments</text><path d=\"M170 86 L700 86\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"20\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">controlador de ReplicaSets</text><path d=\"M170 142 L700 142\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"20\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">escalonador</text><path d=\"M170 198 L700 198\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"20\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">kubelet</text><path d=\"M170 254 L700 254\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"176\" y=\"14\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"226.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">Deployment novo</text><path d=\"M240 46 L240 78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah-paper-dim)\"></path><text x=\"240\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">escreve um ReplicaSet</text><path d=\"M256 78 L300 48\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah-phosphor)\"></path><path d=\"M350 46 L350 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah-paper-dim)\"></path><text x=\"350\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">escreve um pod, sem nó</text><path d=\"M366 134 L410 48\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah-phosphor)\"></path><path d=\"M460 46 L460 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah-paper-dim)\"></path><text x=\"460\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">escreve o nó</text><path d=\"M476 190 L520 48\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah-phosphor)\"></path><path d=\"M560 46 L560 246\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah-paper-dim)\"></path><text x=\"560\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">inicia o container</text><path d=\"M170 288 L700 288\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah-wire)\"></path><text x=\"700\" y=\"278\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tempo</text></svg>", "caption": "Cada passo é uma escrita no API server, e cada passo seguinte começa com um componente notando essa escrita.", "same": ["API server", "kubelet"]}
```

Nenhum dos quatro sabe que os outros existem. **É isso que faz o cluster sobreviver à perda de uma
peça**: cada um depende de objetos no API server, nunca de outro componente estar de pé.

## Desligando o escalonador

O escalonador é um pod estático, então tirar o arquivo dele do diretório de manifestos o para. A Ana
move o arquivo para outro lugar, e o kubelet do nó do plano de controle derruba o escalonador:

```
ana@laptop:~/shop$ docker exec shop-control-plane mv /etc/kubernetes/manifests/kube-scheduler.yaml /root/
ana@laptop:~/shop$ kubectl get pods -n kube-system -l component=kube-scheduler
No resources found in kube-system namespace.
```

Depois ela pede mais duas cópias da loja:

```
ana@laptop:~/shop$ kubectl scale deployment shop --replicas=3
deployment.apps/shop scaled
ana@laptop:~/shop$ kubectl get pods -l app=shop
NAME                    READY   STATUS    RESTARTS   AGE
shop-774b84ff8c-4z28q   1/1     Running   0          33s
shop-774b84ff8c-fgthg   0/1     Pending   0          5s
shop-774b84ff8c-vbb5p   0/1     Pending   0          5s
```

**O trabalho parou exatamente no passo que faltava.** O controlador de deployments e o de ReplicaSets
fizeram a sua parte, então dois pods novos existem. Ninguém escolheu um nó para eles, então estão em
`Pending`, e nada neles vai mudar sozinho. O primeiro pod, que já estava num nó, continuou rodando
como se nada tivesse acontecido. A Ana devolve o arquivo:

```
ana@laptop:~/shop$ docker exec shop-control-plane mv /root/kube-scheduler.yaml /etc/kubernetes/manifests/
ana@laptop:~/shop$ kubectl get pods -l app=shop -o wide
NAME                    READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
shop-774b84ff8c-4z28q   1/1     Running   0          63s   10.244.2.3   shop-worker2   <none>           <none>
shop-774b84ff8c-fgthg   1/1     Running   0          35s   10.244.1.4   shop-worker    <none>           <none>
shop-774b84ff8c-vbb5p   1/1     Running   0          35s   10.244.1.3   shop-worker    <none>           <none>
```

O escalonador novo subiu, encontrou dois pods sem nó e pôs os dois em `shop-worker`. Ninguém rodou o
comando de escala de novo. O trabalho estava esperando no API server o tempo todo, como objetos num
estado pelo qual alguém responde.

O mesmo vale para o resto do plano de controle. Sem o controller manager, nada substituiria um pod
apagado. Sem o próprio API server, nada poderia mudar, e os containers que já rodavam continuariam
rodando, porque cada kubelet mantém os pods que já tem. Um plano de controle que para é um cluster
que não consegue mudar, não um cluster que para de atender.
