---
title: Funções serverless
version: 1
---

"Serverless" não quer dizer que não existe servidor. Quer dizer que **você nunca vê um**: você entrega
uma função a uma plataforma, a plataforma a roda quando chega um evento, quantas cópias os eventos
pedirem, e para quando eles param. Você paga pelo tempo em que o seu código rodou, e nada enquanto
ficou parado.

O modelo costuma ser chamado de **funções como serviço**, FaaS. O AWS Lambda o popularizou em 2014;
Google Cloud Run functions, Azure Functions e Cloudflare Workers são outros, e Knative e OpenFaaS
rodam o mesmo modelo no seu próprio cluster Kubernetes.

## Uma função

A unidade é um handler: uma função que recebe um evento e devolve um resultado, e não guarda na
memória nada em que a próxima chamada possa confiar. Aqui está uma para a Quitanda, cotando a taxa de
entrega de uma cesta pelo peso. Ela fica no diretório da aula, `~/lab/faas`:

```sh
mkdir -p ~/lab/faas && cd ~/lab/faas
```

`handler.py`:

```schooling-example
{"language": "python", "file": "handler.py", "parts": [{"code": "def handle(event):\n    grams = event[\"weight_g\"]\n    fee = 790 if grams <= 5000 else 790 + (grams - 5000 + 999) // 1000 * 150\n    return {\"weight_g\": grams, \"fee_cents\": fee}", "note": "Uma função no sentido serverless: um handler que recebe um evento e devolve uma resposta, sem guardar nada entre as chamadas. Esta cota a taxa de entrega de uma cesta, pelo peso."}]}
```

Uma cesta de até 5 kg paga a taxa base de 790 centavos, e cada quilo começado acima disso acrescenta
150. A plataforma é responsável por todo o resto: receber o evento, achar uma máquina, iniciar o
código, escalar as cópias, registrar logs e parar tudo.

## O que dispara uma função

| evento | exemplo na Quitanda |
| --- | --- |
| uma requisição HTTP | o checkout pede a taxa de entrega |
| uma mensagem numa fila | um pedido foi feito; mande o e-mail de confirmação |
| um arquivo chegando no armazenamento | um fornecedor sobe a lista de preços; importe |
| um agendamento | toda noite às 02:00, expire os pedidos não pagos |
| uma mudança num banco | uma contagem de estoque caiu abaixo de dez; avise o comprador |

A maioria dessas linhas é cola entre sistemas, e **cola é onde funções encaixam melhor**: pedaços
curtos de trabalho, disparados por outra coisa, sem nada para guardar entre um e outro.

## Escalar até zero

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Um gráfico ao longo de um dia. As requisições chegam em duas rajadas, uma no almoço e outra à noite, e nenhuma de madrugada. O número de instâncias rodando acompanha as requisições: zero de madrugada, várias durante cada rajada, e de volta a zero depois. Um servidor sempre ligado aparece como uma linha reta em duas instâncias o dia todo.\"><defs><marker id=\"l3-zero-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M60 220 L690 220\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3-zero-ah-wire)\"></path><path d=\"M60 220 L60 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3-zero-ah-wire)\"></path><text x=\"375\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um dia, de meia-noite a meia-noite</text><text x=\"66\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">instâncias</text><path d=\"M60 220 L250 220 L270 120 L300 80 L330 110 L350 220 L470 220 L490 150 L520 60 L560 70 L590 160 L610 220 L690 220 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></path><path d=\"M60 180 L690 180\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"140\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">sempre ligado: 2</text><text x=\"300\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">almoço</text><text x=\"540\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">noite</text><text x=\"150\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">zero de madrugada</text></svg>", "caption": "Uma plataforma de funções escala com os eventos e desce a zero entre eles; você paga pela área sombreada, não pelo dia. Um servidor sempre ligado paga pela linha reta, chame alguém ou não."}
```

Uma plataforma de funções roda quantas cópias os eventos pedirem, e nenhuma quando não há eventos.
Para uma carga com longos trechos parados, essa é a atração inteira: as cotações de entrega da
Quitanda chegam perto do almoço e do jantar e quase nunca às quatro da manhã, e um servidor
dimensionado para o jantar fica parado a maior parte do resto do dia.

**Escalar até zero tem um custo, e quem paga é uma pessoa.** Quando nenhuma cópia está rodando e chega
um evento, a plataforma tem de iniciar uma antes de o seu código poder responder. A próxima seção mede
o que essa partida leva.
