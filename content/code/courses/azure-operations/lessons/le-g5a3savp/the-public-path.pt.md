---
title: Três jeitos de alcançar um serviço, e o que fecha a porta
version: 1
---

**Um serviço PaaS como o Azure SQL, o Storage ou o Key Vault tem um endpoint público por padrão.** O nome dele resolve para um
endereço público, e o que fica entre a internet e os dados é o firewall do serviço e a autenticação. Existem três jeitos de
estreitar isso:

| | como o tráfego chega ao serviço | o endpoint público continua? |
|---|---|---|
| **regras de firewall** | pela internet, de endereços listados | sim, filtrado |
| **service endpoints** | pela rede interna do Azure, de sub-redes listadas | sim, filtrado por sub-rede |
| **private endpoint** | uma interface de rede com endereço privado na sua sub-rede | só se você o deixar ligado |

Um **private endpoint** é o mais forte: o serviço aparece dentro da sua rede virtual, num endereço privado, e o tráfego até ele
nunca sai da rede. Com o endpoint público desligado, não sobra endereço na internet para um atacante tentar, que é o ponto em
que a lição 19 terminou. A loja põe o servidor SQL, o Key Vault e a conta de armazenamento do estado atrás de private endpoints.

Service endpoints são mais antigos e mais baratos, e mantêm o endpoint público, só restringindo quem pode usá-lo; também só
funcionam a partir de sub-redes do Azure. Private endpoints são cobrados por hora e por gigabyte processado, e precisam de DNS,
que é onde mora a maior parte do problema:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A cadeia de DNS de sql-shop. De dentro de vnet-shop, o nome sql-shop.database.windows.net é um CNAME para sql-shop.privatelink.database.windows.net, que a zona DNS privada ligada à rede responde com o endereço do private endpoint na sub-rede. Da internet, o mesmo CNAME leva à resposta pública do Azure, e com o acesso público desligado o servidor recusa a conexão.\"><defs><marker id=\"ah-dns\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"230\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"135\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sql-shop.database</text><text x=\"135\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.windows.net</text><rect x=\"290\" y=\"90\" width=\"200\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"390\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sql-shop.privatelink</text><text x=\"390\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.database.windows.net</text><path d=\"M250 115 L288 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-dns)\"></path><text x=\"269\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">CNAME</text><rect x=\"530\" y=\"30\" width=\"170\" height=\"60\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">dentro de vnet-shop</text><text x=\"615\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">endereço privado</text><rect x=\"530\" y=\"140\" width=\"170\" height=\"60\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"615\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">da internet</text><text x=\"615\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">recusado</text><path d=\"M490 105 L528 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-dns)\"></path><path d=\"M490 125 L528 165\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-dns)\"></path></svg>", "caption": "Um nome, duas respostas, conforme quem pergunta."}
```
