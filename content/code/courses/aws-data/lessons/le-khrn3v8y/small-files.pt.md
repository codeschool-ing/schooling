---
title: O particionamento, e o custo dos arquivos pequenos
version: 1
---

**Uma chave de partição é escolhida pelas consultas, e limitada pelos arquivos que deixa.** A chave
deve ser a coluna que a maioria das perguntas filtra, porque um filtro na chave abre só os prefixos
que servem, que é o que a lição 15 mediu. Mas cada valor distinto da chave é pelo menos um arquivo, e
um arquivo tem um custo próprio seja o que for que guarde: uma requisição para abri-lo, um rodapé
para ler, uma linha no catálogo. Uma chave com valores demais compra seletividade com arquivos
pequenos demais para valerem a abertura.

Três candidatas nos pedidos da Quitanda, e quantos valores cada uma tem:

```
ana@laptop:~/aws$ python3 ask.py "SELECT count(DISTINCT dt) AS days, count(DISTINCT neighbourhood) AS neighbourhoods, count(DISTINCT customer_id) AS customers FROM orders"
┌───────┬────────────────┬───────────┐
│ days  │ neighbourhoods │ customers │
│ int64 │     int64      │   int64   │
├───────┼────────────────┼───────────┤
│    31 │             16 │     39979 │
└───────┴────────────────┴───────────┘

read from S3: 5,880,348 bytes in 93 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"Duas árvores de prefixos sob a tabela orders. À esquerda, particionada por dt: 31 prefixos como dt=2026-10-01, cada um com um arquivo de cerca de 400 KB, e uma pergunta sobre um dia abre um arquivo. À direita, particionada por customer_id: 39.979 prefixos como customer_id=c-1, cada um com um arquivo de 318 bytes de dados em média, e uma pergunta sobre um dia abre os 39.979 arquivos.\" data-fig=\"l19-partitions\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">particionado por dt</text><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">orders/</text><line x1=\"30\" y1=\"46\" x2=\"30\" y2=\"74\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"30\" y1=\"74\" x2=\"44\" y2=\"74\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"44\" y=\"64\" width=\"300\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"52\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">dt=2026-10-01/orders.parquet</text><line x1=\"30\" y1=\"46\" x2=\"30\" y2=\"102\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"30\" y1=\"102\" x2=\"44\" y2=\"102\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"44\" y=\"92\" width=\"300\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"52\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">dt=2026-10-02/orders.parquet</text><line x1=\"30\" y1=\"46\" x2=\"30\" y2=\"158\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"30\" y1=\"158\" x2=\"44\" y2=\"158\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"44\" y=\"148\" width=\"300\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"52\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">dt=2026-10-31/orders.parquet</text><text x=\"52\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">… 31 dias</text><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">31 prefixos, um arquivo cada</text><text x=\"20\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cerca de 400 KB por arquivo</text><text x=\"20\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">uma pergunta sobre um dia abre 1 arquivo</text><text x=\"370\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">particionado por customer_id</text><text x=\"370\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">orders/</text><line x1=\"380\" y1=\"46\" x2=\"380\" y2=\"74\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"380\" y1=\"74\" x2=\"394\" y2=\"74\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"394\" y=\"64\" width=\"300\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"402\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">customer_id=c-1/orders.parquet</text><line x1=\"380\" y1=\"46\" x2=\"380\" y2=\"102\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"380\" y1=\"102\" x2=\"394\" y2=\"102\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"394\" y=\"92\" width=\"300\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"402\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">customer_id=c-2/orders.parquet</text><line x1=\"380\" y1=\"46\" x2=\"380\" y2=\"158\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"380\" y1=\"158\" x2=\"394\" y2=\"158\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"394\" y=\"148\" width=\"300\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"402\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">customer_id=c-17/orders.parquet</text><text x=\"402\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">… 39.979 clientes</text><text x=\"370\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">39.979 prefixos, um arquivo cada</text><text x=\"370\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">318 bytes de dados por arquivo</text><text x=\"370\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">uma pergunta sobre um dia abre 39.979 arquivos</text></svg>", "caption": "O mesmo mês sob duas chaves de partição. Por dia, poucos arquivos que vale abrir; por cliente, dezenas de milhares de arquivos, cada um menor que o próprio rodapé."}
```

**31 dias, 16 bairros, 39.979 clientes.** Por `dt` cada partição é um dia de uns 400 KB num arquivo, e
toda pergunta com uma data, que são quase todas, abre só os dias dela. Por `neighbourhood`, 16
partições de um mês cada, e uma pergunta sobre um bairro pula os outros 15, mas uma pergunta sobre
ontem abre os 16. Por `customer_id`, o histórico de um cliente é um único prefixo, e o mês são 39.979
deles: 12.703.975 bytes em 39.979 arquivos são 318 bytes de dados por arquivo, menos que um rodapé de
Parquet, e uma pergunta sobre as vendas de outubro abre cada um deles.

## Arquivos pequenos, medidos

`customer_id` não foi gravado como arranjo, porque 39.979 objetos levariam mais tempo para gravar que
o resto desta lição. O arranjo `small-files` mostra a mesma falha num tamanho que dá para rodar: cada
dia cortado em 96 arquivos, que é o que um gravador que descarrega a cada quarto de hora deixa para
trás. A pergunta sobre as vendas de outubro, depois uma pergunta sobre um dia:

```
ana@laptop:~/aws$ python3 ask.py -t t=quitanda-curated-prod/layouts/small-files/:parquet "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM t GROUP BY payment ORDER BY reais DESC" | tail -2
read from S3: 27,000,299 bytes in 5952 GET requests to 2976 objects
Athena would bill 26 MB (whole MB, 10 MB minimum): 0.000223 USD at 9.00 USD per TB
```

```
ana@laptop:~/aws$ python3 ask.py -t t=quitanda-curated-prod/layouts/small-files/:parquet "SELECT count(*) AS orders FROM t WHERE dt = '2026-10-15' AND payment = 'pix'" | tail -2
read from S3: 714,177 bytes in 192 GET requests to 96 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
ana@laptop:~/aws$ python3 ask.py "SELECT count(*) AS orders FROM orders WHERE dt = '2026-10-15' AND payment = 'pix'"
┌────────┐
│ orders │
│ int64  │
├────────┤
│  10885 │
└────────┘

read from S3: 71,697 bytes in 2 GET requests to 1 object
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

**O mês leu 27.000.299 bytes em 5.952 requisições, mais bytes que os 22.068.273 que o arranjo
guarda.** Cada arquivo tem menos de 64 KiB, então a primeira leitura que o PyArrow faz do fim dele, a
leitura de rodapé que a lição 15 encontrou, buscou o arquivo inteiro, e os column chunks foram então
buscados de novo. A mesma pergunta feita a um arquivo por dia leu 5.102.048 bytes em 62 requisições.
Um dia foram 714.177 bytes em 192 requisições contra 71.697 em 2, pelos mesmos 10.885 pedidos.
**Arquivos pequenos desfazem o formato colunar**: passado um ponto, a parte da conta que paga por
abrir arquivos é maior que a parte que paga por dados.

## Quanto custam as requisições

As leituras do Athena são requisições GET contra os seus buckets, cobradas na sua conta como as de
qualquer outro:

```
ana@laptop:~/aws$ python3 prices.py s3 | grep -E 'GET and|PUT'
  Standard: PUT, COPY, POST, LIST                       0.00700  per 1,000
  Standard: GET and the rest                            0.00056  per 1,000
ana@laptop:~/aws$ python3 prices.py athena | tail -1
  SQL queries, per TB scanned                           9.00000  TB
```

A 0,00056 dólar por mil GETs, a pergunta do mês custa 5.952 × 0,00056 / 1.000 = 0,0033 dólar em
requisições nos arquivos pequenos, e 0,000035 com um arquivo por dia. O painel da lição 15, perguntando
a cada dez minutos, pergunta 4.464 vezes em outubro: **14,88 dólares de requisições GET contra 0,15**,
antes da conta do próprio Athena pelos bytes. A listagem também é cobrada, pelo preço maior do
`LIST`, uma requisição por mil chaves.

A orientação da AWS para o Athena são arquivos de pelo menos uns 128 MB, que um lago pequeno como este
nunca alcança e um lago do tamanho da Quitanda daqui a alguns anos alcança. A cura para arquivos
pequenos é um job que reescreve cada partição em menos arquivos, e maiores, depois que ela fecha, o
que se chama compactação; o `etl.py` da lição 17 é um, já que grava cada dia como um arquivo seja o
que for que tenha chegado. A cura para uma chave com valores demais é uma chave mais grossa, `dt` e
não `customer_id`, com a coluna fina ordenada dentro dos arquivos para as estatísticas da seção
anterior usarem.
