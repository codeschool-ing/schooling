---
title: Chamado: "o site caiu"
version: 1
---

O último chamado sobe a escada inteira:

```
ana@laptop:~$ curl -sS https://www.example.com/
curl: (7) Failed to connect to www.example.com port 443 after 1 ms: Couldn't connect to server
ana@www:~$ sudo ss -tlnp | grep -E ":(80|443) " || echo "nothing on 80 or 443"
nothing on 80 or 443
ana@www:~$ sudo nginx
ana@laptop:~$ curl -sS -o /dev/null -w "%{http_code}\n" https://www.example.com/
200
```

`www.example.com` resolveu, já que o curl citou o endereço que tentou, e a conexão foi recusada **depois
de 1 ms**: algo na outra ponta respondeu na hora, e a resposta foi não. É o degrau 5. Uma recusa vem da
própria máquina, sem nada escutando na porta (aula 3); um firewall que descarta teria deixado o curl
esperando.

No servidor, o `ss -tlnp` não tem nada na 80 nem na 443, então o servidor web não está rodando.
Iniciá-lo, aqui `sudo nginx` e num servidor normal `sudo systemctl start nginx`, e perguntar de novo deu
`200`. **Recusada aponta para o servidor, tempo esgotado aponta para o caminho**, e essa diferença decide
de quem é o chamado. A pergunta seguinte é por que o serviço parou, e isso está no log dele, onde a aula
17 de operating-systems olhou.
