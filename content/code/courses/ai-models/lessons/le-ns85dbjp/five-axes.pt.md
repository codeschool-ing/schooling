---
title: Cinco critérios, dois tipos
version: 1
---

Toda comparação de modelos termina nos mesmos cinco critérios: **qualidade**, **custo**,
**latência**, **contexto** e **privacidade**. O erro é tratá-los como cinco notas para somar. São
dois tipos diferentes de coisa, usados em dois passos diferentes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Escolher um modelo em dois passos. Primeiro filtrar: todo candidato passa pelos limites, que são privacidade, funcionalidades exigidas, janela de contexto e um piso de qualidade, e quem falha num deles sai. Depois ordenar o que sobrou pelas trocas, que são custo, latência e qualidade acima do piso.\"><defs><marker id=\"l4mat-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"95\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">todos os candidatos</text><rect x=\"160\" y=\"30\" width=\"190\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"255\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">1. filtrar</text><text x=\"255\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">limites: passa ou sai</text><rect x=\"180\" y=\"82\" width=\"150\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">privacidade</text><rect x=\"180\" y=\"112\" width=\"150\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">funcionalidades</text><rect x=\"180\" y=\"142\" width=\"150\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">contexto</text><rect x=\"180\" y=\"172\" width=\"150\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">piso de qualidade</text><rect x=\"380\" y=\"95\" width=\"100\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">lista curta</text><rect x=\"510\" y=\"30\" width=\"190\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2. ordenar</text><text x=\"605\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">trocas: melhor ou pior</text><rect x=\"530\" y=\"82\" width=\"150\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">custo</text><rect x=\"530\" y=\"112\" width=\"150\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">latência</text><rect x=\"530\" y=\"142\" width=\"150\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">qualidade acima do piso</text><rect x=\"530\" y=\"196\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a escolha</text><line x1=\"130\" y1=\"120\" x2=\"160\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l4mat-ah)\"></line><line x1=\"350\" y1=\"120\" x2=\"380\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l4mat-ah)\"></line><line x1=\"480\" y1=\"120\" x2=\"510\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l4mat-ah)\"></line><line x1=\"605\" y1=\"180\" x2=\"605\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l4mat-ah)\"></line><line x1=\"255\" y1=\"210\" x2=\"255\" y2=\"236\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#l4mat-ah)\"></line><text x=\"275\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">fora</text></svg>", "caption": "Limites tiram candidatos; trocas ordenam os que sobram. Nenhum preço compensa um limite em que o modelo falhou."}
```

**Alguns critérios são limites.** Os dados podem ir para um provedor ou não podem. O modelo suporta
saída estruturada ou não suporta. A janela comporta o prompt mais longo ou não comporta. Um modelo
que falha num desses não é um candidato pior, ele **não é candidato**, e nenhum preço compensa isso.
Privacidade quase sempre é um limite; contexto costuma ser; uma funcionalidade de que o programa
depende sempre é.

**Alguns critérios são trocas.** Acima da linha do aceitável, uma nota melhor de qualidade custa
alguma coisa em preço ou velocidade. Esses são os critérios para **ordenar**, quando a lista só tem
modelos que dariam conta do trabalho.

Então o método tem dois passos, nesta ordem:

1. **Filtrar** por tudo o que é limite. O que sobra daria conta do trabalho.
2. **Ordenar** o que sobrou: o mais barato, ou o mais rápido, entre os que passam da barra de
   qualidade.

A ordem importa porque evita a decisão ruim mais comum: escolher o modelo mais barato de uma tabela e
descobrir depois que ele não atendia a uma exigência que ninguém anotou. A seção 03 é a anotação.

## Qualidade é as duas coisas

A qualidade aparece nos dois passos, por isso ganha dois nomes. Há um **piso**, a acurácia abaixo da
qual a funcionalidade não vale a pena, e isso é um limite. Acima do piso, mais acurácia vale algum
dinheiro e algum tempo, e isso é uma troca. Para a tarefa de classificação da ana o piso pode ser
"concorda com uma pessoa em 35 dos 40 casos"; se 39 de 40 vale o dobro do preço é outra pergunta,
respondida na seção 08.

Nenhum dos dois números vem desta aula. **Qualidade se mede nos seus próprios casos**, que é a aula
5. Tudo aqui pode ser lido numa tabela; qualidade não.
