---
title: Escolhendo uma ferramenta
version: 1
---

Todo gráfico deste curso foi desenhado com o matplotlib, porque uma biblioteca gratuita, que roda em
qualquer lugar e escreve cada passo, era o melhor jeito de ensinar. As pessoas que vão ler os seus
gráficos não se importam com o que os desenhou. O seu empregador talvez se importe: a maioria dos
lugares já tem uma ferramenta, e a escolha muitas vezes foi feita antes de você chegar.

As ferramentas caem em quatro famílias, e todas trocam as mesmas duas coisas entre si:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 300\" role=\"img\" data-fig=\"l20-landscape\" aria-label=\"Quatro famílias de ferramenta postas em dois eixos: na horizontal, quanto do gráfico você controla; na vertical, quão rápido sai um primeiro gráfico. As planilhas ficam no alto à esquerda: um primeiro gráfico em segundos, pouco controle. As ferramentas de BI, como Power BI e Tableau, ficam um pouco abaixo e mais à direita. As bibliotecas de gráficos, como o matplotlib, ficam mais abaixo e mais à direita. O D3.js fica embaixo à direita: controle total e o começo mais lento.\"><path d=\"M60.0 250.0 L580.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 36.0 L60.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"580.0\" y=\"266.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quanto do gráfico você controla →</text><text x=\"68.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">↑ quão rápido sai um primeiro gráfico</text><circle cx=\"130.0\" cy=\"66.0\" r=\"7.0\" fill=\"var(--phosphor)\"></circle><text x=\"142.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">planilhas</text><text x=\"142.0\" y=\"77.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Excel, LibreOffice Calc</text><circle cx=\"260.0\" cy=\"112.0\" r=\"7.0\" fill=\"var(--phosphor)\"></circle><text x=\"272.0\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ferramentas de BI</text><text x=\"272.0\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Power BI, Tableau</text><circle cx=\"390.0\" cy=\"166.0\" r=\"7.0\" fill=\"var(--phosphor)\"></circle><text x=\"402.0\" y=\"162.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">bibliotecas de gráficos</text><text x=\"402.0\" y=\"177.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">matplotlib, ggplot2</text><circle cx=\"510.0\" cy=\"218.0\" r=\"7.0\" fill=\"var(--phosphor)\"></circle><text x=\"522.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">D3.js</text><text x=\"522.0\" y=\"229.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">gráficos web</text><text x=\"580.0\" y=\"286.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">as posições são o julgamento desta aula, não uma medida</text></svg>", "caption": "Nenhuma ferramenta é a melhor nas duas coisas. As que dão um gráfico em segundos decidem quase tudo por você; as que deixam você decidir tudo fazem você decidir tudo.", "same": ["D3.js", "Excel, LibreOffice Calc", "Power BI, Tableau", "matplotlib, ggplot2"]}
```

- **Planilhas** dão um gráfico em segundos a partir de dados que já estão numa grade, e decidem quase
  toda a aparência dele por você.
- **Ferramentas de BI**, de business intelligence, são feitas para painéis: conectam-se a bancos de
  dados, mantêm um modelo do dado e deixam o leitor filtrar e clicar. Power BI e Tableau são as duas
  mais usadas.
- **Bibliotecas de gráficos** são código: cada parte do gráfico é uma linha que você escreveu, e o
  mesmo arquivo desenha o gráfico de novo no mês que vem.
- **D3.js** e bibliotecas web parecidas desenham direto no navegador e fazem qualquer coisa, ao custo
  de construir tudo.

## Perguntas que decidem

| pergunta | aponta para |
| --- | --- |
| É um gráfico, hoje, de dados que já estão numa planilha? | uma planilha |
| Muita gente vai abri-lo toda semana e querer filtrar? | uma ferramenta de BI |
| Vai ser redesenhado todo mês com dados novos? | uma biblioteca, ou uma ferramenta de BI com atualização |
| Precisa de uma forma que nenhuma ferramenta oferece? | uma biblioteca, ou o D3 |
| Quem vai manter quando você sair? | o que essas pessoas já conhecem |

A última pergunta é a que as pessoas esquecem. Um painel numa ferramenta que mais ninguém da equipe
consegue abrir para de ser atualizado na semana em que o autor sai de férias.

## O que não muda

Toda regra deste curso vale em toda ferramenta: a base no zero, a afirmação no título, uma cor usada
com intenção, contraste e rótulos diretos. O que muda é **onde você as ajusta**, num menu ou numa
linha de código, e **o que a ferramenta faz se você não ajustar**. O resto desta aula passa pelas
famílias com essa pergunta em mente.
