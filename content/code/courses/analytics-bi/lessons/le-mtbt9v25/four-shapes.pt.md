---
title: Quatro formatos de ferramenta de BI
version: 1
---

Há dezenas de ferramentas de BI, e compará-las recurso por recurso é um jeito de passar uma semana e
não lembrar de nada. Elas ficam mais fáceis de distinguir por duas perguntas:

- **Quem constrói?** Um analista arrastando campos numa tela, um modelador escrevendo definições em
  arquivos, qualquer pessoa clicando em menus, ou um programador escrevendo código.
- **Onde as definições moram?** Em cada pasta de trabalho, num modelo central, nas perguntas salvas da
  própria ferramenta, ou no código do app.

As quatro ferramentas desta aula estão em quatro respostas diferentes, e é por isso que foram
escolhidas:

| ferramenta | quem constrói | onde as definições moram | quanto custa |
|---|---|---|---|
| **Tableau** | analistas, numa tela visual | em cada pasta de trabalho, ou em fontes de dados compartilhadas | licenças por pessoa; uma edição gratuita publica em público |
| **Looker** | modeladores escrevem LookML; os outros exploram | num modelo central, em arquivos guardados no git | um contrato corporativo |
| **Metabase** | qualquer pessoa, por menus; analistas, em SQL | no banco (aula 3) e nos modelos e métricas dele | código aberto e gratuito para rodar você mesmo; planos hospedados são pagos |
| **Streamlit** | um programador, em Python | no código do app | código aberto e gratuito |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"four-shapes\" aria-label=\"As ferramentas de BI em dois eixos. Na horizontal: quem constrói, de qualquer pessoa clicando em menus, à esquerda, a um programador escrevendo código, à direita. Na vertical: onde as definições moram, de em cada trabalho, embaixo, a num modelo central, em cima. O Metabase fica à esquerda e no meio. O Tableau fica à esquerda e embaixo. O Power BI fica à esquerda do centro e um pouco acima do Tableau. O Looker fica no meio e em cima. O Streamlit fica à direita e embaixo. As duas que este curso roda, Metabase e Streamlit, estão destacadas.\"><defs><marker id=\"four-shapes-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"110\" y1=\"270\" x2=\"690\" y2=\"270\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#four-shapes-ah)\"></line><line x1=\"110\" y1=\"270\" x2=\"110\" y2=\"40\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#four-shapes-ah)\"></line><text x=\"110\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">qualquer pessoa, clicando</text><text x=\"690\" y=\"288\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um programador, em código</text><text x=\"400.0\" y=\"310\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">quem constrói</text><text x=\"100\" y=\"264\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">em cada</text><text x=\"100\" y=\"278\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">trabalho</text><text x=\"100\" y=\"46\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">num modelo</text><text x=\"100\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">central</text><text x=\"120\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">onde as definições moram</text><rect x=\"148\" y=\"135\" width=\"104\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Metabase</text><rect x=\"178\" y=\"220\" width=\"104\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"230\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Tableau</text><rect x=\"278\" y=\"180\" width=\"104\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"330\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Power BI</text><rect x=\"378\" y=\"55\" width=\"104\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"430\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Looker</text><rect x=\"548\" y=\"220\" width=\"104\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Streamlit</text></svg>", "caption": "Uma posição para discutir, não uma medida: cada ferramenta pode ser empurrada nos dois eixos pelo jeito como um time a usa.", "same": ["Metabase", "Tableau", "Power BI", "Looker", "Streamlit"]}
```

O Power BI da aula 4 fica entre o Tableau e o Looker: um analista constrói numa tela, e um modelo
semântico pode ser publicado uma vez e compartilhado. As duas que este curso consegue rodar, Metabase
e Streamlit, ficam em cantos opostos, e isso é de propósito: juntas, mostram o que uma ferramenta de
menus e uma de código tornam fácil, e o que cada uma deixa com você.

Duas das quatro — Tableau e Looker — são produtos comerciais que este curso não roda. As seções delas
descrevem o que são e como pensam, a partir da documentação delas, e mostram como as definições delas
se parecem; tudo o que aparece delas diz que não rodou.
