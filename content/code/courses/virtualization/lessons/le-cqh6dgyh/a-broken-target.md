---
title: A target broken on purpose
version: 1
---

The target gets the same service, and then one small, realistic fault: **a semicolon removed** from
nginx's configuration, the kind of typo that happens to everybody who edits a file by hand. Then a
snapshot of each machine:

```
ana@target:~$ sudo systemctl enable --now nginx 2>&1 | tail -1
Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service → /usr/lib/systemd/system/nginx.service.
ana@target:~$ sudo sed -i "s/listen 80 default_server;/listen 80 default_server/" /etc/nginx/sites-enabled/default && sudo systemctl restart nginx
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
ana@client:~$ curl -sS -m 5 http://target/
curl: (7) Failed to connect to target port 80 after 35 ms: Couldn't connect to server
ana@host:~$ virsh snapshot-create-as target broken --description "nginx config missing a semicolon" && virsh snapshot-create-as server clean && virsh snapshot-create-as client clean
Domain snapshot broken created
Domain snapshot clean created
Domain snapshot clean created
```

The restart failed, and from the client the target now refuses connections, while the server still
answers. That is the ticket: *"the website on target is down"*. The snapshot called `broken` keeps the
target in exactly this state, and `clean` snapshots of the client and the server keep the rest of the
lab as it should be.

Breaking a machine on purpose is how support labs are built. **Pick faults that happen in real life,
one at a time**, and write down in the snapshot's description what you broke, so that in a month the lab
still knows the answer even if you do not.
