---
title: Tirando um nó e pondo de volta
version: 1
---

Remover um nó são três passos, e a ordem deles importa. O `drain` tira o trabalho enquanto o nó ainda faz
parte do cluster. O `kubeadm reset`, no nó, desfaz o que o `join` fez ali. O `delete node` remove o
objeto Node, que nada mais removeria:

```
ana@laptop:~/shop$ kubectl drain shop-worker2 --ignore-daemonsets --delete-emptydir-data
node/shop-worker2 cordoned
Warning: ignoring DaemonSet-managed Pods: kube-system/kindnet-hlvjh, kube-system/kube-proxy-jf7fk
evicting pod kube-system/coredns-bc958fb98-28hp7
pod/coredns-bc958fb98-28hp7 evicted
node/shop-worker2 drained
ana@laptop:~/shop$ docker exec shop-worker2 kubeadm reset -f 2>&1 | tail -n 3
For information on how to perform this cleanup manually, please see:
    https://k8s.io/docs/reference/setup-tools/kubeadm/kubeadm-reset/

ana@laptop:~/shop$ kubectl delete node shop-worker2
node "shop-worker2" deleted
ana@laptop:~/shop$ kubectl get nodes
NAME                 STATUS   ROLES           AGE   VERSION
shop-control-plane   Ready    control-plane   35s   v1.37.0
shop-worker          Ready    <none>          25s   v1.37.0
```

O `drain` isola o nó primeiro, então nada novo cai nele, e depois despeja o que está lá. Pods de um
DaemonSet são deixados em paz, porque o controlador deles só os poria de volta; a réplica do CoreDNS foi
para outro nó. O aviso com que o `reset` termina é sobre o que ele **não** limpa: a configuração do plugin
de rede e as regras que ele deixou no kernel. Numa máquina que vai ser reaproveitada, esse aviso é uma
lista de trabalho.

## Entrando

Um nó novo precisa de duas coisas do control plane: um jeito de provar que foi convidado, e um jeito de
saber que o control plane que ele alcança é o verdadeiro. O comando de join leva as duas:

```
ana@laptop:~/shop$ docker exec shop-control-plane kubeadm token create --print-join-command | tee join.txt
kubeadm join shop-control-plane:6443 --token z9znre.c6glz146pu1ortd9 --discovery-token-ca-cert-hash sha256:2facd21479f6e9df54383fa6f8ba7f4d044e409404afc6bd58a07f4be0a7fd1f 
ana@laptop:~/shop$ docker exec shop-worker2 kubeadm join shop-control-plane:6443 --token z9znre.c6glz146pu1ortd9 --discovery-token-ca-cert-hash sha256:2facd21479f6e9df54383fa6f8ba7f4d044e409404afc6bd58a07f4be0a7fd1f  --ignore-preflight-errors=all 2>&1 | grep -v '^\[preflight\]\|^W\|^I' | tail -n 6
This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.

ana@laptop:~/shop$ kubectl get nodes
NAME                 STATUS   ROLES           AGE   VERSION
shop-control-plane   Ready    control-plane   36s   v1.37.0
shop-worker          Ready    <none>          26s   v1.37.0
shop-worker2         Ready    <none>          0s    v1.37.0
```

O `--token` é o convite. **Quem o tiver pode acrescentar uma máquina a este cluster como nó**, e um nó
pode ler os Secrets dos pods que roda, então ele é uma senha: dura 24 horas a menos que digam outra coisa,
e o `kubeadm token delete` o encerra antes. O `--discovery-token-ca-cert-hash` é a outra direção. Ele fixa
a autoridade certificadora do cluster, então um nó que recebeu o endereço errado se recusa a entrar num
control plane que não é este, em vez de confiar em quem respondeu.

Duas coisas nesta transcrição são do kind e não do método. O `--ignore-preflight-errors=all` está ali
porque um nó que é um container falha em verificações prévias que o próprio kind pula quando monta um
cluster; **numa máquina de verdade, deixe-o de fora** e corrija o que as verificações apontarem. E o nó
que voltou pede um certificado de servidor, como todo nó dos clusters deste curso (aula 1), e ninguém o
aprova por ele. O `up.sh` aprovou os primeiros; este você aprova à mão enquanto o nó entra, com
`kubectl get csr` para achar o pedido `Pending` e `kubectl certificate approve` seguido do nome dele.
Até lá o `kubectl logs` e o `kubectl exec` falham para todo pod desse nó.
