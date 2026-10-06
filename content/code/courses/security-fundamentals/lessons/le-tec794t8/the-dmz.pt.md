---
title: A DMZ
version: 1
---

A livraria tem um servidor que a internet inteira deve alcançar: `www`, que serve as páginas da loja
e o portal da equipe. Ela também tem um banco de dados, `db`, que ninguém na internet deveria
alcançar nunca, e um escritório com os notebooks da equipe.

Pôr o servidor público lá dentro com todo o resto significaria abrir um caminho da internet para a
rede confiável, e um servidor com quem todo mundo conversa é o servidor com mais chance de ser
comprometido. Pô-lo fora do firewall o deixaria desprotegido. **A resposta é uma terceira zona: a
DMZ.**

O nome vem da zona desmilitarizada entre dois países, uma faixa que não pertence a nenhum dos lados.
Numa rede, a **DMZ** é um segmento para os serviços que o lado de fora precisa alcançar, com um
firewall entre ela e a internet e outra fronteira entre ela e o lado de dentro. As regras dela dizem
três coisas:

1. **a internet pode alcançar a DMZ**, mas só os serviços que devem ser públicos;
2. **a DMZ pode alcançar o lado de dentro** só onde um serviço público precisa de algo específico, e
   só disso;
3. **a internet nunca alcança o lado de dentro diretamente.**

Aqui está o laboratório desenhado como zonas, que é como a rede da loja fica nesta aula:

```schooling-figure
{"svg": "<svg id=\"sf-zones\" viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O laboratório do curso desenhado como zonas. O firewall fw fica no meio com quatro pernas: eth0 para a internet, onde está outside; eth1 para a DMZ, onde está www; eth2 para o escritório, onde está laptop; eth3 para os servidores, onde está db. Três caminhos permitidos estão listados: 1, a internet para www na porta 80; 2, www para db na porta 5432; 3, o escritório para a internet e para www. Todo o resto é descartado.\"><rect x=\"20\" y=\"20\" width=\"220\" height=\"90\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"30\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">internet · 203.0.113.0/24</text><rect x=\"70\" y=\"56\" width=\"120\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"130.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">outside</text><rect x=\"480\" y=\"20\" width=\"220\" height=\"90\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"490\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">DMZ · 192.0.2.0/24</text><rect x=\"530\" y=\"56\" width=\"120\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www</text><rect x=\"20\" y=\"190\" width=\"220\" height=\"90\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"30\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">escritório · 192.168.10.0/24</text><rect x=\"70\" y=\"226\" width=\"120\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"130.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><rect x=\"480\" y=\"190\" width=\"220\" height=\"90\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"490\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">servidores · 192.168.20.0/24</text><rect x=\"530\" y=\"226\" width=\"120\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db</text><rect x=\"300\" y=\"130\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">fw</text><path d=\"M240 70 L300 140\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M480 70 L420 140\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M240 240 L300 160\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M480 240 L420 160\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><text x=\"262\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">eth0</text><text x=\"458\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">eth1</text><text x=\"262\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">eth2</text><text x=\"458\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">eth3</text><text x=\"360\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">1  internet → www:80</text><text x=\"360\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">2  www → db:5432</text><text x=\"360\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">3  escritório → internet, www</text><text x=\"360\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">todo o resto: descartado</text></svg>", "caption": "As zonas da loja, e os três caminhos que as regras desta aula permitem. O que não está listado é descartado por padrão.", "same": ["internet · 203.0.113.0/24", "DMZ · 192.0.2.0/24", "1  internet → www:80", "2  www → db:5432"]}
```

O valor da DMZ vem da segunda regra. Se o `www` for comprometido, o atacante está na DMZ, não lá
dentro, e de lá o firewall permite exatamente uma coisa: uma conexão à porta do banco. Nem o
escritório, nem os outros serviços do banco, nem a internet por outro caminho. O estrago que um
servidor público comprometido consegue fazer se limita ao que ele já tinha permissão de fazer.

Algumas redes montam a DMZ com um firewall de três pernas, como faz o laboratório; outras põem dois
firewalls em fila, um externo entre a internet e a DMZ e um interno entre a DMZ e o lado de dentro. A
segunda forma custa mais e, na linguagem da aula 4, são duas camadas em vez de uma, especialmente se
os dois firewalls forem de fabricantes diferentes. A aula 4 de `networks-security` monta as duas.

**O que vai numa DMZ:** tudo o que precisa responder à internet. Servidores web, o servidor de
e-mail que recebe mensagens, o DNS público, um gateway de VPN. **O que nunca vai numa DMZ:** os dados
que esses serviços usam. Os pedidos da loja moram no `db`, lá dentro; o servidor web na DMZ os pede
por uma porta permitida, e nunca guarda uma cópia.
