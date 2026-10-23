---
title: Rules that survive a reboot
version: 1
---

**`nft -f` changes the running kernel and nothing else.** Reboot `web`, and the table is gone with
the memory it lived in; the portal starts again with every port open. Rules become permanent by being
loaded at boot, and on Ubuntu that is the job of the `nftables` service, which loads
`/etc/nftables.conf`. Ubuntu ships the file with empty chains and the service disabled, which is why
nothing was filtered before this lesson.

Copy the checked file into place and enable the service, with `--now` so it also loads the file at
once:

```
ana@web:~$ sudo cp nftables.conf /etc/nftables.conf && sudo systemctl enable --now nftables 2>&1 | sed "s/ → .*//"
Created symlink /etc/systemd/system/sysinit.target.wants/nftables.service
ana@web:~$ systemctl is-active nftables; sudo nft list ruleset | grep -c accept
active
5
ana@web:~$ sudo systemctl restart nftables && sudo nft list ruleset | grep -E "policy|reject"
		type filter hook input priority filter; policy drop;
ana@admin:~$ ssh web hostname
web
```

The service is active, and the five `accept` rules are in the kernel. The restart is the test that
matters: it throws away whatever is loaded and loads the file again, exactly as a boot would. The
`reject` experiment of the last section was loaded by hand, and after the restart it is gone: only
the `policy drop` from the file remains. **What is in the file is what the machine runs after its
next reboot**, whatever anybody loaded since, and `admin` can still log in.

## Three habits

**Check before you install.** `nft -c -f /etc/nftables.conf` before every restart. A file that does
not parse leaves the service failed, and on most systems a failed firewall service means no firewall
at all.

**Keep the file under the same control as the baseline.** The rule set is configuration like
`sshd_config.d`, and lesson 3's playbook is the right way to put it on every server and to put it
back when somebody edits it by hand. A firewall changed at the console during an incident and never
written back is drift with a port open.

**Know what else manages the firewall.** Ubuntu also ships `ufw`, a simpler front-end that writes its
own rules, and Docker, Kubernetes and fail2ban add theirs. Two tools that both believe they own the
rule set will undo each other. On `web`, `ufw` is installed and inactive, and the `nftables` file is
the only source; the moment a second tool is enabled, `nft list ruleset` is where you find out what
the kernel actually does.

Lesson 11 adds rules to this table automatically, banning an address after repeated failed logins,
and lesson 10 filters the other direction, what `web` itself may send.
