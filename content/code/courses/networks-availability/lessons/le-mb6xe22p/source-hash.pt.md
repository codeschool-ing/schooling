---
title: Hash do endereço de origem, e por que cinco clientes são poucos
version: 1
---

Algumas aplicações precisam que toda requisição de um cliente chegue ao mesmo servidor, um problema que a
próxima seção trata a fundo. O jeito mais antigo de conseguir isso sem ler a requisição é **fazer o hash do
endereço do cliente: o mesmo endereço sempre dá o mesmo número, então sempre escolhe o mesmo servidor**. O
HAProxy chama isso de `balance source`, e funciona com qualquer serviço TCP, não só HTTP. Cinco máquinas do
laboratório enviam quatro requisições cada:

```
ana@lb1:~$ sed -n "/^backend/,\$p" /etc/haproxy/haproxy.cfg
backend web
    balance source
    server web1 192.0.2.21:80
    server web2 192.0.2.22:80
    server web3 192.0.2.23:80
ana@laptop:~$ for i in $(seq 4); do curl -s http://www.example.com/; done
served by web1
served by web1
served by web1
served by web1
ana@remote:~$ for i in $(seq 4); do curl -s http://www.example.com/; done
served by web1
served by web1
served by web1
served by web1
ana@till:~$ for i in $(seq 4); do curl -s http://www.example.com/; done
served by web1
served by web1
served by web1
served by web1
ana@isp:~$ for i in $(seq 4); do curl -s http://www.example.com/; done
served by web1
served by web1
served by web1
served by web1
ana@ns:~$ for i in $(seq 4); do curl -s http://www.example.com/; done
served by web2
served by web2
served by web2
served by web2
```

Todo cliente ficou num servidor só, que é o que foi pedido. Mas **quatro dos cinco caíram em `web1`, um em
`web2` e nenhum em `web3`**. Não há nada quebrado. Um hash espalha os endereços por igual só quando eles são
muitos, do mesmo jeito que uma moeda dá cara mais ou menos metade das vezes em mil lançamentos e pode muito
bem dar cara quatro vezes em cinco. Com cinco clientes, um terço dos servidores parado é um resultado comum.

O laboratório também mostra o segundo motivo de um hash de origem balancear mal na vida real. `lb1` não vê
`192.168.10.20`, o endereço do próprio laptop: vê o endereço de onde a conexão chega, que para o laptop é o
público de `hq`, `203.0.113.2`, depois do NAT do escritório, a aula 11 de `networks-addressing`. Toda
máquina da matriz chega desse único endereço, então **um escritório inteiro atrás de NAT é um cliente só
para um hash de origem**, e vai todo para um servidor. O NAT de grande escala de uma operadora móvel faz o
mesmo com milhares de celulares de uma vez.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 300\" role=\"img\" aria-label=\"Cinco clientes e o endereço que lb1 vê de cada um: laptop, 192.168.10.20, é visto como 203.0.113.2 depois do NAT em hq; remote, 192.168.1.50, como 198.51.100.77 depois do NAT em homegw; till, 192.168.20.30, como 198.51.100.2 depois do NAT em branch; isp como 192.0.2.1 e ns como 192.0.2.53, sem NAT. O hash manda os quatro primeiros para web1 e ns para web2. web3 não recebe nenhum.\"><defs><marker id=\"h19-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cliente</text><text x=\"250\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o endereço que lb1 vê</text><text x=\"560\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">servidor escolhido pelo hash</text><rect x=\"20\" y=\"30\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">laptop</text><text x=\"95.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.20</text><path d=\"M170 50 L248 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#h19-ah)\"></path><rect x=\"250\" y=\"34\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"315\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">203.0.113.2</text><text x=\"390\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">NAT em hq</text><path d=\"M480 50 C 520 50, 530 90, 578 90\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#h19-ah)\"></path><rect x=\"20\" y=\"80\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">remote</text><text x=\"95.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.1.50</text><path d=\"M170 100 L248 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#h19-ah)\"></path><rect x=\"250\" y=\"84\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"315\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">198.51.100.77</text><text x=\"390\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">NAT em homegw</text><path d=\"M480 100 C 520 100, 530 90, 578 90\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#h19-ah)\"></path><rect x=\"20\" y=\"130\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">till</text><text x=\"95.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.20.30</text><path d=\"M170 150 L248 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#h19-ah)\"></path><rect x=\"250\" y=\"134\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"315\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">198.51.100.2</text><text x=\"390\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">NAT em branch</text><path d=\"M480 150 C 520 150, 530 90, 578 90\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#h19-ah)\"></path><rect x=\"20\" y=\"180\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">isp</text><text x=\"95.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.1</text><path d=\"M170 200 L248 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#h19-ah)\"></path><rect x=\"250\" y=\"184\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"315\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">192.0.2.1</text><text x=\"390\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem NAT</text><path d=\"M480 200 C 520 200, 530 90, 578 90\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#h19-ah)\"></path><rect x=\"20\" y=\"230\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ns</text><text x=\"95.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.53</text><path d=\"M170 250 L248 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#h19-ah)\"></path><rect x=\"250\" y=\"234\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"315\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">192.0.2.53</text><text x=\"390\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem NAT</text><path d=\"M480 250 C 520 250, 530 170, 578 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#h19-ah)\"></path><rect x=\"580\" y=\"70\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"655.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web1</text><text x=\"655\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4 clientes</text><rect x=\"580\" y=\"150\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"655.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web2</text><text x=\"655\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 cliente</text><rect x=\"580\" y=\"230\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"655.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web3</text><text x=\"655\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nenhum</text></svg>", "caption": "A rodada com hash de origem, com os endereços que o balanceador realmente usa no hash: para três dos cinco, um endereço de NAT e não o da própria máquina. Toda máquina da matriz chegaria como 203.0.113.2."}
```

O hash tem mais uma fraqueza. O HAProxy divide o hash pelo peso total dos servidores e fica com o resto,
então acrescentar ou tirar um servidor muda o divisor, e a maioria dos clientes muda de servidor de uma vez.
O `hash-type consistent` é o jeito do HAProxy de mover só os clientes que precisam mudar, e não foi
executado aqui.

Um hash de origem se justifica para protocolos que o balanceador não consegue ler, e dentro de uma rede
onde cada cliente tem endereço próprio. **Para HTTP vindo da internet, a persistência pertence à
requisição**, que é onde fica um cookie.
