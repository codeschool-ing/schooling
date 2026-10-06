---
title: Um claim, acompanhado chamada a chamada
version: 1
---

O claim é o da lição 26, com a classe CSI nomeada:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: csi-hostpath-fast
  resources:
    requests:
      storage: 1Gi
```

```
ana@laptop:~/shop$ kubectl apply -f claim.yaml
persistentvolumeclaim/data created
ana@laptop:~/shop$ kubectl get pvc data
NAME   STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS        VOLUMEATTRIBUTESCLASS   AGE
data   Pending                                      csi-hostpath-fast   <unset>                 3s
ana@laptop:~/shop$ kubectl get events --field-selector involvedObject.name=data -o custom-columns=REASON:.reason,MESSAGE:.message
REASON                 MESSAGE
WaitForFirstConsumer   waiting for first consumer to be created before binding
```

`Pending`, esperando um consumidor, pelo mesmo motivo de antes: a classe liga no primeiro uso, então o
volume é criado em qualquer nó em que o pod cair.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: writer
spec:
  containers:
  - name: box
    image: busybox:1.37
    command: ["sh", "-c", "date > /data/first; sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: data
```

```
ana@laptop:~/shop$ kubectl apply -f writer.yaml
pod/writer created
ana@laptop:~/shop$ kubectl get pod writer -o wide
NAME     READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
writer   1/1     Running   0          2s    10.244.2.4   shop-worker2   <none>           <none>
ana@laptop:~/shop$ kubectl get pvc data
NAME   STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        VOLUMEATTRIBUTESCLASS   AGE
data   Bound    pvc-50aa12b5-b5a8-4132-a5f7-5f2fdef6f6fa   1Gi        RWO            csi-hostpath-fast   <unset>                 5s
```

O scheduler pôs `writer` em `shop-worker2`, e o claim foi ligado a um PersistentVolume novo em
segundos. O volume diz quem o criou e como achá-lo de novo:

```
ana@laptop:~/shop$ kubectl get pv -o jsonpath='{.items[0].spec.csi}'; echo
{"driver":"hostpath.csi.k8s.io","volumeAttributes":{"kind":"fast","storage.kubernetes.io/csiProvisionerIdentity":"1791311334737-7540-hostpath.csi.k8s.io-shop-worker2"},"volumeHandle":"cc853bf3-c1b3-11f1-8644-4a042d320914"}
ana@laptop:~/shop$ kubectl get pv -o jsonpath='{.items[0].spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0]}'; echo
{"key":"topology.hostpath.csi/node","operator":"In","values":["shop-worker2"]}
```

**`driver` nomeia o driver CSI, e `volumeHandle` é o id do próprio driver para o volume**, que o
Kubernetes guarda e devolve em toda chamada seguinte sem entendê-lo. Para um disco de nuvem seria o id
do disco na nuvem. `kind: fast` é o parâmetro da classe, levado junto. A afinidade de nó usa a chave
de topologia que o driver informou, então este volume, como o da lição 26, prende todo pod futuro a
`shop-worker2`.

## As chamadas, em ordem

O driver registra cada chamada que recebe. Em `shop-worker2`, com repetições seguidas juntadas pelo
`uniq`:

```
ana@laptop:~/shop$ kubectl logs pod/csi-hostpathplugin-7r2rb -c hostpath | grep -o 'GRPC call: [^ ]*' | uniq
GRPC call: /csi.v1.Identity/GetPluginInfo
GRPC call: /csi.v1.Identity/Probe
GRPC call: /csi.v1.Identity/GetPluginInfo
GRPC call: /csi.v1.Identity/GetPluginCapabilities
GRPC call: /csi.v1.Controller/ControllerGetCapabilities
GRPC call: /csi.v1.Node/NodeGetInfo
GRPC call: /csi.v1.Controller/GetCapacity
GRPC call: /csi.v1.Node/NodeGetInfo
GRPC call: /csi.v1.Controller/CreateVolume
GRPC call: /csi.v1.Controller/GetCapacity
GRPC call: /csi.v1.Node/NodeGetCapabilities
GRPC call: /csi.v1.Node/NodeStageVolume
GRPC call: /csi.v1.Node/NodeGetCapabilities
GRPC call: /csi.v1.Node/NodePublishVolume
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um nó, shop-worker2, com o pod do driver e três containers: csi-provisioner, node-driver-registrar e hostpath, que compartilham um socket. O API server guarda o claim. O csi-provisioner observa o API server à procura de claims e chama CreateVolume e DeleteVolume no socket. O node-driver-registrar diz ao kubelet onde o socket está. O kubelet chama NodeStageVolume e NodePublishVolume no mesmo socket para montar o volume no pod writer.\"><defs><marker id=\"csi-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"csi-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"csi-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">API server</text><text x=\"95.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">PVC data</text><rect x=\"200\" y=\"14\" width=\"500\" height=\"276\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"216\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nó shop-worker2</text><rect x=\"230\" y=\"50\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">csi-provisioner</text><rect x=\"230\" y=\"130\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">node-driver-registrar</text><rect x=\"500\" y=\"90\" width=\"180\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hostpath</text><text x=\"590.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">csi.sock</text><rect x=\"230\" y=\"210\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">kubelet</text><rect x=\"500\" y=\"210\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pod writer</text><text x=\"590.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/data</text><path d=\"M228 72 L172 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#csi-ah-paper-dim)\"></path><text x=\"95\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">observa claims</text><path d=\"M402 72 L498 104\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#csi-ah-amber)\"></path><text x=\"450\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">CreateVolume</text><path d=\"M315 176 L315 208\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#csi-ah-paper-dim)\"></path><text x=\"322\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">registra o socket</text><path d=\"M402 222 L540 152\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#csi-ah-phosphor)\"></path><text x=\"470\" y=\"176\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">NodePublish</text><path d=\"M402 240 L498 240\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#csi-ah-phosphor)\"></path></svg>", "caption": "Dois que chamam, um socket. O sidecar faz as chamadas de controller em nome da API, e o kubelet faz as chamadas de nó em nome do pod."}
```

Lido de cima para baixo, o log é a vida inteira do driver até aqui:

1. **Identidade e capacidades.** Quando os sidecars e o kubelet se conectaram pela primeira vez, eles
   perguntaram quem o driver é, se está pronto e o que sabe fazer.
2. **`GetCapacity`.** O provisioner perguntou quanto espaço o nó tem, o que virou os objetos
   CSIStorageCapacity da seção anterior.
3. **`CreateVolume`.** O provisioner viu o claim, já com o nó escolhido, e pediu um volume ao driver. O driver
   criou um diretório e devolveu o handle dele.
4. **`NodeStageVolume`, depois `NodePublishVolume`.** O kubelet, subindo `writer`, pediu ao driver para
   preparar o volume no nó e depois para fazê-lo aparecer no caminho dentro do pod. Para um dispositivo
   de bloco, o stage é onde ele é formatado e montado uma vez por nó; o publish o monta com bind em
   cada pod que o usa.

Nenhum componente do Kubernetes tocou o armazenamento em si. **Toda ação sobre ele foi uma chamada ao
driver**, e esse é o contrato para o qual o CSI existe.
