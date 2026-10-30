---
title: Deployment safeguards, e os manifestos que elas recusam
version: 1
---

Duas imagens das deployment safeguards são comuns. Uma é um linter, algo que lê o seu YAML num
pipeline e imprime conselhos. A outra é o Kubernetes sendo rigoroso: certamente um cluster recusa um
pod que não diz nada sobre memória. Nenhuma das duas está certa. O Kubernetes aceita esse pod, como
esta seção mostra, e nada no seu pipeline participa. **As deployment safeguards são regras do Azure
Policy que o API server consulta como uma checagem de admissão, toda vez que um objeto é criado ou
atualizado.** A documentação da Microsoft diz que o Azure Policy estende o Gatekeeper, o controlador
de admissão do Open Policy Agent para Kubernetes, para fazer isso. A regra roda dentro do cluster,
no momento do `kubectl apply`, seja quem for que estiver digitando.

## Warn e Enforce

As salvaguardas têm dois níveis:

- `Warn` deixa o pedido passar e imprime um aviso no terminal de quem o enviou;
- `Enforce` recusa um pedido que quebra uma regra e, para algumas regras, **muta** o pedido
  antes: muda o objeto para que ele cumpra a regra, e então o deixa passar.

No Standard elas são uma opção, em qualquer dos dois níveis. **No Automatic elas estão ligadas, em
`Enforce`, e não podem ir para `Warn`.** Você pode excluir namespaces, e esse é o único jeito de
contorná-las. O Pod Security Standard baseline também é aplicado, e a documentação diz que ele não
pode ser desligado no Automatic: nada de contêineres privilegiados, de namespaces de rede ou de
processos do host, de `hostPort`. A documentação da Microsoft, lida em 30 de outubro de 2026, lista
as salvaguardas assim:

| salvaguarda | o que ela pede de uma carga |
|---|---|
| resource requests | todo contêiner tem requests de CPU e de memória; mutada |
| anti-affinity ou topology spread | uma carga com várias réplicas diz como espalhá-las pelos nodes; mutada |
| probes | todo contêiner tem uma readiness probe e uma liveness probe |
| sem `latest` | uma tag de imagem explícita, que não seja `latest` nem vazia |
| imagens permitidas | os contêineres usam só imagens que uma lista de permissões aceita |
| seletores únicos | dois services não selecionam com o mesmo seletor |
| storage classes CSI | as storage classes usam os drivers CSI, não os provisionadores in-tree antigos |
| sem rótulos do AKS | nenhuma carga leva um rótulo em `kubernetes.azure.com` |
| sem edição de um node só | nodes recebem rótulos e taints por pool, não um de cada vez |
| taints reservados de sistema | o `CriticalAddonsOnly` fica nos pools de sistema |

As duas últimas teriam recusado parte da aula 11: `kubectl taint nodes shop-worker` é exatamente a
edição de um node só, recusada com *Tainting or labeling individual nodes is not recommended. Please
use Azure CLI to taint/label node pools instead*.

O nível é definido pela linha de comando num cluster em que você pode mudá-lo; isto lista os
valores:

```
ana@laptop:~/azure$ az aks safeguards update --help | grep -A1 -- "^    --level"
    --level                             : The deployment safeguards level. Possible values are Warn
                                          and Enforce.  Allowed values: Enforce, Warn.
```

## O shop como costuma ser escrito da primeira vez

Um manifesto escrito com pressa se parece com este: a imagem do shop pela tag `latest`, nada sobre
recursos, nenhuma probe. Salve como `hurried.yaml`:

```yaml
# hurried.yaml: the shop as it is often first written.
apiVersion: v1
kind: Pod
metadata:
  name: hurried
spec:
  containers:
  - name: shop
    image: shop:latest
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 8080
```

O `imagePullPolicy: IfNotPresent` está ali por causa do kind, como na aula 11, e a parte seguinte
desta seção mostra o que tirá-lo faz. A imagem precisa da segunda tag, e os nodes precisam da cópia
com essa tag:

```
ana@laptop:~/azure$ docker tag shop:1.0 shop:latest
ana@laptop:~/azure$ kind load docker-image shop:latest --name shop
Image: "shop:latest" with ID "sha256:7c124f4e5b5b8fe4d6f2f0f60719afcb74b2083478cbd0ac04e69eb37e43b6dd" not yet present on node "shop-worker", loading...
Image: "shop:latest" with ID "sha256:7c124f4e5b5b8fe4d6f2f0f60719afcb74b2083478cbd0ac04e69eb37e43b6dd" not yet present on node "shop-control-plane", loading...
Image: "shop:latest" with ID "sha256:7c124f4e5b5b8fe4d6f2f0f60719afcb74b2083478cbd0ac04e69eb37e43b6dd" not yet present on node "shop-worker2", loading...
ana@laptop:~/azure$ kubectl apply -f hurried.yaml
pod/hurried created
ana@laptop:~/azure$ kubectl wait --for=condition=Ready pod/hurried --timeout=60s
pod/hurried condition met
ana@laptop:~/azure$ kubectl get pod hurried -o custom-columns=POD:.metadata.name,STATUS:.status.phase,QOS:.status.qosClass
POD       STATUS    QOS
hurried   Running   BestEffort
```

**O Kubernetes aceitou sem dizer nada, e o pod está rodando.** O que ele fez com os requests que
faltavam está na última linha: a classe de qualidade de serviço do pod é `BestEffort`, a classe de
um pod cujos contêineres não pedem nada e não são limitados por nada. Três coisas vêm disso, e cada
uma é o motivo de uma salvaguarda:

- o scheduler conta os requests dele como zero, então ele pode ir para um node que já está cheio;
- quando esse node fica sem memória, o kubelet despeja os pods `BestEffort` primeiro;
- o node auto-provisioning dimensiona máquinas pelos requests, então um pod que não pede nada não
  dá a ele nada para dimensionar, o que anula o mecanismo da seção anterior.

A tag tem um custo próprio, e o API server o mostra quando a linha de que o kind precisa sai. A
cópia ganha outro nome, porque os contêineres de um pod em execução não podem ser mudados e o
servidor a compararia com o `hurried`. O `--dry-run=server` devolve o objeto como ele seria gravado,
com os padrões preenchidos:

```
ana@laptop:~/azure$ sed -e '/imagePullPolicy/d' -e 's/name: hurried/name: hurried-2/' hurried.yaml > nopolicy.yaml
ana@laptop:~/azure$ kubectl apply --dry-run=server -f nopolicy.yaml -o jsonpath='{.spec.containers[0].imagePullPolicy}{"\n"}'
Always
ana@laptop:~/azure$ sed -i 's/shop:latest/shop:1.0/' nopolicy.yaml
ana@laptop:~/azure$ kubectl apply --dry-run=server -f nopolicy.yaml -o jsonpath='{.spec.containers[0].imagePullPolicy}{"\n"}'
IfNotPresent
```

**Uma tag `latest` muda a política de pull padrão para `Always`**, enquanto a tag fixa `1.0` fica com
`IfNotPresent`. Todo pod novo do primeiro tipo consulta o registry de novo, e o que roda é aquilo
para que a tag aponta naquele dia. Duas réplicas iniciadas com uma semana de diferença podem rodar
dois programas diferentes com um mesmo nome, e um rollback não tem para onde voltar, que é o
argumento que a aula 10 fez a favor dos digests.

Num cluster Automatic esse pod não teria sido gravado. A regra de resource requests muta, então os
requests que faltam são preenchidos, mas a regra de probes e a regra de `latest` só recusam. A
resposta do API server começaria com *Error from server (Forbidden)* e traria a mensagem da
salvaguarda, como *Container shop in your Pod hurried has no livenessProbe. Required probes:
readinessProbe, livenessProbe*. Nada neste lab aplica isso: o kind não tem Azure Policy. A mensagem
foi citada da documentação da Microsoft.

## O que a mutação teria escolhido

Quando um contêiner não tem requests nem limits, o mutador de resource requests os escreve, e a
documentação dá os valores:

| | request | limit |
|---|---|---|
| CPU | `500m` | `500m` |
| memória | `2048Mi` | `2048Mi` |

Quando um valor existe mas é pequeno, ele sobe para um mínimo de `100m` de CPU e `100Mi` de memória.
Requests iguais aos limits põem o pod na classe `Guaranteed`, então a mutação de fato deixa o pod
bem-comportado. **Ela também o deixa caro.** O shop é um servidor Python pequeno; dez réplicas
mutadas para 2 GiB cada pedem ao NAP 20 GiB de memória, e o NAP compra nodes à altura. Um request
escrito por alguém que mediu o programa é a resposta mais barata, e a única que o mutador não
consegue escrever por você.

O mutador de anti-affinity faz o mesmo para a distribuição: uma carga sem pod anti-affinity e sem
topology spread constraint ganha as duas, preferindo uma réplica por node e nunca deixando de
agendar por causa disso.

## O shop como as salvaguardas pedem

O Deployment do shop, reescrito para passar em todas as regras, que é também como ele deveria ter
sido escrito na aula 11. Salve por cima do `shop.yaml` da aula 11:

```schooling-example
{"language": "yaml", "file": "shop.yaml", "parts": [{"code": "# shop.yaml\napiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: shop\nspec:\n  replicas: 3\n  selector:\n    matchLabels:\n      app: shop\n  template:\n    metadata:\n      labels:\n        app: shop\n    spec:\n", "note": "O Deployment da aula 11, sem o `nodeSelector`: um cluster Automatic não tem pool chamado `apps` para selecionar, e o node que um pod recebe é escolha do NAP."}, {"code": "      topologySpreadConstraints:\n      - maxSkew: 1\n        topologyKey: kubernetes.io/hostname\n        whenUnsatisfiable: ScheduleAnyway\n        labelSelector:\n          matchLabels:\n            app: shop\n", "note": "**A regra de distribuição, escrita por você em vez de acrescentada pelo mutador.** Nenhum node pode ter mais de uma réplica a mais que outro, e quando isso não dá para cumprir o pod é agendado mesmo assim: são as configurações que a documentação diz que o mutador usa."}, {"code": "      containers:\n      - name: shop\n        image: shop:1.0\n        imagePullPolicy: IfNotPresent\n        ports:\n        - containerPort: 8080\n", "note": "Uma tag fixa. `IfNotPresent` já é o padrão para ela, e fica escrito por causa do kind, que não tem registry para consultar."}, {"code": "        resources:\n          requests:\n            cpu: 100m\n            memory: 128Mi\n          limits:\n            cpu: 100m\n            memory: 128Mi\n", "note": "**Requests iguais aos limits**, no mínimo do mutador para CPU e um pouco acima dele para memória: o bastante para um servidor Python pequeno, e um dezesseis avos do que o mutador teria pedido."}, {"code": "        readinessProbe:\n          httpGet:\n            path: /healthz\n            port: 8080\n          periodSeconds: 2\n        livenessProbe:\n          httpGet:\n            path: /healthz\n            port: 8080\n          periodSeconds: 10\n          failureThreshold: 3\n", "note": "As duas probes no `/healthz` do shop. A readiness decide se o pod recebe tráfego e conta como disponível; a liveness reinicia um contêiner que parou de responder por trinta segundos."}]}
```

O pod apressado sai, e o shop chega:

```
ana@laptop:~/azure$ kubectl delete pod hurried
pod "hurried" deleted from default namespace
ana@laptop:~/azure$ kubectl apply -f shop.yaml
deployment.apps/shop created
ana@laptop:~/azure$ kubectl rollout status deployment/shop --timeout=120s
Waiting for deployment "shop" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "shop" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "shop" rollout to finish: 2 of 3 updated replicas are available...
deployment "shop" successfully rolled out
ana@laptop:~/azure$ kubectl get pods -l app=shop -o custom-columns=POD:.metadata.name,NODE:.spec.nodeName,QOS:.status.qosClass,READY:.status.containerStatuses[0].ready
POD                     NODE           QOS          READY
shop-6897f59f8b-67fw4   shop-worker    Guaranteed   true
shop-6897f59f8b-qpt99   shop-worker2   Guaranteed   true
shop-6897f59f8b-r7qr8   shop-worker    Guaranteed   true
```

**`Guaranteed`, pronto, e espalhado pelos dois workers.** Nada aqui foi checado por uma salvaguarda:
o kind não tem nenhuma, e o manifesto teria sido aceito sem nenhuma destas linhas. A transcrição
mostra outra coisa: o manifesto que as salvaguardas pedem é também o que o Kubernetes trata melhor.
Os pods dele são os últimos a ser despejados, o scheduler e o NAP sabem o tamanho deles, e um node
perdido leva no máximo duas das três réplicas consigo.

## Rotulando um node

Mais uma edição de um node só, do tipo que a aula 11 fez com o taint dela, que o Kubernetes permite:

```
ana@laptop:~/azure$ kubectl label node shop-worker team=shop
node/shop-worker labeled
```

No Automatic, esse comando é recusado pela salvaguarda contra edição de um node só, e os managed
system nodes têm uma restrição própria contra exatamente isso. Um rótulo pensado para um grupo de
nodes pertence a um NodePool, no template dele, onde o NAP o escreve em todo node que cria.

Isso é tudo para o que esta aula precisa do cluster. Apague-o:

```
ana@laptop:~/azure$ kind delete cluster --name shop
Deleting cluster "shop" ...
Deleted nodes: ["shop-worker" "shop-control-plane" "shop-worker2"]
```

## Onde as regras param

Dois limites estão na documentação e vale conhecê-los antes de confiar nas regras. **As
salvaguardas são tudo ou nada**: depois de ligadas, todas as regras ficam ativas, e você não escolhe
algumas delas. E **o Gatekeeper falha aberto**: se o webhook de admissão não responde ao API server
a tempo, a checagem é pulada e o objeto é admitido, para que um serviço de política lento nunca
bloqueie todos os deployments do cluster. Uma salvaguarda é, portanto, um padrão forte e não uma
prova: uma carga fora das regras pode estar no cluster, e é na visão de conformidade do Azure Policy,
não na resposta da admissão, que você a encontra.
