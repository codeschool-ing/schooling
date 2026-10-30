---
title: Servindo arquivos para a internet
version: 1
---

**Bytes que saem do Google Cloud para a internet são a coisa mais cara que um bucket faz**, e são
cobrados do projeto do bucket, seja quem for que os pediu. As imagens de um site público, os
downloads de um aplicativo, um relatório que um cliente baixa: cada byte que sai é medido, a 0,12 o
GiB nos primeiros 10 TiB do mês para destinos fora da Ásia e da Austrália, que é onde o Brasil fica.
Isso é quase três vezes e meia o preço de guardar o mesmo byte por um mês no Standard.

A tabela, da parte "General network usage" de cloud.google.com/storage/pricing, lida em 2026-10-30,
por GiB:

| destino | primeiros 10 TiB | de 10 a 150 TiB | acima de 150 TiB |
|---|---|---|---|
| mundo, exceto Ásia e Austrália | 0,12 | 0,11 | 0,08 |
| Ásia, exceto China, incluindo Hong Kong | 0,12 | 0,11 | 0,08 |
| Austrália | 0,19 | 0,18 | 0,15 |

A China, exceto Hong Kong, tem degraus próprios: 0,23 no primeiro TiB, 0,22 até 10 TiB e 0,20 acima.

**Esta tabela não é por região.** A página imprime uma só, para todo bucket, e o preço segue para onde
os bytes vão, e não de onde vieram. Isso é diferente de uma máquina virtual: a página de preços de
rede, cloud.google.com/vpc/network-pricing, imprime uma tabela do Premium Tier para tráfego que sai de
`southamerica-east1`, e ela começa em 0,19 o GiB no primeiro TiB para a América do Norte, a Europa ou a
América do Sul. O mesmo byte custa menos para sair de um bucket em São Paulo do que de uma máquina ao
lado dele, e a aula 6 reencontra a tabela da máquina no Cloud SQL.

As imagens de produtos da Quitanda somam 500 GiB, e o aplicativo e o site baixam cerca de 20 TiB delas
por mês. É a terceira linha do programa da seção anterior:

```
500 GiB of images, 20 TiB out         17.50     21.47   2,355.20   2,394.17
```

**O armazenamento é 17,50 de um mês que custa 2.394,17.** As requisições, 53,7 milhões de downloads de
400 KiB, dão 21,47 pela tarifa da Classe B. Os outros 2.355,20 são a transferência, calculada pelas
faixas em `tiers()`: os primeiros 10.240 GiB a 0,12 dão 1.228,80, e os 10.240 GiB restantes a 0,11
dão 1.126,40. As faixas baixam o preço à medida que o volume do mês cresce, e um projeto precisa mandar
150 TiB num mês antes de chegar à mais barata, 0,08.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas escadas de preço por GiB contra os TiB enviados no mês. Cloud Storage para a internet: 0,12 nos primeiros 10 TiB, 0,11 até 150 TiB, 0,08 acima disso. Cloud CDN para quem está na América do Sul: 0,09 nos primeiros 10 TiB, 0,06 até 150 TiB, 0,05 acima. A Quitanda, com 20 TiB por mês, paga 2.355,20 USD saindo do bucket, ou 1.536,00 USD de transferência do cache pelo Cloud CDN.\" data-fig=\"l05-gcs-tiers\"><path d=\"M80.0 250.0 L680.0 250.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"72\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.04</text><path d=\"M80.0 210.0 L680.0 210.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"72\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.06</text><path d=\"M80.0 170.0 L680.0 170.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"72\" y=\"170.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.08</text><path d=\"M80.0 130.0 L680.0 130.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"72\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.10</text><path d=\"M80.0 90.0 L680.0 90.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"72\" y=\"90.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.12</text><path d=\"M80.0 50.0 L680.0 50.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"72\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.14</text><path d=\"M80.0 250.0 L680.0 250.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 250.0 L80.0 255.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M110.0 250.0 L110.0 255.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"110.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><path d=\"M230.0 250.0 L230.0 255.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"230.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><path d=\"M530.0 250.0 L530.0 255.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"530.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">150</text><path d=\"M680.0 250.0 L680.0 255.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"680.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><text x=\"680\" y=\"288\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">TiB enviados no mês</text><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">USD por GiB, naquela faixa</text><path d=\"M80.0 90.0 L110.0 90.0 L110.0 110.0 L530.0 110.0 L530.0 170.0 L680.0 170.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M80.0 150.0 L110.0 150.0 L110.0 210.0 L530.0 210.0 L530.0 230.0 L680.0 230.0\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"114\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.12</text><text x=\"330\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.11</text><text x=\"605\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.08</text><text x=\"114\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0.09</text><text x=\"330\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0.06</text><text x=\"605\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0.05</text><path d=\"M140.0 116.0 L140.0 246.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><circle cx=\"140.0\" cy=\"110.0\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"140.0\" cy=\"210.0\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"148\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">Quitanda, 20 TiB: 2.355,20 USD</text><text x=\"148\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">pelo Cloud CDN: 1.536,00 USD</text><path d=\"M420.0 40.0 L450.0 40.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"458\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Cloud Storage para a internet</text><path d=\"M420.0 58.0 L450.0 58.0\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"458\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Cloud CDN para quem está na América do Sul</text></svg>", "caption": "A transferência para a internet é uma escada, não uma taxa: cada degrau vale só para os GiB que caem nele. Com 20 TiB, a Quitanda paga o primeiro degrau inteiro e parte do segundo, em qualquer das duas escadas."}
```

**A cota gratuita não chega a São Paulo.** O nível Always Free do Cloud Storage inclui 100 GB de
transferência por mês, e a página limita tudo isso, o armazenamento e as operações também, a buckets
em `us-west1`, `us-central1` e `us-east1`. Um bucket em `southamerica-east1` começa a pagar no
primeiro byte.

## Atrás do Cloud CDN

**O Cloud CDN é o cache do Google na borda da rede dele**, e o Cloud Storage pode ser a origem. O
pedido de quem está vendo chega à borda mais próxima. Se a borda tem uma cópia, ela responde, e o
bucket nem fica sabendo; se não tem, busca o objeto no bucket uma vez, guarda, e responde os próximos
mil pedidos com a cópia. **A cobrança de transferência do próprio bucket é dispensada** para o que ele
manda ao Cloud CDN, como a página de preços do armazenamento diz em "Specialty network services", e o
Cloud CDN cobra então os preços dele, de cloud.google.com/cdn/pricing, lidos em 2026-10-30:

| o que o Cloud CDN cobra | preço |
|---|---|
| transferência do cache, para a América do Sul, primeiros 10 TiB | 0,09 o GiB |
| a mesma, de 10 a 150 TiB | 0,06 o GiB |
| preenchimento do cache, origem e borda na América do Sul | 0,02 o GiB |
| consultas ao cache, todo `GET` e `HEAD` | 0,0075 por 10.000 |

A quarta linha do programa supõe que 19 de cada 20 downloads são respondidos pelo cache:

```
the same behind Cloud CDN             17.50     41.34   1,556.48   1,615.32
```

**As requisições subiram e a transferência caiu.** Cada um dos 53,7 milhões de downloads é uma
consulta ao cache a 0,0075 por 10.000, 40,27, mais do que custavam as leituras do próprio bucket; o
bucket ainda responde os 2,7 milhões de faltas, 1,07. Mas os 20 TiB agora saem pelo Cloud CDN, pela
escada mais baixa dele, 1.536,00, mais o 1 TiB de faltas que o cache buscou no bucket a 0,02, 20,48. O
mês cai de 2.394,17 para 1.615,32.

**Esse total deixa uma coisa de fora, e diz isso no rótulo.** O Cloud CDN serve um bucket por um
Application Load Balancer externo, que a aula 20 de `gcp-foundations` monta, e o balanceador tem
cobranças próprias na página de preços de rede: um preço por hora pelas regras de encaminhamento e um
preço por GiB que ele processa. Qual delas vale para o tráfego que o cache responde é uma questão para
as notas de rodapé daquela página, e nada aqui conferiu isso. Então os 1.615,32 são um piso, e a
comparação que eles sustentam é a forma: passando de alguns TiB por mês, um cache na frente de um
bucket público sai mais barato do que o bucket sozinho, e a taxa de acerto decide por quanto.

Há um segundo efeito que importa tanto quanto o preço: o bucket deixa de ser o endereço com que a
internet fala. Com o balanceador e o cache na frente, o bucket pode manter a prevenção de acesso
público da aula 4 e deixar só o cache lê-lo.
