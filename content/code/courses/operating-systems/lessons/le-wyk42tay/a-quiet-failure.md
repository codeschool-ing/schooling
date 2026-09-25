---
title: A failure that reported success
version: 1
---

The disk report has not appeared. The service that writes it was started by hand, to watch:

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

**systemd reports no failed units, and there is no report.** The journal explains it: line 2 of the
script **could not create** the file, because `/srv/reports` does not exist, and then the script went
on, printed `report written`, and **exited successfully**. A shell script continues after a failed
command unless told not to, and a service is judged by its **last** command. So the service said
*Deactivated successfully*, every night, for a week.

That is why diagnosis reads the log **even when the status is green**. The fix comes in two parts, and
the first makes the next failure visible:

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

**`set -e`**, inserted at line 2 by `sed`, makes the script stop at the first failing command. Now the
same missing folder makes the **service fail**: `systemctl start` says so at once, `--failed` lists it,
and `status` shows *failed (Result: exit-code)*. A failure that shows itself is one somebody will
notice on the first night, not the eighth.

Then the cause itself:

```
ana@server:~$ sudo mkdir /srv/reports
ana@server:~$ sudo systemctl start office-report.service
ana@server:~$ systemctl is-failed office-report.service
inactive
ana@server:~$ ls /srv/reports
disk-2026-09-25.txt
```

The folder exists, the service ran, `is-failed` answers `inactive` (a oneshot that finished cleanly),
and the report is there.

The general lesson: **"it says it worked" is a claim, and the output is the evidence.** Check the file
the job was supposed to produce, not only the job's own report.
