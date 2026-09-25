---
title: Achando um processo e parando
version: 1
---

Um `sleep` foi deixado rodando em segundo plano para esta seção, para ter o que achar.

```
ana@server:~$ ps -eo pid,user,comm --sort=pid | head -6
    PID USER     COMMAND
      1 root     systemd
     17 root     systemd-journal
     41 systemd+ systemd-resolve
     48 root     cron
     49 message+ dbus-daemon
ana@server:~$ pgrep -a sleep
5401 sleep 600
PS /home/ana> Get-Process -Name sleep | Select-Object Id, ProcessName

  Id ProcessName
  -- -----------
5401 sleep

PS /home/ana> Get-Process | Measure-Object | Select-Object Count

Count
-----
   12
```

- O `ps` lista processos; o `-eo` escolhe as colunas. As primeiras linhas são o primeiro processo da
  aula 1, o `systemd`, e os serviços que ele iniciou.
- O `pgrep -a` acha processos pelo nome e imprime o ID e a linha de comando deles.
- O `Get-Process -Name` achou o mesmo processo, com o mesmo ID, pelo PowerShell, e **contou 12** na
  máquina inteira. Um desktop roda centenas; este é um servidor mínimo.

Para parar, usa-se o ID:

```
ana@server:~$ kill 5401
ana@server:~$ pgrep -a sleep || echo "no sleep left"
no sleep left
```

O `kill` manda um pedido para parar, e um programa bem-comportado arruma as coisas e sai. O `kill -9` é
o que não pode ser recusado, os sinais da aula 1, e serve para um processo que ignorou o educado.

No Prompt de Comando:

```sh
tasklist /FI "IMAGENAME eq notepad.exe"
taskkill /PID 4312
taskkill /IM notepad.exe /F
```

O `tasklist` é a lista e o `taskkill` a parada, por ID ou por nome; o `/F` força, como o `-9`. No
PowerShell do Windows, o `Get-Process` e o **`Stop-Process -Id`** funcionam exatamente como aqui.
