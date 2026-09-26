---
title: O que é o Proxmox VE
version: 1
---

O **Proxmox Virtual Environment** é uma distribuição Linux, baseada no Debian, cujo único trabalho é
rodar máquinas virtuais e contêineres. Ele é instalado num servidor pela ISO própria, toma o disco
inteiro, e depois da instalação o servidor mostra uma única linha na tela: o endereço da interface web,
`https://` seguido do endereço do servidor e da **porta 8006**. Todo o resto é feito por um navegador.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"O que é o Proxmox VE, em camadas. Embaixo, o hardware de um servidor com VT-x ou AMD-V. Sobre ele, o Debian com o kernel do Proxmox e o KVM. Sobre isso, o QEMU para máquinas virtuais e o LXC para contêineres, lado a lado. Por cima de tudo, a interface web na porta 8006 e os comandos qm, pct e vzdump. Ao lado da pilha, o armazenamento, local, LVM, ZFS, NFS ou Ceph, e o cluster que faz de vários nós um só. À direita, o laboratório deste curso para comparar: Ubuntu, libvirt e virsh, com o mesmo QEMU por baixo.\"><defs><marker id=\"px-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"440\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"35\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a interface web, porta 8006</text><rect x=\"20\" y=\"56\" width=\"440\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"77\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">qm, pct, vzdump na linha de comando</text><rect x=\"20\" y=\"100\" width=\"214\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">QEMU: máquinas virtuais</text><rect x=\"246\" y=\"100\" width=\"214\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">LXC: contêineres</text><rect x=\"20\" y=\"148\" width=\"440\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Debian, com o kernel do Proxmox e o KVM</text><rect x=\"20\" y=\"190\" width=\"440\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o hardware de um servidor, com VT-x ou AMD-V</text><text x=\"20\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">armazenamento: local, LVM, ZFS, NFS, Ceph</text><text x=\"20\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o cluster: vários nós como um</text><rect x=\"500\" y=\"100\" width=\"200\" height=\"82\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"514\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o laboratório deste curso</text><text x=\"514\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Ubuntu, libvirt, virsh</text><text x=\"514\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o mesmo QEMU por baixo</text><path d=\"M498 144 L130 144\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#px-ah)\" stroke-dasharray=\"4 3\"></path></svg>", "caption": "O Proxmox é uma distribuição Linux cujo único trabalho é ser hypervisor, e o motor dele é o QEMU com KVM que este curso já usa. O que ele acrescenta é tudo em volta do motor: interface web, armazenamento, backups e cluster.", "same": ["Ubuntu, libvirt, virsh"]}
```

Ele roda dois tipos de convidado. **Máquinas virtuais** são QEMU com KVM, a discussão sobre tipo 1 da
aula 2 em concreto. **Contêineres** são LXC, que a aula 13 compara com máquinas virtuais. Em volta
deles, ele acrescenta **armazenamento** para discos e ISOs, **backups**, um **firewall**, usuários com
permissões, e um **cluster** que junta vários servidores numa interface só.

O Proxmox é software livre sob a AGPL. A empresa vende **assinaturas**, que dão acesso ao repositório de
pacotes *enterprise* e ao suporte. Sem uma, o servidor usa o repositório *no-subscription*, que é
gratuito e um pouco menos testado, e a interface web mostra uma mensagem *No valid subscription* a cada
login. Para um laboratório ou um escritório pequeno essa mensagem é o custo todo, e é uma mensagem, não
um limite.

Você entra como `root` com o realm *Linux PAM standard authentication*, que é a senha de root do próprio
servidor. Toda máquina recebe um **número**, começando em `100`, e o número é o nome dela para os
arquivos e os comandos.

O Proxmox não está instalado no host deste curso, que é ele mesmo uma máquina virtual sem VT-x, como a
aula 2 descobriu. O que o laboratório tem é o motor que o Proxmox roda, e as próximas três seções o
olham pelos nomes que o Proxmox dá a cada parte.
