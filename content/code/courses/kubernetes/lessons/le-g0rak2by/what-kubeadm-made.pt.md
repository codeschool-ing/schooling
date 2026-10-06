---
title: O que o kubeadm deixou
version: 1
---

O `kubeadm init` transforma uma máquina num control plane, e o `kubeadm join` transforma outra num nó
dele. Todo cluster kind deste curso foi construído assim: o kind inicia um container por nó e roda o
kubeadm lá dentro. Os comandos abaixo passam por `docker exec` porque cada nó é um container; em máquinas
de verdade eles rodam num shell em cada máquina, como root.

```
ana@laptop:~/shop$ docker exec shop-control-plane kubeadm version -o short
v1.37.0
ana@laptop:~/shop$ docker exec shop-control-plane ls /etc/kubernetes /etc/kubernetes/manifests
/etc/kubernetes:
admin.conf
controller-manager.conf
kubelet.conf
manifests
pki
scheduler.conf
super-admin.conf

/etc/kubernetes/manifests:
etcd.yaml
kube-apiserver.yaml
kube-controller-manager.yaml
kube-scheduler.yaml
ana@laptop:~/shop$ docker exec shop-control-plane kubeadm certs check-expiration | head -n 8
[check-expiration] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[check-expiration] Use 'kubeadm init phase upload-config kubeadm --config your-config-file' to re-upload it.

CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Oct 06, 2027 21:56 UTC   364d            ca                      no      
apiserver                  Oct 06, 2027 21:56 UTC   364d            ca                      no      
apiserver-etcd-client      Oct 06, 2027 21:56 UTC   364d            etcd-ca                 no      
apiserver-kubelet-client   Oct 06, 2027 21:56 UTC   364d            ca                      no      
```

Tudo o que o kubeadm fez são arquivos. **O control plane são quatro manifestos**, num diretório que o
kubelet observa. Um pod definido assim é um *pod estático*: o kubelet o roda direto do arquivo, sem
nenhum API server envolvido, e é assim que o próprio API server pode ser um pod.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"No nó do control plane, o kubelet observa o diretório /etc/kubernetes/manifests. Ele guarda quatro arquivos, etcd, kube-apiserver, kube-controller-manager e kube-scheduler, e o kubelet roda um pod para cada arquivo, sem nenhum API server envolvido. Tirar um arquivo do diretório para o pod dele; devolver o arquivo o inicia. O pod do etcd guarda os dados num diretório do nó, /var/lib/etcd.\"><defs><marker id=\"sp-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">kubelet</text><text x=\"90.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">roda o que está nele</text><rect x=\"210\" y=\"20\" width=\"230\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"325\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/etc/kubernetes/manifests</text><rect x=\"225\" y=\"54\" width=\"200\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">etcd.yaml</text><rect x=\"225\" y=\"96\" width=\"200\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">kube-apiserver.yaml</text><rect x=\"225\" y=\"138\" width=\"200\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">kube-controller-manager.yaml</text><rect x=\"225\" y=\"180\" width=\"200\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">kube-scheduler.yaml</text><path d=\"M162 118 L208 118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah-paper-dim)\"></path><rect x=\"520\" y=\"54\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/var/lib/etcd</text><text x=\"610\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o disco do nó</text><path d=\"M427 70 L518 70\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah-amber)\"></path><path d=\"M427 196 L512 196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-ah-paper-dim)\"></path><text x=\"518\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um arquivo tirado: o pod dele para</text></svg>", "caption": "O control plane são quatro pods estáticos. O kubelet roda o que estiver no diretório, e é assim que a restauração os para e os inicia."}
```

Ao lado deles ficam um kubeconfig para cada componente que fala com o API server, o `admin.conf` para o
administrador, e o `pki`, a autoridade certificadora e todo certificado assinado por ela. **Esses
certificados expiram depois de um ano**: o tempo restante acima é `364d` num cluster criado um minuto
antes. O `kubeadm upgrade` os renova de quebra, e é por isso que um cluster atualizado no calendário nunca
percebe. No primeiro aniversário de um cluster que ninguém atualizou, os componentes dele param de aceitar os
certificados uns dos outros, e o `kubeadm certs renew all` é a correção.

A linha da versão é a outra metade desse calendário. O `kubeadm upgrade` move um control plane uma versão
menor de cada vez, e cada versão tem suporte por cerca de catorze meses, então um cluster deixado de lado
fica sem suporte pouco mais de um ano depois de a versão dele sair.
