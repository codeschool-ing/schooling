---
title: A metade do PowerShell que esta máquina não tem
version: 1
---

Tudo até aqui rodou na máquina em que estas capturas foram feitas. Esta seção é
sobre o que não rodou, e por quê — porque o motivo de o PowerShell existir é
administrar Windows, e nada disso está aqui.

```
PS /home/ana/work/ps> Get-Service
Get-Service: The term 'Get-Service' is not recognized as a name of a cmdlet, function, script file, or executable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
PS /home/ana/work/ps> Get-CimInstance Win32_OperatingSystem
Get-CimInstance: The term 'Get-CimInstance' is not recognized as a name of a cmdlet, function, script file, or executable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
PS /home/ana/work/ps> Get-ChildItem HKLM:\Software
Get-ChildItem: Cannot find drive. A drive with the name 'HKLM' does not exist.
```

**Esses são os erros reais.** Os cmdlets não estão escondidos nem desativados — eles
não existem, porque os módulos que os contêm não são compilados para esta
plataforma.

```
PS /home/ana/work/ps> Get-Module -ListAvailable | Select-Object Name | Sort-Object Name
Name
----
Microsoft.PowerShell.Archive
Microsoft.PowerShell.Host
Microsoft.PowerShell.Management
Microsoft.PowerShell.PSResourceGet
Microsoft.PowerShell.Security
Microsoft.PowerShell.Utility
PackageManagement
PowerShellGet
PSReadLine
ThreadJob
```

Dez módulos, 293 comandos. Um Windows Server tem esses mais dezenas de outros, e a
contagem chega aos milhares assim que os papéis de servidor são instalados.

**Este é o escopo honesto da aula.** O que segue é descrito, não demonstrado, e
você deve tratar como um mapa e não como uma captura.

## Serviços

```sh
Get-Service                                   # all of them
Get-Service -Name 'W3SVC' | Select Status
Get-Service | Where-Object Status -eq 'Stopped'
Restart-Service -Name 'Spooler'
Set-Service -Name 'Spooler' -StartupType Disabled
```

A forma é a mesma de tudo que você viu: objetos com um `Status`, um `StartMode` e
um `DisplayName`, filtrados com `Where-Object`. Isso é o `systemctl` da aula 5 seção 09
com a análise removida — o `systemctl is-active` te dá uma palavra para comparar,
o `Get-Service` te dá uma propriedade.

## CIM e WMI — a máquina como objetos

```sh
Get-CimInstance Win32_OperatingSystem | Select Caption, LastBootUpTime
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select DeviceID, FreeSpace
Get-CimInstance Win32_Process | Where-Object Name -eq 'notepad.exe'
Get-CimInstance -ClassName Win32_BIOS -ComputerName web01
```

O CIM é um catálogo de tudo que o Windows sabe sobre si mesmo — hardware, discos,
placas de rede, software instalado, a BIOS — exposto como classes com propriedades.

**Não há um equivalente único no Linux** porque a informação está espalhada por
`/proc`, `/sys`, `dmidecode`, `lsblk` e `ip`, cada um com o próprio formato de
saída. A aula 11 usa vários deles. A vantagem do CIM é a uniformidade; o custo é
que os nomes de classe são inadivinháveis e o `Get-CimClass -ClassName Win32_*` é
como você os encontra.

O `Get-WmiObject` é o cmdlet mais antigo para os mesmos dados. Ele foi removido no
PowerShell 7 e você ainda vai encontrá-lo em todo script escrito antes de 2019.

## O registro

A seção de provedores mostrou o drive não existindo. No Windows:

```sh
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' | Select ProductName
Set-ItemProperty -Path 'HKCU:\Software\MyApp' -Name Level -Value debug
New-ItemProperty -Path 'HKCU:\Software\MyApp' -Name Retries -Value 3 -PropertyType DWord
```

O registro é onde o Windows guarda o que o Linux guarda em `/etc`, e a diferença
que importa operacionalmente é que ele é uma árvore **tipada** — `DWord`, `String`,
`MultiString` — em vez de um diretório de arquivos de texto. Você não consegue
passar um `sed` nele, e não precisa.

## Remoting

```sh
Invoke-Command -ComputerName web01,web02 -ScriptBlock { Get-Service W3SVC }
$s = New-PSSession -ComputerName web01; Invoke-Command -Session $s { … }
Enter-PSSession -ComputerName web01
```

Esta é a que vale entender mesmo de longe, porque é genuinamente diferente do
`ssh`.

**O `ssh host 'comando'` manda texto e recebe texto.** A aula 5 seção 06 mostrou
exatamente isso, e qualquer coisa que você queira fazer com o resultado você
analisa.

**O `Invoke-Command` manda um bloco de script e recebe objetos.** Eles são
serializados do outro lado, mandados pela rede, e reidratados do seu — então o
`Invoke-Command -ComputerName web01,web02 { Get-Service }` te dá uma coleção de
objetos de serviço de duas máquinas, com uma propriedade `PSComputerName` dizendo
qual é qual, e dá para passar um `Group-Object` nela.

A pegadinha é que eles chegam **desserializados**: as propriedades estão lá, os
métodos não. Um objeto que voltou de uma máquina remota é uma fotografia, não uma
alça.

O PowerShell 7 também faz isso por ssh em vez de WinRM, que é como uma caixa Linux
conduz uma Windows.

## Active Directory

```sh
Get-ADUser -Filter "Department -eq 'Support'" -Properties LastLogonDate
Get-ADComputer -Filter * | Where-Object OperatingSystem -like '*Server*'
Add-ADGroupMember -Identity 'App Admins' -Members alice
```

Todo usuário, grupo e máquina de um domínio Windows, como objetos. **É por isso que
o PowerShell não é opcional numa casa Windows** — não há outra forma suportada de
mudar dez mil contas, e a interface gráfica faz uma por vez.

Repare no `-Filter`: ele é entregue ao servidor de diretório, que é o argumento de
filtrar à esquerda da seção 05 na escala em que ele deixa de ser otimização e vira
a diferença entre uma consulta e um tempo esgotado.

## Duas versões, e qual você vai encontrar

| | |
|---|---|
| **Windows PowerShell 5.1** | vem no Windows. Construído sobre o .NET Framework. Congelado |
| **PowerShell 7** | o atual. Multiplataforma, instalado à parte. `pwsh` |

Os executáveis têm até nomes diferentes — `powershell.exe` contra `pwsh.exe` — e os
dois podem estar instalados ao mesmo tempo.

**Assuma 5.1 num servidor que você não configurou.** A maior parte desta aula é
idêntica nele; as diferenças que vão te pegar são o `.Count` num objeto único
(seção 09), o `ConvertTo-Json -Depth`, os operadores ternário e de coalescência
nula que o 5.1 não tem, e o `Get-WmiObject` ainda estar presente lá e ter sumido
aqui.
