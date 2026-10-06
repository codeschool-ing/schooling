---
title: Três escolas de projeto de warehouse
version: 1
---

Onde normalizar e onde não normalizar também divide a área em escolas, e você vai encontrar as três
em descrições de vaga e em revisões de projeto.

**Inmon: normalize o warehouse, desnormalize os marts.** O warehouse de Bill Inmon, a *corporate
information factory*, é um banco integrado e normalizado, perto da terceira forma normal, com o histórico
da empresa inteira. Os departamentos não o consultam diretamente; recebem **data marts** construídos a
partir dele, e os marts são dimensionais. O núcleo normalizado é a fonte única da verdade, e é projetado
para sobreviver a qualquer mudança no que o negócio pergunta.

**Kimball: dimensional do começo ao fim, unido por dimensões conformadas.** O warehouse de Ralph Kimball é
a coleção de estrelas, uma por processo de negócio, compartilhando dimensões conformadas pela matriz de
barramento. Não há camada normalizada no meio que os relatórios não possam ler. O que as lições 2 a 5
construíram é o projeto de Kimball.

**Data Vault: normalize mais, por histórico e auditoria.** O Data Vault de Dan Linstedt divide tudo em
três tipos de tabela, guarda toda versão de tudo com a carga que a trouxe, e deixa a forma para
relatórios para uma camada posterior, que em geral são estrelas de Kimball. A próxima seção constrói um
fragmento.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Três colunas, uma por escola, cada uma desenhada em camadas das origens embaixo até o que as pessoas consultam em cima. Inmon: origens, depois um warehouse corporativo normalizado, depois data marts dimensionais. Kimball: origens, depois estrelas com dimensões conformadas, consultadas diretamente. Data Vault: origens, depois hubs, links e satélites, depois marts dimensionais construídos a partir do vault. As três terminam em tabelas dimensionais.\"><defs><marker id=\"ah-three-schools\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"125\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">Inmon</text><rect x=\"20\" y=\"45\" width=\"210\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">data marts dimensionais</text><line x1=\"125\" y1=\"118\" x2=\"125\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-three-schools)\"></line><rect x=\"20\" y=\"120\" width=\"210\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">warehouse normalizado (3FN)</text><line x1=\"125\" y1=\"193\" x2=\"125\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-three-schools)\"></line><rect x=\"20\" y=\"195\" width=\"210\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sistemas de origem</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">Kimball</text><rect x=\"255\" y=\"45\" width=\"210\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">estrelas, lidas direto</text><line x1=\"360\" y1=\"118\" x2=\"360\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-three-schools)\"></line><rect x=\"255\" y=\"120\" width=\"210\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">dimensões conformadas</text><line x1=\"360\" y1=\"193\" x2=\"360\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-three-schools)\"></line><rect x=\"255\" y=\"195\" width=\"210\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sistemas de origem</text><text x=\"595\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">Data Vault</text><rect x=\"490\" y=\"45\" width=\"210\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">data marts dimensionais</text><line x1=\"595\" y1=\"118\" x2=\"595\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-three-schools)\"></line><rect x=\"490\" y=\"120\" width=\"210\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hubs, links, satélites</text><line x1=\"595\" y1=\"193\" x2=\"595\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-three-schools)\"></line><rect x=\"490\" y=\"195\" width=\"210\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sistemas de origem</text><text x=\"360\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">as pessoas consultam a camada de cima; as escolas diferem no que fica embaixo</text></svg>", "caption": "Inmon, Kimball e Data Vault: onde fica a camada normalizada, e o que as pessoas leem.", "same": ["Data Vault", "Inmon", "Kimball"]}
```

Elas discordam sobre **onde fica a camada normalizada e quem a lê**, e concordam em mais do que as
discussões sugerem. As três terminam em tabelas dimensionais para as pessoas consultarem. As três guardam
histórico. As diferenças são sobre o que fica embaixo:

| | Inmon | Kimball | Data Vault |
|---|---|---|---|
| o núcleo integrado | normalizado, perto da 3FN | estrelas conformadas | hubs, links e satélites |
| o que as pessoas consultam | marts dimensionais construídos do núcleo | as estrelas diretamente | marts construídos do vault |
| mais forte quando | muitas origens, um modelo corporativo estável desejado primeiro | entregar respostas úteis rápido, processo a processo | as origens mudam com frequência; trilha de auditoria completa exigida |
| principal custo | um modelo grande a construir antes do primeiro relatório | conformar dimensões exige disciplina entre times | muito mais tabelas, e uma segunda camada a construir |

**Para a Ana, na Ponto Final, Kimball é o encaixe óbvio**: um sistema de origem, poucos processos de
negócio, e um gerente que quer respostas neste trimestre. Um banco com quarenta sistemas de origem e
auditores perguntando que carga gravou qual número poderia, com razão, escolher outro.
