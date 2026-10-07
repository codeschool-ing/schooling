---
title: O que o recomendador sugere
version: 1
---

**O Vertical Pod Autoscaler tem três partes**: um recomendador que observa o uso e calcula requests, um
updater que despeja pods cujos requests estão longe da recomendação, e um admission controller que
escreve os requests recomendados nos pods novos. Esta aula instala só o recomendador, com as CRDs e o
RBAC do projeto, porque ler recomendações é o primeiro passo seguro, e é o que `updateMode: "Off"` pede
de qualquer jeito. Ele lê o uso do metrics-server, então um `./up.sh` novo recebe os dois, o
metrics-server como na aula 21 e depois o recomendador a partir dos manifestos do próprio projeto, na
versão que este curso usou:

```sh
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.9.0/components.yaml
```

```sh
BASE=https://raw.githubusercontent.com/kubernetes/autoscaler/vertical-pod-autoscaler-1.8.0/vertical-pod-autoscaler/deploy
kubectl apply -f $BASE/vpa-v1-crd-gen.yaml -f $BASE/vpa-rbac.yaml -f $BASE/recommender-deployment.yaml
kubectl -n kube-system rollout status deployment/vpa-recommender
```

Na máquina em que o curso foi gravado, as duas imagens foram compiladas do código-fonte dos projetos
nessas versões, porque o registro delas não era alcançável de lá; os manifestos são os mesmos.

A loja, com requests errados de propósito, muito menos CPU do que ela usa sob carga e muito mais memória
do que ela usa:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 2
  selector:
    matchLabels:
      app: shop
  template:
    metadata:
      labels:
        app: shop
    spec:
      containers:
      - name: shop
        image: shop:1.0
        resources:
          requests:
            cpu: 50m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: shop
spec:
  selector:
    app: shop
  ports:
  - port: 80
    targetPort: 8080
```

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: shop
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: shop
  updatePolicy:
    updateMode: "Off"
```

```
ana@laptop:~/shop$ kubectl apply -f shop.yaml -f vpa.yaml
deployment.apps/shop created
service/shop created
verticalpodautoscaler.autoscaling.k8s.io/shop created
```

Um pod busybox manteve a loja ocupada, pedindo a ela um décimo de segundo de trabalho em loop:

```sh
kubectl run load --image=busybox:1.37 --restart=Never --command -- sh -c "while true; do wget -qO- shop/work?ms=100 >/dev/null; done"
```

Quatro minutos depois:

```
ana@laptop:~/shop$ kubectl get vpa shop
NAME   MODE   CPU    MEM     PROVIDED   AGE
shop   Off    671m   250Mi   True       4m1s
ana@laptop:~/shop$ kubectl get vpa shop -o jsonpath='{range .status.recommendation.containerRecommendations[*]}{.containerName}: lower {.lowerBound} target {.target} upper {.upperBound}{"\n"}{end}'
shop: lower {"cpu":"181m","memory":"250Mi"} target {"cpu":"671m","memory":"250Mi"} upper {"cpu":"496178m","memory":"8503807692"}
ana@laptop:~/shop$ kubectl top pods -l app=shop
NAME                   CPU(cores)   MEMORY(bytes)   
shop-8c87b866c-b4f85   446m         5Mi             
shop-8c87b866c-tsbst   497m         6Mi             
```

**O alvo é 671m de CPU e 250Mi de memória**, contra 50m e 256Mi pedidos. O número de CPU segue a
medição: os dois pods usavam uns 450m a 500m cada, e o recomendador acrescenta uma margem. O número de
memória é um piso, não uma medição: a loja usa alguns mebibytes, mas o recomendador nunca sugere menos
de 250Mi se não for mandado, então sobre memória ele quase não diz nada aqui. **Leia uma recomendação
contra o uso antes de aplicá-la.**

Os limites dizem o quanto ele tem certeza. Depois de quatro minutos o limite superior é enorme, porque o
recomendador tem pouco histórico e alarga a faixa para compensar; ela estreita ao longo de dias. É o
mesmo ponto que a lição 21 fez sobre uma leitura do `kubectl top`, embutido nos números.

| `updateMode` | o que o VPA faz |
|---|---|
| `Off` | só recomenda, como aqui |
| `Initial` | define requests em pods novos, nunca mexe nos que rodam |
| `Recreate` | despeja pods para lhes dar requests novos |
| `InPlaceOrRecreate` | redimensiona pods no lugar onde consegue, despeja onde não consegue |

**Não deixe um VPA e um HPA agirem sobre CPU no mesmo Deployment.** O VPA sobe os requests porque o uso
está alto, o HPA vê a utilização cair como porcentagem do request maior e remove pods, e um desfaz o
outro.
