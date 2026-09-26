---
title: VMware ESXi
version: 1
---

O **ESXi** é o hypervisor tipo 1 da VMware. Ele é instalado no disco do próprio servidor, e a tela dele, a **DCUI**, é uma página amarela e cinza mostrando o endereço do servidor. Apertar
F2 ali abre um menu pequeno para as poucas coisas que não podem esperar pela rede: a senha de root, o
endereço de gerência, reiniciar os agentes de gerência. Todo o resto é feito por um navegador.

Cada servidor ESXi tem a própria página web, o **Host Client**, em `https://` seguido do endereço dele e
de `/ui`. Ele cria e roda máquinas, e basta para um servidor. Com vários, as empresas acrescentam o
**vCenter**, um appliance separado que gerencia todos como um só, que é a seção 03.

**Os termos do ESXi também mudaram em 2024.** A Broadcom encerrou a edição gratuita que laboratórios
usavam havia anos e passou as pagas para assinatura; parte disso já mudou de novo desde então. Um
laboratório em ESXi só vale ser planejado depois de conferir quanto custa hoje, e o Proxmox, aula 6, é
para onde a maioria das pessoas foi.

A linha de comando dele é alcançada por SSH, quando um administrador a habilita, e é assim:

```sh
esxcli system version get          # the ESXi version and build
esxcli network ip interface ipv4 get   # the host's own addresses
esxcli storage filesystem list     # the datastores this host sees
vim-cmd vmsvc/getallvms            # every VM registered on this host, with its id
vim-cmd vmsvc/power.getstate 12    # whether VM 12 is on
vim-cmd vmsvc/power.shutdown 12    # ask VM 12's guest to shut down, through VMware Tools
```

**Nenhum deles foi rodado para esta aula**; o ESXi não está instalado no host do curso e nem pode estar.
