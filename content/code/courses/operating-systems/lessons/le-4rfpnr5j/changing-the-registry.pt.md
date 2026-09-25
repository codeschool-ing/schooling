---
title: Mudando o registro, e a versão do Mac
version: 1
---

As regras da seção 03 valem, e importam mais: um arquivo de texto quebrado por um erro de digitação se
conserta com um editor, um registro quebrado na chave errada pode impedir o Windows de iniciar.

1. *Exporte antes de mudar.* No `regedit`, *Arquivo > Exportar* a chave que você vai mexer; o arquivo
   `.reg` que ele grava pode ser aberto com clique duplo para pô-la de volta.
2. *Prefira a tela do próprio ajuste.* Quase tudo no registro tem um lugar nas Configurações, nas
   opções de um programa ou na Política de Grupo, que grava o valor por você, com o tipo certo. A
   Política de Grupo, da aula 5, grava os ajustes embaixo de `HKLM\SOFTWARE\Policies`.
3. *Mude a menor coisa*, no *HKCU* quando o assunto é uma pessoa.

Pela linha de comando, no Prompt de Comando e no PowerShell:

```sh
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild
reg export "HKCU\Software\OfficeApp" C:\Backup\officeapp.reg
reg add "HKCU\Software\OfficeApp" /v Server /t REG_SZ /d printer.office /f
reg import C:\Backup\officeapp.reg
```

```sh
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' |
  Select-Object ProductName, DisplayVersion, CurrentBuild
New-Item -Path 'HKCU:\Software\OfficeApp' -Force
Set-ItemProperty -Path 'HKCU:\Software\OfficeApp' -Name Server -Value 'printer.office'
Remove-ItemProperty -Path 'HKCU:\Software\OfficeApp' -Name Server
```

**Nada disso foi rodado para esta aula.** O PowerShell trata o registro como uma unidade, `HKLM:` e
`HKCU:`, então o `New-Item`, o `Get-ItemProperty` e o `Remove-ItemProperty` da aula 12 funcionam em
chaves e valores como funcionam em pastas e arquivos, e o `-WhatIf` funciona também.

A **Restauração do Sistema**, quando está ligada, guarda o registro a cada ponto de restauração, e é o
caminho de volta quando uma mudança impede o Windows de funcionar normalmente. A aula 17 a usa.

## macOS: listas de propriedades

Um Mac guarda configurações em arquivos de **lista de propriedades**, `.plist`, o mesmo formato dos
trabalhos do launchd da aula 14: os da máquina em `/Library/Preferences`, os de cada pessoa em
`~/Library/Preferences`. São arquivos, como no Linux, e estruturados, como o registro. O comando
**`defaults`** os lê e grava pelo identificador do programa:

```sh
defaults read com.apple.dock autohide           # 0 or 1
defaults write com.apple.dock autohide -bool true
killall Dock                                     # the Dock rereads its settings
plutil -p ~/Library/Preferences/com.apple.dock.plist | head
```

**Não foi rodado para esta aula.** Um app lê os ajustes quando inicia, e é por isso que o Dock teve de ser
reiniciado com `killall Dock` para perceber.
