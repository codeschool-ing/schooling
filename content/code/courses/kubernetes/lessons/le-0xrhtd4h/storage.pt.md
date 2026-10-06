---
title: Um disco que acompanha o nome
version: 1
---

A segunda metade de um StatefulSet são os `volumeClaimTemplates`. **Cada pod recebe uma requisição de
disco própria, com o nome do pod**, criada na primeira vez que o pod é criado e nunca compartilhada:

```
ana@laptop:~/shop$ kubectl get pvc
NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
data-db-0   Bound    pvc-e5048645-5c4b-4e61-b898-edc75d14d061   64Mi       RWO            standard       <unset>                 15s
data-db-1   Bound    pvc-f7619570-411e-4eca-8f27-1fb14536c879   64Mi       RWO            standard       <unset>                 10s
data-db-2   Bound    pvc-119eb272-e680-438c-936c-e810a0b6c5d1   64Mi       RWO            standard       <unset>                 5s
```

`data-db-0`, `data-db-1`, `data-db-2`: o nome do modelo, `data`, mais o do pod. Cada uma está `Bound`
a um volume próprio, fornecido aqui pelo provisionador local-path do kind como um diretório no nó em
que o pod rodou primeiro. A lição 26 abre direito claims, volumes e storage classes; o que importa
aqui é a ligação entre um nome e um disco.

## Apagando um membro

O `db-1` recebe algo para lembrar, e depois é apagado:

```
ana@laptop:~/shop$ kubectl exec db-1 -- sh -c "echo order-1042 > /data/last-order; ls /data"
born
last-order
ana@laptop:~/shop$ kubectl delete pod db-1
pod "db-1" deleted from default namespace
```

```
ana@laptop:~/shop$ kubectl get pod db-1 -o wide
NAME   READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
db-1   1/1     Running   0          1s    10.244.1.6   shop-worker2   <none>           <none>
ana@laptop:~/shop$ kubectl exec db-1 -- cat /data/born /data/last-order
db-1
order-1042
```

**O pod que voltou é o `db-1`, e ele tem os dados do `db-1`**: o arquivo `born` continua dizendo
`db-1`, escrito na primeira subida, e `last-order` é a linha escrita no pod que foi apagado. O endereço
mudou, de `10.244.1.3` para `10.244.1.6`, e é por isso que o conselho da seção anterior era usar o
nome. Ele voltou em `shop-worker2`, o mesmo nó de antes, porque um disco local-path existe num nó só e
o pod precisa ir para onde está o disco.

## Reduzir a escala mantém os discos

```
ana@laptop:~/shop$ kubectl scale statefulset db --replicas=1
statefulset.apps/db scaled
ana@laptop:~/shop$ kubectl get pods -l app=db
NAME   READY   STATUS        RESTARTS   AGE
db-0   1/1     Running       0          62s
db-1   1/1     Running       0          16s
db-2   1/1     Terminating   0          52s
ana@laptop:~/shop$ kubectl get pvc
NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
data-db-0   Bound    pvc-e5048645-5c4b-4e61-b898-edc75d14d061   64Mi       RWO            standard       <unset>                 62s
data-db-1   Bound    pvc-f7619570-411e-4eca-8f27-1fb14536c879   64Mi       RWO            standard       <unset>                 57s
data-db-2   Bound    pvc-119eb272-e680-438c-936c-e810a0b6c5d1   64Mi       RWO            standard       <unset>                 52s
```

O `db-2` sai primeiro, de cima para baixo, e ainda está `Terminating` quinze segundos depois porque o
`sleep` dele ignora o sinal educado e o kubelet espera os trinta segundos de tolerância; a lição 35
trata de desligar direito. **As três claims continuam lá.** O Kubernetes não apaga os discos de um
StatefulSet quando a escala diminui, nem mesmo quando o StatefulSet é apagado, porque um disco é a
única coisa no cluster que não pode ser recriada a partir de um arquivo. Aumente a escala de novo e o
`db-2` recebe o `data-db-2` outra vez. Apagá-los é uma decisão que alguém toma de propósito.

| | Deployment | StatefulSet |
|---|---|---|
| nomes dos pods | sufixo aleatório, novo a cada substituição | `db-0`, `db-1`, … fixos |
| subir e parar | todos de uma vez | um de cada vez, em ordem |
| disco | compartilhado ou nenhum | uma claim por pod, mantida quando o pod sai |
| acessado por | um endereço de Service, qualquer pod | um Service headless: um nome por pod |
