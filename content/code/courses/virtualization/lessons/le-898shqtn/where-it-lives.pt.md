---
title: Onde mora uma máquina do VirtualBox
version: 1
---

Tudo sobre a `lab1` está numa pasta:

```
ana@host:~$ ls ~/"VirtualBox VMs"/lab1
lab1.vbox
lab1.vbox-prev
lab1.vdi
ana@host:~$ grep -E "<(Memory|CPU|HardDisk) |<Adapter slot=.0." ~/"VirtualBox VMs"/lab1/lab1.vbox
        <HardDisk uuid="{2d68bc32-d25f-4071-9cf8-1d85af0f25e4}" location="lab1.vdi" format="VDI" type="Normal"/>
      <CPU count="2">
      <Memory RAMSize="2048"/>
        <Adapter slot="0" enabled="true" MACAddress="0800276D37CF" type="82540EM">
```

O `lab1.vbox` é a descrição da máquina, o equivalente do XML que o libvirt guarda na aula 3, e o
`lab1.vbox-prev` é a versão anterior à última mudança, guardada caso a mais nova se estrague. O
`lab1.vdi` é o disco. A descrição guarda o disco pelo nome do arquivo, os processadores e a memória como
foram definidos, e a placa de rede, com um MAC que o VirtualBox escolheu, `0800276D37CF`, ou `08:00:27:6d:37:cf` escrito do
jeito de sempre. **Todo MAC do VirtualBox começa com `08:00:27`**, como todo MAC do QEMU começa com
`52:54:00`, e a placa é uma `82540EM`, um modelo Intel para o qual todo sistema tem driver.

A pasta é a máquina. **Para fazer backup de uma, ou levá-la para outro computador, copie a pasta
inteira com a máquina desligada**, e do outro lado acrescente-a com *Máquina* → *Adicionar*, que lê o
`.vbox`. Copiar só o `.vdi` traz o disco e perde as configurações.

Por padrão a pasta fica em *VirtualBox VMs* na sua pasta pessoal, e num laptop com disco de sistema
pequeno a primeira coisa que vale mudar é isso: *Arquivo* → *Preferências* → *Pasta Padrão de
Máquinas* pode apontar para um disco maior.
