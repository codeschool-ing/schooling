---
title: Um alvo quebrado de propósito
version: 1
---

O target ganha o mesmo serviço e, depois, um defeito pequeno e realista: **um ponto e vírgula tirado** da
configuração do nginx, o tipo de erro de digitação que acontece com todo mundo que edita um arquivo à mão.
Depois, um snapshot de cada máquina:

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

O reinício falhou, e do client o target agora recusa conexões, enquanto o server ainda responde. Esse é o
chamado: *"o site no target caiu"*. O snapshot chamado `broken` guarda o target exatamente neste estado, e
os snapshots `clean` do client e do server guardam o resto do laboratório como deve ser.

Quebrar uma máquina de propósito é como laboratórios de suporte são montados. **Escolha defeitos que
acontecem na vida real, um de cada vez**, e anote na descrição do snapshot o que você quebrou, para daqui a
um mês o laboratório ainda saber a resposta mesmo que você não saiba.
