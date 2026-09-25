---
title: Cinco coisas antes de alguém usar
version: 1
---

A mesma ideia da lista da aula 2, com os nomes do Mac:

1. **Atualizações.** *Ajustes do Sistema > Geral > Atualização de Software*, até dizer que o Mac está
   em dia, e ligue as **atualizações automáticas** no mesmo lugar. A primeira rodada depois de apagar
   pode levar mais de uma passada.
2. **FileVault ligado.** Se foi pulado no Assistente de Configuração: *Ajustes do Sistema > Privacidade
   e Segurança > FileVault*. Anote a chave de recuperação.
3. **Um nome.** *Ajustes do Sistema > Geral > Compartilhamento*, no fim, define o **nome do host
   local**, que é como o Mac aparece na rede. `OFFICE-MAC-01`, não *MacBook Pro de Ana*.
4. **O firewall.** O macOS vem com ele **desligado**. *Ajustes do Sistema > Rede > Firewall*. Num
   notebook que entra no Wi-Fi do café, ele deve ficar ligado.
5. **Um backup.** O **Time Machine**, em *Ajustes do Sistema > Geral*, para um disco externo ou uma
   pasta de rede. Ele guarda cópias de hora em hora por um dia e diárias por um mês, e é o que o
   *Restaurar do Time Machine* da Recuperação lê.

O mesmo pelo Terminal, para quando há vários Macs:

```sh
softwareupdate --list                             # what is waiting
sudo softwareupdate --install --all --restart     # install it all, restart if needed
fdesetup status                                   # "FileVault is On." or Off
sudo scutil --set ComputerName "OFFICE-MAC-01"    # the name people see
sudo scutil --set LocalHostName "OFFICE-MAC-01"   # the name on the network (.local)
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
```

**Nenhum destes foi rodado para esta aula.** Dois dos nomes do Mac diferem de propósito: o
*ComputerName* é o que as pessoas veem no Finder, e o *LocalHostName* é o que a rede usa, com `.local`
no fim.

## Muitos Macs

Uma empresa com cinquenta Macs não faz nada disso à mão. Ela usa o **Apple Business Manager** com um
serviço de **gerenciamento de dispositivos** (*MDM*): os Macs comprados pela conta da empresa ficam
registrados nela desde a fábrica, e quando um novo entra no Wi-Fi pela primeira vez, o Assistente de
Configuração o inscreve, aplica os ajustes, liga o FileVault e guarda a chave de recuperação num lugar
central. **O Bloqueio de Ativação passa a ser gerenciado pela organização**, e não por quem tirou o Mac
da caixa. É o Autopilot da aula 2 com o nome da Apple, e faz as mesmas perguntas uma vez em vez de em
cada mesa.
