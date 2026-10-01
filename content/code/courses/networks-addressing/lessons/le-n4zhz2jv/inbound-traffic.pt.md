---
title: Direcionando o tráfego que chega até você
version: 1
---

**O tráfego de saída é decisão sua; o de entrada é decisão de outro.** edge escolhe por qual provedor sair
em direção a a1 pela própria tabela, e pode mudar isso com local preference quando quiser. Por qual enlace
o tráfego de a1 chega à empresa quem escolhe é ispa, a partir do que ispa ouve. Tudo o que a empresa pode
fazer é mudar o que diz.

Eis o que ispa ouve sobre o bloco da empresa:

```
root@ispa:~# vtysh -c "show ip bgp 203.0.113.0/24"
BGP routing table entry for 203.0.113.0/24, version 3
Paths: (2 available, best #2, table default)
  Advertised to non peer-group peers:
  192.0.2.1 192.0.2.10
  64502 64500
    192.0.2.10 from 192.0.2.10 (192.0.2.6)
      Origin IGP, valid, external
      Last update: Tue Sep 29 08:49:59 2026
  64500
    192.0.2.1 from 192.0.2.1 (192.0.2.1)
      Origin IGP, metric 0, valid, external, best (AS Path)
      Last update: Tue Sep 29 08:50:05 2026
```

Dois caminhos. **`64502 64500`**, vindo de `192.0.2.10`, é o bloco da empresa como ispb o repassou.
**`64500`**, vindo de `192.0.2.1`, é o próprio edge, e é o `best (AS Path)`: o FRR nomeia o passo da lista
de desempate que decidiu, e é o tamanho do caminho. A linha `Advertised to` lista `192.0.2.1` entre os
vizinhos a quem ispa repassa o prefixo, que é a oferta de volta que edge recusa.

Suponha que a empresa queira que o provedor de a1 mande o tráfego por ispb, porque o enlace até ispa é o
menor. **A alavanca é o AS path prepending**: anunciar a ispa um caminho alongado artificialmente,
repetindo o próprio número da empresa.

```
root@edge:~# vtysh -c "configure terminal" -c "route-map TO-ISPA permit 10" -c "match ip address prefix-list OURS" -c "set as-path prepend 64500 64500" -c "exit" -c "router bgp 64500" -c "address-family ipv4 unicast" -c "neighbor 192.0.2.2 route-map TO-ISPA out"
```

Um novo route map, `TO-ISPA`, continua permitindo só `OURS`, e acrescenta
`set as-path prepend 64500 64500`. Ele substitui `TO-PROVIDER` só em direção a ispa. A visão de ispa
depois:

```
root@ispa:~# vtysh -c "show ip bgp 203.0.113.0/24"
BGP routing table entry for 203.0.113.0/24, version 4
Paths: (2 available, best #1, table default)
  Advertised to non peer-group peers:
  192.0.2.1 192.0.2.10
  64502 64500
    192.0.2.10 from 192.0.2.10 (192.0.2.6)
      Origin IGP, valid, external, best (AS Path)
      Last update: Tue Sep 29 08:49:59 2026
  64500 64500 64500
    192.0.2.1 from 192.0.2.1 (192.0.2.1)
      Origin IGP, metric 0, valid, external
      Last update: Tue Sep 29 08:50:18 2026
```

O caminho direto agora é **`64500 64500 64500`**, três números, contra **`64502 64500`**, dois, e o caminho
por ispb é o `best (AS Path)`. O tráfego de a1 vai atrás:

```
ana@a1:~$ traceroute -n 203.0.113.10
traceroute to 203.0.113.10 (203.0.113.10), 30 hops max, 60 byte packets
 1  198.51.100.1  0.697 ms  0.195 ms  0.152 ms
 2  192.0.2.10  0.505 ms  0.397 ms  0.133 ms
 3  192.0.2.5  0.129 ms  0.194 ms  0.097 ms
 4  203.0.113.10  0.475 ms  0.512 ms  0.152 ms
```

**Quatro saltos em vez de três**: ispa em `198.51.100.1`, depois ispb em `192.0.2.10`, depois edge em
`192.0.2.5`, sua interface voltada para ispb, depois o servidor. O tráfego agora entra pelo outro provedor.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Dois painéis, antes e depois de a empresa repetir seu número de AS em direção ao provedor A. Antes: ispa tem dois caminhos para 203.0.113.0/24, 64500 direto e 64502 64500 por ispb, e escolhe o mais curto, 64500; o tráfego de a1 vai de ispa direto para edge. Depois: o caminho vindo de edge é 64500 64500 64500, três números, contra 64502 64500, dois; ispa escolhe o caminho por ispb, e o tráfego de a1 vai de ispa para ispb e então para edge.\"><defs><marker id=\"bp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"340\" height=\"310\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">antes do prepend</text><rect x=\"135\" y=\"46\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">edge</text><rect x=\"30\" y=\"140\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"75\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ispa</text><rect x=\"240\" y=\"140\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"285\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ispb</text><rect x=\"30\" y=\"214\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"75\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a1</text><path d=\"M75 214 L75 170\" stroke=\"var(--phosphor)\" stroke-width=\"2.6\" fill=\"none\"></path><path d=\"M150 76 L90 140\" stroke=\"var(--phosphor)\" stroke-width=\"2.6\" fill=\"none\"></path><path d=\"M210 76 L270 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M120 155 L240 155\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"24\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">caminhos de ispa para 203.0.113.0/24</text><text x=\"24\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">64500</text><text x=\"210\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">best</text><text x=\"24\" y=\"300\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">64502 64500</text><rect x=\"370\" y=\"10\" width=\"340\" height=\"310\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"384\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">depois do prepend</text><rect x=\"495\" y=\"46\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">edge</text><rect x=\"390\" y=\"140\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"435\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ispa</text><rect x=\"600\" y=\"140\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"645\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ispb</text><rect x=\"390\" y=\"214\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"435\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a1</text><path d=\"M435 214 L435 170\" stroke=\"var(--phosphor)\" stroke-width=\"2.6\" fill=\"none\"></path><path d=\"M510 76 L450 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M570 76 L630 140\" stroke=\"var(--phosphor)\" stroke-width=\"2.6\" fill=\"none\"></path><path d=\"M480 155 L600 155\" stroke=\"var(--phosphor)\" stroke-width=\"2.6\" fill=\"none\"></path><text x=\"384\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">caminhos de ispa para 203.0.113.0/24</text><text x=\"384\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">64500 64500 64500</text><text x=\"384\" y=\"300\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">64502 64500</text><text x=\"570\" y=\"300\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">best</text></svg>", "caption": "A empresa mudou o que anunciava, e o provedor A escolheu diferente. A linha grossa é o caminho por onde chega o tráfego de a1."}
```

## O que você consegue e o que não consegue fazer os outros fazerem

O prepending é um pedido, e funcionou aqui porque a configuração de ispa não ajusta nada antes do passo do
AS path. **Provedores reais dão uma local preference maior às rotas aprendidas dos clientes do que às
aprendidas de outros provedores**, porque os clientes pagam e os pares não, e a local preference é
verificada antes do tamanho do caminho. Contra essa política um prepend não muda nada no provedor a que
foi dirigido; só muda a escolha de redes mais distantes.

Existem outras três alavancas, cada uma citada e nenhuma executada neste laboratório:

- **MED** (*multi-exit discriminator*), uma dica a um vizinho sobre qual de vários enlaces até esse mesmo
  vizinho você prefere.
- **Communities**, etiquetas presas a uma rota às quais o provedor publicou um significado, como *baixe
  minha local preference* ou *não anuncie isto àquele par*.
- **Um prefixo mais específico** por um provedor: dois `/25` por um enlace e o `/24` pelos dois. O prefixo
  mais longo vence, como a aula 14 mostrou, então os `/25` atraem o tráfego; isso também acrescenta rotas a
  todo roteador da internet, e muitas redes descartam prefixos mais longos que `/24`.

Nada mudou nas escolhas do próprio edge: sua tabela continua mandando o tráfego para `198.51.100.0/25` por
ispa, então os pedidos de a1 agora chegam por ispb e as respostas saem por ispa. **Caminhos assimétricos
são normais no BGP**, e é por eles que uma captura num enlace vê só metade de uma conversa.
