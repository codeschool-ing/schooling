---
title: Que máquina é esta?
version: 1
---

As primeiras perguntas de qualquer chamado: que máquina, de que tamanho, há quanto tempo está ligada.

```
ana@server:~$ hostname
server
ana@server:~$ nproc
4
ana@server:~$ uptime -p
up 1 hour, 42 minutes
PS /home/ana> [Environment]::MachineName
server
PS /home/ana> [Environment]::ProcessorCount
4
```

O `hostname` é a mesma palavra nos três sistemas. O `nproc` conta processadores; o **`uptime`** diz há
quanto tempo foi a última inicialização, e um PC que "está lento" com quarenta dias ligado tem uma
resposta antes de qualquer outro comando. O PowerShell pediu ao .NET os mesmos dois dados,
**`[Environment]::MachineName`** e `ProcessorCount`, e é por isso que essas linhas funcionam sem
mudança no Windows.

No Windows, PowerShell:

```sh
hostname
$env:COMPUTERNAME
systeminfo | Select-String "OS Name", "Total Physical Memory"
(Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
(Get-CimInstance Win32_OperatingSystem).LastBootUpTime
```

**Nenhum dos comandos do Windows desta aula foi rodado para ela.** O `systeminfo` imprime uma página
comprida de texto, e o `Select-String` pesca linhas dela, o mesmo trabalho do `grep` na seção 04. A
última linha responde a pergunta do uptime no Windows: a data e a hora da última inicialização.

No Mac a maioria dos comandos do Linux funciona como está. As exceções são poucas, e vale tê-las num
lugar só:

```sh
sysctl -n hw.ncpu                 # nproc does not exist on macOS
top -o cpu                        # sort by CPU; Linux top uses other keys
ifconfig                          # macOS still uses it; Linux uses ip
sw_vers                           # the version, lesson 4
```
