---
title: Fora do cluster, uma escolha entre um salto e um endereço
version: 1
---

Uma requisição de fora chega a um nó, por um NodePort ou pelo load balancer na frente de um. **O nó a
que ela chega pode não rodar nenhum dos pods do Service**, e o que acontece então é a
`externalTrafficPolicy` do Service.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: shop-public
spec:
  type: NodePort
  externalTrafficPolicy: Cluster
  selector:
    app: shop
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
```

`Cluster` é o padrão, escrito aqui porque o próximo passo o muda. Antes das requisições, a loja foi
reduzida a uma cópia, para que dois dos três nós não tenham pod próprio:

```
ana@laptop:~/shop$ kubectl apply -f shop-public.yaml
service/shop-public created
ana@laptop:~/shop$ kubectl get pods -l app=shop -o wide
NAME                    READY   STATUS    RESTARTS   AGE   IP           NODE          NOMINATED NODE   READINESS GATES
shop-774b84ff8c-mt4qn   1/1     Running   0          13s   10.244.2.4   shop-worker   <none>           <none>
ana@laptop:~/shop$ kubectl get nodes -o custom-columns=NAME:.metadata.name,ADDRESS:.status.addresses[0].address
NAME                 ADDRESS
shop-control-plane   172.18.0.7
shop-worker          172.18.0.6
shop-worker2         172.18.0.5
```

O laptop chama o NodePort em cada nó, um de cada vez, e depois lê as três últimas linhas do log da
loja, que registra de onde veio cada requisição:

```
ana@laptop:~/shop$ for ip in 172.18.0.7 172.18.0.6 172.18.0.5 ; do echo -n "$ip: "; curl -s -m 2 $ip:30080 || echo no answer; done
172.18.0.7: shop 1.0 on shop-774b84ff8c-mt4qn
172.18.0.6: shop 1.0 on shop-774b84ff8c-mt4qn
172.18.0.5: shop 1.0 on shop-774b84ff8c-mt4qn
ana@laptop:~/shop$ kubectl logs deployment/shop --tail=3
2026-10-06T17:49:43Z GET / from 172.18.0.7:22551
2026-10-06T17:49:43Z GET / from 10.244.2.1:27346
2026-10-06T17:49:43Z GET / from 172.18.0.5:31359
```

**Todo nó respondeu, e o único pod atendeu as três.** Os dois nós sem pod repassaram a requisição
para `shop-worker`. Para receber a resposta de volta por eles mesmos, eles reescreveram o endereço de
origem com o seu próprio, então a loja viu `172.18.0.7` e `172.18.0.5` em vez do laptop. O nó com o
pod também o reescreveu, para o seu gateway na rede dos pods, `10.244.2.1`. **Sob `Cluster`, a
aplicação nunca fica sabendo quem chamou.**

## Local: nenhum salto, e o endereço de verdade

```
ana@laptop:~/shop$ kubectl patch service shop-public -p '{"spec":{"externalTrafficPolicy":"Local"}}'
service/shop-public patched
ana@laptop:~/shop$ for ip in 172.18.0.7 172.18.0.6 172.18.0.5 ; do echo -n "$ip: "; curl -s -m 2 $ip:30080 || echo no answer; done
172.18.0.7: no answer
172.18.0.6: shop 1.0 on shop-774b84ff8c-mt4qn
172.18.0.5: no answer
ana@laptop:~/shop$ kubectl logs deployment/shop --tail=1
2026-10-06T17:49:49Z GET / from 172.18.0.1:39834
```

Com `Local`, um nó só entrega uma requisição a um pod no mesmo nó. Os dois nós sem pod não deram
resposta nenhuma; o nó com o pod respondeu, e o log mostra `172.18.0.1`, o próprio endereço do laptop
na rede que o kind criou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dois painéis. À esquerda, externalTrafficPolicy Cluster: o laptop, em 172.18.0.1, manda uma requisição a cada um dos três nós, control-plane, worker e worker2. Só o worker roda o pod da loja. Os outros dois nós repassam a requisição para ele, então os três respondem, e o pod vê o endereço de um nó em vez do laptop. À direita, externalTrafficPolicy Local: as mesmas três requisições. Control-plane e worker2 não respondem; worker responde, e o pod dele vê 172.18.0.1.\"><defs><marker id=\"etp-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"etp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"etp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"330\" height=\"274\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">externalTrafficPolicy: Cluster</text><rect x=\"125\" y=\"48\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">laptop</text><text x=\"185.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">172.18.0.1</text><rect x=\"30\" y=\"170\" width=\"96\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"78.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">control-plane</text><path d=\"M185 90 L78 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#etp-ah-paper-dim)\"></path><rect x=\"137\" y=\"170\" width=\"96\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">worker</text><text x=\"185.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pod</text><path d=\"M185 90 L185 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#etp-ah-paper-dim)\"></path><rect x=\"244\" y=\"170\" width=\"96\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"292.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">worker2</text><path d=\"M185 90 L292 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#etp-ah-paper-dim)\"></path><path d=\"M78 228 L78 248 L175 248 L175 230\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#etp-ah-phosphor)\"></path><path d=\"M292 228 L292 248 L195 248 L195 230\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#etp-ah-phosphor)\"></path><text x=\"185\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">todos respondem; o pod vê o endereço de um nó</text><rect x=\"370\" y=\"14\" width=\"330\" height=\"274\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">externalTrafficPolicy: Local</text><rect x=\"475\" y=\"48\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">laptop</text><text x=\"535.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">172.18.0.1</text><rect x=\"380\" y=\"170\" width=\"96\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"428.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">control-plane</text><path d=\"M535 90 L428 168\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#etp-ah-amber)\"></path><text x=\"428\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">sem resposta</text><rect x=\"487\" y=\"170\" width=\"96\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">worker</text><text x=\"535.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pod</text><path d=\"M535 90 L535 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#etp-ah-paper-dim)\"></path><rect x=\"594\" y=\"170\" width=\"96\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"642.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">worker2</text><path d=\"M535 90 L642 168\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#etp-ah-amber)\"></path><text x=\"642\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">sem resposta</text><text x=\"535\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um responde; o pod vê 172.18.0.1</text></svg>", "caption": "Cluster gasta um salto e o endereço de quem chamou para tornar todo nó útil. Local guarda os dois, e torna inútil um nó sem pod."}
```

| | `Cluster` | `Local` |
|---|---|---|
| um nó sem pod | repassa para outro nó | recusa |
| o endereço que o pod vê | o de um nó | o de quem chamou |
| quão por igual os pods dividem a carga | por igual, entre todos os pods | por nó: dois pods num nó dividem a parte desse nó |
| um salto a mais | às vezes | nunca |

**`Local` só funciona com algo na frente que saiba quais nós evitar.** Um load balancer de nuvem sabe:
o Kubernetes dá a um Service `Local` uma porta de verificação de saúde, e cada nó responde a ela com
sucesso só enquanto roda um pod. O load balancer então manda o tráfego para esses nós e nenhum outro.
Uma pessoa digitando à mão o endereço de um nó, como acima, não recebe essa ajuda.

O motivo comum para escolher `Local` é a segunda linha da tabela: uma aplicação que registra, limita
ou bloqueia pelo endereço do cliente precisa do verdadeiro. A outra resposta comum é um proxy na
frente que escreve o endereço de quem chamou num cabeçalho, `X-Forwarded-For`, o que os controladores
de ingress da lição 16 fazem.
