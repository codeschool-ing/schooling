---
title: As duas decisões, com preço juntas
version: 1
---

**Formato e particionamento se multiplicam, e a conta é o produto deles.** O formato decide que parte
de cada arquivo uma pergunta lê; o particionamento decide quantos arquivos ela abre e de que tamanho.
Toda medida desta lição e da lição 15 é uma célula desse produto, e lado a lado elas deixam clara a
escolha para o lago da Quitanda.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 212\" role=\"img\" aria-label=\"Um gráfico de barras dos bytes lidos do S3 para uma pergunta em sete arranjos. CSV 40.641.097 bytes. CSV com gzip 8.421.323. Parquet sem codec 6.481.669. Parquet com Snappy 5.102.048. Parquet com zstd 4.280.951. ORC com zstd 2.820.788. Parquet em 96 arquivos por dia 27.000.299. O CSV puro e os arquivos pequenos são as duas barras longas.\" data-fig=\"l19-bytes\"><text x=\"180\" y=\"29\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">CSV</text><rect x=\"190\" y=\"20\" width=\"400.0\" height=\"18\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"598.0\" y=\"29\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40.641.097 bytes</text><text x=\"180\" y=\"55\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">CSV, gzip</text><rect x=\"190\" y=\"46\" width=\"82.88480008302926\" height=\"18\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"280.8848000830293\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8.421.323 bytes</text><text x=\"180\" y=\"81\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Parquet, sem codec</text><rect x=\"190\" y=\"72\" width=\"63.79423271965321\" height=\"18\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"261.7942327196532\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6.481.669 bytes</text><text x=\"180\" y=\"107\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Parquet, Snappy</text><rect x=\"190\" y=\"98\" width=\"50.215652397375\" height=\"18\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"248.215652397375\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5.102.048 bytes</text><text x=\"180\" y=\"133\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Parquet, zstd</text><rect x=\"190\" y=\"124\" width=\"42.134207154890525\" height=\"18\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"240.13420715489053\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4.280.951 bytes</text><text x=\"180\" y=\"159\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ORC, zstd</text><rect x=\"190\" y=\"150\" width=\"27.76291200997847\" height=\"18\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"225.76291200997846\" y=\"159\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2.820.788 bytes</text><text x=\"180\" y=\"185\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Parquet, 96 arquivos por dia</text><rect x=\"190\" y=\"176\" width=\"265.7438011577296\" height=\"18\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"463.7438011577296\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">27.000.299 bytes</text><line x1=\"190\" y1=\"16\" x2=\"190\" y2=\"202\" stroke=\"var(--wire)\" stroke-width=\"1\"></line></svg>", "caption": "A mesma pergunta, as vendas de outubro por forma de pagamento, feita a sete arranjos dos mesmos pedidos: os bytes que cada um leu do S3, medidos pelo ask.py, numa escala linear.", "same": ["CSV", "CSV, gzip", "Parquet, Snappy", "Parquet, zstd", "ORC, zstd"]}
```

## A pergunta do mês, mil vezes maior

Neste tamanho de lago todo arranjo menos dois paga o mínimo de 10 MB do Athena, então a conta
esconde a diferença, como escondeu na lição 15. Multiplicada por mil, a leitura de cada arranjo para
a pergunta sobre as vendas de outubro vira isto, com o preço da linha do Athena da tabela e feita
4.464 vezes por mês pelo painel:

| arranjo | lido aqui | uma consulta ×1.000 | MB cobrados | USD por consulta | USD por mês |
|---|---:|---:|---:|---:|---:|
| CSV | 40.641.097 | 40,6 GB | 38.759 | 0,333 | 1.485,04 |
| CSV, gzip | 8.421.323 | 8,4 GB | 8.032 | 0,069 | 307,74 |
| Parquet, sem codec | 6.481.669 | 6,5 GB | 6.182 | 0,053 | 236,86 |
| Parquet, Snappy | 5.102.048 | 5,1 GB | 4.866 | 0,042 | 186,44 |
| Parquet, zstd | 4.280.951 | 4,3 GB | 4.083 | 0,035 | 156,44 |
| ORC, zstd | 2.820.788 | 2,8 GB | 2.691 | 0,023 | 103,11 |
| Parquet, 96 arquivos por dia | 27.000.299 | 27,0 GB | 25.750 | 0,221 | 986,61 |

**O pior arranjo colunar custa dois terços do CSV, e o melhor um catorze avos.** Os arquivos pequenos
jogaram fora a maior parte do que o Parquet tinha ganhado, e ainda pagam as requisições GET por cima,
14,88 dólares por mês neste tamanho, o que mil vezes maior seria muito mais. A conta multiplica a
leitura medida por mil, o que é justo para os dados das colunas e generoso com os arquivos pequenos,
cujos rodapés se multiplicariam com a quantidade deles; é um tamanho de conta, não uma fatura.

## Como deve ser o lago da Quitanda

As medidas dão uma resposta, e nada nela é exótico:

- **Parquet, com zstd ou com Snappy**, na camada curated. A diferença entre os dois é de 30 dólares
  por mês aqui, e a diferença entre qualquer um deles e o CSV é de quase 1.300.
- **particionado por `dt`**, a coluna que quase toda pergunta nomeia, grossa o bastante para que um
  dia seja um arquivo que vale abrir;
- **um arquivo por dia, ou tão poucos quanto o volume permitir**, mantido assim pelo job que grava,
  para que a linha dos arquivos pequenos nunca apareça;
- **ordenado por `hour` dentro de cada arquivo**, o filtro mais comum depois, para as estatísticas
  dos grupos de linhas.

**As duas decisões são tomadas quando os dados são gravados e pagas toda vez que são lidos**, e é por
isso que vale acertá-las antes de o lago ficar grande. Mudar qualquer uma depois quer dizer reescrever
todo arquivo sob a tabela, um CTAS ou um job que lê o histórico inteiro uma vez. Com um mês, isso é uma execução de um job pequeno; com três anos, é a maior conta que o lago vai rodar.
