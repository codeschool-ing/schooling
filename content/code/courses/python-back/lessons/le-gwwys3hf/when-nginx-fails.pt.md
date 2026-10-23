---
title: Quando o nginx falha
version: 1
---

Três falhas, cada uma com a mensagem que a nomeia.

## 502 Bad Gateway

Pare a aplicação atrás do nginx:

```
ana@vm:~/agenda$ sudo systemctl stop agenda
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" --cacert /etc/ssl/agenda/agenda.crt --resolve agenda.example.org:443:127.0.0.1 https://agenda.example.org/events/
502
ana@vm:~/agenda$ sudo tail -1 /var/log/nginx/error.log | cut -c1-160
2026/10/23 00:56:00 [error] 1100#1100: *17 connect() failed (111: Connection refused) while connecting to upstream, client: 127.0.0.1, server: agenda.example.or
ana@vm:~/agenda$ sudo systemctl start agenda
```

**502** é o nginx dizendo que ele está bem e o que ele repassa não está. O log de erros diz qual destino
e por quê: `Connection refused` em `127.0.0.1:8000`, nada escutando. O **`systemctl status agenda`** e o
**`journalctl -u agenda`** são os próximos lugares para olhar. Um **504** no lugar quer dizer que a
aplicação aceitou a conexão e não respondeu a tempo.

## Uma configuração que não passa

Um ponto e vírgula faltando depois do `proxy_pass`:

```
ana@vm:~/agenda$ sudo nginx -t
2026/10/23 00:56:00 [emerg] 1195#1195: invalid number of arguments in "proxy_pass" directive in /etc/nginx/sites-enabled/agenda:21
nginx: configuration file /etc/nginx/nginx.conf test failed
```

**O `nginx -t` nomeia o arquivo e a linha**, e um reload depois de um teste que falhou teria mantido a
configuração antiga rodando. É por isso que todo reload desta aula veio depois de um teste.

## Um redirecionamento que não acaba

Tire o `proxy_set_header X-Forwarded-Proto $scheme;` do `location /` do site, e peça por HTTPS:

```
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" --cacert /etc/ssl/agenda/agenda.crt --resolve agenda.example.org:443:127.0.0.1 https://agenda.example.org/events/
301 https://agenda.example.org/events/
```

**Um 301 para o endereço que foi pedido.** O Django não viu `https` no cabeçalho, concluiu que a
requisição era HTTP simples, e a redirecionou para HTTPS, onde a mesma coisa acontece de novo; um
navegador desiste com *redirecionamentos demais*. Com a linha de volta:

```
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" --cacert /etc/ssl/agenda/agenda.crt --resolve agenda.example.org:443:127.0.0.1 https://agenda.example.org/events/
200
```

## Outras que você vai encontrar

| sintoma | causa | conserto |
|---|---|---|
| `403 Forbidden` em `/static/`, `Permission denied` no log de erros | o diretório estático está dentro de um diretório pessoal em que o `www-data` não entra | junte em `/var/www`, como esta aula fez |
| `Address already in use` quando o nginx sobe | outro servidor ocupa a porta 80 ou 443 | o `sudo ss -ltnp` o nomeia |
| `400 Bad Request` do Django | `Host` fora do `ALLOWED_HOSTS`, muitas vezes por falta do `proxy_set_header Host` | a configuração da aula 15, e o cabeçalho |

Essas três não foram produzidas para este curso; as mensagens são as do nginx e do Django para essas
causas.
