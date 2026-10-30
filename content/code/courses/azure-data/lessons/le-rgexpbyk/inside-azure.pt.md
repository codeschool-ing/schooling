---
title: Entre regiões, gateways e endpoints
version: 1
---

**Dentro do Azure, para onde os bytes vão decide se eles custam alguma coisa.** Ler uma conta a partir
de uma máquina na mesma região não paga banda, e só as operações são cobradas. Sair da região custa
por GB. E duas peças de rede que muitas assinaturas têm, o NAT gateway e o private endpoint, cobram
por todo gigabyte que carregam, mesmo quando o destino é a conta de armazenamento ali do lado.

**Esta seção é ensinada a partir das páginas de preços da Microsoft para banda, NAT Gateway e Private
Link, e nada nela foi rodado**: o laboratório não tem rede para um byte atravessar. As contas usam
preços ilustrativos, e dizem isso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Para onde vai um byte de uma conta de armazenamento em brazilsouth, e o que cada caminho cobra, segundo as páginas de preços da Microsoft. Dentro da região, um job noturno numa sub-rede privada chega à conta por três caminhos: por um NAT gateway, que cobra por GB processado; por um service endpoint, que é de graça; ou por um private endpoint, que cobra por GB processado nas duas direções. Fora da região, uma cópia para outra região é cobrada por GB, a replicação geo-redundante para a região par é cobrada por GB como transferência de georreplicação, e a transferência para a internet é de graça nos primeiros 100 GB do mês e cobrada por GB depois disso.\" data-fig=\"l07-routes\"><defs><marker id=\"arr-l07-routes-amber\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--amber)\"></path></marker><marker id=\"arr-l07-routes-phosphor\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"500\" height=\"285\" rx=\"10\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></rect><text x=\"32\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">brazilsouth</text><rect x=\"34\" y=\"60\" width=\"140\" height=\"230\" rx=\"6\" fill=\"none\" stroke=\"var(--scan)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></rect><text x=\"44\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sub-rede privada</text><rect x=\"48\" y=\"145\" width=\"112\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"104\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">job noturno</text><rect x=\"350\" y=\"145\" width=\"156\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"428\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">conta de armazenamento</text><path d=\"M 104 145 L 104 100 L 215 100\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"215\" y=\"86\" width=\"100\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">NAT gateway</text><path d=\"M 315 100 L 428 100 L 428 141\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#arr-l07-routes-amber)\"></path><text x=\"265\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">por GB processado</text><line x1=\"160\" y1=\"165\" x2=\"346\" y2=\"165\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l07-routes-phosphor)\"></line><text x=\"253\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">service endpoint: de graça</text><path d=\"M 104 185 L 104 240 L 215 240\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"215\" y=\"226\" width=\"100\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">private endpoint</text><path d=\"M 315 240 L 428 240 L 428 189\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#arr-l07-routes-amber)\"></path><text x=\"265\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">por GB processado, nos dois sentidos</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">outra região</text><text x=\"630\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">por GB</text><path d=\"M 506 165 L 536 165 L 536 55 L 556 55\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#arr-l07-routes-amber)\"></path><rect x=\"560\" y=\"132\" width=\"140\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">região par</text><text x=\"630\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">georreplicação, por GB</text><path d=\"M 506 165 L 536 165 L 536 147 L 556 147\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#arr-l07-routes-amber)\"></path><rect x=\"560\" y=\"224\" width=\"140\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">internet</text><text x=\"630\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">100 GB por mês de graça,</text><text x=\"630\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">depois por GB</text><path d=\"M 506 165 L 536 165 L 536 239 L 556 239\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#arr-l07-routes-amber)\"></path></svg>", "caption": "Dentro da região o caminho decide a cobrança, e o caminho de graça é uma configuração da sub-rede. Tudo o que sai da região é cobrado por GB, da conta que envia.", "same": ["NAT gateway", "private endpoint", "internet"]}
```

## Regiões

**Transferência entre duas regiões do Azure é cobrada por GB, pela região de onde sai.** A página de
banda da Microsoft dá o preço pelo lugar onde as duas regiões estão, no mesmo continente ou entre
continentes. O jurídico da Quitanda pediu uma vez uma cópia do lago de 5 TB em `eastus`, para um
parceiro que trabalha lá. A ilustrativos 0,08 USD por GB, são 5.120 × 0,08 = 409,60 pela cópia, uma
vez, e toda mudança copiada depois paga a mesma tarifa.

**A replicação geo-redundante é a mesma transferência, feita sozinha.** Uma conta em GRS ou GZRS copia
toda escrita para a região par, que para `brazilsouth` é `southcentralus`, no Texas, como a lição 1
notou, e a tabela cobra isso como transferência de dados de georreplicação, por GB. O ZRS da Quitanda
mantém as três cópias no Brasil e as paga no preço de capacidade, então essa linha nunca aparece na
fatura dela.

O tráfego entre as zonas de disponibilidade de uma região tem uma linha própria na página de banda.
Leia lá se ele é cobrado na sua região antes de contar com qualquer resposta; este curso não
verificou.

## O NAT gateway, e o caminho de graça que o evita

**Um NAT gateway cobra por todo GB que processa**, além de um preço por hora por existir. Máquinas
numa sub-rede privada com um deles anexado chegam à internet por ele e, sem mais nada configurado,
chegam a uma conta de armazenamento por ele também, porque o endereço da conta é público. A
ilustrativos 0,05 USD por GB processado, o job noturno da Quitanda, que lê 2 TB por mês do lago, paga
2.048 × 0,05 = 102,40 por mês só de processamento, por tráfego que nunca saiu de São Paulo.

**Um service endpoint não custa nada e tira esse tráfego do gateway.** É uma configuração da sub-rede,
`Microsoft.Storage`, que manda o tráfego para contas de armazenamento da região pela rede do próprio
Azure em vez de pelo gateway, e o firewall da conta pode então admitir essa sub-rede pelo nome. A
Microsoft não documenta cobrança por ele. Os 102,40 viram 0,00, e nada mais no job muda. É a mudança
mais barata desta lição, e uma das mais esquecidas, porque nada quebra sem ela; a fatura só fica
maior.

**Um private endpoint é o outro caminho, e não é de graça.** Ele dá à conta um endereço dentro da sua
própria rede, então o tráfego nunca toca um endereço público, que é o que uma equipe de segurança
costuma pedir. Ele é cobrado por hora e por GB processado, nos dois sentidos. A ilustrativos 0,01 USD
por GB, o mesmo job paga 2.048 × 0,01 = 20,48 por mês. Escolher entre os dois é uma decisão de
segurança com um preço, e a lição 19 de `azure-foundations` é onde os dois são montados.
