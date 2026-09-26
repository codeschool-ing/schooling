---
title: Uma tabela para todos
version: 1
---

Todo hypervisor deste curso tem as mesmas partes com nomes diferentes. Esta é a tabela para deixar aberta
durante um chamado sobre um produto que você nunca usou:

| | libvirt e QEMU | VirtualBox | VMware Workstation | ESXi | Hyper-V | Proxmox |
|---|---|---|---|---|---|---|
| tipo | discutido | 2 | 2 | 1 | 1 | discutido, como o libvirt |
| configurações | XML | `.vbox` | `.vmx` | `.vmx` | `.vmcx` | `100.conf` |
| disco | qcow2 | VDI | VMDK | VMDK | VHDX | qcow2, ou volumes LVM e ZFS |
| agente | qemu-guest-agent | Guest Additions | VMware Tools | VMware Tools | Serviços de Integração | qemu-guest-agent |
| salvar um estado | snapshot | snapshot | snapshot | snapshot | checkpoint | snapshot |
| o switch dos convidados | virbr0 | por modo de rede | VMnet0, 1, 8 | vSwitch | switch virtual | vmbr0 |
| gerenciado por | virsh, virt-manager | a janela dele, VBoxManage | a janela dele, vmrun | Host Client, vCenter | Gerenciador do Hyper-V, PowerShell | um navegador, qm |

As linhas que mais importam para o suporte são **disco** e **agente**. Um disco sempre pode ser levado a
outro hypervisor e convertido, aula 5. Um convidado sem o agente dele é a causa de muitas reclamações
pequenas: uma tela que não muda de tamanho, uma área de transferência que não faz nada, um
desligamento que precisa ser forçado, um endereço que o host não consegue mostrar.

**As aulas 8 a 15 usam o libvirt para tudo**, porque é o que o laboratório consegue rodar. Cada coisa que
elas fazem existe em toda coluna desta tabela, com o nome da linha dela.
