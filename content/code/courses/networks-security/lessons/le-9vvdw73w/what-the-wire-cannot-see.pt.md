---
title: O que o fio não vê
version: 1
---

O sensor de rede na DMZ vigia o caminho de administração pedido de fora, como na aula 14. Um
desconhecido o pede duas vezes: uma por HTTP puro, uma por HTTPS:

```
ana@remote:~$ curl -s http://www.example.com/admin/; curl -s https://www.example.com/admin/
admin console
admin console
```

As duas requisições foram atendidas. Os alertas do sensor:

```
root@sensor:~# jq -c "select(.event_type==\"alert\") | [.alert.signature_id, .dest_port, .http.url]" /var/log/suricata/eve.json
[1000101,80,"/admin/"]
```

**Um alerta, para a porta 80.** A requisição HTTPS não gerou nenhum, porque a regra procura um caminho
e o caminho estava cifrado. O sensor registrou a conexão TLS, mas tudo o que conseguiu ler foi o nome:

```
root@sensor:~# jq -c "select(.event_type==\"tls\") | [.src_ip, .dest_port, .tls.sni]" /var/log/suricata/eve.json
["203.0.113.50",443,"www.example.com"]
```

Um cliente na internet, uma conexão TLS para `www.example.com`, e nada sobre o que foi pedido. A
máquina que terminou o TLS sabe exatamente o que foi pedido, e anotou:

```
root@www:~# grep "/admin/" /var/log/nginx/access.log | cut -d" " -f1,4,6-9
203.0.113.50 [28/Sep/2026:18:06:19 "GET /admin/ HTTP/1.1" 200
203.0.113.50 [28/Sep/2026:18:06:19 "GET /admin/ HTTP/1.1" 200
```

**As duas requisições, as duas para `/admin/`, as duas respondidas com `200`.** Nada disso é defeito
do sensor; o TLS está fazendo o seu trabalho. Significa que a detecção de qualquer coisa dentro do
HTTPS tem de acontecer onde o TLS termina: nos logs do proxy, num WAF ali (aula 3), ou num agente
naquele host mandando esses logs para onde alguém os leia. A maior parte do tráfego da web é cifrada,
então a maior parte da detecção na web foi para os hosts, e o trabalho do sensor de rede se deslocou
para o que ele ainda vê bem: quem falou com quem, quando, quanto e em qual protocolo.
