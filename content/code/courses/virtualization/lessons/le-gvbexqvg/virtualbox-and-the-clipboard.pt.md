---
title: VirtualBox, VMware e a área de transferência
version: 1
---

No VirtualBox, a mesma pasta é um comando, e a área de transferência e o arrastar e soltar são
configurações da máquina:

```
ana@host:~$ VBoxManage sharedfolder add lab1 --name docs --hostpath /srv/docs --readonly --automount
ana@host:~$ VBoxManage modifyvm lab1 --clipboard-mode bidirectional --drag-and-drop hosttoguest
ana@host:~$ VBoxManage showvminfo lab1 --machinereadable | grep -E "^(SharedFolder|clipboard|draganddrop)"
clipboard="bidirectional"
draganddrop="hosttoguest"
SharedFolderNameMachineMapping1="docs"
SharedFolderPathMachineMapping1="/srv/docs"
```

O `--readonly` e o `--automount` fizeram o que dizem. Num convidado com os **Guest Additions**, um
compartilhamento montado automaticamente aparece como `/media/sf_docs` no Linux, legível pelos membros do
grupo `vboxsf`, ao qual um usuário precisa ser acrescentado antes, ou como uma unidade de rede no Windows.
As pastas compartilhadas do VMware vêm com o **VMware Tools** e aparecem em `/mnt/hgfs` no Linux.

**A área de transferência compartilhada** copia texto entre a área de trabalho do host e a do convidado, e
**arrastar e soltar** move arquivos do mesmo jeito. As duas precisam do agente do convidado e de uma área
de trabalho gráfica no convidado, então nenhuma pode ser mostrada no host deste curso, cujos convidados
não têm tela. Cada uma pode ficar *desativada*, *hospedeiro para convidado*, *convidado para
hospedeiro* ou *bidirecional*, e essa escolha é tão de segurança quanto de conforto: **uma área de
transferência bidirecional entrega ao convidado tudo o que você copia no host**, inclusive uma senha do seu
gerenciador de senhas. Para um convidado em que você não confia, *desativada* é a configuração; para um
que você só alimenta com arquivos, *hospedeiro para convidado*, como a `lab1` tem para arrastar e soltar.
