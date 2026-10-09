---
title: Uma linha de aritmética, a cada quinze segundos
version: 1
---

O autoscaler lê seus números do metrics-server, que um cluster kind não tem, então esta aula começa
com `./up.sh` e o instala como a aula 21 fez:

```sh
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.9.0/components.yaml
```

Depois a loja, com uma réplica e um request de CPU de 200m. **O request importa mais aqui do que em qualquer
outro lugar**, porque o autoscaler mede cada pod como uma porcentagem do que ele pediu:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 1
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
            cpu: 200m
            memory: 32Mi
          limits:
            memory: 64Mi
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
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: shop
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: shop
  minReplicas: 1
  maxReplicas: 6
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 30
```

Leia o autoscaler como uma frase: mantenha `shop` entre uma e seis réplicas, mirando um uso médio de CPU
de 50% do request, que aqui é 100m por pod. O bloco `behavior` é o assunto da próxima seção.

```
ana@laptop:~/shop$ kubectl apply -f hpa.yaml
horizontalpodautoscaler.autoscaling/shop created
ana@laptop:~/shop$ kubectl get hpa shop
NAME   REFERENCE         TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
shop   Deployment/shop   cpu: 0%/50%   1         6         1          60s
```

`cpu: 0%/50%`: ninguém está chamando a loja, então a única réplica está parada e o autoscaler a deixa em
paz. Ele lê os números do metrics-server, instalado como na lição 21.

## Sob carga

Um pod busybox agora roda quatro laços ao mesmo tempo, cada um pedindo à loja 300 milissegundos de
trabalho por vez, durante dois minutos e meio. A primeira linha cria o pod; a segunda começa os laços e
segura o terminal até eles acabarem, então rode-a num segundo terminal:

```sh
kubectl run load --image=busybox:1.37 --restart=Never --command -- sleep 3600
kubectl exec load -- sh -c 'for n in 1 2 3 4; do (end=$(($(date +%s)+150)); while [ $(date +%s) -lt $end ]; do wget -qO- "shop/work?ms=300" >/dev/null; done) & done; wait'
```

Quarenta e cinco segundos depois, e de novo um minuto depois:

```
ana@laptop:~/shop$ kubectl get hpa shop
NAME   REFERENCE         TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
shop   Deployment/shop   cpu: 604%/50%   1         6         6          106s
ana@laptop:~/shop$ kubectl get hpa shop
NAME   REFERENCE         TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
shop   Deployment/shop   cpu: 174%/50%   1         6         6          2m46s
ana@laptop:~/shop$ kubectl get pods -l app=shop
NAME                   READY   STATUS    RESTARTS   AGE
shop-5b54594cd-8776z   1/1     Running   0          76s
shop-5b54594cd-96cg9   1/1     Running   0          2m47s
shop-5b54594cd-bxz6q   1/1     Running   0          76s
shop-5b54594cd-lzslv   1/1     Running   0          91s
shop-5b54594cd-prnp2   1/1     Running   0          76s
shop-5b54594cd-v2tfx   1/1     Running   0          76s
```

**604% contra um alvo de 50, e seis réplicas.** A fórmula que o controller aplica é

`desired = ceil(current replicas × current utilisation ÷ target utilisation)`

e aplicada a essa leitura com uma única réplica ela dá `ceil(1 × 604 ÷ 50) = 13`, muito além de
`maxReplicas`, que a limita a 6. Com seis cópias
dividindo o trabalho, a média caiu para 174%: ainda acima do alvo, mas o autoscaler não pode subir
mais, então fica no teto. Um teto de verdade é uma decisão sobre custo e sobre o que o banco por trás da
loja aguenta, e batê-lo é algo que merece um alerta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um ciclo de quatro passos. O metrics-server informa a CPU de cada pod. O HPA a divide pelo request do pod para obter a utilização, e tira a média. Ele calcula as réplicas desejadas como as réplicas atuais vezes a utilização atual sobre o alvo, arredondado para cima, e prende o resultado entre minReplicas e maxReplicas. Ele escreve o número em replicas do Deployment, e o Deployment acrescenta ou remove pods. Então o ciclo recomeça quinze segundos depois.\"><defs><marker id=\"hpa-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"hpa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">metrics-server</text><text x=\"105.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a CPU de cada pod</text><rect x=\"270\" y=\"30\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HPA</text><text x=\"360.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">÷ request = utilização</text><rect x=\"530\" y=\"30\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Deployment</text><text x=\"615.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">spec.replicas</text><rect x=\"170\" y=\"150\" width=\"380\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ceil(réplicas × utilização ÷ alvo)</text><text x=\"360.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">minReplicas ≤ n ≤ maxReplicas</text><path d=\"M192 58 L268 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hpa-ah-paper-dim)\"></path><path d=\"M360 88 L360 148\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hpa-ah-amber)\"></path><path d=\"M552 178 L615 178 L615 88\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hpa-ah-amber)\"></path><text x=\"624\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">réplicas</text><path d=\"M530 44 L500 14 L105 14 L105 28\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#hpa-ah-paper-dim)\"></path><text x=\"300\" y=\"8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a cada 15 s</text></svg>", "caption": "O autoscaler nunca toca num pod. Ele muda um número no Deployment e deixa o Deployment fazer o resto."}
```

Os eventos do autoscaler contam a história em ordem:

```
ana@laptop:~/shop$ kubectl get events --field-selector involvedObject.kind=HorizontalPodAutoscaler -o custom-columns=REASON:.reason,MESSAGE:.message
REASON                         MESSAGE
FailedGetResourceMetric        failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
FailedComputeMetricsReplicas   invalid metrics (1 invalid out of 1), first error is: failed to get cpu resource metric value: failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
SuccessfulRescale              New size: 2; reason: cpu resource utilization (percentage of request) above target
SuccessfulRescale              New size: 6; reason: cpu resource utilization (percentage of request) above target
```

As duas primeiras linhas são do minuto depois de o autoscaler ser criado, antes de o metrics-server ter
uma amostra do pod novo. **Sem medição ele não faz nada**, que é a falha segura. Depois dois passos,
para 2 e para 6: subir também é limitado por período, por padrão a dobrar ou a quatro pods a cada
quinze segundos, o que for maior, então um pico repentino é atendido em degraus.

Um pod sem request de CPU não pode ser medido como porcentagem, e o autoscaler se recusa a escalar por
ele. Esse é mais um motivo, além dos da lição 19, para sempre escrever requests.
