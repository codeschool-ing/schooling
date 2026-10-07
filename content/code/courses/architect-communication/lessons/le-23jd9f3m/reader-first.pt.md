---
title: Comece pelo leitor, não pelo que você sabe
version: 1
---

A maior parte da escrita técnica se organiza em torno de quem escreve: o que a pessoa descobriu, na
ordem em que descobriu, com o esforço à mostra. **Um documento é uma ferramenta para a próxima ação
de outra pessoa**, e ele é julgado por essa ação acontecer ou não, e não por quanto ele contém.

Este curso acompanha uma única empresa do começo ao fim. A **Marola** é fictícia: um delivery de
supermercado on-line em Recife, com cerca de sessenta engenheiros em sete times. Lívia é engenheira
staff lá, a pessoa que os outros times chamam quando uma decisão atravessa as fronteiras deles, e a
maior parte da semana dela é escrever. Uma proposta, uma resposta ao diretor financeiro, um
comentário de revisão, uma mensagem num canal de incidente. Cada um desses textos é lido por gente
que não pediu para ler e que tem outra coisa para fazer depois.

## Quatro perguntas antes da primeira frase

Antes de escrever qualquer coisa mais longa que uma mensagem de chat, Lívia responde a quatro
perguntas, em geral de cabeça e às vezes no topo de um rascunho que ela apaga depois:

1. **Quem vai ler isto?** Um nome ou um cargo, não "o time" nem "as partes interessadas". Se a
   resposta honesta são três pessoas diferentes, talvez sejam três documentos.
2. **O que essa pessoa já sabe?** O diretor financeiro sabe quanto custa um reembolso e não sabe o
   que é um pool de conexões. Com um tech lead é o contrário.
3. **O que ela deve fazer depois de ler?** Aprovar, escolher entre duas opções, mudar uma data,
   parar de se preocupar ou nada. Um documento sem resposta para esta pergunta é uma página de
   diário.
4. **Quanto tempo ela vai dar ao texto?** Trinta segundos no celular entre duas reuniões pedem um
   documento diferente de vinte minutos na mesa antes de uma revisão.

As respostas mudam o documento mais do que qualquer regra de estilo. Veja o mesmo fato escrito para
dois leitores. Nas noites de sexta, o checkout da Marola falha para cerca de dois em cada cem
clientes, porque um único banco de dados é compartilhado por coisas demais.

Para Bruna, tech lead do time de checkout:

> Os timeouts do checkout às sextas coincidem com o número de conexões no primário batendo em
> `max_connections` entre 18:00 e 21:00. A maior parte vem das leituras do planejador de rotas. Dá
> para a gente parear na terça e ver como passar essas leituras para uma réplica?

Para Caio, o diretor financeiro:

> Cerca de 180 clientes por semana não conseguem pagar nas noites de sexta por causa de um limite de
> capacidade em um dos nossos sistemas. Estou preparando uma proposta para resolver isso, com custo,
> para a reunião do dia 19. Por enquanto você não precisa fazer nada.

Nenhuma das duas é melhor texto em geral. **Cada uma está certa para um leitor e é inútil para o
outro.** Bruna recebe a evidência que ela conferiria e uma ação; Caio recebe o efeito no negócio, o
próximo passo e a afirmação explícita de que nada é pedido a ele, que é a linha que o impede de
responder com perguntas.

## A aritmética do tempo de quem lê

**Quem escreve paga uma vez, e cada leitor paga de novo.** Uma nota de status enviada a trinta
pessoas, que leva cinco minutos para cada uma decifrar, custou duas horas e meia do tempo dos
outros. Se vinte minutos de edição reduzem isso a um minuto por pessoa, a edição economizou duas
horas. Essa conta é todo o argumento desta aula, e ela cresce quanto mais sênior for o leitor,
porque o tempo dele é ao mesmo tempo mais escasso e mais caro.

Ela também explica por que um documento longo não é sinal de quem escreve com seriedade. Pelo
tamanho, o leitor não sabe se as páginas a mais trazem alguma coisa, então ele passa o olho. **O
tamanho é um custo que você impõe, e ele precisa comprar alguma coisa.**

## A maioria passa o olho, então escreva para a passada de olho

Os estudos de rastreamento ocular do Nielsen Norman Group em páginas da web mostraram que as pessoas
varrem o texto em vez de ler: os olhos correm pelas primeiras linhas e descem pela margem esquerda,
num padrão que os pesquisadores chamaram de padrão em F. Documentos de trabalho são lidos do mesmo
jeito, por gente decidindo se aquele merece a sua atenção.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Uma página desenhada como barras. O título, os três títulos de seção e a primeira linha de cada parágrafo estão destacados: é o que lê quem passa o olho. As outras linhas estão em cinza: só são lidas se a passada de olho convenceu a voltar.\"><defs><marker id=\"skim-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"380\" height=\"288\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"60\" y=\"40\" width=\"300\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"74\" width=\"170\" height=\"9\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"94\" width=\"340\" height=\"7\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"107\" width=\"330\" height=\"7\" rx=\"2\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"120\" width=\"340\" height=\"7\" rx=\"2\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"133\" width=\"250\" height=\"7\" rx=\"2\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"158\" width=\"170\" height=\"9\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"178\" width=\"340\" height=\"7\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"191\" width=\"330\" height=\"7\" rx=\"2\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"204\" width=\"340\" height=\"7\" rx=\"2\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"229\" width=\"170\" height=\"9\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"249\" width=\"340\" height=\"7\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"262\" width=\"330\" height=\"7\" rx=\"2\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"275\" width=\"340\" height=\"7\" rx=\"2\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"288\" width=\"250\" height=\"7\" rx=\"2\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><path d=\"M450 46 L426 46\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#skim-ah)\"></path><text x=\"458\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o título: quase todo mundo lê</text><path d=\"M450 98 L426 98\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#skim-ah)\"></path><text x=\"458\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">títulos e a primeira frase de cada</text><text x=\"458\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">parágrafo: o que quem passa o olho lê</text><path d=\"M450 128 L426 128\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#skim-ah)\"></path><text x=\"458\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o resto: só é lido se a passada</text><text x=\"458\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">de olho convenceu a voltar</text></svg>", "caption": "Dois leitores numa pessoa só. Quem passa o olho lê as linhas destacadas e decide; o leitor só volta às cinzas se as destacadas carregaram o argumento."}
```

Então um documento tem dois leitores numa só pessoa: **quem passa o olho, que lê os títulos e a
primeira frase de cada parágrafo, e o leitor, que volta se a passada de olho o convenceu.** Escrever
para os dois significa que a primeira frase de cada parágrafo carrega a afirmação do parágrafo, e
que os títulos dizem alguma coisa em vez de rotular um assunto. "Custos" é um rótulo. "A correção
custa seis semanas-engenheiro e R$ 4.000 por mês" é um título que sobrevive à passada de olho.
