---
title: O agente do convidado
version: 1
---

O host consegue descrever o hardware de um convidado, mas o que acontece lá dentro é assunto do
convidado: o endereço, os sistemas de arquivos, a versão do Ubuntu. Para saber isso, o host pergunta a
um serviço pequeno **dentro** do convidado, o **agente do convidado**, `qemu-guest-agent`, por um canal
privado que não é a rede:

```
ana@host:~$ virsh qemu-agent-command vm1 "{\"execute\":\"guest-get-osinfo\"}" | python3 -m json.tool
{
    "return": {
        "name": "Ubuntu",
        "kernel-release": "6.8.0-139-generic",
        "version": "24.04.4 LTS (Noble Numbat)",
        "pretty-name": "Ubuntu 24.04.4 LTS",
        "version-id": "24.04",
        "kernel-version": "#139-Ubuntu SMP PREEMPT_DYNAMIC Sat Aug  1 03:52:05 UTC 2026",
        "machine": "x86_64",
        "id": "ubuntu"
    }
}
ana@host:~$ virsh domifaddr vm1 --source agent
 Name       MAC address          Protocol     Address
-------------------------------------------------------------------------------
 lo         00:00:00:00:00:00    ipv4         127.0.0.1/8
 -          -                    ipv6         ::1/128
 enp1s0     52:54:00:ce:da:4e    ipv4         192.168.122.117/24
 -          -                    ipv6         fe80::5054:ff:fece:da4e/64

ana@host:~$ virsh domfsinfo vm1
 Mountpoint   Name    Type   Target
-------------------------------------
 /            vda1    ext4   vda
 /boot        vda16   ext4   vda
 /boot/efi    vda15   vfat   vda

ana@host:~$ virsh domtime vm1; date +%s
Time: 1790374001
1790374002
```

O `guest-get-osinfo` respondeu com o sistema e o kernel do convidado. O `domifaddr --source agent` deu o
endereço lá dentro, `192.168.122.117`, direto do convidado em vez dos registros do servidor DHCP. O `domfsinfo`
listou o que está montado onde. O `domtime` leu o relógio do convidado, e ele bateu com o `date +%s` do
host com diferença de um segundo no máximo.

Pare o agente lá dentro, e o host fica cego para tudo isso:

```
ana@host:~$ virsh domfsinfo vm1
error: Unable to get filesystem information
error: Guest agent is not responding: QEMU guest agent is not connected
```

**`Guest agent is not responding`** é uma das mensagens mais comuns no log de qualquer hypervisor, e
quase sempre quer dizer que o agente não está instalado ou não está rodando lá dentro, e não que algo
quebrou. O convidado em si estava bem. O agente também é o que deixa um hypervisor congelar os
sistemas de arquivos de um convidado para um backup consistente, então um convidado sem ele recebe uma
cópia mais bruta.

Todo hypervisor tem um, com outro nome. O VirtualBox chama o pacote dele de **Guest Additions** e o
VMware chama o dele de **VMware Tools**, e os dois fazem mais que este: ajustam a tela do convidado à
janela, compartilham a área de transferência e compartilham pastas, que é a aula 12. **Instalá-los é a
primeira coisa a fazer num convidado novo.**
