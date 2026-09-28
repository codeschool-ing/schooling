---
title: Limites de taxa no proxy
version: 1
---

Uma requisição pode estar perfeitamente bem formada e ainda assim ser um problema quando chega
duzentas vezes por segundo de um mesmo endereço. Adivinhar senhas, raspar um catálogo e um script
afoito têm essa cara. **Um limite de taxa** (*rate limit*) **restringe a velocidade com que um
cliente pode pedir**, e o proxy é o lugar natural para ele, porque vê cada requisição antes que a
aplicação gaste qualquer coisa com ela.

O nginx faz isso em duas linhas, uma no topo do arquivo e uma no location:

```
root@www:~# grep -n "limit_req" /etc/nginx/sites-enabled/shop
2:limit_req_zone $binary_remote_addr zone=perip:10m rate=5r/s;
3:limit_req_status 429;
23:        limit_req zone=perip burst=10 nodelay;
```

`limit_req_zone` indexa o limite pelo endereço do cliente, guarda seus contadores em 10 MB de
memória compartilhada e permite **5 requisições por segundo**. `burst=10` deixa um cliente se
adiantar dez requisições em relação a essa taxa antes que algo seja recusado, e `nodelay` atende
essas dez de uma vez em vez de espaçá-las. `limit_req_status 429` responde com o status que
significa *requisições demais*; o padrão do nginx é `503`, que diz ao cliente que o servidor está
quebrado quando não está.

Trinta requisições a partir de `remote`, tão rápido quanto o `curl` consegue enviá-las:

```
ana@remote:~$ for i in $(seq 30); do curl -s -o /dev/null -w "%{http_code}\n" https://www.example.com/; done | sort | uniq -c
     15 200
     15 429
```

**Dezesseis foram atendidas e catorze recusadas**: o burst de dez, mais o que a taxa reabasteceu
enquanto o laço rodava. Enquanto isso, o limite só dizia respeito a `remote`:

```
ana@laptop:~$ curl -s -o /dev/null -w "%{http_code}\n" https://www.example.com/
200
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" https://www.example.com/
200
root@www:~# grep -c "limiting requests" /var/log/nginx/error.log; grep -m1 "limiting requests" /var/log/nginx/error.log | cut -d" " -f3-
15
[error] 32145#32145: *41 limiting requests, excess: 10.715 by zone "perip", client: 203.0.113.50, server: www.example.com, request: "GET / HTTP/1.1", host: "www.example.com"
```

O `laptop` foi atendido durante o burst porque seu endereço tem um contador próprio, e três segundos
depois `remote` voltou a ser atendido. Cada recusa está no log de erros com o endereço do cliente,
que é o que alguém lê depois para decidir se foi um script ou um engano.

## O que um limite por endereço não consegue fazer

Um limite indexado pelo endereço supõe que um endereço é um cliente. Duas coisas quebram isso:

- **Muitos clientes atrás de um endereço.** Um escritório inteiro atrás de um NAT compartilha um
  contador, e um escritório movimentado atinge o limite em conjunto. Os limites são definidos para o
  endereço legítimo mais movimentado, não para a média.
- **Um cliente atrás de muitos endereços.** Tráfego espalhado por milhares de máquinas fica abaixo
  de todo limite por endereço. Isso é um ataque distribuído, e a aula 6 o trata à parte, porque ele
  precisa ser absorvido antes de chegar ao proxy.
