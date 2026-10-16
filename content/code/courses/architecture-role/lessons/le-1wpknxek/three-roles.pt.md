---
title: Três papéis em dois eixos
version: 1
---

**Engenheiro sênior, tech lead e arquiteto não são três degraus da mesma escada.** A imagem
habitual põe os três em fila: alguns anos como engenheiro sênior, depois liderando um time, depois
arquiteto, e cada passo significa saber mais. Essa imagem mistura duas coisas diferentes. *Sênior* é
um nível, uma medida de quanto a empresa confia no julgamento de alguém. *Tech lead* e *arquiteto*
são papéis, trabalhos com um escopo próprio. Um engenheiro sênior pode ser tech lead, um arquiteto
pode nunca ter liderado um time, e os três se distinguem menos por quanto sabem do que por **quanto
do sistema as suas decisões tocam e por quanto tempo essas decisões precisam valer**.

São esses os dois eixos desta aula, **escopo** e **horizonte**, e cada uma das três pessoas da
Carreto a seguir fica num ponto diferente dos dois.

## A engenheira sênior: profundidade num lugar

Paula Reis é engenheira sênior no time de Platform da Carreto. A semana dela, tirada da agenda:
mover os runners de CI para uma nova imagem de máquina, revisar onze pull requests, dois dias de
plantão e uma tarde pareando com um desenvolvedor do Matching que não entendia por que um deploy
levava 22 minutos. **O escopo dela é o próprio trabalho e a parte do sistema que o time dela possui;
o horizonte é a sprint e, no máximo, o trimestre.**

O que a faz sênior não é um escopo maior. É que confiam nela para tomar as decisões dentro desse
escopo sem que ninguém as confira: como fazer cache do build, se um teste pertence à suíte lenta,
quando uma correção está boa o bastante para ir para produção. A aula 1 mediu a arquitetura pelo
custo de mudança, e essas decisões são baratas de mudar. É exatamente por isso que quem está mais
perto do código deve tomá-las, e por isso uma empresa que as faz passar por alguém mais sênior está
pagando por uma fila.

Ícaro Nunes, dois anos depois da faculdade e no Payments, fica mais abaixo nos dois eixos: uma
tarefa de cada vez, decidida dentro do dia, com a revisão de um colega mais experiente por trás da
maioria delas. A senioridade é a distância entre Ícaro e Paula, e ela é feita principalmente de
confiança conquistada no mesmo tipo de decisão.

## O tech lead: a direção de um time

Bruno Farias é o tech lead do Payments. A semana dele: planejar as duas próximas sprints com o
gerente de produto, quebrar o trabalho de pagamento por Pix em tickets que Ícaro consiga pegar sem
se perder, escolher a biblioteca de retentativas que o time vai padronizar, destravar um deploy que
falhou por falta de um segredo e escrever código em cerca de um terço do tempo. **O escopo dele é a
entrega de um time e a sua direção técnica; o horizonte é o trimestre, às vezes dois.**

O tech lead responde a uma pergunta que mais ninguém no time responde: *como este time constrói o
que precisa construir?* Isso cobre o desenho interno do time (como o Payments divide os seus
módulos, que tabelas mantém, como testa) e a forma como o time trabalha junto no código. Não cobre
como o Payments se encaixa com o Tracking ou o Matching, a não ser pelo fato de Bruno falar pelo
time quando isso é discutido.

## A arquiteta: as juntas entre os times

A semana de Renata Okubo teve quatro itens:

- uma hora com Bruno e o tech lead do Tracking sobre como o Payments fica sabendo que uma entrega
  foi comprovada, decisão que a aula 5 registrou num registro de decisão;
- a revisão de um desenho do Matching para oferecer cargas aos motoristas em lotes;
- a passada trimestral pelo registro de riscos da aula 14;
- uma tarde escrevendo a fitness function da aula 9 para mais um par de módulos.

 **O escopo dela é o sistema através dos times; o horizonte é de um a três anos.**

Repare no que falta nessa semana. **Ela não tomou nenhuma decisão que viva inteira dentro de um
time.** Cada item atravessava uma fronteira entre times ou sairia muito caro de mudar depois, que é
o teste da aula 6 para uma decisão arquitetural aplicado à agenda de uma pessoa em vez de a um
desenho.

## Os dois eixos numa figura

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 392\" role=\"img\" aria-label=\"Um gráfico com dois eixos. Na horizontal, o escopo: uma tarefa, o código de um time, um time, vários times, a empresa. Na vertical, o horizonte: dias, uma sprint, um trimestre, um ano, anos. Um dev júnior, Ícaro, fica em uma tarefa e dias. Uma engenheira sênior, Paula, do Platform, cobre de uma tarefa ao código de um time, de uma sprint a um trimestre. Um tech lead, Bruno, do Payments, fica em um time, perto de um trimestre. A arquiteta, Renata, fica em vários times, de um ano a anos. Uma caixa tracejada para o arquiteto corporativo da aula 4 fica na empresa e em anos.\"><path d=\"M100 330 L700 330\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M100 330 L100 40\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M96 60 L104 60\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"90\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">anos</text><path d=\"M96 120 L104 120\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"90\" y=\"120\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um ano</text><path d=\"M96 180 L104 180\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"90\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um trimestre</text><path d=\"M96 240 L104 240\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"90\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma sprint</text><path d=\"M96 300 L104 300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"90\" y=\"300\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dias</text><path d=\"M170 326 L170 334\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"170\" y=\"348\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma tarefa</text><path d=\"M290 326 L290 334\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"290\" y=\"348\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o código de um time</text><path d=\"M410 326 L410 334\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"410\" y=\"348\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um time</text><path d=\"M530 326 L530 334\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"530\" y=\"348\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">vários times</text><path d=\"M650 326 L650 334\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"650\" y=\"348\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a empresa</text><text x=\"400\" y=\"376\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">escopo: quanto do sistema uma decisão toca</text><text x=\"100\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">horizonte: por quanto tempo uma decisão precisa valer</text><rect x=\"112\" y=\"276\" width=\"116\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">dev júnior</text><text x=\"170\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Ícaro</text><rect x=\"150\" y=\"196\" width=\"180\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"240\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">engenheiro sênior</text><text x=\"240\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Paula, Platform</text><rect x=\"350\" y=\"146\" width=\"120\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"410\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tech lead</text><text x=\"410\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Bruno, Payments</text><rect x=\"478\" y=\"70\" width=\"124\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">arquiteto</text><text x=\"540\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Renata</text><rect x=\"614\" y=\"40\" width=\"82\" height=\"48\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"655\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">arquiteto</text><text x=\"655\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">corporativo</text><text x=\"655\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">aula 4</text></svg>", "caption": "Cada papel fica onde ficam as suas decisões: mais à direita, a decisão toca mais times; mais acima, ela precisa valer por mais tempo. O canto tracejado é o nível corporativo da aula 4, que a Carreto, com 50 engenheiros, não tem quem ocupe.", "same": ["tech lead", "Paula, Platform", "Bruno, Payments", "Renata", "Ícaro"]}
```

A figura diz algo que os cargos não dizem. **Andar para a direita ou para cima é mudar de papel,
enquanto ficar mais sênior move a pessoa dentro da mesma caixa.** Paula pode se tornar uma
engenheira muito melhor nos próximos cinco anos sem nunca sair da dela, e ninguém deveria ler isso
como uma carreira parada. Se um dia ela assumir o trabalho de Bruno, não terá subido acima do
trabalho antigo; terá trocado esse trabalho por um escopo diferente e um horizonte mais longo, e
parte do que a fazia boa no primeiro não vai ajudar no segundo.

## Os quatro arquétipos de Larson

*Staff Engineer: Leadership beyond the management track* (2021), de Will Larson, nasceu de
entrevistas com engenheiros que trabalham acima do nível sênior. Uma das conclusões do livro é que o
mesmo cargo, *staff engineer*, cobre trabalhos bem diferentes, e ele descreve quatro deles como
**arquétipos**:

| arquétipo | o que é o trabalho, em paráfrase | na Carreto |
|---|---|---|
| tech lead | orienta a abordagem e a execução de um time, em geral ao lado do gestor dele | Bruno, no Payments |
| arquiteto | responde pela direção e pela qualidade de uma área crítica, através dos times e ao longo do tempo | Renata |
| solucionador (*solver*) | mergulha num problema difícil atrás do outro, onde quer que a empresa precise | Paula, no mês em que o banco de dados do monólito ficou sem conexões |
| braço direito (*right hand*) | estende o alcance de um executivo, emprestando o escopo e a autoridade dele para tocar algo complicado | ninguém ainda; Tomás não tem ninguém nesse papel |

Duas coisas decorrem disso para este curso. Primeiro, **os arquétipos são formas de um mesmo
nível**: os quatro são staff engineers, e o que os separa é escopo e horizonte, que é o argumento
desta seção nos dados de outra pessoa. Segundo, o arquétipo de arquiteto não é o único que toma
decisões arquiteturais. Paula, como solucionadora, mudou a forma como o monólito mantém o pool de
conexões com o banco, e essa decisão vai durar anos depois do incidente. O que o arquiteto tem e o
solucionador não tem é **uma área pela qual responder ao longo do tempo**: o solucionador vai embora
quando o problema está resolvido, e o arquiteto ainda está lá quando a decisão precisa ser revista.

O mês de Paula como solucionadora também lembra que uma pessoa passa de um arquétipo a outro. As
empresas precisam de formas diferentes em momentos diferentes, e a forma que alguém ocupa este ano
diz respeito ao que a Carreto precisou este ano.

## Por que os eixos vêm antes das sobreposições

Toda discussão sobre de quem é uma decisão acaba sendo uma discussão sobre onde essa decisão fica
nesses dois eixos. **Uma decisão que toca um time e vale por uma sprint pertence a esse time; uma
que toca vários times ou vale por anos precisa de alguém cujo trabalho seja esse escopo.** A próxima
seção trata dos casos em que a resposta não é óbvia, e da tabela que a Carreto escreveu para não ter
de discutir o mesmo caso duas vezes.
