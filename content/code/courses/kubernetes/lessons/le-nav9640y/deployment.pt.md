---
title: Um Deployment administra ReplicaSets
version: 1
---

Um ReplicaSet mantém um número de pods idênticos. Ele não consegue mudar o que esses pods são: dê a
ele uma imagem nova e ele deixa os pods existentes em paz, porque eles continuam batendo com o
seletor. **Mudar os pods é trabalho de um Deployment, e ele faz isso criando um segundo ReplicaSet** em
vez de editar o primeiro.

## Escalar é o número, e mais nada

```
ana@laptop:~/shop$ kubectl scale deployment web --replicas=5
deployment.apps/web scaled
ana@laptop:~/shop$ kubectl get deployment web
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
web    5/5     5            5           7s
ana@laptop:~/shop$ kubectl scale deployment web --replicas=2
deployment.apps/web scaled
ana@laptop:~/shop$ kubectl get pods -l app=web
NAME                   READY   STATUS    RESTARTS   AGE
web-768c88b7c7-lvz57   1/1     Running   0          6s
web-768c88b7c7-wbwkb   1/1     Running   0          12s
```

O `scale` escreve `replicas` no Deployment, que passa o número ao ReplicaSet dele, que cria ou apaga
pods. Descendo de cinco para dois, o controlador escolheu quais três apagar, por uma ordem: primeiro
os pods ainda não prontos, depois os pods dos nós que têm mais cópias, depois os que estão prontos há
menos tempo. É por isso que sobraram um original, o `wbwkb`, e um recém-chegado, o `lvz57`.

## Um modelo novo é um ReplicaSet novo

```
ana@laptop:~/shop$ kubectl set image deployment/web shop=shop:1.1
deployment.apps/web image updated
ana@laptop:~/shop$ kubectl get replicasets -l app=web
NAME             DESIRED   CURRENT   READY   AGE
web-768c88b7c7   0         0         0       13s
web-798bdd9498   2         2         2       1s
ana@laptop:~/shop$ kubectl get pods -l app=web -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image
NAME                   IMAGE
web-768c88b7c7-lvz57   shop:1.0
web-768c88b7c7-wbwkb   shop:1.0
web-798bdd9498-nkhm8   shop:1.1
web-798bdd9498-rx9tr   shop:1.1
```

O `set image` mudou o modelo do pod, então o hash do modelo mudou, então o Deployment criou o
`web-798bdd9498` para ele e passou a contagem para o outro lado: o ReplicaSet novo quer dois, o antigo
quer zero. A listagem pegou o momento intermediário: dois pods `shop:1.1` rodando, e os dois pods
`shop:1.0` de saída. **O ReplicaSet antigo é mantido, vazio**, e esse objeto vazio é o que torna um
rollback um comando de uma linha: a lição 35 faz a atualização direito, com a ordem e o ritmo sob
controle, e a desfaz.

## Por que você quase nunca cria um

O que acontece se os próprios ReplicaSets forem apagados?

```
ana@laptop:~/shop$ kubectl delete replicaset -l app=web --cascade=foreground
replicaset.apps "web-768c88b7c7" deleted from default namespace
replicaset.apps "web-798bdd9498" deleted from default namespace
ana@laptop:~/shop$ kubectl get replicasets -l app=web
NAME             DESIRED   CURRENT   READY   AGE
web-798bdd9498   2         2         2       6s
```

Os dois foram apagados, e seis segundos depois o Deployment já tinha criado de novo o que precisa,
com o mesmo nome, porque o modelo, e portanto o hash, não tinha mudado. Um ReplicaSet criado à mão não
teria nada disso: nenhum histórico, nenhum ReplicaSet novo para uma imagem nova, ninguém para
recriá-lo. **Então a regra é simples: escreva Deployments, e leia ReplicaSets** quando precisar saber
a que versão um pod pertence.

| | ReplicaSet | Deployment |
|---|---|---|
| mantém um número de pods rodando | sim | pelos seus ReplicaSets |
| muda os pods quando o modelo muda | não | sim, com um ReplicaSet novo |
| guarda a versão anterior para rollback | não | sim, como um ReplicaSet vazio |
| escrito por você | quase nunca | quase sempre |
