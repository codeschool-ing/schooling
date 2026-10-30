---
title: O grafo de execução do BigQuery, pela documentação
version: 1
---

**O plano do BigQuery não é uma árvore de operadores num processo, é um grafo de estágios por muitos
slots.** Um estágio é um pedaço da consulta que muitos workers rodam em paralelo, cada um na sua parte da
entrada, e as linhas passam de um estágio para o seguinte pelo shuffle da aula 13. No console ele é a aba
**Execution graph** de um job terminado; na API e em `INFORMATION_SCHEMA.JOBS` é o plano de consulta do
job, uma entrada por estágio. Tudo nesta seção vem da documentação do Google sobre o plano de consulta e
sobre os insights de desempenho de consultas, e nada disso rodou: não há job do BigQuery neste
laboratório para abrir.

## A mesma consulta, em estágios

**As vendas de setembro por bairro rodariam em uns três estágios**, e os próprios exemplos da
documentação têm essa forma. A divisão exata é decisão do BigQuery e pode mudar; o que não muda é o
motivo de cada fronteira.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" aria-label=\"O grafo de execução do BigQuery para as vendas de setembro por bairro, em três estágios. S00, Input, rodado por muitos workers: READ de district e total_cents das partições de setembro de orders; AGGREGATE de somas parciais por bairro; WRITE no shuffle, por bairro. Uma seta marcada shuffle leva ao S01, Aggregate: READ do S00; AGGREGATE das somas por bairro; WRITE no shuffle. Uma segunda seta de shuffle leva ao S02, Output: READ do S01; SORT por vendas; WRITE da resposta. Ao lado de cada estágio, o que ele informa: registros lidos e escritos, tempo de espera, leitura, computação e escrita como média e máximo, bytes de shuffle e slot-milissegundos.\" data-fig=\"l16-stages\"><defs><marker id=\"l16-stages-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"12\" width=\"430\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">S00: Input</text><text x=\"434\" y=\"28\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">muitos workers</text><text x=\"36\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">READ $1, $2 FROM orders</text><text x=\"36\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">WHERE dt BETWEEN '2026-09-01' AND '2026-09-29'</text><text x=\"36\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">AGGREGATE SUM($2) GROUP BY $1</text><text x=\"36\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">WRITE TO __stage00_output</text><rect x=\"20\" y=\"150\" width=\"430\" height=\"82\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">S01: Aggregate</text><text x=\"434\" y=\"166\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">alguns workers</text><text x=\"36\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">READ FROM __stage00_output</text><text x=\"36\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">AGGREGATE SUM GROUP BY $1</text><text x=\"36\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">WRITE TO __stage01_output</text><rect x=\"20\" y=\"270\" width=\"430\" height=\"82\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"286\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">S02: Output</text><text x=\"434\" y=\"286\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um worker</text><text x=\"36\" y=\"306\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">READ FROM __stage01_output</text><text x=\"36\" y=\"322\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SORT BY sales DESC</text><text x=\"36\" y=\"338\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">WRITE TO __stage02_output</text><polyline points=\"235,112 235,148\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l16-stages-ah-0)\"></polyline><text x=\"245\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">shuffle, por bairro</text><polyline points=\"235,232 235,268\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l16-stages-ah-0)\"></polyline><text x=\"245\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">shuffle</text><rect x=\"480\" y=\"12\" width=\"220\" height=\"340\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"590\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">cada estágio informa</text><text x=\"496\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">registros lidos e escritos</text><text x=\"496\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">espera, leitura, computação, escrita:</text><text x=\"496\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">média e máximo</text><text x=\"496\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">bytes de shuffle, derramados</text><text x=\"496\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">slot-milissegundos</text></svg>", "caption": "Uma ilustração dos estágios, a partir dos exemplos da documentação do Google; nenhum job do BigQuery foi rodado, e o BigQuery decide a divisão real de cada consulta.", "same": ["shuffle"]}
```

**O primeiro estágio lê.** Os workers dele pegam cada um uma parte da tabela, as partições de setembro,
leem as duas colunas e já somam `total_cents` por bairro na própria parte: uma agregação parcial, para
que o que sai do estágio seja um punhado de linhas por worker e não todo pedido. **Eles escrevem essas
linhas no shuffle**, divididas por bairro, para que toda soma parcial de Pinheiros chegue ao mesmo
worker do estágio seguinte.

**O segundo estágio termina a agregação** a partir do que o primeiro escreveu, um bairro por grupo, e
**o terceiro ordena os oito resultados e escreve a resposta.** As fronteiras caem onde o trabalho precisa
de linhas que outro worker tem: um total por bairro precisa da parcial de todo worker para aquele bairro,
e uma ordenação precisa de todos os bairros.

## O que cada estágio informa

**Cada estágio lista seus passos**, e os nomes dos passos são os da documentação: `READ` de uma tabela ou
da saída de um estágio anterior, `COMPUTE` para expressões, `FILTER`, `AGGREGATE`, `SORT`, `JOIN`, e
`WRITE` para o shuffle ou para a saída. Lidos em ordem dentro de um estágio, e estágio por estágio a
partir do primeiro, são a mesma história da árvore do DuckDB lida de baixo.

**Cada estágio informa registros lidos e registros escritos**, e a razão entre eles é onde uma consulta
fica pequena. O primeiro estágio da consulta por bairro leria as linhas de setembro e escreveria poucas
linhas por worker; essa queda é a agregação parcial funcionando. Um estágio que escreve tantas linhas
quanto lê, para um shuffle, está movendo a tabela inteira pela rede.

**Cada estágio informa o tempo como espera, leitura, computação e escrita, cada um como média e máximo
entre os workers.** A média é o worker típico e o máximo é o mais lento, e o estágio termina quando o
mais lento termina. Um máximo muito acima da média é **skew**: um worker recebeu muito mais que os
outros, em geral porque um valor da chave do shuffle é muito mais comum que os demais. Os insights de
desempenho da documentação chamam isso de **partition skew**, e a cura é a que a distribuição de qualquer
sistema paralelo precisa: uma chave cujos valores se espalhem melhor, ou um filtro que tire o gigante
antes do shuffle.

**Cada estágio informa os bytes de shuffle que escreveu, e quantos deles foram derramados em disco.** O
shuffle fica primeiro em memória; um estágio que escreve mais que a memória disponível derrama o resto, e
roda mais devagar. Os insights da documentação chamam a causa de **insufficient shuffle quota**.

**E cada estágio informa o seu tempo de slot**, em slot-milissegundos. Somado pelos estágios, é o
`total_slot_ms` do job, o número que a aula 14 usou: numa reserva, é o quanto a consulta custou; sob
demanda, é o quanto ela usou sem ser cobrada por isso. Dividido pelos milissegundos decorridos do job, é
o número médio de slots que a consulta ocupou enquanto rodava. Uma consulta de 120.000 slot-ms que levou
quatro segundos ocupou em média 30 slots.

## As perguntas para levar a ele

**Qual estágio levou o tempo, e ele estava esperando ou trabalhando?** Uma espera longa com pouca leitura
ou computação é **slot contention**, outro insight da documentação: a consulta estava pronta e os slots
estavam ocupados com outras consultas, o que numa reserva é motivo para olhar o máximo dela e sob demanda
para olhar o que mais o projeto roda na mesma hora.

**Onde as linhas caíram?** O estágio em que os registros escritos ficam muito abaixo dos lidos é onde a
consulta ficou barata de mover. Se essa queda vem tarde, depois de um join que multiplicou as linhas, o
filtro ou a agregação deveria vir antes.

**Algum estágio escreveu a entrada inteira no shuffle?** Isso é um join ou uma agregação numa chave para a
qual o dado não estava arrumado, e os bytes desse shuffle são pagos em tempo sob demanda e em slots numa
reserva.

**Nenhuma dessas perguntas é sobre os bytes cobrados.** Sob demanda, a conta foi fixada antes de o grafo
existir, pelas colunas e pelas partições. O grafo de execução explica tempo e slots, e é por isso que a
próxima seção volta aos bytes e pergunta o que um motor de fato lê para responder uma consulta.
