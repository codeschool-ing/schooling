---
title: Windows: Visualizador de Eventos e as ferramentas de reparo
version: 1
---

O Windows guarda o registro dele no **Visualizador de Eventos**, o `eventvwr.msc`. Os logs que importam
primeiro ficam em *Logs do Windows*:

| log | o que vai para lá |
|---|---|
| **Sistema** | o próprio Windows: drivers, serviços, desligamentos |
| **Aplicativo** | os programas: travamentos, erros que eles informam |
| **Segurança** | logins e ações auditadas, o registro da aula 10 |

Cada evento tem um *nível* (*Crítico*, *Erro*, *Aviso*, *Informações*), uma *fonte*, e um *ID de
evento*, um número que quer dizer a mesma coisa em todo PC com Windows e é o que se busca. Dois que vale
conhecer: o *41* da fonte *Kernel-Power* quer dizer que o PC reiniciou sem desligar direito, o sintoma
do PC da recepção; o *7000* do *Service Control Manager* quer dizer que um serviço falhou ao iniciar.

```sh
Get-WinEvent -LogName System -MaxEvents 5
Get-WinEvent -FilterHashtable @{LogName='System'; Level=2; StartTime=(Get-Date).AddDays(-1)}
Get-WinEvent -FilterHashtable @{LogName='System'; Id=41} -MaxEvents 3   # unexpected shutdowns
perfmon /rel                                                             # Reliability Monitor
```

**Nenhum dos comandos do Windows foi rodado para esta aula.** O **Monitor de Confiabilidade**, a última
linha, desenha os mesmos eventos como uma linha do tempo com uma nota de estabilidade por dia. É a
resposta mais rápida para *desde quando, e o que mudou?*: o dia em que a linha cai em geral tem uma
atualização ou um programa novo instalado.

## Quando os próprios arquivos do Windows estão danificados

```sh
sfc /scannow                                     # check Windows' own files, replace damaged ones
DISM /Online /Cleanup-Image /RestoreHealth       # repair the store sfc copies from
chkdsk C: /scan                                  # check the file system while running
```

O `sfc` compara os arquivos de sistema do Windows com cópias boas conhecidas e troca os danificados; o
`DISM` repara o repositório de onde vêm essas cópias, então roda antes quando o `sfc` não consegue
consertar tudo. O `chkdsk` confere o próprio sistema de arquivos. Os três precisam de um Terminal elevado,
o *Executar como administrador* da aula 10.
