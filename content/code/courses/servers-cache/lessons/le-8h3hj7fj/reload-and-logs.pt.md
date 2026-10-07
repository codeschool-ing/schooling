---
title: Logs, reloads e a configuração quebrada
version: 1
---

Toda requisição deixa uma linha num log de acesso, e cada um dos três servidores escreveu uma para o
benchmark da seção anterior:

```
ana@web:~$ tail -n 2 /var/log/nginx/ipelivros.access.log
127.0.0.1 - - [07/Oct/2026:00:11:23 -0300] "GET /css/site.css HTTP/1.0" 200 237 "-" "ApacheBench/2.3"
127.0.0.1 - - [07/Oct/2026:00:11:23 -0300] "GET /css/site.css HTTP/1.0" 200 237 "-" "ApacheBench/2.3"
ana@web:~$ sudo tail -n 1 /var/log/apache2/ipelivros-access.log
127.0.0.1 - - [07/Oct/2026:00:11:24 -0300] "GET /css/site.css HTTP/1.0" 200 506 "-" "ApacheBench/2.3"
ana@web:~$ sudo tail -n 1 /var/log/caddy/ipelivros.access.log | jq -c '{status, uri: .request.uri, size, duration}'
{"status":200,"uri":"/css/site.css","size":237,"duration":0.00247275}
```

As duas primeiras estão no **formato combinado** (*combined log format*), mais antigo que qualquer um
desses servidores e ainda o mais comum: o endereço do cliente, a hora, a linha da requisição, o
status, o tamanho da resposta, a página de origem e o nome que o cliente dá a si mesmo. O Nginx contou
237 bytes, o arquivo; o Apache contou 506, o arquivo mais os cabeçalhos. A mesma requisição, dois
significados para uma coluna, e o tipo de detalhe que importa no dia em que você soma dois logs. O
JSON do Caddy dá nome a cada campo, e a `duration` dele é em segundos: 0,00247, dois milissegundos e
meio para a última requisição de um benchmark que mantinha cinquenta em andamento ao mesmo tempo.

Uma requisição que falha deixa também uma linha no **log de erros**, e o log de erros diz por quê:

```
ana@web:~$ curl -s -o /dev/null http://ipelivros.example/nothing-here; tail -n 1 /var/log/nginx/ipelivros.error.log
2026/10/07 00:11:24 [error] 285#285: *2035 open() "/var/www/ipe/nothing-here" failed (2: No such file or directory), client: 127.0.0.1, server: ipelivros.example, request: "GET /nothing-here HTTP/1.1", host: "ipelivros.example"
```

## Reload, e o que ele não interrompe

Mudar uma configuração significa mandar o servidor lê-la de novo. Há dois jeitos, e a diferença
entre eles é a coisa mais útil desta seção.

```
ana@web:~$ ps -o pid,cmd --ppid $(cat /run/nginx.pid) -p $(cat /run/nginx.pid)
    PID CMD
    227 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
    283 nginx: worker process
    284 nginx: worker process
    285 nginx: worker process
    287 nginx: worker process
ana@web:~$ sudo systemctl reload nginx; sleep 1; ps -o pid,cmd --ppid $(cat /run/nginx.pid) -p $(cat /run/nginx.pid)
    PID CMD
    227 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
    609 nginx: worker process
    610 nginx: worker process
    611 nginx: worker process
    612 nginx: worker process
```

**Depois de um reload, o mestre é o mesmo processo e os workers são novos.** O mestre lê a
configuração nova, sobe workers que a usam e manda os antigos terminarem as requisições que estão
atendendo e saírem. Nenhuma conexão é recusada em momento algum. Um `restart` para tudo e sobe de
novo, e o que chega no meio é recusado.

Agora quebre a configuração de propósito, com um erro de digitação que uma pessoa cansada comete:

```
ana@web:~$ sudo sed -i 's/    root /    rooot /' /etc/nginx/sites-available/ipelivros
ana@web:~$ sudo nginx -t
2026/10/07 00:11:25 [emerg] 625#625: unknown directive "rooot" in /etc/nginx/sites-enabled/ipelivros:5
nginx: configuration file /etc/nginx/nginx.conf test failed
ana@web:~$ sudo systemctl reload nginx; echo "exit $?"
Job for nginx.service failed.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
exit 1
ana@web:~$ sudo journalctl -u nginx --no-pager -o cat | tail -n 3
2026/10/07 00:11:25 [emerg] 631#631: unknown directive "rooot" in /etc/nginx/sites-enabled/ipelivros:5
nginx.service: Control process exited, code=exited, status=1/FAILURE
Reload failed for nginx.service - A high performance web server and a reverse proxy server.
```

**O teste pegou, o reload recusou, e o site nunca parou.** O `systemctl reload` pede ao Nginx que
confira a configuração nova antes de sinalizar qualquer coisa, a conferência falhou, e o mestre
continuou rodando com a configuração que já tinha. O site respondeu `200` o tempo todo. Um restart com
o mesmo arquivo quebrado faz algo bem diferente:

```
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' http://ipelivros.example/
200
ana@web:~$ sudo systemctl restart nginx; echo "exit $?"
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
exit 1
```

Um restart para o servidor em execução primeiro e depois não consegue subir o novo, e **o site
cai**: `000` é o `curl` dizendo que nada respondeu. Esse é o argumento inteiro a favor do hábito:
**teste, depois recarregue; nunca use restart para aplicar uma mudança de configuração.** Restart é
para atualizar o próprio binário do servidor, e mesmo assim só depois de o `nginx -t` dizer que a
configuração está boa.

Corrigir o erro e subir traz o site de volta:

```
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' http://ipelivros.example/
000
ana@web:~$ sudo sed -i 's/    rooot /    root /' /etc/nginx/sites-available/ipelivros && sudo nginx -t && sudo systemctl start nginx
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

O Apache e o Caddy têm os mesmos dois verbos. `systemctl reload apache2` é um restart gracioso, que
deixa as requisições em andamento terminarem, e `systemctl reload caddy` carrega o Caddyfile novo sem
derrubar conexões. Os dois recusam uma configuração que não passa na leitura, desde que você use
reload e não restart.
