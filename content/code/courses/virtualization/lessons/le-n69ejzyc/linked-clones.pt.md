---
title: Clones ligados
version: 1
---

Uma máquina feita de um modelo não precisa de uma cópia completa. Ela pode ser uma camada fina sobre o
modelo, a mesma sobreposição que o laboratório usa desde a aula 1, e isso se chama **clone ligado**
(linked clone):

```
ana@host:~$ cd /var/lib/libvirt/images && for n in web1 web2; do sudo qemu-img create -q -f qcow2 -b template.qcow2 -F qcow2 $n.qcow2 8G; done && ls -lsh template.qcow2 web1.qcow2 web2.qcow2
 37M -r--r--r-- 1 root root  37M Sep 25 20:52 template.qcow2
196K -rw-r--r-- 1 root root 193K Sep 25 20:52 web1.qcow2
196K -rw-r--r-- 1 root root 193K Sep 25 20:52 web2.qcow2
ana@host:~$ sudo qemu-img info --backing-chain /var/lib/libvirt/images/web1.qcow2 | grep "^image:"
image: /var/lib/libvirt/images/web1.qcow2
image: /var/lib/libvirt/images/template.qcow2
image: /var/lib/libvirt/images/lab-base.qcow2
ana@host:~$ for n in web1 web2; do sudo virt-install --name $n --virt-type qemu --memory 1024 --vcpus 2 --import --disk /var/lib/libvirt/images/$n.qcow2,bus=virtio --disk /var/lib/libvirt/images/$n-seed.img,bus=virtio,format=raw --os-variant ubuntu24.04 --network network=default --graphics none --noautoconsole >/dev/null 2>&1; done; virsh list
 Id   Name   State
----------------------
 12   web1   running
 13   web2   running
```

Dois clones, com 196K cada, sobre um modelo de 37M. O `--backing-chain` mostra três níveis: o
`web1.qcow2` lê do `template.qcow2`, que lê do `lab-base.qcow2`. Cada clone recebeu o próprio disco do
cloud-init com o próprio nome, e os dois foram ligados.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Um modelo com clones ligados. Embaixo, o lab-base.qcow2, a base do laboratório, só leitura. Sobre ela, o template.qcow2, com 37M, que era a vm1, selada e tornada só leitura. Sobre o modelo, dois clones ligados, o web1.qcow2 e o web2.qcow2, com 196K cada quando novos.\"><defs><marker id=\"tt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"60\" y=\"16\" width=\"260\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"74\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">web1.qcow2   196K</text><text x=\"74\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um clone ligado</text><path d=\"M190 68 L360 94\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tt-ah)\"></path><rect x=\"400\" y=\"16\" width=\"260\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"414\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">web2.qcow2   196K</text><text x=\"414\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um clone ligado</text><path d=\"M530 68 L360 94\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tt-ah)\"></path><rect x=\"200\" y=\"96\" width=\"320\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"214\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">template.qcow2   37M</text><text x=\"214\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a vm1, selada e só leitura</text><path d=\"M360 148 L360 164\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tt-ah)\"></path><rect x=\"200\" y=\"166\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"214\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lab-base.qcow2</text><text x=\"214\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a base do laboratório, só leitura</text></svg>", "caption": "Cada clone ligado é uma camada fina sobre o modelo, que por sua vez é uma camada sobre a base. Nada é copiado, então um clone é feito num instante; e nada debaixo de um clone pode mudar ou sair do lugar, nunca."}
```

O preço da camada fina é uma dependência. **Nada debaixo de um clone ligado pode mudar**: um modelo que é
atualizado, movido ou apagado quebra todo clone feito dele, e é por isso que este é só de leitura. E toda
leitura que o clone não escreveu ele mesmo desce pela cadeia, então um clone ligado num disco
compartilhado lento é um pouco mais lento que um completo.
