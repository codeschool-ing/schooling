---
title: Do que um driver CSI é feito
version: 1
---

**Um driver CSI é um programa comum que responde a um conjunto fixo de chamadas gRPC por um socket
Unix.** As chamadas são definidas pela especificação Container Storage Interface, que o Kubernetes
compartilha com outros orquestradores, e vêm em três grupos: identidade (quem é você, está vivo),
controller (criar, apagar, anexar um volume) e nó (montá-lo nesta máquina). O driver de discos de uma
nuvem as responde chamando a API da nuvem; o driver daqui as responde criando um diretório.

Este laboratório instala o CSI host-path driver, o driver de exemplo do próprio projeto Kubernetes,
que guarda cada volume num diretório num nó. É um driver de ensino e nada mais: os dados nunca saem do
nó, e perder o nó os perde. O valor dele aqui é ser pequeno o bastante para ser observado.

```
ana@laptop:~/shop$ kubectl get csidriver
NAME                  ATTACHREQUIRED   PODINFOONMOUNT   STORAGECAPACITY   TOKENREQUESTS   REQUIRESREPUBLISH   MODES                  AGE
hostpath.csi.k8s.io   false            true             true              <unset>         false               Persistent,Ephemeral   4s
```

O objeto CSIDriver é como o driver diz ao cluster do que precisa. `ATTACHREQUIRED false`: não há passo
separado de anexar, porque um diretório num nó já está onde precisa estar; um disco de nuvem precisa
ser anexado a uma máquina antes. `STORAGECAPACITY true`: o driver informa quanto espaço cada nó ainda
tem, o que o scheduler então usa.

```
ana@laptop:~/shop$ kubectl get pods -l app.kubernetes.io/name=csi-hostpathplugin -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
csi-hostpathplugin-7r2rb   3/3     Running   0          4s    10.244.2.3   shop-worker2   <none>           <none>
csi-hostpathplugin-zwkc9   3/3     Running   0          4s    10.244.1.3   shop-worker    <none>           <none>
ana@laptop:~/shop$ kubectl get pods -l app.kubernetes.io/name=csi-hostpathplugin -o jsonpath="{.items[0].spec.containers[*].name}"; echo
csi-provisioner node-driver-registrar hostpath
```

Uma cópia por nó worker, três containers cada. **Só `hostpath` é o driver; os outros dois são sidecars
que o projeto Kubernetes publica**, e todo driver CSI vem com alguns deles, porque eles traduzem entre
objetos do Kubernetes e chamadas CSI para que o fornecedor não precise:

| container | trabalho |
|---|---|
| `hostpath` | o driver: responde às chamadas CSI no seu socket |
| `csi-provisioner` | observa a API à procura de claims e chama `CreateVolume` e `DeleteVolume` |
| `node-driver-registrar` | diz ao kubelet do nó onde está o socket do driver |

```
ana@laptop:~/shop$ kubectl get csinodes
NAME                 DRIVERS   AGE
shop-control-plane   0         42s
shop-worker          1         31s
shop-worker2         1         31s
```

`DRIVERS 1` em cada worker é trabalho do registrar: cada kubelet agora conhece este driver. O nó
control-plane não roda cópia nenhuma, então não tem nenhum.

## A classe e a capacidade

```
ana@laptop:~/shop$ kubectl get storageclass
NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
csi-hostpath-fast    hostpath.csi.k8s.io     Delete          WaitForFirstConsumer   false                  4s
standard (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  37s
ana@laptop:~/shop$ kubectl get csistoragecapacities -o custom-columns=CLASS:.storageClassName,CAPACITY:.capacity,NODE:.nodeTopology.matchLabels
CLASS               CAPACITY   NODE
csi-hostpath-fast   100Gi      map[topology.hostpath.csi/node:shop-worker2]
csi-hostpath-fast   100Gi      map[topology.hostpath.csi/node:shop-worker]
```

`csi-hostpath-fast` é a classe que o projeto entrega com o driver; o parâmetro dela, `kind: fast`, é
repassado ao driver em todo volume, e é assim que um driver oferece vários tipos de armazenamento.
Cada worker informa 100 GiB disponíveis nela, um número que o driver foi mandado anunciar e não uma
medição do disco. Ao lado, a classe `standard` do próprio kind, da lição 26, continua sendo a padrão.
