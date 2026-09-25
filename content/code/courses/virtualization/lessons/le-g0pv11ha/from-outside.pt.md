---
title: Por fora
version: 1
---

Agora a mesma máquina pelo lado do host, enquanto roda:

```
ana@host:~$ ps -o pid,rss,etime,comm -C qemu-system-x86_64
    PID   RSS     ELAPSED COMMAND
   4340 1608536     02:10 qemu-system-x86
ana@host:~$ ls -lh /var/lib/libvirt/images/lab-base.qcow2 /var/lib/libvirt/images/vm1.qcow2
-rw-r--r-- 1 libvirt-qemu kvm 318M Sep 25 18:28 /var/lib/libvirt/images/lab-base.qcow2
-rw-r--r-- 1 libvirt-qemu kvm  25M Sep 25 18:34 /var/lib/libvirt/images/vm1.qcow2
ana@host:~$ free -h | head -2
               total        used        free      shared  buff/cache   available
Mem:            15Gi       2.1Gi        12Gi        12Mi       1.1Gi        13Gi
ana@host:~$ nproc
4
```

**O convidado inteiro é um processo**, o `qemu-system-x86`, rodando há `02:10`. Os dois processadores
dele são threads desse processo, que o escalonador do host reparte entre os próprios **4**
processadores como os de qualquer outro programa. A memória dele é a memória desse processo: o **RSS**,
a memória que ele ocupa de fato, é de 1608536 KiB, cerca de 1,5 GiB. É mais que o 1
GiB que o convidado recebeu, porque o QEMU precisa de memória própria além da do convidado, e a aula 8
mede para onde ela vai.

O disco é o arquivo `vm1.qcow2`, com **25M** depois de um boot inteiro, em cima da base de 318M
que ele compartilha. E o host ainda tem 15Gi de memória, a maior parte livre.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Duas visões da mesma máquina, lado a lado. De dentro, a vm1 tem 2 processadores chamados QEMU Virtual CPU, 961Mi de memória, um disco vda de 8G e o endereço 192.168.122.165. De fora, no host, os processadores são threads de um processo, o qemu-system-x86; a memória é o que esse processo usa, 1,5 GiB, RSS de 1608536 kibibytes; o disco é um arquivo, vm1.qcow2, com 25M até agora; e a placa de rede é uma porta num switch virtual, o virbr0.\"><defs><marker id=\"vw-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">o que a vm1 vê, de dentro</text><text x=\"400\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">o que o host vê, de fora</text><rect x=\"20\" y=\"40\" width=\"260\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">processador</text><text x=\"32\" y=\"77\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2 CPUs, “QEMU Virtual CPU”</text><rect x=\"400\" y=\"40\" width=\"300\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"412\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">threads de um processo</text><text x=\"412\" y=\"77\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">qemu-system-x86</text><path d=\"M282 64 L398 64\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vw-ah)\" stroke-dasharray=\"4 4\"></path><rect x=\"20\" y=\"102\" width=\"260\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">memória</text><text x=\"32\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">961Mi no total</text><rect x=\"400\" y=\"102\" width=\"300\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"412\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o processo usa 1,5 GiB</text><text x=\"412\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">RSS 1608536 KiB</text><path d=\"M282 126 L398 126\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vw-ah)\" stroke-dasharray=\"4 4\"></path><rect x=\"20\" y=\"164\" width=\"260\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">disco</text><text x=\"32\" y=\"201\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">vda, 8G</text><rect x=\"400\" y=\"164\" width=\"300\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"412\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um arquivo que cresce</text><text x=\"412\" y=\"201\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">vm1.qcow2, 25M</text><path d=\"M282 188 L398 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vw-ah)\" stroke-dasharray=\"4 4\"></path><rect x=\"20\" y=\"226\" width=\"260\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rede</text><text x=\"32\" y=\"263\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">192.168.122.165</text><rect x=\"400\" y=\"226\" width=\"300\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"412\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma porta num switch virtual</text><text x=\"412\" y=\"263\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">virbr0</text><path d=\"M282 250 L398 250\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vw-ah)\" stroke-dasharray=\"4 4\"></path></svg>", "caption": "Tudo o que a vm1 acredita ser hardware é algo comum no host: um processo, a memória dele, um arquivo e uma porta num switch que também é software.", "same": ["2 CPUs, “QEMU Virtual CPU”", "vda, 8G"]}
```

As duas visões são a mesma máquina, e ter as duas em mente é boa parte deste curso. Quando um
convidado está lento, a resposta muitas vezes está fora dele: o host está sem memória, ou o disco dele
encheu, ou vinte convidados dividem quatro processadores. Quando um convidado não dá boot, a resposta
costuma estar dentro dele, e as ferramentas são as do curso de sistemas operacionais.
