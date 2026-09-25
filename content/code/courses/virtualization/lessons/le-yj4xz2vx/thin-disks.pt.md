---
title: Discos finos, e o espaço de volta
version: 1
---

Um disco fino cresce conforme o convidado escreve. O que acontece quando o convidado apaga?

```
ana@host:~$ cd /var/lib/libvirt/images && ls -lsh vm1.qcow2
27M -rw-r--r-- 1 libvirt-qemu kvm 27M Sep 25 20:04 vm1.qcow2
ana@vm1:~$ dd if=/dev/urandom of=big bs=1M count=300 status=none && sync && ls -lh big
-rw-rw-r-- 1 ana ana 300M Sep 25 20:04 big
ana@host:~$ cd /var/lib/libvirt/images && ls -lsh vm1.qcow2
327M -rw-r--r-- 1 libvirt-qemu kvm 327M Sep 25 20:04 vm1.qcow2
ana@vm1:~$ rm big && sync && sudo fstrim -v /
/: 6.2 GiB (6664396800 bytes) trimmed
ana@host:~$ cd /var/lib/libvirt/images && ls -lsh vm1.qcow2
327M -rw-r--r-- 1 libvirt-qemu kvm 327M Sep 25 20:04 vm1.qcow2
```

O arquivo cresceu de 27M para 327M quando o convidado escreveu 300 MB, e ficou em 327M
depois que o convidado o apagou. A primeira coluna do `ls -lsh` é o espaço que o arquivo ocupa de fato no
host, a segunda é o tamanho aparente, e nenhuma se mexeu. **Apagar um arquivo libera espaço no sistema de
arquivos do convidado e em nenhum outro lugar**; o disco por baixo ainda guarda os blocos, porque nada
disse a ele que estão livres.

Quem diz é o **TRIM**, o mesmo comando que um SSD recebe, e o `fstrim` o manda para cada bloco livre. O
convidado informou `6.2 GiB trimmed`, e o host ignorou: o padrão do libvirt é não descartar nada. A
configuração que faz o host ouvir é `discard='unmap'` no disco e, como a maioria das configurações de
hardware, precisa do convidado desligado e ligado, seção 07. Depois disso:

```
ana@host:~$ cd /var/lib/libvirt/images && ls -lsh vm1.qcow2
212M -rw-r--r-- 1 libvirt-qemu kvm 332M Sep 25 20:07 vm1.qcow2
ana@vm1:~$ sudo fstrim -v /
/: 6.2 GiB (6659100672 bytes) trimmed
ana@host:~$ cd /var/lib/libvirt/images && ls -lsh vm1.qcow2
33M -rw-r--r-- 1 libvirt-qemu kvm 332M Sep 25 20:07 vm1.qcow2
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"O vm1.qcow2 no host, em cinco momentos. Novo: 27M. Depois que o convidado escreve 300 MB: 327M. Depois que o convidado apaga o arquivo e roda o fstrim, que o host ignora: ainda 327M. Depois de pôr discard=unmap e reiniciar o convidado: 212M. Depois do fstrim de novo, agora atendido: 33M.\"><defs><marker id=\"tr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"140.09174311926606\" width=\"60\" height=\"9.908256880733944\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"60\" y=\"130.09174311926606\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">27M</text><text x=\"30\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">novo</text><rect x=\"168\" y=\"30.0\" width=\"60\" height=\"120.0\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"198\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">327M</text><text x=\"168\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300 MB escritos</text><rect x=\"306\" y=\"30.0\" width=\"60\" height=\"120.0\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"336\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">327M</text><text x=\"306\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">apagado, fstrim ignorado</text><rect x=\"444\" y=\"72.20183486238533\" width=\"60\" height=\"77.79816513761467\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"474\" y=\"62.201834862385326\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">212M</text><text x=\"444\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">discard=unmap, reiniciado</text><rect x=\"582\" y=\"137.88990825688074\" width=\"60\" height=\"12.110091743119266\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"612\" y=\"127.88990825688073\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">33M</text><text x=\"582\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fstrim atendido</text></svg>", "caption": "Um convidado apagando um arquivo libera espaço dentro do convidado e em nenhum outro lugar. O host só o recebe de volta quando o convidado avisa, com TRIM, e só quando o host está configurado para ouvir."}
```

O espaço ocupado caiu para 33M, enquanto o tamanho aparente ficou onde estava. Parte dele já tinha
voltado durante o reinício, e o `fstrim` devolveu o resto. O Ubuntu roda o `fstrim` uma vez por semana
sozinho, então um convidado com `discard='unmap'` mantém o arquivo perto do que guarda de fato. Sem isso,
os discos de um laboratório movimentado só crescem.
