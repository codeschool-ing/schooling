---
title: Qual usar, e a partir do Windows e do macOS
version: 1
---

| | porta | cifrado | onde cabe |
|---|---|---|---|
| FTP | 21, e uma porta de dados por transferência | não | contas de hospedagem antigas, e aparelhos que não sabem outra coisa |
| FTPS | 21 (ou 990), e portas de dados | sim, TLS | hospedagem que o oferece em vez de SFTP |
| SFTP | 22 | sim, SSH | tudo que tenha servidor SSH |
| scp | 22 | sim, SSH | um arquivo, rápido |
| rsync por SSH | 22 | sim, SSH | backups, e pastas que mudam um pouco |

Onde há escolha, SFTP, scp e rsync ganham: uma porta, cifragem, e as chaves já configuradas para o SSH.
**O FTP puro só cabe onde nada mais é oferecido**, com uma senha que não sirva para mais nada.

```sh
scp report.pdf ana@192.168.10.10:                  # Windows 10 and 11, PowerShell: the same scp
sftp ana@192.168.10.10                             # Windows: the same sftp
robocopy C:\Docs \\server\backup /MIR             # Windows: mirror a folder to a share; /MIR deletes too
rsync -av Documents/ ana@192.168.10.10:backup/     # macOS: rsync is in the Terminal
```

Nenhum deles foi rodado para esta aula. O Windows 10 e o 11 têm `scp` e `sftp` no PowerShell, do mesmo
cliente OpenSSH da aula 7. O WinSCP e o FileZilla são os clientes gráficos que a maioria dos escritórios
usa; o FileZilla fala FTP, FTPS e SFTP, então confira qual deles um site salvo está usando. O Windows não
tem rsync próprio; o `robocopy /MIR` espelha uma pasta num compartilhamento, e apaga como o `--delete`
apaga. No Mac, `scp`, `sftp` e `rsync` estão no Terminal.
