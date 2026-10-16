---
title: Servindo arquivos para a internet
version: 1
---

**Bytes que saem da AWS para a internet são a coisa mais cara que o S3 faz**, e são cobrados do dono do
bucket, seja quem for que os pediu. As imagens de um site público, os downloads de um aplicativo, um
relatório que um cliente baixa: cada byte que sai é medido a 0,15000 por GB nos primeiros 10 TB do mês
em São Paulo, quase quatro vezes o preço de guardar esse byte por um mês.

As imagens de produtos da Quitanda somam 500 GB, e o aplicativo e o site servem cerca de 20 TB delas
por mês. Essa é a terceira linha do programa da seção anterior:

```
500 GB of images, 20 TB out         20.25     29.12   2,949.12   2,998.49
```

**O armazenamento é 20,25 de um mês que custa 2.998,49.** As requisições, 52 milhões de `GET`s, dão
29,12. Os outros 2.949,12 são a transferência, com o preço calculado faixa a faixa pelo `egress()`: os
primeiros 10.240 GB a 0,15000 dão 1.536,00, e os 10.240 GB restantes a 0,13800 da segunda faixa dão
1.413,12. As faixas baixam o preço por GB conforme o volume do mês cresce, e uma empresa precisa mandar
150 TB num mês antes de chegar à mais barata, 0,11400.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O preço por GB da transferência do S3 de São Paulo para a internet, em degraus de volume mensal: 0,150 nos primeiros 10 TB, 0,138 até 50 TB, 0,126 até 150 TB e 0,114 acima disso. A Quitanda, com 20 TB por mês, está no segundo degrau: 2.949,12 USD, em média 0,144 por GB.\" data-fig=\"l05-tiers\"><path d=\"M80.0 250.0 L680.0 250.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"72.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,10</text><path d=\"M80.0 183.3 L680.0 183.3\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"72.0\" y=\"183.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,12</text><path d=\"M80.0 116.7 L680.0 116.7\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"72.0\" y=\"116.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,14</text><path d=\"M80.0 50.0 L680.0 50.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"72.0\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,16</text><path d=\"M80.0 250.0 L680.0 250.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 250.0 L80.0 255.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M110.0 250.0 L110.0 255.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"110.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><path d=\"M230.0 250.0 L230.0 255.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"230.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><path d=\"M530.0 250.0 L530.0 255.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"530.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">150</text><path d=\"M680.0 250.0 L680.0 255.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"680.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><text x=\"680.0\" y=\"288.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">TB enviados à internet num mês</text><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">USD por GB, nessa faixa</text><path d=\"M80.0 83.3 L110.0 83.3 L110.0 123.3 L230.0 123.3 L230.0 163.3 L530.0 163.3 L530.0 203.3 L680.0 203.3\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"114.0\" y=\"71.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,150</text><text x=\"170.0\" y=\"111.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,138</text><text x=\"380.0\" y=\"151.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,126</text><text x=\"605.0\" y=\"191.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,114</text><path d=\"M140.0 129.3 L140.0 246.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><circle cx=\"140.0\" cy=\"123.3\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"148.0\" y=\"208.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">Quitanda, 20 TB: 2.949,12 USD</text><text x=\"148.0\" y=\"224.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">em média 0,144 por GB</text></svg>", "caption": "A transferência para a internet é uma escada, não uma tarifa: cada degrau só vale para os GB que caem nele. Os 20 TB da Quitanda pagam o primeiro degrau inteiro e metade do segundo."}
```

A AWS também dá a toda conta uma franquia mensal de transferência para a internet, que a tabela de
preços não imprime; a lição 10 de `cloud`, "As linhas que ninguém espera", a mostra como 100 GB. Contra
20 TB, é meio por cento.

## Atrás do CloudFront

**A transferência do S3 para o CloudFront é de graça**: a linha `to CloudFront` da tabela é 0,00000. O
CloudFront, da lição 23 de `aws-foundations`, é a rede de pontos de presença da AWS. Ele busca um objeto
no bucket uma vez, guarda uma cópia perto de quem vê, e serve os mil pedidos seguintes a partir da
cópia. O bucket vê um `GET` em vez de mil e não manda nada para a internet ele mesmo.

A quarta linha do programa supõe que 95 de cada 100 downloads saem do cache do CloudFront, então o
bucket responde a 2,6 milhões de `GET`s, que custam 1,46:

```
the same behind CloudFront          20.25      1.46          -          -
```

**Os traços são honestos.** A transferência do próprio S3 para o CloudFront é 0,00, e o CloudFront
então cobra o preço dele para entregar os bytes a quem vê, por GB e por requisição. Esse preço está na
oferta do CloudFront, que a tabela de preços deste curso não lê, então o programa não imprime
transferência nem total. O que a linha mostra é a metade que é do S3: os 2.949,12 da linha de cima
saem da conta do bucket. Se o todo fica mais barato depende do preço do CloudFront e da parte dos
downloads que o cache dele responde, e nenhum dos dois foi conferido aqui.

Há um segundo efeito que importa tanto quanto: o bucket deixa de ser o endereço com que a internet
fala. Com o CloudFront na frente, o bucket pode continuar privado atrás do Block Public Access da lição
4, com uma política de bucket que deixa só o CloudFront ler.
