---
title: As outras portas
version: 1
---

A rede é um dos caminhos entre convidado e host. A aula 12 abriu mais dois de propósito, e um laboratório
que roda algo em que você não confia os mantém fechados. No libvirt, a descrição do convidado diz que
dispositivos ele tem:

```
ana@host:~$ virsh dumpxml client | grep -E "<(interface|filesystem|graphics|channel) "
    <interface type='network'>
    <channel type='unix'>
ana@host:~$ VBoxManage modifyvm lab1 --clipboard-mode disabled --drag-and-drop disabled --nic1 intnet --intnet1 labnet && VBoxManage showvminfo lab1 --machinereadable | grep -E "^(clipboard|draganddrop|nic1|intnet1)="
intnet1="labnet"
nic1="intnet"
clipboard="disabled"
draganddrop="disabled"
```

O client tem **uma interface numa rede e um canal**, o do agente do convidado, que deixa o host perguntar
coisas ao convidado e não dá nada ao convidado no host. **Nenhum `filesystem`**, então nenhuma pasta
compartilhada; **nenhum `graphics`**, então nenhuma tela para levar área de transferência ou arrastar e
soltar.

O VirtualBox guarda as mesmas portas como configurações. A `lab1` começou com a área de transferência
compartilhada nos dois sentidos, arrastar e soltar do host para o convidado e NAT, o arranjo da aula 12;
um comando desliga os dois primeiros e põe a placa de rede dela numa **internal network**, o nome do
VirtualBox para o quarto modo da aula 11: os convidados se alcançam, e o host não tem endereço nenhum nela,
então não há serviço do host para alcançar.

Antes de um convidado rodar algo em que você não confia, então:

| porta | fechada por | conferida de dentro por |
| --- | --- | --- |
| a rede de verdade | uma rede isolada ou interna | nenhuma linha `default via` |
| os serviços do host | uma regra de firewall no host, ou uma rede interna | o `nc -z` para o host falha |
| uma pasta compartilhada | nenhum dispositivo `filesystem`, nenhuma pasta configurada | nenhuma montagem `9p` ou `virtiofs` |
| área de transferência, arrastar e soltar | sem gráficos, ou os dois desligados | nenhum agente de área de transferência rodando |

Depois tire um snapshot, aula 9, para o que acontecer no convidado poder ser desfeito com um comando.
