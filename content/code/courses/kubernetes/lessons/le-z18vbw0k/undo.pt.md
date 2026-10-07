---
title: Uma versão que quebra, e o caminho de volta
version: 1
---

A loja sai ao iniciar quando a variável `CRASH` está definida, o que dá uma versão ruim conveniente.
Mudar uma variável de ambiente muda o modelo de pod, então é um rollout como outro qualquer:

```
ana@laptop:~/shop$ kubectl set env deployment/shop CRASH=1
deployment.apps/shop env updated
ana@laptop:~/shop$ kubectl rollout status deployment/shop --timeout=10s
Waiting for deployment "shop" rollout to finish: 1 out of 4 new replicas have been updated...
error: timed out waiting for the condition
ana@laptop:~/shop$ kubectl get pods -l app=shop
NAME                    READY   STATUS             RESTARTS      AGE
shop-5cdd5f6b94-nwssx   0/1     CrashLoopBackOff   3 (15s ago)   50s
shop-997ffd576-2cg2c    1/1     Running            0             81s
shop-997ffd576-dvvbf    1/1     Running            0             80s
shop-997ffd576-j8ql6    1/1     Running            0             80s
shop-997ffd576-xjdql    1/1     Running            0             79s
ana@laptop:~/shop$ kubectl exec probe -- sh -c "for i in \$(seq 300); do wget -qO- -T 2 shop || echo FAILED; sleep 0.1; done" | cut -d" " -f1,2 | sort | uniq -c
    300 shop 2.0
```

**O rollout parou sozinho, num pod.** O pod novo nunca ficou pronto, então com `maxUnavailable: 0`
nenhum pod antigo pôde sair, e com `maxSurge: 1` nenhum segundo pod novo pôde entrar. Os quatro pods
antigos continuaram servindo, e a contagem mostra as trezentas requisições respondidas pela `2.0`. As
configurações da primeira seção fizeram mais que ditar o ritmo da atualização; **elas limitaram quanto do
serviço uma versão quebrada podia alcançar.** Com o padrão de `25%` em cada uma, um pod antigo teria saído
também.

Nada desfaz isso sozinho. Depois de `progressDeadlineSeconds`, dez minutos por padrão, o Deployment se
marca como sem progresso, e isso é uma condição para uma pessoa ou um pipeline ler. O `error` acima não é
isso: é o `kubectl rollout status` desistindo depois dos dez segundos que mandaram ele esperar.

## Histórico

Cada mudança no modelo criou um ReplicaSet, e o Deployment guarda os antigos, dez por padrão, como
histórico:

```
ana@laptop:~/shop$ kubectl rollout history deployment/shop
deployment.apps/shop 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         <none>
4         <none>
5         <none>

ana@laptop:~/shop$ kubectl rollout history deployment/shop --revision=4 | grep -E "Image|CRASH"
    Image:	shop:2.0
```

Cinco revisões: o primeiro apply, a `1.1`, o patch do `preStop` (ele também mudou o modelo), a `2.0` e a
quebra. A coluna `CHANGE-CAUSE` está vazia porque nada a preencheu; ela lê a anotação
`kubernetes.io/change-cause`, que é fácil de definir e igualmente fácil de deixar descrevendo a revisão
errada. **O modelo de uma revisão é o registro confiável**, e o `--revision` o mostra: a revisão 4 é a
`2.0` sem `CRASH`. Então:

```
ana@laptop:~/shop$ kubectl rollout undo deployment/shop
Warning: resource deployments/shop was previously managed with 'kubectl apply'. Rolling back will not update the kubectl.kubernetes.io/last-applied-configuration annotation, which may cause unexpected behavior on future 'kubectl apply' operations. Consider using 'kubectl apply' with your previous configuration file instead.
deployment.apps/shop rolled back
ana@laptop:~/shop$ kubectl get pods -l app=shop
NAME                    READY   STATUS        RESTARTS     AGE
shop-5cdd5f6b94-nwssx   0/1     Terminating   4 (5s ago)   81s
shop-997ffd576-2cg2c    1/1     Running       0            112s
shop-997ffd576-dvvbf    1/1     Running       0            111s
shop-997ffd576-j8ql6    1/1     Running       0            111s
shop-997ffd576-xjdql    1/1     Running       0            110s
ana@laptop:~/shop$ kubectl rollout history deployment/shop
deployment.apps/shop 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         <none>
5         <none>
6         <none>
```

O `undo` copia o modelo da revisão anterior de volta para o Deployment, o que vira um rollout comum na
direção de um ReplicaSet que já existe. O pod que quebra está de saída e os quatro bons nunca se mexeram.
**O histórico perdeu a revisão 4 e ganhou a 6**: o mesmo modelo não recebe dois números, então ele subiu
para o topo. `kubectl rollout undo --to-revision=2` iria para uma específica.

O aviso importa mais do que parece. Toda mudança desta lição foi feita por um comando, então o
`shop.yaml` ainda diz `shop:1.0`, e o próximo `kubectl apply -f shop.yaml` levaria a loja de volta à
`1.0`, sem alarde. **Num time o arquivo é a verdade, e a correção vai para o arquivo:** o `undo` compra
os minutos para fazê-la.
