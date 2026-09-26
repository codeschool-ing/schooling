---
title: O servidor que funciona
version: 1
---

O servidor ganha um servidor web que funciona, e uma página que diz isso:

```
ana@server:~$ sudo systemctl enable --now nginx 2>&1 | tail -1; echo "lab server: ok" | sudo tee /var/www/html/index.html
Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service → /usr/lib/systemd/system/nginx.service.
lab server: ok
ana@client:~$ curl -sS http://server/
lab server: ok
```

O `systemctl enable --now` faz duas coisas de uma vez: liga o nginx agora e o liga a cada boot. A página é
uma linha, escrita com `tee` porque a pasta é do root. E o client a buscou pelo nome. Esse é o **estado
bom conhecido** do laboratório: um pedido do client a um servidor, respondido. Todo defeito no target é
medido contra ele.
