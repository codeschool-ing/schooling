---
title: Os direitos de quem?
version: 1
---

Agora o convidado escreve na pasta compartilhada:

```
ana@vm1:~$ echo "written in vm1" > /mnt/share/from-guest.txt
bash: line 1: /mnt/share/from-guest.txt: Permission denied
ana@host:~$ ls -ld /srv/share; ps -o user= -C qemu-system-x86_64
drwxr-xr-x 2 ana ana 4096 Sep 25 21:25 /srv/share
libvirt-qemu
ana@host:~$ sudo chgrp kvm /srv/share && sudo chmod g+w /srv/share
ana@vm1:~$ echo "written in vm1" > /mnt/share/from-guest.txt && ls -l /mnt/share
total 12
-rw-rw-r-- 1 ana ana 15 Sep 25  2026 from-guest.txt
-rw-r--r-- 1 ana ana 16 Sep 25 21:25 from-host.txt
ana@host:~$ ls -l /srv/share && cat /srv/share/from-guest.txt
total 12
-rw------- 1 libvirt-qemu kvm 15 Sep 25 21:28 from-guest.txt
-rw-r--r-- 1 ana          ana 16 Sep 25 21:25 from-host.txt
cat: /srv/share/from-guest.txt: Permission denied
ana@vm1:~$ echo "a note" > /mnt/docs/note.txt
bash: line 1: /mnt/docs/note.txt: Read-only file system
```

A primeira escrita foi **recusada**. Não pelo convidado: para a vm1, a ana é dona dos arquivos dela lá
dentro. Pelo host, porque **todo acesso a uma pasta compartilhada é feito pelo processo do hypervisor**,
e o `ps` mostra que esse processo roda como `libvirt-qemu`. A pasta era da ana com `drwxr-xr-x`, então o
`libvirt-qemu` conseguia ler e não escrever nela. Dar ao grupo do QEMU, `kvm`, o direito de escrever
resolveu.

Depois, a outra metade da mesma regra. No convidado, o `from-guest.txt` é da ana com `rw-rw-r--`. No host
ele é de **`libvirt-qemu`, `rw-------`**, e a ana no host não consegue lê-lo. É isso que `mapped` quer
dizer: o QEMU cria o arquivo como ele mesmo, e guarda à parte, em atributos estendidos, a ideia que o
convidado tem do dono e do modo, para o convidado ver.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 180\" role=\"img\" aria-label=\"O caminho de uma escrita numa pasta compartilhada. Dentro da vm1, a ana escreve um arquivo e o vê como dela, rw-rw-r--. O pedido vai por 9p até o QEMU, que roda no host como libvirt-qemu e escreve com os próprios direitos. No host, o arquivo pertence a libvirt-qemu com modo rw-------, e a ideia que o convidado tem de dono e modo é guardada à parte em atributos estendidos.\"><defs><marker id=\"sp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"69\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dentro da vm1: ana, rw-rw-r--</text><rect x=\"260\" y=\"40\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"272\" y=\"69\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">QEMU, rodando como libvirt-qemu</text><rect x=\"500\" y=\"40\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"69\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">no host: libvirt-qemu, rw-------</text><path d=\"M222 65 L258 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah)\"></path><path d=\"M462 65 L498 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah)\"></path><text x=\"20\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pede como ana</text><text x=\"260\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">escreve com os próprios direitos</text><text x=\"500\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">guarda ana e rw-rw-r--</text><text x=\"500\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">em atributos estendidos</text></svg>", "caption": "Todo acesso a uma pasta compartilhada é feito pelo processo do hypervisor, com os direitos desse processo. Então a pasta precisa deixar o QEMU entrar, e o que o convidado escreve pertence, no host, ao QEMU."}
```

Nada está quebrado aqui, e é exatamente o tipo de coisa pela qual um cliente liga: "a VM não consegue
salvar na pasta compartilhada", "não consigo abrir o que a VM salvou". O conserto depende do produto, e a
pergunta é sempre a mesma: **com os direitos de quem o hypervisor está chegando a esta pasta?**

O compartilhamento só de leitura recusou a última escrita de cara: `Read-only file system`.
