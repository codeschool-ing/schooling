---
title: Quatro documentos, quatro perguntas
version: 1
---

A maioria das organizações de engenharia usa quatro palavras como se fossem uma. A visão, a
estratégia, o roadmap e o backlog viram todos "o plano", e um slide com o título *Estratégia
técnica* tem tanta chance de mostrar uma lista de trimestres quanto um diagnóstico. **Os quatro são
documentos diferentes.** Cada um responde à sua pergunta, olha a uma distância diferente e muda no
seu próprio ritmo. Misturá-los é como uma empresa acaba com uma estratégia que muda todo trimestre,
ou com um backlog que ninguém sabe explicar.

## O que cada um responde

| documento | a pergunta que responde | até onde olha | com que frequência muda |
|---|---|---|---|
| visão | aonde queremos chegar? | vários anos | raramente; reescrevê-la é um acontecimento |
| estratégia | como vamos chegar lá, dado o que está no caminho? | cerca de um ano | quando o diagnóstico muda |
| roadmap | o que vamos fazer, e em que ordem? | os próximos trimestres | todo trimestre, e quando algo atrasa |
| backlog | o que vem agora? | as próximas sprints | toda sprint |

Leia a tabela descendo pelas duas últimas colunas e aparece um padrão. **Quanto mais longe um
documento olha, menos ele deveria mudar.** Uma visão reescrita todo trimestre é um estado de
espírito. Um backlog que fica igual por seis meses é uma lista de coisas que ninguém está fazendo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Um gráfico com dois eixos. Na horizontal: até onde o documento olha, de semanas à esquerda a anos à direita. Na vertical: com que frequência muda, de toda sprint embaixo a raramente em cima. Quatro caixas numa diagonal que sobe: backlog em semanas e toda sprint, roadmap em trimestres e todo trimestre, estratégia em cerca de um ano e quando o diagnóstico muda, visão em anos e raramente. Uma caixa tracejada âmbar abaixo da estratégia marca uma estratégia que muda todo trimestre: um roadmap com outro título.\"><defs><marker id=\"fourdoc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M80 290 L700 290\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#fourdoc-ah)\"></path><path d=\"M80 290 L80 20\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#fourdoc-ah)\"></path><text x=\"390\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">até onde olha: semanas → trimestres → um ano → anos</text><text x=\"92\" y=\"26\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">quão raramente muda</text><rect x=\"100\" y=\"220\" width=\"140\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170\" y=\"243\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">Backlog</text><text x=\"170\" y=\"262\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">toda sprint</text><rect x=\"250\" y=\"160\" width=\"140\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"320\" y=\"183\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">Roadmap</text><text x=\"320\" y=\"202\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">todo trimestre</text><rect x=\"400\" y=\"100\" width=\"140\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"123\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">Estratégia</text><text x=\"470\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">com o diagnóstico</text><rect x=\"550\" y=\"40\" width=\"140\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"620\" y=\"63\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">Visão</text><text x=\"620\" y=\"82\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">raramente</text><rect x=\"400\" y=\"200\" width=\"290\" height=\"54\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"545\" y=\"223\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">uma estratégia que muda todo trimestre</text><text x=\"545\" y=\"241\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">é um roadmap com outro título</text></svg>", "caption": "Os quatro documentos em dois eixos. Quanto mais longe um documento olha, mais raramente ele deveria mudar; um documento fora da diagonal está fazendo o trabalho de outro.", "same": ["Backlog", "Roadmap"]}
```

## As quatro da Coreto, uma de cada

Quando terminou a segunda versão da estratégia na aula 1, Davi percebeu que a Coreto já tinha três
dos quatro documentos, com os nomes trocados. Arrumados, eles ficam assim.

**A visão** é uma frase que Helena repetia nas reuniões gerais havia muito tempo sem nunca a ter
escrito:

> Quem compra numa abertura de vendas às 10h tem o mesmo checkout de quem compra às três da manhã.

Ela não cita tecnologia nem data. Vai continuar valendo, como objetivo, quando cada linha do
`coreto-core` tiver sido substituída, e é isso que faz dela uma visão e não um plano.

**A estratégia** é a segunda versão da aula 1: o diagnóstico de que as grandes aberturas de vendas
falham no código de reserva de assentos que não tem dono, a política "proteger a abertura de vendas
primeiro" e quatro ações. Ela olha cerca de um ano à frente, porque é mais ou menos o tempo que as
ações levam, e muda quando o diagnóstico muda — quando as reservas de assento pararem de falhar,
outro desafio vira o crítico e a estratégia é reescrita em torno dele.

**O roadmap** põe as ações em sequência por trimestre, ao lado do trabalho de produto, para que o
time de produto da Júlia e o time de vendas vejam o que a engenharia está fazendo e quando. O time
de Reservas se forma em março; o teste de carga vem antes de qualquer mudança no caminho da reserva;
o trabalho nas travas de linha ocupa os dois trimestres seguintes.

**O backlog** são as próximas sprints de cada time. Os primeiros itens do time de Reservas na sua
primeira sprint eram coisas como "tirar o tempo limite da reserva de assento do código e levar para
a configuração" e "criar um painel de esperas por trava nas tabelas de reserva". Ninguém de fora do
time precisa lê-los, e eles mudam a cada duas semanas.

## Quem escreve cada um

Os quatro também têm autores diferentes, e isso pesa tanto quanto o horizonte. **A visão pertence à
liderança**, aqui à Helena, porque é um compromisso sobre para que a empresa existe. A estratégia
costuma ser rascunhada por alguém sênior que enxerga através dos times, como pediram ao Davi, e é
assinada pela CTO. O roadmap tem dois autores, produto e engenharia, e a aula 18 trata de escrevê-lo
com as duas canetas. O backlog pertence ao time que faz o trabalho.

Um documento escrito pelo autor errado escorrega para a pergunta errada. Um roadmap montado só pela
engenharia tende a virar uma lista de desejos da engenharia em ordem de data. Um backlog escrito por
um diretor vira um roadmap com tickets dentro.

## Por que a confusão custa caro

Cada documento é uma ferramenta para uma decisão diferente. A visão encerra as discussões sobre
direção que, sem ela, seriam reabertas todo trimestre. A estratégia decide qual de duas boas
propostas vence. O roadmap decide o que acontece em que ordem, e é contra ele que os outros
departamentos planejam. O backlog decide o que um time começa na segunda-feira.

Quando um documento tenta fazer o trabalho de outro, a decisão que ele deveria resolver fica em
aberto. O caso mais comum, de longe, é o roadmap fazendo as vezes de estratégia, e a próxima seção
trata dele diretamente.
