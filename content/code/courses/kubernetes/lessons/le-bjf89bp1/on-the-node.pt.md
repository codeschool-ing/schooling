---
title: Onde o volume realmente está, e como ele vai embora
version: 1
---

Um nó do kind é um container, então `docker exec` consegue olhar dentro do diretório em que o driver
guarda os volumes:

```
ana@laptop:~/shop$ docker exec shop-worker2 ls /var/lib/csi-hostpath-data
cc853bf3-c1b3-11f1-8644-4a042d320914
state.json
```

**Um diretório, com o nome do `volumeHandle` que o PersistentVolume registrou**, ao lado do arquivo de
controle do próprio driver. Dentro do pod, o mesmo armazenamento é `/data`:

```
ana@laptop:~/shop$ kubectl exec writer -- cat /data/first
Tue Oct  6 18:29:01 UTC 2026
ana@laptop:~/shop$ kubectl exec writer -- sh -c 'mount | grep /data'
/dev/vda on /data type ext4 (rw,relatime,discard,no_prefetch_block_bitmaps,resv_strict,resuid=65534,resgid=65534)
```

O arquivo que o container escreveu está lá. A linha de montagem cita `/dev/vda`, o disco da máquina em
que o nó roda, porque um volume host-path é um diretório nesse disco, montado com bind no pod; o
volume de um driver de nuvem mostraria aqui o próprio dispositivo.

## Apagando, chamada a chamada

```
ana@laptop:~/shop$ kubectl delete pod writer
pod "writer" deleted from default namespace
ana@laptop:~/shop$ kubectl delete pvc data
persistentvolumeclaim "data" deleted from default namespace
ana@laptop:~/shop$ kubectl get pv
No resources found
```

O PersistentVolume foi junto com o claim, porque a política de reclaim da classe é `Delete`, como na
lição 26. Desta vez o log do driver mostra o que isso significou:

```
ana@laptop:~/shop$ kubectl logs pod/csi-hostpathplugin-7r2rb -c hostpath | grep -o 'GRPC call: [^ ]*' | grep -E 'Unpublish|Unstage|DeleteVolume'
GRPC call: /csi.v1.Node/NodeUnpublishVolume
GRPC call: /csi.v1.Node/NodeUnstageVolume
GRPC call: /csi.v1.Controller/DeleteVolume
```

**O kubelet fez unpublish e unstage do volume quando o pod foi embora; o provisioner pediu
`DeleteVolume` quando o claim foi embora.** Os mesmos três passos da criação, ao contrário, feitos
pelos mesmos dois que chamam.

```
ana@laptop:~/shop$ docker exec shop-worker2 ls /var/lib/csi-hostpath-data
state.json
```

O diretório sumiu. Numa nuvem, a mesma sequência desanexa e apaga um disco de verdade, e é por isso
que o `Retain` existe.

| chamada CSI | feita por | quando |
|---|---|---|
| `CreateVolume` | `csi-provisioner` | um claim precisa de um volume |
| `NodeStageVolume` | o kubelet | um nó precisa do volume pela primeira vez |
| `NodePublishVolume` | o kubelet | um pod nesse nó o monta |
| `NodeUnpublishVolume`, `NodeUnstageVolume` | o kubelet | o pod, e depois o nó, não precisam mais dele |
| `DeleteVolume` | `csi-provisioner` | o claim é apagado e a política é `Delete` |

Snapshots, redimensionamento e anexar a uma máquina são outras chamadas com outros sidecars, deixados
de fora do driver desta aula. A lição 28 é sobre proteger o que um banco guarda num volume.
