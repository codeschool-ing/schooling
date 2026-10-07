---
title: Tempos-limite, e os três erros de gateway
version: 1
---

A loja tem um endpoint que demora o quanto mandarem, e cinco segundos passam sem problema por padrão:

```
ana@web:~$ time curl -s -o /dev/null -w '%{http_code}\n' 'http://ipelivros.example/api/slow?s=5'
200

real	0m5.008s
user	0m0.000s
sys	0m0.007s
```

O Nginx espera até sessenta segundos para a aplicação começar a responder, que é o padrão do
`proxy_read_timeout`. Sessenta segundos é muito mais do que qualquer pessoa espera por uma página, e
uma requisição que demora isso segura uma conexão, a atenção de um worker e uma thread da aplicação
por um minuto. Baixe para três segundos, só para a API, e pergunte de novo:

```
ana@web:~$ sudo sed -i 's|        proxy_pass http://shop;|        proxy_pass http://shop;\n        proxy_read_timeout 3s;|' /etc/nginx/sites-available/ipelivros && grep -A2 'location /api/' /etc/nginx/sites-available/ipelivros
    location /api/ {
        proxy_pass http://shop;
        proxy_read_timeout 3s;
ana@web:~$ time curl -s -o /dev/null -w '%{http_code}\n' 'http://ipelivros.example/api/slow?s=5'
504

real	0m6.016s
user	0m0.003s
sys	0m0.006s
```

`504 Gateway Timeout`, como esperado. **Mas levou seis segundos, não três**, e o log diz por quê:

```
ana@web:~$ tail -n 2 /var/log/nginx/ipelivros.error.log | sed -E 's/ \[error\].*(upstream timed out).*(upstream: "[^"]*").*/ \1, \2/'
2026/10/07 00:26:27 upstream timed out, upstream: "http://127.0.0.1:8001/api/slow?s=5"
2026/10/07 00:26:30 upstream timed out, upstream: "http://127.0.0.1:8002/api/slow?s=5"
```

O Nginx deu três segundos ao primeiro membro, desistiu e **tentou a requisição de novo no outro
membro**, que levou mais três: o mesmo `proxy_next_upstream` que salvou todas as requisições da seção
anterior. Para um membro morto isso é exatamente o certo. Para um membro só lento, é o dobro da espera
e o dobro da carga, mandados a uma aplicação que já está sofrendo, e cada membro de um grupo de dez
teria a sua vez. Duas configurações limitam isso:

```conf
proxy_next_upstream_tries 2;      # at most this many members per request
proxy_next_upstream_timeout 5s;   # and at most this long, all attempts together
```

O Nginx nunca repete uma requisição que não é **idempotente**, um `POST` por exemplo, a não ser que
mandem com `non_idempotent`, porque enviar um pagamento duas vezes é pior do que falhar uma.

## 502, 503 e 504

Três códigos de status dizem "o servidor da frente está bem e o de trás não", e querem dizer coisas
diferentes:

| código | o que o Nginx está dizendo | onde olhar |
|---|---|---|
| `502 Bad Gateway` | a aplicação não respondeu direito: recusou a conexão, fechou-a ou mandou algo que não é HTTP | ela está rodando? os logs dela |
| `503 Service Unavailable` | ninguém está disponível de propósito: um limite foi atingido ou há manutenção | os limites do Nginx (aula 4) |
| `504 Gateway Timeout` | a aplicação aceitou a requisição e não respondeu a tempo | o que a aplicação está esperando |

Os três tempos-limite que produzem um `504` ou um `502` medem coisas diferentes:
`proxy_connect_timeout` é quanto esperar pela conexão em si (60 segundos por padrão, e numa rede
local raramente é preciso mais que um), `proxy_read_timeout` o intervalo entre duas leituras da
resposta, e `proxy_send_timeout` o intervalo entre duas escritas da requisição. Nenhum deles limita o
tempo total de uma requisição; uma resposta que pinga um byte a cada cinquenta segundos nunca estoura.

**Um tempo-limite na frente deve ser menor que a paciência de quem está atrás do cliente**, e maior
que a requisição mais lenta que a aplicação deve atender. A segunda metade é a que se esquece: um
relatório que leva quarenta segundos para ser montado precisa do próprio `location`, com o próprio
tempo-limite, mais longo.
