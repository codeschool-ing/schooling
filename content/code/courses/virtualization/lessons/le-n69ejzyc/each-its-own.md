---
title: Each with its own identity
version: 1
---

On their first boot, both clones built an identity of their own:

```
ana@web1:~$ hostname; cat /etc/machine-id; ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub | cut -d" " -f2; ip -br addr show enp1s0
web1
497efb056e9e47e2ad5e043f60c0197e
SHA256:QwyMWfkx9XuCuYM4gL0kEXcsVfng91WTDJJcvv81wok
enp1s0           UP             192.168.122.94/24 metric 100 fe80::5054:ff:fede:d811/64 
ana@web2:~$ hostname; cat /etc/machine-id; ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub | cut -d" " -f2; ip -br addr show enp1s0
web2
cad521dab6f54a3c8e19814358bd185d
SHA256:rToOEEK6436+h6osMISaGDGNlNgkHVT5FkX2Q+BIcvE
enp1s0           UP             192.168.122.87/24 metric 100 fe80::5054:ff:fec6:50d0/64 
```

Each has **its own name**, `web1` and `web2`, from its own cloud-init disk. Each has **its own
machine-id**, `497efb056e9e47e2ad5e043f60c0197e` and `cad521dab6f54a3c8e19814358bd185d`, and neither is the template's old `f2b0a97d568b4cd0bb0179512eaab5f9`. Each has **its own
host key**, and **its own address**, `192.168.122.94` and `192.168.122.87`, because the network configuration was
written again for each card. Two guests from one template, and nothing that should be unique is
shared.

This is how every lab in the rest of this course is made, and how most clouds make machines: a sealed
image, a thin layer per machine, and a small disk of settings read on the first boot. `lab.sh vm` has
done exactly this since lesson 1, with Ubuntu's own cloud image as the template.
