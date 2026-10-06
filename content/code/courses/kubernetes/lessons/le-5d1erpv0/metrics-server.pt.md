---
title: De onde vêm os números
version: 1
---

**Todo kubelet mede os containers do seu nó o tempo todo**, porque precisa dos números para aplicar
limits e decidir despejos. O que um cluster não tem por padrão é algo que reúna esses números num
lugar só. O metrics-server é esse coletor: a cada quinze segundos ele pede a cada kubelet os números
mais recentes, guarda só o conjunto mais novo na memória, e o serve pela API do Kubernetes. Ele não
guarda histórico, e essa é a primeira coisa a saber sobre ele.

Neste laboratório ele foi instalado a partir dos manifestos do próprio projeto (`lab.sh metrics`), com
a imagem compilada do código-fonte.

## O certificado do kubelet

O metrics-server fala com cada kubelet por HTTPS, então precisa confiar no certificado que o kubelet
apresenta. Num cluster kind os kubelets assinam o próprio certificado por padrão, e o contorno comum é
uma flag que desliga a verificação. Este laboratório faz o contrário: cada kubelet pede à autoridade
certificadora do cluster um certificado de verdade.

```
ana@laptop:~/shop$ kubectl get csr -o custom-columns=NAME:.metadata.name,SIGNER:.spec.signerName,REQUESTOR:.spec.username,CONDITION:.status.conditions[0].type
NAME        SIGNER                                        REQUESTOR                        CONDITION
csr-c8sb9   kubernetes.io/kubelet-serving                 system:node:shop-control-plane   Approved
csr-djvgq   kubernetes.io/kubelet-serving                 system:node:shop-worker          Approved
csr-hw8rp   kubernetes.io/kubelet-serving                 system:node:shop-control-plane   Approved
csr-wp6bj   kubernetes.io/kubelet-serving                 system:node:shop-worker2         Approved
csr-wqtcn   kubernetes.io/kube-apiserver-client-kubelet   system:bootstrap:abcdef          Approved
csr-zc5fw   kubernetes.io/kube-apiserver-client-kubelet   system:bootstrap:abcdef          Approved
```

Os quatro pedidos `kubelet-serving` são esses, um de cada worker e dois do nó control-plane, cada um
feito pelo próprio nó e aprovado pelo laboratório assim que chegou. Os dois pedidos
`kube-apiserver-client-kubelet` são mais antigos; são como os nós workers ganharam os certificados de
cliente quando entraram, e o cluster aprova esses sozinho.

## Ligado à API

O metrics-server não ganha uma URL própria. **Ele registra um grupo de API, `metrics.k8s.io`, no API
server**, que repassa essas requisições para ele. Esse registro é um objeto APIService:

```
ana@laptop:~/shop$ kubectl get apiservice v1beta1.metrics.k8s.io
NAME                     SERVICE                      AVAILABLE   AGE
v1beta1.metrics.k8s.io   kube-system/metrics-server   True        22s
ana@laptop:~/shop$ kubectl -n kube-system get deployment metrics-server -o jsonpath="{.spec.template.spec.containers[0].args}"; echo
["--cert-dir=/tmp","--secure-port=10250","--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname","--kubelet-use-node-status-port","--metric-resolution=15s"]
```

`AVAILABLE True` quer dizer que o API server consegue alcançá-lo. Os argumentos são os do próprio
manifesto, e nenhum deles é `--kubelet-insecure-tls`: os certificados acima tornaram essa flag
desnecessária. A lição 45 volta aos APIServices como forma de estender o cluster; este é o mais comum
que existe por aí.
