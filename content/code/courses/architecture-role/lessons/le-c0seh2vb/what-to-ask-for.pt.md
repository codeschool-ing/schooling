---
title: Três tipos de requisito
version: 1
---

**Um requisito não é só uma funcionalidade que alguém quer.** É qualquer coisa que o sistema precisa
fazer, qualquer coisa sobre o quão bem precisa fazê-la e qualquer coisa que já foi decidida por ele.
O primeiro tipo é o que as pessoas dizem em voz alta. O segundo decide a maior parte da arquitetura,
e é o que elas deixam de fora.

A imagem comum é um backlog: uma lista de coisas que o produto deveria permitir que alguém faça,
escrita pelo produto e entregue à engenharia. Essa lista é real e necessária. É também a parte dos
requisitos que menos diz a um arquiteto, porque a mesma lista de funcionalidades pode ser construída
com uma dúzia de estruturas diferentes, e o que escolhe entre elas quase nunca está nela.

## Requisitos funcionais, atributos de qualidade e restrições

**Requisitos funcionais dizem o que o sistema faz.** Um embarcador informa origem, destino e carga e
recebe um preço. Um motorista aceita uma carga. Payments paga o motorista depois que a entrega é
comprovada. Cada um é um comportamento que daria para demonstrar numa tela, e cada um pode ser
conferido fazendo-o uma vez.

**Atributos de qualidade dizem o quão bem ele precisa fazer.** Quanto tempo o embarcador espera pelo
preço. Quantas horas por mês o fluxo de reserva pode ficar fora do ar. Quanto tempo leva para mudar as
regras de preço quando a ANTT publica uma nova tabela do piso. Quantos embarcadores conseguem pedir
caminhão ao mesmo tempo na segunda-feira depois de um feriado. São as propriedades que a aula 1
chamou de razão de ser da arquitetura, e que a aula 6 pôs para negociar umas contra as outras.
Também são chamados de requisitos não funcionais, nome que os faz parecer opcionais, e por isso este
curso o evita.

**Restrições são decisões que outra pessoa já tomou.** O desenho não pode escolhê-las, só respeitá-las.
Na Carreto, algumas vêm da lei: uma cotação não pode ficar abaixo do piso mínimo do frete da ANTT, e
um caminhão não pode sair antes de a SEFAZ autorizar o CT-e. Algumas vêm da empresa: o dinheiro deste
trimestre, o banco parceiro com quem Payments já trabalha, os seis engenheiros do time de Matching e o
que eles sabem. Algumas vêm do calendário: a safra de soja, que passa mais grão pela Carreto em
fevereiro e março do que em quaisquer outros dois meses.

Os três tipos são tratados de formas diferentes. Um requisito funcional se negocia com o produto como
escopo. Um atributo de qualidade se negocia como um número, e o número é o que custa dinheiro. Uma
restrição não é negociada pelo arquiteto; se ela dói, a conversa é com quem é dono dela, e o papel do
arquiteto é dizer quanto ela custa.

## O negócio diz o primeiro e pressupõe o segundo

Este é o pedido que Helena Prado, diretora de produto, levou a Renata no terceiro mês dela como
arquiteta:

> Os embarcadores precisam cotar e reservar um caminhão de uma vez só, numa tela só. Tem que ser
> rápido, e tem que estar sempre disponível.

Leia de novo por tipo. "Cotar e reservar um caminhão de uma vez só, numa tela só" é funcional, ou
parece. "Rápido" e "sempre disponível" são atributos de qualidade, e nenhum dos dois é requisito
ainda, porque ninguém consegue dizer se um desenho os atende. E há restrições que Helena não citou
porque, para ela, nem precisam ser ditas: o piso da ANTT, o CT-e, a safra.

**Os atributos de qualidade não ditos são os perigosos.** Helena não disse que um motorista que toca
em "aceitar" não pode ser avisado um minuto depois de que outro ficou com a carga. Não disse que o
histórico de reservas precisa sobreviver à perda de um servidor de banco de dados. Deixou isso de fora
porque ninguém que trabalha com frete há dez anos pensaria em dizer, do mesmo jeito que ninguém avisa
ao pedreiro que a casa precisa de telhado. Um engenheiro que constrói só o que foi dito vai entregar
algo que atende cada frase do pedido e falha na primeira semana.

Então o primeiro trabalho do arquiteto com um pedido é **achar o segundo e o terceiro tipo dentro do
primeiro.** Toda funcionalidade implica qualidades: quem usa, com que frequência, em que horários,
quantos ao mesmo tempo, o que acontece com eles quando falha, com que frequência mudam as regras por
trás dela. Toda funcionalidade também vive dentro de restrições, e as que vale achar cedo são as que
limitam a forma da resposta.

## As mesmas funcionalidades, arquiteturas diferentes

Por que os atributos de qualidade importam mais para a arquitetura do que as funcionalidades? Porque
**as funcionalidades raramente mudam a estrutura, e as qualidades quase sempre mudam.**

Pegue o pedido de Helena com dois números diferentes. Se "rápido" quer dizer que o preço aparece em
menos de dois segundos, o trabalho fica dentro de Pricing e do app web do embarcador: um cache, talvez
uma consulta mais rápida, nada que atravesse a fronteira de um time. Se "rápido" quer dizer que um
motorista aceitou a carga em até quinze minutos depois do pedido, o trabalho está em como Matching
oferta cargas aos motoristas e no app do motorista. Está também no que o app do embarcador mostra
enquanto espera, e na regra do banco de dados que impede dois motoristas de pegarem a mesma carga. A frase no backlog é
idêntica. A arquitetura não é.

É isso que a definição de Booch, da aula 1, quer dizer na prática: as decisões significativas são as
que custam caro para mudar. Um atributo de qualidade é o que transforma uma funcionalidade numa
decisão cara.

## Requisitos arquiteturalmente significativos

A maioria dos requisitos não precisa de arquiteto. Um novo filtro na lista de reservas do embarcador,
uma coluna num relatório, o texto de uma notificação: um time resolve isso numa sprint e ninguém mais
precisa saber. **Um requisito arquiteturalmente significativo**, o nome usual para o outro tipo, é o
que dá forma à estrutura, de modo que mudar de ideia sobre ele depois sairia caro.

Três sinais marcam um, e basta um deles:

- **Custa caro mudar depois.** Quem é dono de quais dados, se um fluxo é síncrono, o que precisa
  sobreviver à perda de um servidor.
- **Atravessa fronteiras de times.** Na Carreto, qualquer coisa que mexa ao mesmo tempo em Matching,
  no app do motorista e no app do embarcador.
- **A medida de qualidade dá forma à estrutura.** Quinze minutos para nove pedidos em dez mudam como
  Matching funciona; um preço em menos de dois segundos se resolve dentro de Pricing, por mais rígido
  que seja o número.

Um quarto sinal diz com que urgência ele merece atenção, e não se é arquitetural: **alto valor para o
negócio ou alto risco**, quando errar custa clientes, dinheiro ou uma conversa com um órgão regulador.

O Architecture Tradeoff Analysis Method, do SEI, classifica cada candidato em duas escalas ao mesmo
tempo, a importância para o negócio e o quão difícil ou arriscado é atingi-lo, cada uma alta, média ou
baixa, numa estrutura que chama de árvore de utilidade. Não é preciso a árvore para usar a ideia.
Posicionar cada requisito em dois eixos, valor para o negócio e impacto na arquitetura, basta para ver
quais poucos merecem o tempo do arquiteto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Uma grade com o valor para o negócio no eixo vertical e o impacto na arquitetura no eixo horizontal. O canto superior direito, alto nos dois, está marcado como arquiteturalmente significativo e contém três requisitos: um motorista confirmado em até 15 minutos, o comprovante de entrega registrado sem sinal e as reservas que resistem à perda de um servidor. Fora dele: o preço exibido em menos de 2 segundos (valor alto, impacto baixo), um segundo banco para os repasses (impacto alto, valor menor), um novo filtro na lista de reservas e exportar reservas para planilha (baixos nos dois).\"><defs><marker id=\"l7grid-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"390\" y=\"40\" width=\"300\" height=\"130\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><path d=\"M390 40 L390 300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></path><path d=\"M90 170 L690 170\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></path><path d=\"M90 300 L90 32\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l7grid-ah)\"></path><path d=\"M90 300 L698 300\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l7grid-ah)\"></path><text x=\"90\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">valor para o negócio</text><text x=\"690\" y=\"342\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">impacto na arquitetura</text><text x=\"100\" y=\"318\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">baixo</text><text x=\"680\" y=\"318\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">alto</text><text x=\"82\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">alto</text><text x=\"82\" y=\"290\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">baixo</text><text x=\"680\" y=\"58\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">arquiteturalmente significativo</text><circle cx=\"420\" cy=\"88\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"432\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">motorista confirmado em até 15 min</text><circle cx=\"430\" cy=\"117\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"442\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">comprovante registrado sem sinal</text><circle cx=\"402\" cy=\"146\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"414\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">reservas resistem a um servidor perdido</text><circle cx=\"120\" cy=\"80\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"132\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">preço exibido em menos de 2 s</text><circle cx=\"420\" cy=\"225\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"432\" y=\"225\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um segundo banco para os repasses</text><circle cx=\"150\" cy=\"212\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"162\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">novo filtro na lista de reservas</text><circle cx=\"110\" cy=\"262\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"122\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">exportar reservas para planilha</text></svg>", "caption": "Os requisitos candidatos da Carreto posicionados por valor para o negócio e impacto na arquitetura. Só o canto superior direito recebe a atenção completa do arquiteto; o preço em menos de dois segundos importa muito para os embarcadores e mesmo assim fica dentro de um time."}
```

Só o canto superior direito recebe agora o tratamento completo do resto desta aula: perguntas até
ter números, um cenário escrito e uma linha na página única que Helena lê e corrige. O canto inferior
direito também é arquitetural, e espera a vez. A metade esquerda vai para os times donos, que é onde a
aula 6 disse que uma decisão pertence quando não atravessa fronteiras. O
preço em menos de dois segundos importa muito para os embarcadores, e mesmo assim é de Pricing
entregar, dentro de um serviço.

**A lista é curta de propósito.** Um sistema do tamanho do da Carreto tem talvez uma dúzia de
requisitos arquiteturalmente significativos num dado momento, não cem. Se tudo é significativo, o
rótulo parou de selecionar, e o arquiteto volta a revisar cada funcionalidade, que é o gargalo contra
o qual a aula 16 traça a fronteira do papel.
