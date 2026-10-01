---
title: Toda requisição verificada, e registrada
version: 1
---

O log de acesso (*access log*) da aplicação agora responde a uma pergunta que os endereços sozinhos
nunca conseguiram responder:

```
root@app:~# cat /var/log/lab/nginx-access.log
192.168.10.20 - NONE /admin/ 400
192.0.2.80 CN=www-client SUCCESS /health 200
192.0.2.80 CN=www-client SUCCESS /health 200
```

Três requisições, três linhas. A tentativa do `laptop`, sem certificado: `NONE`, recusada com `400`. As
duas do proxy, uma feita à mão e outra em nome do cliente: `CN=www-client`, `SUCCESS`, `200`. **Toda
decisão carrega a identidade sobre a qual foi tomada.** Uma investigação que parte deste log começa
por *quem*, e não por *qual endereço, e quem estava com ele naquele momento*.

## Identidade que expira

Uma decisão Zero Trust é tomada por requisição, e por isso pode levar em conta coisas que mudam: o
horário, o estado do dispositivo, a validade da credencial. A última já vem embutida nos certificados.
O proxy ainda guarda um certificado de cliente antigo, de antes da renovação:

```
root@www:~# openssl x509 -in tls/www-client-old.crt -noout -subject -enddate
subject=CN = www-client-old
notAfter=Aug 31 00:00:00 2026 GMT
```

Ele expirou em 31 de agosto de 2026. Apresentado hoje:

```
root@www:~# curl -sS --resolve app.corp.example.com:8443:192.168.20.10 --cert tls/www-client-old.crt --key tls/www-client-old.key https://app.corp.example.com:8443/health | grep -o "<title>.*</title>"
<title>400 The SSL certificate error</title>
root@app:~# tail -1 /var/log/lab/nginx-access.log
192.0.2.80 CN=www-client-old FAILED:certificate has expired /health 400
```

**Recusado**, e o log diz por quê: `FAILED:certificate has expired`, com o sujeito que o apresentou.
Nada precisou ser revogado e ninguém precisou se lembrar de nada; a credencial trazia a própria data
de fim, e a verificação a leu nesta requisição. É essa a propriedade que a **verificação contínua**
(*continuous verification*), assunto da aula 21, generaliza: toda requisição é julgada pelo que é
verdade agora, e não pelo que era verdade quando a sessão começou.
