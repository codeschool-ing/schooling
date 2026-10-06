---
title: Dentro do cluster, uma moeda com pesos
version: 1
---

A lição 15 mostrou que o endereço de um Service não pertence a nenhuma máquina, e que o kube-proxy o
transforma no endereço de um pod em todo nó. **Como ele escolhe o pod depende do modo do kube-proxy**,
e este cluster roda o padrão, que escreve regras de iptables:

```
ana@laptop:~/shop$ kubectl -n kube-system get configmap kube-proxy -o jsonpath="{.data.config\.conf}" | grep "^mode"
mode: iptables
ana@laptop:~/shop$ kubectl get service shop -o custom-columns=NAME:.metadata.name,CLUSTER-IP:.spec.clusterIP
NAME   CLUSTER-IP
shop   10.96.189.143
```

A loja tem três cópias atrás do ClusterIP `10.96.189.143`. Um nó do kind é um container, então
`docker exec` lê as regras de um deles:

```
ana@laptop:~/shop$ docker exec shop-worker iptables-save -t nat | grep -E 'KUBE-SVC.*default/shop' | grep -v KUBE-MARK
-A KUBE-SVC-PFINMTQ5Y2TT4XZK -m comment --comment "default/shop -> 10.244.1.3:8080" -m statistic --mode random --probability 0.33333333349 -j KUBE-SEP-3WAOER3DW6LNFEFV
-A KUBE-SVC-PFINMTQ5Y2TT4XZK -m comment --comment "default/shop -> 10.244.1.4:8080" -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-YMTAF3BZORA45S74
-A KUBE-SVC-PFINMTQ5Y2TT4XZK -m comment --comment "default/shop -> 10.244.2.4:8080" -j KUBE-SEP-SAG3BBXNDBILXXFV
```

**Três regras, uma por pod, e a aritmética é o algoritmo inteiro.** A primeira regra manda uma conexão
para o primeiro pod com probabilidade de um terço. Uma conexão que não casou tenta a segunda regra, que
fica com metade do que sobrou. A última regra fica com tudo o que chegou até ela. Um terço, depois
metade de dois terços, depois o terço restante: cada pod recebe uma parte igual, decidida por um
sorteio a cada conexão.

Aleatório não é o mesmo que igual, e 300 requisições de um pod chamado `probe` mostram a diferença:

```
ana@laptop:~/shop$ kubectl exec probe -- sh -c "for i in \$(seq 300); do wget -qO- shop; done" | sort | uniq -c
     96 shop 1.0 on shop-774b84ff8c-hd42c
     91 shop 1.0 on shop-774b84ff8c-mt4qn
    113 shop 1.0 on shop-774b84ff8c-x7djd
```

96, 91 e 113, contra uma parte exata de 100 cada. Com muitas conexões as partes convergem; com poucas
elas variam. Nem o iptables nem o kube-proxy sabem o quanto um pod está ocupado, então um pod lento
continua recebendo o seu terço, e uma requisição longa conta o mesmo que uma curta.

**A escolha é feita por conexão, não por requisição.** Cada `wget` aqui abre uma conexão nova, então
cada um sorteia de novo. Um cliente que mantém uma conexão aberta, como fazem os clientes de HTTP/2 e
gRPC, manda todas as requisições por ela para o mesmo pod. Esse é o motivo comum de um pod de três
estar ocupado enquanto os outros ficam parados.

## Prendendo um cliente a um pod

Um Service pode parar de sortear a cada conexão e lembrar para onde um cliente foi:

```
ana@laptop:~/shop$ kubectl patch service shop -p '{"spec":{"sessionAffinity":"ClientIP"}}'
service/shop patched
ana@laptop:~/shop$ kubectl exec probe -- sh -c "for i in \$(seq 300); do wget -qO- shop; done" | sort | uniq -c
    300 shop 1.0 on shop-774b84ff8c-mt4qn
ana@laptop:~/shop$ kubectl patch service shop -p '{"spec":{"sessionAffinity":"None"}}'
service/shop patched
```

`sessionAffinity: ClientIP` mandou as 300 requisições para um pod, porque todas vieram do mesmo
endereço. O kube-proxy lembra de cada cliente por três horas por padrão
(`sessionAffinityConfig.clientIP.timeoutSeconds`).

**Raramente é a correção certa.** Muitos clientes atrás de um gateway compartilham um endereço, então
todos caem num pod só. A afinidade também acaba quando esse pod vai embora, então o que a aplicação
guardava na memória se perde de qualquer jeito. Guardar a sessão num lugar que toda cópia consegue
ler, um banco ou um cache, elimina a necessidade de afinidade. O patch no fim devolve o Service para
`None`.

O kube-proxy também tem um modo `nftables`, que faz o mesmo sorteio pela interface mais nova do kernel.
Uma escolha mais esperta, como o pod com menos conexões, vem de substituir o kube-proxy por inteiro, o
que alguns plugins de rede fazem, o Cilium entre eles. Este laboratório não rodou nenhum dos dois.
