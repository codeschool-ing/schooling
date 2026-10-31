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

```schooling-example
{"language": "sh", "parts": [
 {"code": "esxcli system version get", "note": "A versão e o build do ESXi."},
 {"code": "esxcli network ip interface ipv4 get", "note": "Os endereços do próprio host."},
 {"code": "esxcli storage filesystem list", "note": "Os datastores que este host enxerga."},
 {"code": "vim-cmd vmsvc/getallvms", "note": "Toda VM registrada neste host, cada uma com o id dela."},
 {"code": "vim-cmd vmsvc/power.getstate 12", "note": "Se a VM 12 está ligada."},
 {"code": "vim-cmd vmsvc/power.shutdown 12", "note": "Pede ao convidado da VM 12 que desligue, pelo VMware Tools."}
]}
```

**Nenhum deles foi rodado para esta aula**; o ESXi não está instalado no host do curso e nem pode estar.
