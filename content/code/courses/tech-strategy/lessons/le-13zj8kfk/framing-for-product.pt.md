---
title: Apresentando a escolha para produto
version: 1
---

Depois que uma decisão é reconhecida como decisão de produto, ela ainda precisa chegar a produto
numa forma que produto consiga decidir. Dois hábitos atrapalham, e os dois são comuns em bons
engenheiros.

O primeiro é **apresentar a recomendação como necessidade**: "precisamos encurtar a reserva, senão o
banco de dados cai nas aberturas de vendas." É rápido e consegue um sim, e esconde o trade-off. A
Júlia concorda com uma correção de banco e descobre por uma casa de shows que compradores estão
perdendo assentos na etapa de pagamento. O segundo é o oposto: uma página de timeouts de trava,
isolamento de transações e pools de conexão que produto não consegue pesar, terminando em "então, o
que vocês querem que a gente faça?". **Os dois deixam a decisão com a engenharia**, um escondendo e o
outro soterrando.

O que funciona é um conjunto curto de opções, cada uma com suas consequências escritas nas palavras
de quem vai senti-las, seguido de uma recomendação.

## A nota que o Davi e o Mateus enviaram

> **Decisão necessária: por quanto tempo a Coreto segura um assento enquanto o comprador paga**
>
> Por que agora: nas grandes aberturas de vendas as reservas de assento fazem fila no banco de dados
> e o checkout falha; esse é o problema do diagnóstico da nossa estratégia. A duração da reserva é
> uma das alavancas, e é uma escolha sobre compradores, não só sobre o banco.
>
> Opção A, manter a reserva como está: compradores lentos mantêm seus assentos. As aberturas
> continuam falhando como hoje até o trabalho do time de Reservas nas travas ficar pronto.
>
> Opção B, encurtar a reserva em tudo: menos travas se acumulam nas aberturas. Todo comprador, em todo
> show, tem menos tempo para pagar; compradores cujo banco pede uma confirmação extra vão perder
> assentos pelos quais estavam pagando, o ano inteiro.
>
> Opção C, encurtar a reserva só nas grandes aberturas: a reserva mais curta vale para a dúzia de
> aberturas por ano em que as travas fazem fila, e o mapa de assentos diz ao comprador quanto tempo
> ele tem. O resto do ano fica igual. Custa ao time de Checkout algum trabalho para trocar a
> configuração por evento.
>
> Recomendamos C, como paliativo até o trabalho nas travas terminar, e depois voltaríamos à A. Ela
> se desfaz trocando uma configuração.
>
> O que nos faria mudar de ideia: se as casas disserem a você que um comprador perder o assento no
> meio do pagamento as prejudica mais do que uma abertura que falha, A é a melhor escolha e
> convivemos com as falhas por mais dois trimestres.
>
> Precisamos de uma resposta antes de a próxima grande abertura ser marcada, para a configuração
> ser testada antes no teste de carga da Plataforma.

## O que a nota faz

**Cada opção é descrita por quem a sente.** "Compradores cujo banco pede uma confirmação extra vão
perder assentos" é uma frase que a Júlia pode pôr na frente de uma casa de shows. "Reduzir o TTL da
trava" não é. O conteúdo técnico continua lá — é por causa dele que a opção C custa trabalho —, mas a
serviço da consequência, e não no lugar dela.

**A recomendação fica separada das opções.** A engenharia tem uma opinião e a diz. Escrever as
opções primeiro, com justiça, e a recomendação depois é o que deixa produto discordar da
recomendação sem precisar reconstruir as opções. Uma nota cujas opções são montadas para uma delas
vencer é a moldura da necessidade de novo, só que mais longa.

**Ela diz quais opções têm volta.** A, B e C estão a uma configuração de distância umas das outras,
então a decisão é barata de rever. Isso muda o cuidado que ela merece. A retenção de dados é o
contraste: depois que registros são apagados sob um prazo de retenção mais curto, nenhuma decisão
posterior os traz de volta, e uma nota sobre retenção precisa dizer isso no primeiro parágrafo.

**Ela nomeia a evidência que a viraria.** "O que nos faria mudar de ideia" diz a produto onde o
conhecimento dele pesa mais que o da engenharia. Aqui é a visão das casas, que a Júlia tem e o Davi
não.

**Ela pede uma decisão até uma data e diz por que essa data.** Uma pergunta aberta sem data é
respondida pelo padrão, que, numa decisão disfarçada, é justamente o que a nota foi escrita para
evitar.

## Quem decide

A nota vai para a Júlia porque as consequências caem sobre compradores e casas, e esses são dela.
Isso não entrega o julgamento da engenharia a produto. **Produto é dono da escolha; a engenharia é
dona da honestidade das consequências**: se as opções estão descritas com precisão e a Júlia escolhe
uma, a engenharia constrói, e se ela escolhe uma contra a qual a nota alertou, o alerta fica
registrado.

Esse registro importa depois. A aula 17 trata de registros de decisão, e uma decisão disfarçada é
exatamente o tipo que merece um — o próximo engenheiro a ver a duração da reserva num arquivo de
configuração merece saber que ela foi escolhida, por quem e por quê. E quando produto e engenharia
discordam depois de uma nota assim, a discordância é sobre um trade-off real com os dois lados à
vista, o que é uma discussão muito melhor de ter. A aula 22 de `people-leadership` trata desse
conflito, e a aula 4 de `architect-communication`, do ofício mais amplo de transformar um risco
técnico num risco de negócio.

| a moldura | o que a Júlia ouve | o que isso faz com a decisão |
|---|---|---|
| uma necessidade | "diga sim ou o banco cai" | esconde o trade-off; produto aprova algo que não viu |
| um briefing técnico | "é assim que as travas funcionam" | deixa a escolha com a engenharia, por omissão |
| opções com consequências | "é assim que cada opção faz alguém perder, e o que faríamos" | põe a escolha com quem é dono do resultado |
