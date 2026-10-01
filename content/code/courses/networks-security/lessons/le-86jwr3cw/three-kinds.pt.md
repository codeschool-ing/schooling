---
title: Três tipos de negação, três lugares para contê-las
version: 1
---

Uma **negação de serviço** (denial of service) torna um serviço indisponível para quem tem direito
de usá-lo. Não é preciso roubar nada nem invadir nada: basta esgotar algo de que o serviço precisa.
Quando o tráfego vem de muitas máquinas ao mesmo tempo, em geral milhares de dispositivos
comprometidos, ela é **distribuída**, um DDoS.

O que se esgota decide o tipo de ataque, e o tipo decide onde ele pode ser contido:

| tipo | o que esgota | medido em | onde é absorvido |
|---|---|---|---|
| **volumétrico** | a banda do link que entra na rede | bits por segundo | antes de chegar: o provedor, um serviço de limpeza de tráfego, uma CDN |
| **de protocolo** | uma tabela num dispositivo: conexões semiabertas, entradas do conntrack | pacotes por segundo | o firewall e a pilha TCP do servidor |
| **de aplicação** | o trabalho da aplicação: páginas renderizadas, consultas executadas | requisições por segundo | o proxy, a aplicação, um cache |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O caminho do tráfego até a empresa, da esquerda para a direita: a rede do provedor, o link da empresa, o firewall, o proxy e a aplicação. Abaixo de cada um, o que ele consegue absorver. Uma enxurrada volumétrica tem de ser parada na rede do provedor, antes do link; um ataque de protocolo no firewall e nas pilhas TCP dos servidores; uma enxurrada de aplicação no proxy e na aplicação.\"><defs><marker id=\"dd-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"dd-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">provedor</text><rect x=\"170\" y=\"40\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">o link</text><rect x=\"320\" y=\"40\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"330\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fw</text><rect x=\"460\" y=\"40\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www</text><rect x=\"600\" y=\"40\" width=\"100\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app</text><path d=\"M130 55 L170 55\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dd-ah-paper-dim)\"></path><path d=\"M280 55 L320 55\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dd-ah-paper-dim)\"></path><path d=\"M430 55 L460 55\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dd-ah-paper-dim)\"></path><path d=\"M570 55 L600 55\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dd-ah-paper-dim)\"></path><rect x=\"20\" y=\"110\" width=\"250\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">volumétrico: antes de o link encher</text><rect x=\"320\" y=\"110\" width=\"240\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"330\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">protocolo: tabelas e pilhas TCP</text><rect x=\"460\" y=\"160\" width=\"240\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">aplicação: proxy, cache, o código</text><text x=\"158\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o lado de quem defende começa aqui</text><path d=\"M150 22 L150 100\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></path></svg>", "caption": "Cada tipo de ataque é absorvido onde ainda é pequeno perto do que existe ali."}
```

**A linha mais importante é a primeira**, porque é a que um defensor não consegue resolver em casa.
Se o link que entra no prédio carrega 1 Gbit/s e chegam 20 Gbit/s, o firewall nunca chega a decidir
nada: os pacotes se perdem do lado do cabo que é do provedor, e os bons vão junto. Nenhuma regra no `fw` muda
isso. As três seções seguintes tratam do que o equipamento do próprio defensor consegue absorver, e a
última, do que ele não consegue.

## Negação nem sempre é ataque

O mesmo esgotamento acontece por acidente: uma promoção anunciada por e-mail a um milhão de clientes,
um cliente mal configurado repetindo em laço fechado, a integração de um parceiro colocada no ar numa
sexta-feira. Uma defesa que não sabe distinguir uma onda de clientes reais de um ataque ainda vale a
pena, desde que falhe de um jeito que mantenha alguns clientes atendidos em vez de nenhum. Esse é o
fio que atravessa os controles a seguir.
