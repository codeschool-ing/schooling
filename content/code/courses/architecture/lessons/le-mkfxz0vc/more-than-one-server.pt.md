---
title: Mais de um servidor
version: 1
---

Toda técnica até aqui foi experimentada contra a instância `a` sozinha. Uma loja de verdade roda várias
instâncias atrás de um balanceador, e uma conexão longa cai numa delas. Conecte o cliente WebSocket à
instância `b`, e faça o armazém publicar na instância `a`:

```
ana@vm:~/lab/live$ $W ws://live-b:8000/ws 3 & sleep 1.5; curl -s -X POST localhost:8001/publish -d "o-2 paid"; wait
b: received 'hello'
a: published
```

O cliente disse olá para `b` e `b` respondeu. O evento foi para `a`, e `a` avisou só os seus clientes; `b`
nunca soube dele, e a página do cliente nunca mudou. Nada falhou, então nada foi registrado. Com duas
instâncias metade dos clientes perde metade dos eventos; com dez, nove em cada dez.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Duas instâncias do serviço de status de pedidos atrás de um balanceador. O WebSocket de um cliente está conectado à instância b. O armazém publica um evento na instância a. Sem backplane, o evento fica em a e o cliente não ouve nada. Com backplane, a publica no Redis, o Redis entrega para a e para b, e b o empurra ao cliente.\"><defs><marker id=\"l18-backplane-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l18-backplane-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"40\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">armazém</text><rect x=\"260\" y=\"40\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"335\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">instância a</text><rect x=\"260\" y=\"170\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"335\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">instância b</text><rect x=\"540\" y=\"170\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cliente</text><rect x=\"540\" y=\"40\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Redis</text><path d=\"M182 65 L258 65\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-backplane-ah-wire)\"></path><text x=\"220\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">publicar</text><path d=\"M538 183 L412 183\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"475\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">WebSocket</text><path d=\"M412 65 L538 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-backplane-ah-phosphor)\"></path><path d=\"M560 92 L380 168\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-backplane-ah-phosphor)\"></path><path d=\"M412 208 L538 208\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-backplane-ah-phosphor)\"></path><text x=\"540\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">para toda instância</text><text x=\"335\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">sem: para aqui</text><path d=\"M335 92 L335 116\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "Com mais de uma instância, o evento e a conexão podem estar em servidores diferentes. Um backplane entrega todo evento a toda instância.", "same": ["Redis", "WebSocket"]}
```

A correção é um **backplane**: um canal de publicação e assinatura que toda instância escuta. Uma instância
que recebe um evento não o acrescenta ela mesma; ela o publica no backplane, e toda instância, ela
inclusive, o recebe e o empurra para os seus clientes. O pub/sub do Redis é a escolha de costume, e o
serviço do laboratório já o tem. Reinicie as duas instâncias com ele ligado, e repita:

```
ana@vm:~/lab/live$ BACKPLANE=redis://redis:6379 docker compose up -d
 Container live-redis-1 Running 
 Container live-live-a-1 Recreate 
 Container live-live-b-1 Recreate 
 Container live-live-a-1 Recreated 
 Container live-live-b-1 Recreated 
 Container live-live-b-1 Starting 
 Container live-live-a-1 Starting 
 Container live-live-b-1 Started 
 Container live-live-a-1 Started 
ana@vm:~/lab/live$ $W ws://live-b:8000/ws 3 & sleep 1.5; curl -s -X POST localhost:8001/publish -d "o-2 paid"; wait
b: received 'hello'
a: published
b: o-2 paid
```

`b` empurrou o evento que `a` recebeu. É o que o backplane Redis do SignalR e o adaptador Redis do
Socket.IO fazem. Os brokers da aula 6 também serviriam.

Conexões longas mudam algumas outras coisas na operação de um serviço:

- **Cada conexão custa memória e um descritor de arquivo**, enquanto o cliente mantiver a página aberta. Um
  servidor assíncrono, como o do laboratório, segura dezenas de milhares por instância; uma thread por
  conexão não seguraria.
- **Um deploy termina toda conexão.** As instâncias deveriam drenar: parar de aceitar conexões novas, pedir
  aos clientes que reconectem em outro lugar, e só então parar, senão um release vira uma tempestade de
  reconexões, a tempestade de retries da aula 11 em outro protocolo.
- **O balanceamento fica desigual.** Um balanceador espalha conexões novas, mas conexões vivem horas, então
  uma instância nova fica vazia enquanto as antigas continuam cheias até os clientes reconectarem.
