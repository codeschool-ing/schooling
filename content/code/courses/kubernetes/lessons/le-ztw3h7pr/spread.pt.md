---
title: Espalhando cópias com um limite para a diferença
version: 1
---

A anti-afinidade da lição 29 espalhou cópias proibindo duas no mesmo lugar. Isso funciona para três
cópias e três nós, e falha para seis cópias e duas zonas: a regra não pode ser atendida, e as cópias
a mais esperam. **Uma topology spread constraint pede algo mais fraco e mais útil**: espalhe os pods
pelos domínios, e nunca deixe o domínio mais cheio ter mais do que `maxSkew` pods acima do mais vazio.

Nós do kind não têm zonas, então depois do `./up.sh` os dois workers recebem os rótulos de zona que os
nós de uma nuvem já trazem desde o início:

```sh
kubectl label node shop-worker topology.kubernetes.io/zone=sa-east-1a
kubectl label node shop-worker2 topology.kubernetes.io/zone=sa-east-1b
```

```
ana@laptop:~/shop$ kubectl get nodes -L topology.kubernetes.io/zone
NAME                 STATUS   ROLES           AGE   VERSION   ZONE
shop-control-plane   Ready    control-plane   26s   v1.37.0   
shop-worker          Ready    <none>          16s   v1.37.0   sa-east-1a
shop-worker2         Ready    <none>          16s   v1.37.0   sa-east-1b
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 6
  selector:
    matchLabels:
      app: shop
  template:
    metadata:
      labels:
        app: shop
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: shop
      containers:
      - name: shop
        image: shop:1.0
```

A constraint se lê: em `topology.kubernetes.io/zone`, conte os pods rotulados `app: shop`, e não
aloque um pod onde isso deixaria a diferença entre zonas maior que 1.

```
ana@laptop:~/shop$ kubectl apply -f spread.yaml
deployment.apps/shop created
ana@laptop:~/shop$ kubectl get pods -l app=shop -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName --sort-by=.spec.nodeName
NAME                    NODE
shop-7c8fc6c98c-4nlqv   shop-worker
shop-7c8fc6c98c-bbwdf   shop-worker
shop-7c8fc6c98c-dd6wh   shop-worker
shop-7c8fc6c98c-dkmvx   shop-worker2
shop-7c8fc6c98c-qthb5   shop-worker2
shop-7c8fc6c98c-sxrh5   shop-worker2
```

**Três e três.** A anti-afinidade com uma cópia por zona teria alocado duas e deixado quatro
esperando. Agora mais uma:

```
ana@laptop:~/shop$ kubectl scale deployment shop --replicas=7
deployment.apps/shop scaled
ana@laptop:~/shop$ kubectl get pods -l app=shop -o custom-columns=NODE:.spec.nodeName --no-headers | sort | uniq -c
      3 shop-worker
      4 shop-worker2
```

Quatro e três, uma diferença de 1, que `maxSkew: 1` permite. Uma oitava cópia teria de ir para
`shop-worker`, a zona com três, e uma nona então poderia ir para qualquer uma.

| campo | diz |
|---|---|
| `topologyKey` | qual rótulo de nó define um domínio: uma zona, um nó, um rack |
| `maxSkew` | a maior diferença permitida entre o domínio mais cheio e o mais vazio |
| `whenUnsatisfiable` | `DoNotSchedule` espera, como uma exigência; `ScheduleAnyway` aloca e só prefere o espalhamento igual |
| `labelSelector` | quais pods são contados |

**Duas constraints juntas são comuns**: uma sobre zonas com `DoNotSchedule`, para que a falha de uma
zona nunca leve mais do que a parte dela, e uma sobre `kubernetes.io/hostname` com `ScheduleAnyway`,
para que dentro de uma zona as cópias também caiam em nós diferentes quando puderem. A constraint é
conferida quando um pod é alocado, como toda regra da lição 29, então um cluster que perdeu uma zona e
a recuperou fica desigual até algo substituir pods.
