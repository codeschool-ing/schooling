---
title: NoExecute, e os taints que o Kubernetes põe sozinho
version: 1
---

`NoSchedule` só afeta pods sendo alocados; o que já roda no nó fica. **`NoExecute` também despeja os
pods que já estão lá** e não o toleram, o que o torna a ferramenta para tirar um nó de serviço. Antes,
`shop-worker` roda os quatro pods da loja:

```
ana@laptop:~/shop$ kubectl get pods -o wide --field-selector spec.nodeName=shop-worker
NAME                    READY   STATUS    RESTARTS   AGE   IP           NODE          NOMINATED NODE   READINESS GATES
shop-774b84ff8c-f7xmw   1/1     Running   0          2s    10.244.2.5   shop-worker   <none>           <none>
shop-774b84ff8c-krnt6   1/1     Running   0          2s    10.244.2.6   shop-worker   <none>           <none>
shop-774b84ff8c-wdkn8   1/1     Running   0          2s    10.244.2.3   shop-worker   <none>           <none>
shop-774b84ff8c-wv2nq   1/1     Running   0          2s    10.244.2.4   shop-worker   <none>           <none>
```

O nó é marcado para manutenção:

```
ana@laptop:~/shop$ kubectl taint node shop-worker maintenance=now:NoExecute
node/shop-worker tainted
ana@laptop:~/shop$ kubectl get pods -o wide -l app=shop
NAME                    READY   STATUS    RESTARTS   AGE   IP       NODE     NOMINATED NODE   READINESS GATES
shop-774b84ff8c-9rs89   0/1     Pending   0          10s   <none>   <none>   <none>           <none>
shop-774b84ff8c-lvnbq   0/1     Pending   0          10s   <none>   <none>   <none>           <none>
shop-774b84ff8c-qhhrf   0/1     Pending   0          9s    <none>   <none>   <none>           <none>
shop-774b84ff8c-thw2h   0/1     Pending   0          10s   <none>   <none>   <none>           <none>
```

**Todo pod da loja foi despejado e substituído, e os quatro substitutos estão `Pending`.** Não podem
voltar para `shop-worker`, que agora tem um taint `NoExecute`; não podem ir para `shop-worker2`, ainda
reservado aos relatórios; e o nó control-plane não aceita pods comuns. A loja está fora do ar. Os
eventos citam o componente que fez isso:

```
ana@laptop:~/shop$ kubectl get events --field-selector reason=TaintManagerEviction -o custom-columns=OBJECT:.involvedObject.name,MESSAGE:.message | head -n 3
OBJECT                  MESSAGE
shop-774b84ff8c-f7xmw   Marking for deletion Pod default/shop-774b84ff8c-f7xmw
shop-774b84ff8c-krnt6   Marking for deletion Pod default/shop-774b84ff8c-krnt6
```

`TaintManagerEviction`: o controller que observa taints `NoExecute` apagou cada pod. Essa é a versão
bruta de tirar um nó de serviço. A lição 32 mostra o `kubectl drain`, que faz o mesmo trabalho
respeitando um orçamento de quantas cópias podem estar fora ao mesmo tempo, e que teria se recusado a
deixar a loja sem nenhuma.

Os dois taints saem com o mesmo comando e um sinal de menos no fim:

```
ana@laptop:~/shop$ kubectl taint node shop-worker maintenance=now:NoExecute-
node/shop-worker untainted
ana@laptop:~/shop$ kubectl taint node shop-worker2 dedicated=reports:NoSchedule-
node/shop-worker2 untainted
ana@laptop:~/shop$ kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints[*].key
NAME                 TAINTS
shop-control-plane   node-role.kubernetes.io/control-plane
shop-worker          <none>
shop-worker2         <none>
```

Sem os taints, as cópias `Pending` são alocadas na primeira tentativa do scheduler.

## Os taints que ninguém digitou

Todo pod carrega duas tolerations que ninguém escreveu:

```
ana@laptop:~/shop$ kubectl get pod -l app=shop -o jsonpath="{.items[0].spec.tolerations}"; echo
[{"effect":"NoExecute","key":"node.kubernetes.io/not-ready","operator":"Exists","tolerationSeconds":300},{"effect":"NoExecute","key":"node.kubernetes.io/unreachable","operator":"Exists","tolerationSeconds":300}]
```

**Quando um nó para de dar notícias, o próprio Kubernetes põe um taint nele**, com
`node.kubernetes.io/unreachable` ou `node.kubernetes.io/not-ready`, os dois `NoExecute`. Essas
tolerations padrão deixam um pod ficar num nó assim por `tolerationSeconds: 300`, cinco minutos, antes
de ser despejado e substituído em outro lugar. Essa é a espera
escondida na promessa da lição 1 de que as cópias de uma máquina perdida sobem de novo em outro lugar,
e a lição 32 assiste a isso acontecer. O número pode ser definido por pod: menor para um serviço sem estado que deve
se mudar rápido, maior para um pod cuja substituição é cara.

| efeito | pods novos | pods que já estão lá |
|---|---|---|
| `NoSchedule` | recusados | ficam |
| `PreferNoSchedule` | evitados se possível | ficam |
| `NoExecute` | recusados | despejados, depois de `tolerationSeconds` se definirem um |
