---
title: Windows: Serviços e Agendador de Tarefas
version: 1
---

O Windows guarda as mesmas duas ideias com outros nomes.

## Serviços

O **`services.msc`** lista todo serviço com o **Status** (em execução ou parado, o *agora* do systemd) e o
**Tipo de inicialização**, o *no boot* do systemd:

| tipo de inicialização | quer dizer |
|---|---|
| **Automático** | inicia no boot, como `enabled` |
| **Automático (Atraso na Inicialização)** | inicia pouco depois do boot, para o login ser mais rápido |
| **Manual** | inicia quando algo pede |
| **Desativado** | nunca inicia, como `disable` |

```sh
Get-Service | Where-Object Status -eq Running
Get-Service -Name Spooler | Select-Object Name, Status, StartType
Stop-Service -Name Spooler
Start-Service -Name Spooler
Set-Service -Name Spooler -StartupType Manual     # disable is -StartupType Disabled
sc.exe query Spooler                              # the older tool, same service
```

**Nenhum dos comandos do Windows foi rodado para esta aula.** O Spooler é a fila de impressão;
reiniciá-lo é a cura clássica para um trabalho de impressão travado, e a aula 17 o encontra de novo.

## Tarefas agendadas

O **Agendador de Tarefas**, `taskschd.msc`, é o timer. Uma tarefa tem **disparadores** (um horário, o
logon, a inicialização, um evento), **ações** (um programa a rodar) e **condições** (só na tomada, só
quando ocioso). *Executar estando o usuário conectado ou não* é o ajuste que faz um trabalho noturno
funcionar às duas sem ninguém lá.

```sh
schtasks /Create /TN "Office backup" /TR "C:\Scripts\backup.cmd" /SC WEEKLY /D MON,TUE,WED,THU,FRI /ST 02:00
schtasks /Query /TN "Office backup"
Get-ScheduledTask | Where-Object State -eq Ready | Select-Object -First 5 TaskName
```

## Apps de inicialização

O que inicia quando uma **pessoa** entra é separado dos serviços: *Configurações > Aplicativos >
Inicialização*, ou a aba *Aplicativos de inicialização* do Gerenciador de Tarefas, que também estima o
**impacto na inicialização** de cada um. É o primeiro lugar a olhar num PC que demora a ficar usável
depois do login.
