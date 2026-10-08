---
title: Raw, staging, marts: as camadas de um warehouse ELT
version: 1
---

Quando as linhas cruas estão no warehouse, a transformação deixa de ser um arquivo SQL. Ela vira
uma sequência deles, e o warehouse ganha camadas — **cada uma um schema, cada uma lida só pela
camada de cima**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-layers\" aria-label=\"Três camadas empilhadas dentro do warehouse. Embaixo, raw: as tabelas da origem como chegaram, escritas só pela extração. No meio, staging: uma tabela limpa por tabela crua. No topo, marts: fatos, dimensões e resumos, a única camada que os relatórios leem. As setas só sobem.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"170.0\" y=\"40.0\" width=\"380.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"190.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" font-weight=\"700\" fill=\"var(--amber)\">marts</text><text x=\"190.0\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fatos, dimensões, resumos</text><text x=\"570.0\" y=\"67.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lida pelos relatórios</text><path d=\"M360.0 118.0 L360.0 96.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"170.0\" y=\"120.0\" width=\"380.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"190.0\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" font-weight=\"700\" fill=\"var(--paper)\">staging</text><text x=\"190.0\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma tabela limpa por tabela de origem</text><text x=\"570.0\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lida pelos marts</text><path d=\"M360.0 198.0 L360.0 176.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"170.0\" y=\"200.0\" width=\"380.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"190.0\" y=\"218.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" font-weight=\"700\" fill=\"var(--paper)\">raw</text><text x=\"190.0\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a origem, como chegou</text><text x=\"570.0\" y=\"227.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">escrita pela extração</text><text x=\"90.0\" y=\"287.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">origens</text><path d=\"M90.0 277.0 L168.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"90.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">relatórios</text><path d=\"M168.0 62.0 L110.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path></svg>", "caption": "Cada camada é um schema, e cada uma lê só a de baixo. Um relatório que passa por cima do staging até o raw repete a limpeza, um pouco diferente."}
```

- **`raw`** guarda as linhas da origem como chegaram, uma tabela por tabela de origem, nada limpo.
  Só a extração escreve nela. Ninguém a lê, exceto a camada seguinte.
- **`staging`** guarda uma tabela limpa por tabela crua: colunas renomeadas para as convenções do
  warehouse, tipos corrigidos, lixo óbvio removido, a data de São Paulo calculada uma vez. Ainda uma
  linha por linha de origem. A lição 6 escreve essas.
- **`marts`** guarda aquilo sobre o que as pessoas perguntam: os fatos e dimensões que
  `warehouse-modeling` desenhou, e tabelas de resumo como a que esta lição montou. É a única camada
  que um painel deveria tocar.

O warehouse da Ana tem a primeira camada agora e nada mais:

```
ana@vm:~/etl$ psql -d wh -c "\dn"
      List of schemas
  Name  |       Owner       
--------+-------------------
 public | pg_database_owner
 raw    | ana
(2 rows)

ana@vm:~/etl$ psql -d wh -c "\dt raw.*"
          List of relations
 Schema |    Name     | Type  | Owner 
--------+-------------+-------+-------
 raw    | books       | table | ana
 raw    | order_lines | table | ana
 raw    | orders      | table | ana
(3 rows)
```

**A regra que faz as camadas funcionarem é a direção.** O staging lê o raw, os marts leem o
staging, e nada lê para cima nem pula uma camada. Um relatório que lê `raw.orders` direto repetiu
sem avisar a limpeza que o staging faz, um pouco diferente, e os dois vão discordar no dia em que
alguém consertar um deles.

## Por que os nomes importam

Equipes diferentes usam nomes diferentes — *bronze, silver, gold*; *landing, clean, presentation*;
*sources, intermediate, marts* — e qualquer um deles serve. **O schema de uma tabela deve dizer quem
pode lê-la e quem pode escrevê-la**, para que "posso mudar esta coluna?" tenha uma resposta que dá
para consultar. A Ponto Final usa `raw`, `staging` e `marts`: os dois últimos são os nomes que o
próprio guia do dbt para estruturar um projeto usa, e o dbt chega na lição 11 para cuidar exatamente
desta pilha.
