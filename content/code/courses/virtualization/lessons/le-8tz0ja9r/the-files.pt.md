---
title: Uma máquina VMware no disco
version: 1
---

Uma máquina do Workstation é uma pasta, como a do VirtualBox, e vale conhecer os arquivos dela pelas
terminações, porque um cliente vai lê-las para você:

| terminação | o que é |
|---|---|
| `.vmx` | as configurações da máquina, em texto puro, um `chave = "valor"` por linha |
| `.vmdk` | um disco, ou o pequeno arquivo de texto que descreve um disco dividido em pedaços |
| `-s001.vmdk`, `-s002.vmdk`… | os pedaços de um disco dividido |
| `-000001.vmdk` | as mudanças feitas desde um snapshot, aula 9 |
| `.vmsd`, `.vmsn` | a lista de snapshots, e o estado salvo com um |
| `.vmem`, `.vmss` | a memória e o estado do convidado, enquanto está suspenso |
| `.nvram` | as configurações do firmware do convidado, a BIOS ou o UEFI |
| `vmware.log` | o que aconteceu da última vez que rodou: o primeiro lugar a olhar quando não liga |

**O `.vmx` é o que você abre**: *File* → *Open* no Workstation aceita um `.vmx`, ou um `.ova`. Para mover
uma máquina, copie a pasta inteira com o convidado desligado, não suspenso, e abra o `.vmx` do outro
lado. O Workstation então pergunta se você a *moveu* ou a *copiou*; responder *copiou* dá ao convidado
uma identidade nova e um MAC novo, que é o que você quer quando o original ainda roda em outro lugar.

Dentro do convidado, o agente do VMware é o **VMware Tools**, o agente de convidado da aula 3 com outro
nome. No Linux ele vem da distribuição como `open-vm-tools`, e muitas distribuições o instalam sozinhas
quando percebem que rodam sob o VMware.
