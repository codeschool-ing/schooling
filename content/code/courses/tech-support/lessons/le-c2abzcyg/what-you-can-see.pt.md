---
title: O que o nível 1 consegue ver
version: 1
---

No `srv1`, com acesso de leitura, a técnica segue o pedido um passo para trás de cada vez:

```
ana@srv1:~$ sudo tail -n 1 /var/log/nginx/error.log
2026/09/26 01:09:46 [error] 1082#1082: *1 connect() failed (111: Connection refused) while connecting to upstream, client: 10.30.0.96, server: , request: "GET /sales/ HTTP/1.1", upstream: "http://127.0.0.1:9000/", host: "srv1"
ana@srv1:~$ ss -tln | grep -c ":9000 "; systemctl is-active sales-api
0
failed
ana@srv1:~$ sudo journalctl -u sales-api --no-pager -o cat | grep -m1 -E "PermissionError"
PermissionError: [Errno 13] Permission denied: '/etc/sales/api.conf'
ana@srv1:~$ ls -l /etc/sales/api.conf; systemctl show -p User sales-api
-rw------- 1 root root 9 Sep 26 01:09 /etc/sales/api.conf
User=sales
```

- O log de erros do nginx: ele tentou passar o pedido para `127.0.0.1:9000` e foi **recusado**: nada
  escuta ali.
- O `ss` confirma **0** processos escutando na porta 9000, e o serviço que deveria estar ali, o
  `sales-api`, está **failed**.
- O journal dele diz por quê: `PermissionError`, **ele não consegue ler o próprio arquivo de
  configuração**, `/etc/sales/api.conf`.
- E o arquivo explica o erro: pertence ao `root` com modo `600`, legível só pelo root, enquanto o serviço
  roda como o usuário `sales`.

Isso é uma causa, achada em quatro comandos, por alguém que não é dono do sistema. A próxima seção é sobre
o que fazer com ela.
