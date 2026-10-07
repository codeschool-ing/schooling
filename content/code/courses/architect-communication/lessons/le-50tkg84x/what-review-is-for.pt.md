---
title: Para que serve de fato a revisão de código
version: 1
---

**A maioria dos times diz que a revisão de código serve para pegar bugs, e o melhor estudo sobre o que
ela realmente faz concluiu que ela faz principalmente outra coisa: espalha conhecimento.** Isso não é
uma decepção. Quer dizer que a revisão é o lugar onde um time ensina a si mesmo, todo dia, sem custo
extra, se quem escreve os comentários a tratar assim.

## O estudo da Microsoft

Em 2013, Alberto Bacchelli e Christian Bird publicaram um estudo sobre revisão de código na Microsoft.
Eles entrevistaram desenvolvedores, aplicaram um questionário a centenas de outros e leram os
comentários de centenas de revisões reais. Os desenvolvedores disseram que o principal motivo para
revisar código era encontrar defeitos. Quando os pesquisadores classificaram o assunto dos comentários,
os defeitos eram minoria; a maior parte tratava de legibilidade, soluções alternativas e de entender o
que a mudança fazia. Os autores concluíram que **a transferência de conhecimento e a consciência do
time** estavam entre os resultados mais importantes da revisão, quisesse alguém isso ou não.

Muitos times encontraram o mesmo nos próprios dados desde então, e isso bate com o que Lívia vê na
Marola. Nas revisões do checkout em junho, cerca de um comentário em sete apontava algo que teria
virado um bug. O resto eram perguntas, explicações, sugestões sobre nomes e estrutura, e links para
como algo tinha sido feito em outro lugar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Barras contando 140 comentários de revisão por assunto. Legibilidade e nomes: 48. Perguntas sobre o que a mudança faz: 34. Abordagens alternativas: 26. Teria virado bug: 20. Elogio: 12.\"><defs><marker id=\"reviewcomm-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">legibilidade e nomes</text><rect x=\"300\" y=\"20\" width=\"336\" height=\"20\" rx=\"3\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"644\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">48</text><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">perguntas sobre o que a mudança faz</text><rect x=\"300\" y=\"60\" width=\"238\" height=\"20\" rx=\"3\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"546\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">34</text><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">abordagens alternativas</text><rect x=\"300\" y=\"100\" width=\"182\" height=\"20\" rx=\"3\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"490\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">26</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">teria virado bug</text><rect x=\"300\" y=\"140\" width=\"140\" height=\"20\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"448\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">20</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">elogio</text><rect x=\"300\" y=\"180\" width=\"84\" height=\"20\" rx=\"3\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"392\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">12</text><text x=\"20\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">140 comentários nos pull requests do checkout em junho, pelo assunto</text></svg>", "caption": "Cerca de um comentário em sete pegou algo que teria virado bug. Os outros seis eram o time ensinando a si mesmo, a mesma forma que Bacchelli e Bird encontraram na Microsoft."}
```

## Duas consequências

**Se a revisão é sobretudo ensino, os comentários são o currículo.** Um comentário que diz "corrija
isto" corrige uma linha. Um comentário que diz por quê ensina ao autor, e a todo mundo que ler a
revisão depois, algo que ele vai aplicar nas próximas cem linhas. A próxima seção trata de escrever
esse tipo de comentário.

**E a revisão não é só para o autor.** O plano de desenvolvimento do Diego, da aula 10, o colocava para
revisar dois pull requests por semana de pessoas fora dos pares de sempre. Essa atividade não estava
ali para pegar bugs no código dos outros; estava ali para que Diego lesse código que não escreveu,
perguntasse sobre decisões que ele não teria tomado e visse como outras pessoas quebram um problema em
partes. **Revisar é como um júnior aprende as partes do sistema em que não trabalha.**

## Para que a revisão não serve

- **Não serve para barrar a entrada.** Uma revisão que existe para provar que quem revisa é mais
  sênior ensina o autor a mandar mudanças menores e mais seguras para outra pessoa.
- **Não serve para estilo que a máquina consegue verificar.** Formatação, ordem dos imports e tamanho
  de linha são trabalho de um formatador e de um linter no pipeline. Cada comentário que uma pessoa
  gasta com isso é um comentário a menos sobre o design.
- **Não é a única defesa.** Testes, tipos, homologação e implantações graduais pegam a maioria dos
  defeitos. Um time que depende de quem revisa para achar bugs ganha revisões lentas e bugs do mesmo
  jeito.
