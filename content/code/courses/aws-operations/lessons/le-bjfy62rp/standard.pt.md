---
title: O Shield Standard, que toda conta já tem
version: 1
---

Um ataque de **negação de serviço distribuída**, DDoS, manda a um serviço mais tráfego do que ele consegue
responder, de muitas máquinas ao mesmo tempo, para que os clientes reais não consigam entrar. Nada é
roubado e nada é invadido; o serviço simplesmente fica cheio. Os ataques vêm em duas famílias, e são
parados em lugares diferentes.

**Ataques de rede e transporte**, camadas 3 e 4, inundam a própria conexão: pacotes SYN que abrem conexões
e nunca as terminam, pacotes UDP refletidos em servidores mal configurados em outro ponto da internet e
multiplicados no caminho. São grandes, medidos em gigabits ou pacotes por segundo, e nunca chegam à
aplicação; enchem a estrada até ela.

**Ataques de aplicação**, camada 7, mandam requisições que parecem reais: uma página buscada, uma pesquisa
feita, um login tentado, milhares de vezes por segundo. São pequenos em comparação e caros de responder,
porque cada um faz a aplicação trabalhar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas linhas. Ataques de rede e transporte nas camadas 3 e 4, como SYN flood e reflexão UDP, medidos em gigabits por segundo, são parados pelo Shield Standard na borda e no balanceador, automaticamente e sem custo. Ataques de aplicação na camada 7, requisições que parecem reais e são caras de responder, são parados pelas regras de taxa do WAF e pelo CloudFront, configurados pela equipe como na lição 15, ou pelas regras automáticas do Shield Advanced.\"><defs><marker id=\"lay-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"130\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o ataque</text><text x=\"530\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">onde é parado</text><rect x=\"20\" y=\"44\" width=\"220\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"130.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">camadas 3 e 4</text><text x=\"130.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">SYN flood, reflexão UDP</text><text x=\"130.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">gigabits por segundo</text><path d=\"M242 82 L368 82\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lay-ah)\"></path><rect x=\"370\" y=\"44\" width=\"330\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"535.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Shield Standard</text><text x=\"535.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na borda e no balanceador,</text><text x=\"535.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">automático, sem custo</text><rect x=\"20\" y=\"146\" width=\"220\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"130.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">camada 7</text><text x=\"130.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">requisições que parecem reais</text><text x=\"130.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">caras de responder</text><path d=\"M242 184 L368 184\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lay-ah)\"></path><rect x=\"370\" y=\"146\" width=\"330\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"535.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">regras de taxa do WAF e CloudFront</text><text x=\"535.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lição 15, configurados pela equipe;</text><text x=\"535.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ou as regras automáticas do Shield Advanced</text></svg>", "caption": "O Standard para as inundações que enchem a estrada. As requisições que parecem reais são da camada 7, e essa camada a equipe configura.", "same": ["Shield Standard"]}
```

## O que o Standard faz, e o que não faz

**O AWS Shield Standard está ligado em toda conta, sem custo, sem nada a configurar.** Ele inspeciona o
tráfego para o CloudFront, o Route 53 e o Global Accelerator na borda da AWS, e para balanceadores de carga
e endereços Elastic IP na região, e absorve ou descarta ali os ataques comuns de camada 3 e 4, antes que
cheguem aos recursos. Não há comando para ele, nada para ver no console e nenhuma linha na conta, e é por
isso que as pessoas esquecem que ele existe, e também por isso que o laboratório não tem nada a mostrar
sobre ele.

O que o Standard **não** faz é ler HTTP. Uma enxurrada de requisições `GET /search?q=…` perfeitamente
formadas é tráfego comum na camada 4, e o Standard a deixa passar. Essa família é da lição 15: uma regra
por taxa nos caminhos caros de responder, um grupo de regras gerenciado, e o CloudFront na frente, que
guarda em cache o que der para guardar, de modo que uma enxurrada de requisições idênticas seja respondida
na borda e não pela loja.

**Para a maioria dos serviços pequenos e médios, Standard mais WAF mais CloudFront é a resposta**, e custa
só o que a lição 15 calculou. A próxima seção é sobre o que custa mais, e quando isso vale a pena.
