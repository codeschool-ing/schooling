---
title: Abrindo um caminho de cada vez
version: 1
---

Com `deny-all` no lugar, o namespace não aceita nada. **Políticas só acrescentam permissões**: uma
segunda política não consegue tirar nada da primeira, só consegue permitir mais. Então os caminhos da
loja são abertos acrescentando uma pequena política por caminho.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-front
  namespace: shop
spec:
  podSelector:
    matchLabels:
      app: shop
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: front
    ports:
    - port: 8080
```

Leia de cima para baixo. `podSelector` escolhe os pods que a política protege: os rotulados
`app: shop`. A regra `ingress` diz quem pode se conectar a eles: pods rotulados `app: front`, no mesmo
namespace, e só na porta 8080, a porta em que o container da loja escuta (não a porta 80 do Service,
porque a política é conferida contra o pacote que chega ao pod).

```
ana@laptop:~/shop$ kubectl apply -f allow-front.yaml
networkpolicy.networking.k8s.io/allow-front created
ana@laptop:~/shop$ kubectl -n shop exec front -- wget -qO- -T 3 shop
shop 1.0 on shop-774b84ff8c-4zxcl
ana@laptop:~/shop$ kubectl -n other exec stranger -- wget -qO- -T 3 shop.shop
wget: download timed out
command terminated with exit code 1
```

`front` passa e `stranger` continua sem passar. Um `podSelector` dentro de `from` só casa com pods do
próprio namespace da política, então `stranger`, em `other`, não é um deles, sejam quais forem os
rótulos dele.

```
ana@laptop:~/shop$ kubectl get networkpolicies -n shop
NAME          POD-SELECTOR   AGE
allow-front   app=shop       8s
deny-all      <none>         20s
```

Duas políticas agora selecionam os pods da loja, e uma conexão é permitida se **qualquer** uma delas
permitir. É por isso que a ordem em que foram aplicadas não importa, e por isso não existe regra de
"negar" para escrever: o que nenhuma política permite, num pod que alguma política seleciona, é
recusado.

## Um namespace inteiro como origem

Suponha que `other` seja o namespace da equipe de monitoramento, e que as sondas dela precisem
alcançar a loja. Listar os pods dela por rótulo amarraria a política da loja ao jeito como outra
equipe rotula os seus pods. **Selecionar o namespace dela pelos rótulos** amarra a algo que os
operadores do cluster controlam:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-monitoring
  namespace: shop
spec:
  podSelector:
    matchLabels:
      app: shop
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          purpose: monitoring
    ports:
    - port: 8080
```

```
ana@laptop:~/shop$ kubectl apply -f allow-monitoring.yaml
networkpolicy.networking.k8s.io/allow-monitoring created
ana@laptop:~/shop$ kubectl label namespace other purpose=monitoring
namespace/other labeled
ana@laptop:~/shop$ kubectl -n other exec stranger -- wget -qO- -T 3 shop.shop
shop 1.0 on shop-774b84ff8c-4zxcl
```

A política foi aplicada primeiro e não casou com nada, porque nenhum namespace tinha o rótulo. No
momento em que `other` recebeu o rótulo `purpose=monitoring`, todo pod dele passou a alcançar a loja na
porta 8080, e a política não mudou. Esse também é o risco: quem pode rotular namespaces agora pode
abrir este caminho. O Kubernetes rotula todo namespace com `kubernetes.io/metadata.name` e o próprio
nome, um rótulo que ninguém consegue mudar, e selecionar por ele é a escolha mais segura quando a
origem é um namespace em particular.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Dois namespaces. Em shop, o pod front e os pods de shop, porta 8080. Em other, rotulado purpose monitoring, o pod stranger. Sob deny-all, toda seta para dentro de shop é cortada. allow-front abre a seta de front para shop na 8080. allow-monitoring abre a seta de qualquer pod num namespace rotulado purpose monitoring para shop na 8080. Saindo de front, front-egress só permite shop na 8080, e front-dns permite o kube-dns na porta 53.\"><defs><marker id=\"np-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"np-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"420\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"36\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">namespace: shop</text><rect x=\"470\" y=\"20\" width=\"230\" height=\"110\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"486\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">namespace: other</text><text x=\"486\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">purpose=monitoring</text><text x=\"585\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">namespace: kube-system</text><rect x=\"50\" y=\"90\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">front</text><text x=\"110.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">app=front</text><rect x=\"290\" y=\"90\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><text x=\"350.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">app=shop :8080</text><rect x=\"525\" y=\"70\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">stranger</text><rect x=\"525\" y=\"196\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">kube-dns</text><text x=\"585.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">:53</text><path d=\"M172 115 L288 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#np-ah-phosphor)\"></path><text x=\"230\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">allow-front</text><path d=\"M523 92 L412 108\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#np-ah-phosphor)\"></path><text x=\"585\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">allow-monitoring</text><path d=\"M110 142 L110 218 L523 218\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#np-ah-amber)\"></path><text x=\"300\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">front-dns</text><text x=\"230\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">front-egress</text></svg>", "caption": "Cada seta é uma regra que alguém escreveu. Tudo o que não tem seta é recusado, assim que uma política seleciona o pod daquela ponta."}
```
