---
title: O cache que um build não tem, e quanto custa um minuto
version: 1
---

**Todo build do Cloud Build começa numa máquina nova, então por padrão não tem cache.** No seu laptop o
segundo `docker build` reaproveita as camadas do primeiro. No Cloud Build não existe primeiro: a máquina
que rodou o build de ontem não existe mais, e a de hoje baixa a imagem base e roda de novo cada
instrução do Dockerfile. Um build que leva quarenta segundos num laptop e quatro minutos na esteira
quase sempre é isso, e não uma máquina mais lenta.

Você pode ver a diferença no seu computador esvaziando o cache de build do Docker, que é o estado em
que uma máquina do Cloud Build começa, e construindo duas vezes:

```
ana@laptop:~/gcp/shop$ docker build --progress=plain -t shop-api:cold api 2>&1 | grep -E '^#[67] '
#6 [2/3] WORKDIR /app
#6 DONE 0.2s
#7 [3/3] COPY app.py .
#7 DONE 0.0s
ana@laptop:~/gcp/shop$ docker build --progress=plain -t shop-api:warm api 2>&1 | grep -E '^#[67] '
#6 [2/3] WORKDIR /app
#6 CACHED
#7 [3/3] COPY app.py .
#7 CACHED
```

O primeiro build rodou as duas instruções; o segundo achou os resultados delas no cache e não rodou
nenhuma. O Dockerfile da loja tem três linhas, então a diferença aqui é uma fração de segundo. Com uma
instalação de dependências no meio (um `pip install` de quarenta pacotes, um `npm ci`), são minutos,
em todo build, pagos em minutos de build.

## Três formas de trazer um cache de volta

Nenhuma delas foi executada aqui: precisam de um registro e de uma máquina de build.

- **`--cache-from` de uma imagem que você já enviou.** O primeiro passo do build baixa a última imagem,
  e `docker build --cache-from` trata as camadas dela como cache. Com BuildKit a imagem precisa ter sido
  construída com `--build-arg BUILDKIT_INLINE_CACHE=1`, que grava os metadados do cache nela. Custa um
  download no início de cada build e é a mais simples das três.
- **Kaniko com `--cache=true`.** O Kaniko é um construtor que o Google publicou, que constrói uma imagem
  sem daemon Docker e guarda cada camada que constrói como uma imagem num repositório próprio, então o
  build seguinte busca só as camadas de que precisa. O projeto dele não é mais mantido pelo Google, o
  que é um motivo para preferir a primeira opção num build novo.
- **Um build menor.** Copiar a lista de dependências e instalá-la **antes** de copiar o código faz com
  que uma mudança no código deixe a camada cara intacta, e isso vale para todas as opções acima. O
  Dockerfile da loja copia o `app.py` por último pelo mesmo motivo.

## Quanto custa um minuto de build

O Cloud Build cobra pelo minuto em que um build está rodando, do momento em que começa até terminar, e
não pelo tempo que espera na fila. Frações de minuto são cobradas por segundo. A página de preços dele,
lida em 30 de outubro de 2026, dá uma tabela para o pool padrão em todas as regiões que lista, São Paulo
entre elas:

| tipo de máquina | vCPUs | memória | USD por minuto |
|---|---|---|---|
| `e2-medium` | 1 | 4 GB | 0,003 |
| `e2-standard-2` (o padrão) | 2 | 8 GB | 0,006 |
| `e2-highcpu-8` | 8 | 8 GB | 0,0156 |
| `e2-highcpu-32` | 32 | 32 GB | 0,0624 |

**Cada conta de faturamento ganha 2.500 minutos de build gratuitos por mês** em `e2-standard-2` no pool
padrão, e a página diz que a franquia é promocional e pode mudar. Então o build da loja, de seis minutos,
rodando vinte vezes por dia útil em 22 dias, dá 440 × 6 = 2.640 minutos; menos os 2.500 gratuitos, são
140 minutos a 0,006 USD, ou 0,84 USD no mês. Sem os minutos gratuitos seriam 15,84 USD. Um cache que
levasse o build de seis minutos para dois cortaria os minutos para 880 e a conta, dentro da franquia
gratuita, para zero.

**Esses são preços de lista na data acima**, de uma página que muda sem aviso. A lição 21 é sobre os
descontos, e a lição 23 sobre ler a linha que um build acrescenta à fatura.
