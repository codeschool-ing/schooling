---
title: O disco, dinâmico ou fixo
version: 1
---

Uma máquina precisa de um disco, de uma controladora onde ligá-lo, e normalmente de um drive óptico para
o instalador:

```
ana@host:~$ cd ~/"VirtualBox VMs"/lab1 && VBoxManage createmedium disk --filename lab1.vdi --size 20480
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Medium created. UUID: 2d68bc32-d25f-4071-9cf8-1d85af0f25e4
ana@host:~$ cd ~/"VirtualBox VMs"/lab1 && VBoxManage storagectl lab1 --name SATA --add sata && VBoxManage storageattach lab1 --storagectl SATA --port 0 --type hdd --medium lab1.vdi && VBoxManage storageattach lab1 --storagectl SATA --port 1 --type dvddrive --medium emptydrive
ana@host:~$ VBoxManage showmediuminfo ~/"VirtualBox VMs"/lab1/lab1.vdi | grep -E "^(Format variant|Capacity|Size on disk)"
Format variant: dynamic default
Capacity:       20480 MBytes
Size on disk:   2 MBytes
```

O `createmedium` fez um **VDI**, o formato de disco do próprio VirtualBox, de 20480 MB. O `storagectl`
acrescentou uma controladora SATA, e o `storageattach` ligou o disco na porta 0 e um **drive de DVD
vazio** na porta 1; na janela, esse drive é onde você escolhe a ISO. O `showmediuminfo` diz o resto: o
convidado vai ouvir que o disco tem 20480 MBytes, e o host deu a ele **2 MBytes**, porque a variante é
`dynamic`, o padrão.

Um disco também pode ser feito **fixo**, inteiro de uma vez:

```
ana@host:~$ cd /tmp && VBoxManage createmedium disk --filename fixed.vdi --size 1024 --variant Fixed
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Medium created. UUID: 0791b75d-34a6-4a3e-b44b-236e27344c9e
ana@host:~$ ls -lh /tmp/fixed.vdi ~/"VirtualBox VMs"/lab1/lab1.vdi
-rw------- 1 ana ana 2.0M Sep 25 19:14 /home/ana/VirtualBox VMs/lab1/lab1.vdi
-rw------- 1 ana ana 1.1G Sep 25 19:14 /tmp/fixed.vdi
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Dois discos virtuais comparados. Um disco alocado dinamicamente de 20480 megabytes, que o convidado ouve ser de 20 GB, ocupa 2.0M no host quando é novo. Um disco de tamanho fixo de 1024 megabytes ocupa 1.1G no host desde o momento em que é criado, ele inteiro.\"><defs><marker id=\"dk-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"200\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que dizem ao convidado</text><text x=\"460\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que o host cede agora</text><text x=\"20\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">alocado dinamicamente, 20480 MB</text><rect x=\"200\" y=\"66\" width=\"240\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20480 MB</text><rect x=\"460\" y=\"66\" width=\"2\" height=\"20\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"470\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2.0M</text><text x=\"20\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tamanho fixo, 1024 MB</text><rect x=\"200\" y=\"136\" width=\"12\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1024 MB</text><rect x=\"460\" y=\"136\" width=\"13\" height=\"20\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"481\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1.1G</text></svg>", "caption": "Um disco dinâmico não custa quase nada ao host até o convidado escrever; um fixo custa tudo de uma vez e nunca cresce. O primeiro é o padrão, e a escolha certa para um laboratório."}
```

O disco fixo de 1024 MB ocupa 1.1G no host no momento em que existe, e o dinâmico de
20480 MB ainda ocupa 2.0M. Um disco fixo é um pouco mais rápido de escrever, porque
nada precisa ser alocado no caminho, e nunca enche o host de surpresa. **Um disco dinâmico é a escolha
certa para um laboratório**, onde a maioria dos convidados é pequena e dura pouco, e é o motivo de dez
convidados caberem num laptop. O porém é o da aula 1: um disco dinâmico cresce conforme o convidado
escreve e não encolhe sozinho quando o convidado apaga, então fique de olho no espaço livre do host.
