---
title: Provando que continua no ar
version: 2
---

*Continua no ar* é uma afirmação, e esta aula é sobre evidência, então aqui está a evidência. Primeiro, o
health check que o arquivo da unidade declarou, rodado à mão e lido de volta:

```
ana@srv:~$ sudo podman healthcheck run systemd-loanbook && echo healthy
healthy
ana@srv:~$ sudo podman inspect --format '{{.State.Health.Status}}' systemd-loanbook
healthy
```

Depois o teste de verdade: **derrube**. `podman kill` para o container de repente, como uma pane faria, e o
contador de reinícios do systemd mostra o que aconteceu em seguida:

```
ana@srv:~$ systemctl show -p NRestarts loanbook
NRestarts=0
ana@srv:~$ sudo podman kill systemd-loanbook
systemd-loanbook
ana@srv:~$ systemctl show -p NRestarts loanbook
NRestarts=1
ana@srv:~$ systemctl is-active loanbook
active
ana@laptop:~$ curl -sS https://loans.lab/healthz
{"ok": true}
ana@laptop:~$ curl -sS https://loans.lab/api/items | python3 -c 'import json,sys; print(len(json.load(sys.stdin)), "items")'
8 items
```

O contador foi de 0 para 1: o systemd viu o serviço morrer e o subiu de novo, em segundos, sem ninguém
mexer. Do laptop, o endereço ainda responde, e a lista ainda tem oito itens, porque o banco mora no volume
e não no container que morreu.

A última verificação é o boot. O srv destas transcrições é um container, que não volta sozinho depois de
reiniciar, então um reinício não foi gravado. O que dá para mostrar é que os dois serviços estão ligados
para subir no boot:

```
ana@srv:~$ systemctl is-enabled loanbook caddy
generated
enabled
```

`generated` é como o systemd descreve uma unidade que o Quadlet escreveu; o `WantedBy=multi-user.target`
dela é o que a sobe no boot. `enabled` é o do Caddy. O seu srv é uma máquina de verdade, então reinicie-o
uma vez, com `multipass restart srv`, e peça `https://loans.lab/healthz` de novo antes de dar o deploy por
pronto.

Essas três verificações, saúde, uma pane e um boot, são a diferença entre *rodei num servidor* e *está
implantado*, e cada uma é um ou dois comandos. Ponha-as na seção de deploy do README, aula 16, e elas viram
parte da evidência.
