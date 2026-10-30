---
title: Regiões, zonas e a rede privada
version: 1
---

**Uma região é um lugar no mapa; uma zona é uma falha separada dentro dela.** O curso `cloud` desenhou
esse quadro para todo provedor. Esta seção é o jeito do Google Cloud de escrevê-lo, e os dois detalhes
que o Google acrescenta e que mudam o desenho de um projeto.

O quadro errado mais comum é que uma zona é um datacenter. **Uma zona é uma área de implantação dentro
de uma região, com energia, refrigeração e rede próprias**, feita para que uma zona possa falhar
enquanto as vizinhas continuam. O Google não diz quantos prédios uma zona tem, e a resposta não mudaria
um projeto. Uma região tem três zonas ou mais, perto o bastante para que uma ida e volta entre duas
delas fique bem abaixo de alguns milissegundos. O arranjo é o mesmo de todo lugar: **você escolhe as
zonas, o Google escolhe os prédios**, e um sistema espalhado por duas ou três zonas sobrevive à perda
de uma.

## Os nomes

O nome de uma região é um continente, uma direção e um número. O nome de uma zona é o da região com uma
letra no fim:

| nome | o que é |
|---|---|
| `southamerica-east1` | São Paulo, a região que toda lição deste curso usa |
| `southamerica-east1-a`, `-b`, `-c` | as suas três zonas |
| `southamerica-west1` | Santiago, a outra região da América do Sul |
| `us-central1` | Iowa, a região que boa parte da documentação do próprio Google usa nos exemplos |

**O nome de uma zona quer dizer o mesmo lugar para todo mundo.** O Google não embaralha as letras entre
clientes, então a `southamerica-east1-a` do seu projeto é a `southamerica-east1-a` do próximo. Isso
importa quando duas equipes se planejam em torno da mesma falha: quando uma diz "a zona a caiu", a
outra sabe qual.

## Pedindo a lista, e sendo recusado

`gcloud compute regions list` é o comando que imprime toda região com as cotas e o estado dela. Rode-o
no laboratório:

```
ana@laptop:~/gcp$ gcloud compute regions list
ERROR: (gcloud.compute.regions.list) Some requests did not succeed:
 - Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project.

ana@laptop:~/gcp$ curl -sS https://compute.googleapis.com/compute/v1/projects/planner-dev/zones
{
  "error": {
    "code": 401,
    "message": "Request is missing required authentication credential. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project.",
    "errors": [
      {
        "message": "Login Required.",
        "domain": "global",
        "reason": "required",
        "location": "Authorization",
        "locationType": "header"
      }
    ],
    "status": "UNAUTHENTICATED",
    "details": [
      {
        "@type": "type.googleapis.com/google.rpc.ErrorInfo",
        "reason": "CREDENTIALS_MISSING",
        "domain": "googleapis.com",
        "metadata": {
          "method": "compute.v1.ZonesService.List",
          "service": "compute.googleapis.com"
        }
      }
    ]
  }
}
```

**Essa recusa é a API real do Compute Engine, nos datacenters do Google, respondendo a um pedido que
levava a palavra `placeholder` como credencial.** O laboratório não tem emulador para o Compute
Engine, então a CLI fez o que faz quando nada troca um endereço: mandou o pedido para
`compute.googleapis.com`. O segundo comando manda o mesmo tipo de pedido com o `curl` e sem credencial
nenhuma, e o Google diz isso com outra frase: o primeiro pedido levava uma credencial que falhou, o
segundo não levava nenhuma. A lição 24 lê esse tipo de resposta campo a campo.

Então as regiões são ensinadas aqui pela documentação do Google, e **esta lista não foi produzida por
um comando**. No fim de outubro de 2026 o Google listava mais de quarenta regiões, duas delas na
América do Sul; o número cresce todo ano, e é por isso que um curso nunca deve ser o lugar onde você o
procura.

## A rede do Google

O segundo detalhe é o que torna a rede do Google Cloud incomum. **O Google leva o tráfego entre as suas
regiões na própria fibra**, e no arranjo padrão leva também o tráfego entre uma região e o usuário na
própria fibra, até o ponto de presença mais perto do usuário. Um pedido de Recife para um serviço em
São Paulo entra na rede do Google perto de Recife e não atravessa a internet pública no meio do
caminho.

Esse padrão tem nome, **Premium Tier**, e a alternativa, **Standard Tier**, entrega o tráfego à internet
pública perto da região, por um preço menor por gibibyte. A escolha é feita por endereço, e a lição 20
a encontra de novo num balanceador de carga. É também o motivo de uma única rede poder cobrir todas as
regiões, o que a lição 15 monta: os pacotes entre duas regiões de uma rede nunca saem do Google.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l01-backbone\" aria-label=\"Dois caminhos para um pedido de um usuário em Recife chegar a um serviço em São Paulo. Em cima, o Premium Tier: o pedido entra na rede do Google num ponto de presença perto de Recife e viaja pela rede própria do Google até a região southamerica-east1, que tem três zonas, a, b e c. Embaixo, o Standard Tier: o pedido atravessa a internet pública até o fim e só entra na rede do Google na região. Entre southamerica-east1 e southamerica-west1, Santiago, o tráfego anda sempre pela rede do Google.\"><defs><marker id=\"l01-backbone-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-backbone-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l01-backbone-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"130.0\" width=\"110.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"153.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um usuário</text><text x=\"75.0\" y=\"166.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">em Recife</text><rect x=\"430.0\" y=\"70.0\" width=\"270.0\" height=\"180.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"565.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">southamerica-east1</text><rect x=\"448.0\" y=\"108.0\" width=\"74.0\" height=\"54.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"485.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">a</text><rect x=\"532.0\" y=\"108.0\" width=\"74.0\" height=\"54.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"569.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">b</text><rect x=\"616.0\" y=\"108.0\" width=\"74.0\" height=\"54.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"653.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">c</text><text x=\"565.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">três zonas: energia, refrigeração</text><text x=\"565.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e rede separadas</text><rect x=\"560.0\" y=\"278.0\" width=\"140.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"630.0\" y=\"298.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">southamerica-west1</text><path d=\"M630.0 252.0 L630.0 274.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#l01-backbone-af-ah-phosphor)\" marker-start=\"url(#l01-backbone-af-ah-phosphor)\"></path><text x=\"548.0\" y=\"264.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">sempre a rede do Google</text><rect x=\"170.0\" y=\"40.0\" width=\"92.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"216.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">ponto de presença</text><path d=\"M130.0 145.0 L168.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-backbone-af-ah-paper-dim)\"></path><path d=\"M264.0 60.0 L426.0 100.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\" marker-end=\"url(#l01-backbone-af-ah-phosphor)\"></path><text x=\"330.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Premium Tier</text><text x=\"340.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">fibra do Google</text><path d=\"M130 178 C 200 240, 260 200, 300 236 S 380 250, 426 222\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01-backbone-af-ah-amber)\"></path><text x=\"250.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">Standard Tier</text><text x=\"250.0\" y=\"298.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a internet pública, até a região</text></svg>", "caption": "O Premium Tier é o padrão: o pedido entra na rede do Google perto do usuário.", "same": ["Premium Tier", "Standard Tier"]}
```

O que a rede do Google não muda é a fatura: a próxima seção põe preço nas setas entre essas caixas, e a
mais surpreendente é a que sai de São Paulo.
