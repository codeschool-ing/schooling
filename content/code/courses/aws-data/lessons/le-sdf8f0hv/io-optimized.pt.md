---
title: Standard ou I/O-Optimized, e onde cai a linha
version: 1
---

**O armazenamento do Aurora é cobrado de um de dois jeitos, escolhido por cluster, e a escolha leva dinheiro
de uma linha da conta para outra.** O **Standard** cobra um preço menor pelas instâncias e pelos gigabytes, e
depois cobra cada I/O: cada página que o engine lê da camada de armazenamento porque não estava na memória, e
cada escrita, contada em unidades de 4 KiB. O **I/O-Optimized** cobra mais pelas instâncias e pelos gigabytes
e nada pelo I/O. Qual dos dois sai mais barato é aritmética sobre três números, e o bloco Aurora da tabela de
preços, na seção anterior, tem todos eles:

| | Standard | I/O-Optimized |
|---|---|---|
| `db.r7g.large`, por instância-mês | 0,43884 × 730 = 320,35 | 0,57081 × 730 = 416,69 |
| armazenamento, por GB-mês | 0,19 | 0,428 |
| I/O, por milhão de requisições | 0,28 | 0 |

## O cluster da Quitanda

**Um writer e uma réplica, as duas `db.r7g.large`, e um volume de 500 GB.** A parte fixa de cada conta:

- Standard: 2 × 320,35 + 500 × 0,19 = 640,70 + 95,00 = 735,70 por mês, mais 0,28 por milhão de I/Os;
- I/O-Optimized: 2 × 416,69 + 500 × 0,428 = 833,38 + 214,00 = 1.047,38 por mês, seja qual for o I/O.

**O I/O-Optimized custa 311,68 a mais antes de um único I/O**, então ele compensa quando o I/O teria custado
mais que isso: 311,68 / 0,28 = 1.113,14 milhões de I/Os por mês, cerca de 1,1 bilhão. Abaixo disso, o Standard
é mais barato; acima, o I/O-Optimized, por 0,28 a cada milhão a mais.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Custo mensal de um cluster Aurora PostgreSQL de duas instâncias db.r7g.large e 500 GB, contra milhões de requisições de I/O por mês, de 0 a 2.000. O Standard começa em 735,70 e sobe 0,28 por milhão de I/Os, chegando a 1.295,70 em 2.000 milhões. O I/O-Optimized é constante em 1.047,38. As duas linhas se cruzam em 1.113 milhões de I/Os por mês.\" data-fig=\"l08-breakeven\"><defs><marker id=\"arr-l08-breakeven\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"90.0\" y1=\"240.0\" x2=\"660.0\" y2=\"240.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"90.0\" y1=\"240.0\" x2=\"90.0\" y2=\"30.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"86.0\" y1=\"240.0\" x2=\"90.0\" y2=\"240.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"82.0\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">600</text><line x1=\"86.0\" y1=\"187.5\" x2=\"90.0\" y2=\"187.5\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"82.0\" y=\"187.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">800</text><line x1=\"86.0\" y1=\"135.0\" x2=\"90.0\" y2=\"135.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"82.0\" y=\"135.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1.000</text><line x1=\"86.0\" y1=\"82.5\" x2=\"90.0\" y2=\"82.5\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"82.0\" y=\"82.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1.200</text><line x1=\"86.0\" y1=\"30.0\" x2=\"90.0\" y2=\"30.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"82.0\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1.400</text><line x1=\"90.0\" y1=\"240.0\" x2=\"90.0\" y2=\"244.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"90.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><line x1=\"232.5\" y1=\"240.0\" x2=\"232.5\" y2=\"244.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"232.5\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">500</text><line x1=\"375.0\" y1=\"240.0\" x2=\"375.0\" y2=\"244.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"375.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1.000</text><line x1=\"517.5\" y1=\"240.0\" x2=\"517.5\" y2=\"244.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"517.5\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1.500</text><line x1=\"660.0\" y1=\"240.0\" x2=\"660.0\" y2=\"244.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"660.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2.000</text><text x=\"375.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">milhões de requisições de I/O por mês</text><text x=\"20.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">USD por mês</text><line x1=\"90.0\" y1=\"204.4\" x2=\"660.0\" y2=\"57.4\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"90.0\" y1=\"122.6\" x2=\"660.0\" y2=\"122.6\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"503.2\" y=\"75.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Standard</text><text x=\"175.5\" y=\"114.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">I/O-Optimized</text><line x1=\"407.2\" y1=\"122.6\" x2=\"407.2\" y2=\"240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><circle cx=\"407.2\" cy=\"122.6\" r=\"4\" fill=\"var(--paper)\" stroke=\"none\"></circle><text x=\"415.2\" y=\"140.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1.113 milhões</text><text x=\"96.0\" y=\"216.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">735,70</text></svg>", "caption": "Duas db.r7g.large e 500 GB: abaixo de cerca de 1,1 bilhão de I/Os por mês o Standard é mais barato, acima dele o I/O-Optimized.", "same": ["Standard", "I/O-Optimized"]}
```

**A linha muda com o formato do cluster.** Com uma instância em vez de duas, a diferença fixa é 96,34 +
119,00 = 215,34, e o ponto de equilíbrio cai para 215,34 / 0,28 = 769,07 milhões de I/Os. Cada réplica a mais
aumenta o adicional das instâncias em 96,34 e empurra a linha 344 milhões de I/Os para cima, enquanto cada GB
de armazenamento soma 0,238 à diferença. A orientação da própria AWS põe a troca mais ou menos no ponto em que
o I/O é um quarto da conta do Aurora. Para as duas instâncias da Quitanda, a estes preços de São Paulo, o
ponto de equilíbrio é onde o I/O é 311,68 de uma conta de 1.047,38, 30%: perto dessa regra prática, e não em
cima dela, e é por isso que vale fazer a conta com os seus números.

## De onde vem o número de I/O

**Não do moto**, que não conta nenhum, e não de um palpite. Numa conta de verdade, as métricas
`VolumeReadIOPs` e `VolumeWriteIOPs` do cluster no CloudWatch contam os I/Os cobrados, e o Cost Explorer
mostra a linha de I/O da conta separada, como a lição 13 do `aws-foundations` mostra como ler. Um mês desses
números é a entrada da conta acima, e a troca é feita com um `modify-db-cluster --storage-type`, que a AWS
documenta como permitido uma vez a cada trinta dias na direção do I/O-Optimized e a qualquer momento na volta.

**O que reduz o I/O também move a decisão.** Uma consulta que lê a tabela `orders` inteira porque falta um
índice é, no Aurora Standard, uma linha na conta por página que ela lê, e consertar o índice conserta a conta.
O I/O-Optimized esconde esse custo, o que é um conforto e um ponto cego ao mesmo tempo: a consulta continua
igualmente lenta, e nada na fatura diz isso mais. A regra da lição 6 vale aqui também, e aqui ela tem preço: o
projeto continua sendo seu.
