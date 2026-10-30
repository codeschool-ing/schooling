---
title: De onde o token vem
version: 1
---

**No Azure, a credencial de uma identidade gerenciada nunca chega ao programa, porque o programa pede
um token à plataforma em vez de pedir ao Entra ID.** A imagem errada é um segredo escondido em algum
lugar da máquina que o código lê; não existe nenhum. O que a máquina tem é um endereço que só ela
alcança, e a resposta nesse endereço é um token que o Azure obteve em nome dela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l08-imds\" aria-label=\"Como o código numa máquina virtual do Azure obtém um token sem guardar credencial. Dentro da máquina virtual, a aplicação pergunta ao Instance Metadata Service em 169.254.169.254, que só aquela máquina alcança. A plataforma, fora da máquina, obtém do Entra ID um token para a identidade gerenciada da máquina e o devolve. A aplicação então chama a storage account com o token. Nenhuma credencial entra na máquina.\"><defs><marker id=\"l08-imds-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-imds-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l08-imds-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"135.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">na máquina virtual</text><text x=\"605.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fora dela</text><rect x=\"50.0\" y=\"70.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a aplicação</text><rect x=\"290.0\" y=\"70.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">serviço de metadados</text><text x=\"375.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">169.254.169.254</text><rect x=\"520.0\" y=\"70.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Entra ID</text><rect x=\"520.0\" y=\"180.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">stshopassetsprod</text><path d=\"M221.0 88.0 L289.0 88.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-imds-af-ah-amber)\"></path><path d=\"M461.0 88.0 L519.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-imds-af-ah-paper-dim)\"></path><path d=\"M519.0 104.0 L461.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-imds-af-ah-paper-dim)\"></path><path d=\"M289.0 104.0 L221.0 104.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-imds-af-ah-amber)\"></path><text x=\"255.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">1 pede, 4 token</text><text x=\"490.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2, 3 a plataforma faz login</text><path d=\"M135.0 121.0 L135.0 205.0 L519.0 205.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-imds-af-ah-phosphor)\"></path><text x=\"330.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">5 a chamada, com o token</text></svg>", "caption": "A credencial fica com a plataforma; só um token chega à aplicação.", "same": ["Entra ID"]}
```

Numa máquina virtual o endereço é o **Instance Metadata Service**, IMDS na forma curta, em
`169.254.169.254`. Esse endereço é **link-local**: nunca é roteado para fora do host, então quer
dizer "a plataforma debaixo desta máquina" em toda VM do Azure, e um pedido a ele nunca atravessa uma
rede. Um programa pede um token a ele com um pedido HTTP comum:

| parte | valor | por quê |
|---|---|---|
| endereço | `http://169.254.169.254/metadata/identity/oauth2/token` | HTTP simples basta: o pedido nunca sai do host |
| `api-version` | `2018-02-01` | toda API do Azure recebe uma versão, lição 25 |
| `resource` | `https://management.azure.com/` | para qual API é o token, como no scope da lição 7 |
| `client_id` | o client id da identidade atribuída pelo usuário | qual identidade, quando a máquina tem mais de uma |
| cabeçalho `Metadata: true` | obrigatório | um pedido sem ele é recusado, o que impede que uma página que engana um servidor para buscar uma URL busque esta |

A resposta é um JSON com um `access_token` e a validade dele, e **a plataforma renova e guarda o token
em cache**: pedir de novo um minuto depois devolve o mesmo token, não um novo login. O App Service, o
Functions e o Container Apps oferecem o mesmo serviço num endereço próprio, que eles põem em duas
variáveis de ambiente da aplicação, `IDENTITY_ENDPOINT` e `IDENTITY_HEADER`.

**Nada disto foi executado.** O laboratório não está no Azure, então não há plataforma debaixo dele
para responder, e nada neste curso finge ser uma. A tabela é a interface documentada da Microsoft.

## Qual identidade responde

Um recurso pode ter uma identidade atribuída pelo sistema e várias atribuídas pelo usuário ao mesmo
tempo, como o web app da loja tem. **Um pedido que não diz qual identidade quer recebe a atribuída pelo
sistema**, se houver uma. Para usar o `id-shop-app` o programa precisa nomeá-lo, pelo client id, e é
exatamente por isso que o `app.bicep` pôs esse client id na configuração `AZURE_CLIENT_ID` da
aplicação: o código o lê do ambiente e nunca tem o valor escrito dentro dele.

Essa configuração é fácil de esquecer, e a falha que ela causa é silenciosa: o programa entra como a
identidade **atribuída pelo sistema**, que não tem papel na storage account, e a leitura é recusada com
um erro de autorização que parece um papel faltando e não uma identidade errada. Quando uma identidade
gerenciada é recusada em algo que recebeu, **confira primeiro de quem é o token**: a claim `oid` dele é
o object id do principal que fez login.

## O que uma identidade gerenciada não protege

A credencial não pode vazar, e o token pode. Quem roda código na máquina consegue pedir um token ao
IMDS tão facilmente quanto a aplicação: **uma identidade gerenciada é exatamente tão segura quanto a
máquina a que está ligada.** Dê a ela os papéis de que a aplicação precisa e nada mais, no escopo mais
estreito que funcione, que para a loja é uma storage account e não a assinatura, e a lição 9 é o como.
