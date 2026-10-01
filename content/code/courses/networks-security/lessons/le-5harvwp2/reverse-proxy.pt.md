---
title: Um proxy reverso fica na frente
version: 1
---

A aplicação da loja roda em `app`, no segmento de servidores, e **ninguém na internet fala com
ela**. Todos falam com `www`, na DMZ, que recebe cada requisição e faz uma requisição própria a
`app` em nome deles. Isso é um **proxy reverso** (*reverse proxy*): um servidor que responde por
outros servidores, a imagem espelhada do proxy direto que uma empresa põe entre a equipe e a web.

De `remote`, um desconhecido na internet, a loja responde e a aplicação não:

```
ana@remote:~$ curl -s https://www.example.com/
orders service: ok
ana@remote:~$ curl -s -m3 http://192.168.20.10:8080/; echo "exit $?"
exit 28
```

As duas máquinas registraram a requisição, e cada uma viu um cliente diferente:

```
root@app:~# tail -1 /var/log/lab/app.log
192.0.2.80 - - [28/Sep/2026 15:23:48] "GET / HTTP/1.0" 200 -
root@www:~# tail -1 /var/log/nginx/access.log
203.0.113.50 - - [28/Sep/2026:15:23:48 -0300] "GET / HTTP/1.1" 200 19 "-" "curl/8.5.0"
```

`app` viu `192.0.2.80`, o proxy. **A aplicação nunca trocou um pacote com a internet**, e a regra
do firewall que deixa qualquer coisa alcançá-la nomeia uma única origem, o proxy, em uma única
porta. O proxy registrou o cliente real, `203.0.113.50`, e o repassa no cabeçalho
`X-Forwarded-For`, porque uma aplicação que precisa do endereço do cliente não tem outro jeito de
descobri-lo.

Esse cabeçalho só é tão confiável quanto a máquina que o escreveu. `app` pode acreditar nele porque
o firewall garante que só `www` consegue alcançá-la; uma aplicação alcançável diretamente estaria
acreditando no que quer que um cliente resolvesse enviar.

## O que o proxy está configurado para fazer

```
root@www:~# cat /etc/nginx/sites-enabled/shop | sed -n "/listen 192.0.2.80:443/,/^}/p"
    listen 192.0.2.80:443 ssl;
    server_name www.example.com;
    ssl_certificate     /etc/ssl/private/www.crt;
    ssl_certificate_key /etc/ssl/private/www.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    location / {
        proxy_pass http://192.168.20.10:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
    }
}
```

O proxy **termina o TLS**: o certificado e sua chave privada ficam em `www`, a conexão cifrada
termina ali, e a requisição segue até `app` como HTTP em claro. É isso que permite ao proxy ler e
julgar cada requisição, e o resto desta aula depende disso. Significa também que o trecho da DMZ
até o segmento de servidores carrega tráfego legível, o que só é aceitável porque esse caminho
atravessa o firewall e mais nada; a aula 20 o cifra mesmo assim.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"O caminho de um pedido. remote, na internet, abre HTTPS para o www na DMZ; a conexão cifrada termina no www, que guarda o certificado. O www então faz o próprio pedido HTTP puro para app na porta 8080, e o firewall permite essa conexão a partir do www e de nada mais. app só vê o endereço do www; o www registra o de remote e o repassa em X-Forwarded-For.\"><defs><marker id=\"rp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"rp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">remote</text><text x=\"30\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">203.0.113.50</text><rect x=\"290\" y=\"70\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www</text><text x=\"300\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">guarda o certificado</text><rect x=\"570\" y=\"70\" width=\"130\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app</text><text x=\"580\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.20.10</text><path d=\"M160 93 L290 93\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#rp-ah-phosphor)\"></path><text x=\"225\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">HTTPS :443</text><text x=\"225\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cifrado</text><path d=\"M440 93 L570 93\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#rp-ah-paper-dim)\"></path><text x=\"505\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">HTTP :8080</text><text x=\"505\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só a partir do www</text><rect x=\"10\" y=\"40\" width=\"160\" height=\"90\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"18\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">internet</text><rect x=\"280\" y=\"40\" width=\"170\" height=\"90\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"288\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">DMZ</text><rect x=\"560\" y=\"40\" width=\"150\" height=\"90\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"568\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">servidores</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o www registra: 203.0.113.50</text><text x=\"570\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">app registra: 192.0.2.80</text><text x=\"290\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">X-Forwarded-For: 203.0.113.50</text></svg>", "caption": "Duas conexões, não uma. A primeira é cifrada e termina no proxy; a segunda começa ali.", "same": ["DMZ", "internet"]}
```

Pôr uma máquina na frente da aplicação compra várias coisas de uma vez:

| o proxy | o que ele dá |
|---|---|
| é o único endereço que a internet vê | a máquina da aplicação, sua porta e seu software ficam privados |
| termina o TLS | um lugar guarda o certificado; um lugar é atualizado quando o TLS muda |
| lê cada requisição antes da aplicação | um lugar para recusar o que a aplicação nunca deveria receber |
| fica na DMZ | se for comprometido, o atacante está na DMZ, e a aula 4 faz dela um lugar pequeno |
