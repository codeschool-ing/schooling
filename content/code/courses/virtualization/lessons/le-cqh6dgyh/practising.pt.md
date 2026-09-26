---
title: Praticando, e começando de novo
version: 1
---

Agora o exercício, do jeito que um técnico trabalharia. Primeiro, o que o serviço está fazendo?

```
ana@target:~$ systemctl is-active nginx; sudo nginx -t
failed
2026/09/25 22:46:39 [emerg] 1132#1132: invalid parameter "listen" in /etc/nginx/sites-enabled/default:23
nginx: configuration file /etc/nginx/nginx.conf test failed
ana@target:~$ sudo journalctl -u nginx --no-pager | grep -m1 -i emerg
Sep 25 22:46:22 target nginx[1090]: 2026/09/25 22:46:22 [emerg] 1090#1090: invalid parameter "listen" in /etc/nginx/sites-enabled/default:23
```

O `is-active` diz `failed`. O `nginx -t` confere a configuração sem ligar nada, e nomeia o defeito: um
parâmetro inválido na **linha 23 de `/etc/nginx/sites-enabled/default`**. O journal diz a mesma coisa,
com a hora em que aconteceu pela primeira vez. Dois comandos, e o chamado tem uma causa.

O conserto devolve o ponto e vírgula, testa a configuração antes de reiniciar, e depois confere de onde o
usuário está:

```
ana@target:~$ sudo sed -i "s/listen 80 default_server$/listen 80 default_server;/" /etc/nginx/sites-enabled/default && sudo nginx -t && sudo systemctl restart nginx && systemctl is-active nginx
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
active
ana@client:~$ curl -sS -o /dev/null -w "%{http_code}\n" http://target/
200
```

`200` do client: consertado, e verificado do client, que é a única verificação que importa para o usuário.
Depois, a parte que faz disto um laboratório:

```
ana@host:~$ virsh snapshot-revert target broken
Domain snapshot broken reverted

ana@client:~$ curl -sS -m 5 http://target/
curl: (7) Failed to connect to target port 80 after 32 ms: Couldn't connect to server
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 150\" role=\"img\" aria-label=\"O ciclo de prática, em cinco passos em círculo. O target é salvo num snapshot chamado broken. O aluno acha o defeito, conserta, e confere do client que funciona. Então o target é revertido para broken, e a tentativa seguinte começa exatamente do mesmo defeito.\"><defs><marker id=\"lp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">snapshot broken</text><path d=\"M142 50 L156 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><rect x=\"158\" y=\"30\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"168\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">achar o defeito</text><path d=\"M280 50 L294 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><rect x=\"296\" y=\"30\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"306\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">consertar</text><path d=\"M418 50 L432 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><rect x=\"434\" y=\"30\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"444\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">conferir do client</text><path d=\"M556 50 L570 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><rect x=\"572\" y=\"30\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"582\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">reverter para broken</text><path d=\"M 632 72 C 632 130, 80 130, 80 74\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\" stroke-dasharray=\"4 3\"></path></svg>", "caption": "O snapshot é o que torna o exercício repetível: toda tentativa começa do mesmo defeito, e consertar nunca é trabalho perdido, porque desfazer o conserto é um comando.", "same": ["snapshot broken"]}
```

Uma reversão e o target está quebrado de novo, exatamente como antes, pronto para a próxima tentativa ou a
próxima pessoa. Um laboratório assim é como praticar um defeito até achá-lo ficar rápido, e como testar um
conserto de que você não tem certeza sem nada a perder.
