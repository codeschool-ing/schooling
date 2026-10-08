---
title: O disco base
version: 1
---

Todo convidado deste curso começa de um disco que já tem o Ubuntu, a **base** do laboratório. Instalar o
Ubuntu de uma ISO para cada convidado levaria vinte minutos e uma dúzia de respostas a cada vez. Em vez
disso, a base é a **imagem de nuvem mínima** do Ubuntu, um disco que a Canonical publica com o sistema já
instalado e mais nada, feito para ser copiado. Ela vem com uma lista de checksums, e a primeira coisa a
fazer com um download é conferi-lo contra essa lista:

```
ana@host:~$ curl -sSLO https://cloud-images.ubuntu.com/minimal/releases/noble/release/ubuntu-24.04-minimal-cloudimg-amd64.img
ana@host:~$ curl -sSLO https://cloud-images.ubuntu.com/minimal/releases/noble/release/SHA256SUMS
ana@host:~$ sha256sum --check --ignore-missing SHA256SUMS
ubuntu-24.04-minimal-cloudimg-amd64.img: OK
```

O `curl -O` guarda o arquivo com o próprio nome, o `-L` segue um redirecionamento e o `-sS` fica quieto
a não ser que algo falhe. O `sha256sum --check` calculou o checksum da imagem e o achou no `SHA256SUMS`:
**`OK`**. O `--ignore-missing` pula os outros arquivos que a lista cita, que não foram baixados. Um
arquivo que chegou cortado ou mudou no caminho diz `FAILED` aqui, e é baixado de novo.

A imagem é usada como está, mais cinco programas de que as aulas precisam dentro de todo convidado, que
entram agora porque alguns convidados mais adiante não têm internet para buscá-los: `qemu-guest-agent`,
aula 3; `nginx-light`, um servidor web pequeno, desligado até uma aula ligá-lo; e `curl`,
`netcat-openbsd` e `tcpdump`, para testar redes. O `virt-customize` os põe **sem ligar a imagem como
convidado**: ele dá boot num sistema ajudante pequeno, só dele, com o disco conectado, roda o `apt` lá
dentro e grava o resultado. Ele trabalha numa cópia, para o download ficar como chegou:

```
ana@host:~$ cp ubuntu-24.04-minimal-cloudimg-amd64.img lab-base.qcow2
ana@host:~$ sudo virt-customize -a lab-base.qcow2 --install qemu-guest-agent,nginx-light,curl,netcat-openbsd,tcpdump --run-command "systemctl disable nginx" --truncate /etc/machine-id
[   0.0] Examining the guest ...
[  40.1] Setting a random seed
virt-customize: warning: random seed could not be set for this type of guest
[  40.5] Setting the machine ID in /etc/machine-id
[  40.5] Installing packages: qemu-guest-agent nginx-light curl netcat-openbsd tcpdump
[ 146.2] Running: systemctl disable nginx
[ 148.1] Truncating: /etc/machine-id
[ 148.1] SELinux relabelling
[ 149.1] Finishing off
```

Levou uns dois minutos e meio aqui, quase tudo instalando. As duas linhas de `machine-id` merecem um
olhar. O Ubuntu deixa o `/etc/machine-id` vazio na imagem para cada máquina feita dela inventar o próprio
no primeiro boot; o `virt-customize` o preencheu, e o `--truncate` o esvaziou de novo. Sem isso, todo
convidado do laboratório teria uma só identidade, um problema a que a aula 10 dedica uma seção inteira.

Por último, a base vai para onde o libvirt guarda discos, e fica **só de leitura**:

```
ana@host:~$ sudo mv lab-base.qcow2 /var/lib/libvirt/images/ && sudo chmod 444 /var/lib/libvirt/images/lab-base.qcow2
ana@host:~$ sudo ls -lh /var/lib/libvirt/images/
total 620M
-r--r--r-- 1 ana ana 620M Oct  7 05:35 lab-base.qcow2
```

O `chmod 444` não é capricho. Todo convidado vai ler deste arquivo, então uma escrita nele muda todos os
convidados de uma vez. E existe um comando que escreve nele por padrão: a aula 9 o mostra falhando
contra este arquivo, que é o único motivo de ele falhar.
