---
title: Ajustando
version: 1
---

Algumas configurações decidem se um convidado é agradável ou penoso, e a maioria é sobre dizer ao
convidado a verdade sobre onde ele roda:

```
ana@host:~$ VBoxManage modifyvm lab1 --paravirtprovider kvm --ioapic on --clipboard-mode bidirectional --boot1 disk --boot2 dvd --boot3 none --boot4 none
ana@host:~$ VBoxManage showvminfo lab1 --machinereadable | grep -E "^(memory|cpus|paravirtprovider|graphicscontroller|vram|nic1|clipboard|boot1|boot2|\"SATA-0-0\")="
memory=2048
vram=16
cpus=2
boot1="disk"
boot2="dvd"
paravirtprovider="kvm"
graphicscontroller="vmsvga"
"SATA-0-0"="/home/ana/VirtualBox VMs/lab1/lab1.vdi"
nic1="nat"
clipboard="bidirectional"
```

- **`--paravirtprovider kvm`** deixa um convidado Linux saber que é convidado, para usar jeitos mais
  baratos de marcar o tempo e de esperar em vez de fingir que está sozinho numa máquina de verdade. O
  `hyperv` faz o mesmo para um convidado Windows. O tipo da seção 03 normalmente já define isso.
- **`--ioapic on`** é necessário para mais de um processador. O VirtualBox o liga para a maioria dos
  tipos modernos.
- **`graphicscontroller="vmsvga"`** é o que o VirtualBox recomenda para convidados Linux; para um
  convidado Windows ele recomenda a **VBoxSVGA**. A errada dá uma tela pequena e fixa, que não muda de
  tamanho.
- **Ordem de boot**: `boot1="disk"` e `boot2="dvd"` começam pelo disco e caem no DVD. Durante a
  instalação, o DVD vem primeiro; depois, o disco, ou o convidado dá boot no instalador de novo.
- **`clipboard="bidirectional"`** compartilha a área de transferência nos dois sentidos e, como o ajuste
  de tela e as pastas compartilhadas, só funciona depois que o convidado tem os **Guest Additions**
  ("Adicionais para Convidado" na interface em português), o agente da aula 3 com o nome do VirtualBox.
  Eles são instalados por *Dispositivos* → *Inserir imagem de CD dos Adicionais para Convidado* na
  janela do convidado, e num convidado Linux precisam dos cabeçalhos do kernel do convidado para
  compilar.

E duas regras sobre os números. **Nunca dê a um convidado tantos processadores quanto o host tem**: o
host e os outros convidados ainda precisam de alguns, e o VirtualBox pinta o controle de vermelho
depois do que é seguro. **Memória no convidado é memória fora do host**: 2048 MB aqui são 2048
MB que o host não pode usar enquanto o convidado roda, mais os do próprio hypervisor.
