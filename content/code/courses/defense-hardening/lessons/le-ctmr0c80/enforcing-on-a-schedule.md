---
title: Enforcing it on a schedule
version: 1
---

**A baseline applied once is a baseline that was true once.** Group Policy's answer is the
background refresh every 90 minutes. Ansible's, when it is pushed from a control machine, is to run
the playbook on a timer there. On `admin`, two small systemd units do it: a service that runs the
playbook once, and a timer that starts the service every hour.

```
ana@admin:~$ cat baseline.service baseline.timer
[Unit]
Description=Put the Jatoba baseline back on every machine

[Service]
Type=oneshot
User=ana
WorkingDirectory=/home/ana
Environment=ANSIBLE_NOCOLOR=1
ExecStart=/usr/bin/ansible-playbook -i hosts.ini baseline.yml
[Unit]
Description=Run the Jatoba baseline every hour

[Timer]
OnCalendar=hourly
RandomizedDelaySec=5min
Persistent=true

[Install]
WantedBy=timers.target
```

The service runs as you, from your home, where the inventory and the playbook are, so it uses the
same SSH key you used by hand. `Type=oneshot` means it runs to the end and stops. The timer fires on
the hour, delayed by up to five minutes at random so that a fleet of control machines would not all
start together, which is the same reason Group Policy adds up to 30 minutes to its 90. `Persistent`
runs a missed hour as soon as the machine is back, if it was off.

Install both and start the timer:

```
ana@admin:~$ sudo cp baseline.service baseline.timer /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable --now baseline.timer 2>&1 | sed "s/ → .*//"
Created symlink /etc/systemd/system/timers.target.wants/baseline.timer
ana@admin:~$ systemctl list-timers baseline.timer --no-pager | head -2 | cut -c1-95
NEXT                         LEFT LAST PASSED UNIT           ACTIVATES
Fri 2026-10-23 09:04:10 -03 17min -         - baseline.timer baseline.service
```

`list-timers` shows when it fires next. There is no need to wait for it: starting the service by
hand runs exactly what the timer will, and the playbook's recap lands in the journal.

```
ana@admin:~$ sudo systemctl start baseline.service; journalctl -u baseline.service --no-pager -o cat | grep -E "^(desk|jump|web) "
desk                       : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
jump                       : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
web                        : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
ana@desk:~$ grep MaxAuth /etc/ssh/sshd_config.d/10-baseline.conf
MaxAuthTries 3
```

`desk` reports two changes, the file put back and the reload; the other two report none. The drift
of the last section is gone, and the journal records which run undid it, at what time. **That line
in the journal is the audit trail**: a hand edit that keeps coming back every hour is a person
repeating it, and somebody should ask them why.

## Push or pull

The timer on `admin` **pushes**: one machine reaches out to all the others. It needs SSH into every
machine and a control machine that is up. The alternative is **pull**: `ansible-pull` on each machine
fetches the playbook from a Git repository and applies it to itself, on its own timer. Pull suits
laptops that are rarely on the office network at the hour the push runs, which is the same problem
Microsoft answers with Intune for machines outside the domain. Neither was run for this course.

Either way, the description now lives in one place. The next thing to make central is the record of
who changed it, and that is version control: a baseline kept in a Git repository has a history,
a reviewer and a way back, which a directory on `admin` does not.
