---
title: Kept running by systemd
version: 2
---

An image is not a service. Something has to start it, restart it when it dies and start it again when
the server boots, and on a Linux server that something is **systemd**. Podman's *Quadlet* writes the
systemd service for you from a short file:

```schooling-example
{"language": "ini", "file": "deploy/loanbook.container", "parts": [{"code": "[Unit]\nDescription=loanbook, the equipment loan register", "note": "A Quadlet file: Podman reads `.container` files in `/etc/containers/systemd/` and turns each into a systemd service. The `[Unit]` section is systemd's own."}, {"code": "[Container]\nImage=localhost/loanbook:latest\nPublishPort=127.0.0.1:8000:8000", "note": "The image built a moment before, and its port published on `127.0.0.1` only. Nothing outside the server reaches it directly; Caddy does, and Caddy is the only door."}, {"code": "Volume=loanbook-data:/data:U", "note": "The database lives in a named volume, outside the container, so it survives the container being replaced. `:U` hands the volume to the container's user, 1000, who could not write to it otherwise."}, {"code": "HealthCmd=python3 -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz')\"\nHealthInterval=30s", "note": "Every thirty seconds Podman asks `/healthz` from inside the container. A failure marks the container unhealthy, which is what a monitor looks at."}, {"code": "[Service]\nRestart=always\n\n[Install]\nWantedBy=multi-user.target", "note": "`Restart=always` brings it back when it dies; `WantedBy` starts it at boot. Together they are what *stays up* means."}]}
```

Installing it is a copy and two commands:

```
ana@srv:~/loanbook$ cat deploy/loanbook.container
[Unit]
Description=loanbook, the equipment loan register

[Container]
Image=localhost/loanbook:latest
PublishPort=127.0.0.1:8000:8000
Volume=loanbook-data:/data:U
HealthCmd=python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz')"
HealthInterval=30s

[Service]
Restart=always

[Install]
WantedBy=multi-user.target
ana@srv:~/loanbook$ sudo cp deploy/loanbook.container /etc/containers/systemd/
ana@srv:~/loanbook$ sudo systemctl daemon-reload
ana@srv:~/loanbook$ sudo systemctl start loanbook
ana@srv:~/loanbook$ systemctl status loanbook --no-pager | head -4
● loanbook.service - loanbook, the equipment loan register
     Loaded: loaded (/etc/containers/systemd/loanbook.container; generated)
     Active: active (running) since Wed 2026-10-07 10:58:47 UTC; 3s ago
   Main PID: 2143 (conmon)
ana@srv:~/loanbook$ curl -s 127.0.0.1:8000/healthz
{"ok": true}
```

`daemon-reload` makes systemd read the new file and generate `loanbook.service`; `status` shows it
active, with the container's monitor, `conmon`, as its main process. And `/healthz` answers from the
server itself. The database starts empty, so the seed script of lesson 17 runs **inside** the container,
where the database is:

```
ana@srv:~/loanbook$ sudo podman exec systemd-loanbook python3 seed.py
seeded 8 items, 4 of them out
```

Two decisions in the unit file carry most of the weight. The port is published on `127.0.0.1` only, so
**the container is not reachable from the network at all**: the next section puts Caddy in front, and
Caddy is the only way in. And the data is in a **named volume**, not in the container, so replacing the
container with a new image, which is what every future deploy does, keeps every loan.
