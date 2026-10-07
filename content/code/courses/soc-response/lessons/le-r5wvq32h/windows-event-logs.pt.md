---
title: Windows: canais e eventos
version: 1
---

O Windows não tem `/var/log`. Ele tem **canais**, cada um num arquivo binário `.evtx` em
`C:\Windows\System32\winevt\Logs`, e cada entrada neles é um **evento** com um número que diz que tipo
de coisa aconteceu. Nada nesta seção foi rodado no laboratório do curso, que é Linux; os comandos são os
que se digitam numa máquina Windows sua, no PowerShell aberto como administrador.

Três canais existem desde o começo, e um quarto grupo cresceu em volta deles:

| canal | quem escreve nele |
|---|---|
| **Security** | a auditoria do sistema operacional: logons, uso de privilégios, contas e grupos alterados, o próprio log apagado. Só o que a **política de auditoria** pede |
| **System** | componentes e drivers do Windows: serviços instalados, iniciados, parados, o relógio alterado |
| **Application** | programas: um banco de dados, um antivírus, um instalador |
| **Applications and Services Logs** | um canal por componente, como `Microsoft-Windows-PowerShell/Operational` ou, se instalado, `Microsoft-Windows-Sysmon/Operational` |

**O canal Security registra só o que a política de auditoria habilita**, e uma instalação nova não
habilita a criação de processos, por exemplo. Conferir essa política é a primeira coisa a fazer num
parque Windows, porque um evento que nunca foi auditado não pode ser encontrado depois:

```
auditpol /get /category:*
Get-WinEvent -LogName Security -MaxEvents 5
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=(Get-Date).AddDays(-1)}
wevtutil qe Security /c:5 /rd:true /f:text
```

Todo evento traz a mesma moldura: o **canal**, o **provedor** (o componente que o escreveu), o **id do
evento**, um **nível** (informação, aviso, erro, crítico), a **hora** em UTC, o **computador**, e depois
uma seção `EventData` cujos campos dependem do id. O Visualizador de Eventos mostra essa moldura como um
formulário; o `Get-WinEvent` a devolve como objetos, e `.ToXml()` mostra os campos crus.

Dois detalhes pegam as pessoas. O canal Security tem um **tamanho máximo** e, por padrão, sobrescreve os
eventos mais antigos quando enche; num controlador de domínio movimentado isso pode ser questão de horas, e
é por isso que logs do Windows são encaminhados para fora da máquina (Windows Event Forwarding, ou um
agente) em vez de lidos ali. E a **hora do evento é guardada em UTC** e exibida no fuso local de quem
olha, então dois analistas em duas cidades lendo o mesmo evento veem dois relógios diferentes.
