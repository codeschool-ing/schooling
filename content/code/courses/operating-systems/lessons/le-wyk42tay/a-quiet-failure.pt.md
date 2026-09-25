---
title: Uma falha que disse ter dado certo
version: 1
---

O relatório de disco não apareceu. O serviço que o escreve foi iniciado à mão, para observar:

```
ana@server:~$ sudo systemctl start office-report.service
ana@server:~$ systemctl --failed --no-pager --no-legend
ana@server:~$ ls /srv/reports
ls: cannot access '/srv/reports': No such file or directory
ana@server:~$ sudo journalctl -u office-report.service --no-pager -o cat -n 5
Starting office-report.service - Write the daily disk report...
/usr/local/bin/office-report: 2: cannot create /srv/reports/disk-2026-09-25.txt: Directory nonexistent
report written
office-report.service: Deactivated successfully.
Finished office-report.service - Write the daily disk report.
```

**O systemd não informa unidade nenhuma com falha, e não há relatório.** O journal explica: a linha 2 do
script **não conseguiu criar** o arquivo, porque o `/srv/reports` não existe, e aí o script seguiu em
frente, imprimiu `report written` e **terminou com sucesso**. Um script de shell continua depois de um
comando que falhou, a não ser que alguém mande parar, e um serviço é julgado pelo **último** comando.
Então o serviço disse *Deactivated successfully*, toda noite, por uma semana.

É por isso que o diagnóstico lê o log **mesmo quando o status está verde**. O conserto vem em duas
partes, e a primeira torna a próxima falha visível:

```
ana@server:~$ cat /usr/local/bin/office-report
#!/bin/sh
df -h / > /srv/reports/disk-$(date +%F).txt
echo "report written"
ana@server:~$ sudo sed -i '2i set -e' /usr/local/bin/office-report
ana@server:~$ sudo systemctl start office-report.service
Job for office-report.service failed because the control process exited with error code.
See "systemctl status office-report.service" and "journalctl -xeu office-report.service" for details.
ana@server:~$ systemctl --failed --no-pager --no-legend
● office-report.service loaded failed failed Write the daily disk report
ana@server:~$ systemctl status office-report.service --no-pager -n 0 | head -3
× office-report.service - Write the daily disk report
     Loaded: loaded (/etc/systemd/system/office-report.service; static)
     Active: failed (Result: exit-code) since Fri 2026-09-25 11:42:09 -03; 19ms ago
```

O **`set -e`**, inserido na linha 2 pelo `sed`, faz o script parar no primeiro comando que falhar. Agora a
mesma pasta faltando faz o **serviço falhar**: o `systemctl start` avisa na hora, o `--failed` o lista, e
o `status` mostra *failed (Result: exit-code)*. Uma falha que se mostra é uma que alguém percebe na
primeira noite, não na oitava.

Depois, a causa em si:

```
ana@server:~$ sudo mkdir /srv/reports
ana@server:~$ sudo systemctl start office-report.service
ana@server:~$ systemctl is-failed office-report.service
inactive
ana@server:~$ ls /srv/reports
disk-2026-09-25.txt
```

A pasta existe, o serviço rodou, o `is-failed` responde `inactive` (um oneshot que terminou limpo), e o
relatório está lá.

A lição geral: **"diz que funcionou" é uma afirmação, e a saída é a prova.** Confira o arquivo que o
trabalho deveria produzir, não só o relatório do próprio trabalho.
