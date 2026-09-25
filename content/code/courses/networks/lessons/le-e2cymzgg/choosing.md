---
title: Which one, and from Windows and macOS
version: 1
---

| | port | encrypted | where it fits |
|---|---|---|---|
| FTP | 21, and a data port per transfer | no | old hosting accounts, and devices that know nothing else |
| FTPS | 21 (or 990), and data ports | yes, TLS | hosting that offers it instead of SFTP |
| SFTP | 22 | yes, SSH | anything with an SSH server |
| scp | 22 | yes, SSH | one file, quickly |
| rsync over SSH | 22 | yes, SSH | backups, and folders that change a little |

Where there is a choice, SFTP, scp and rsync win: one port, encryption, and the keys already set up for
SSH. **Plain FTP belongs only where nothing else is offered**, with a password used for nothing else.

```sh
scp report.pdf ana@192.168.10.10:                  # Windows 10 and 11, PowerShell: the same scp
sftp ana@192.168.10.10                             # Windows: the same sftp
robocopy C:\Docs \\server\backup /MIR             # Windows: mirror a folder to a share; /MIR deletes too
rsync -av Documents/ ana@192.168.10.10:backup/     # macOS: rsync is in the Terminal
```

None of these were run for this lesson. Windows 10 and 11 have `scp` and `sftp` in PowerShell, from
the same OpenSSH client as lesson 7. WinSCP and FileZilla are the graphical clients most offices use;
FileZilla speaks FTP, FTPS and SFTP, so check which one a saved site is set to. Windows has no rsync of
its own; `robocopy /MIR` mirrors a folder to a share, and deletes like `--delete` does. On a Mac, `scp`,
`sftp` and `rsync` are in the Terminal.
