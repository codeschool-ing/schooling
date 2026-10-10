---
title: As três partes de um não
version: 1
---

Sem uma estratégia, um não é a opinião do tech lead contra a da head de produto, e ganha quem fala
mais alto ou tem mais cargo. Com uma, **o motivo do não é uma decisão que a empresa já tomou**, e o
trabalho do líder é mostrar como o pedido esbarra nela. Três partes carregam isso: uma alternativa
que cabe na política orientadora, o custo nos termos da estratégia, e a data em que a resposta muda.

## O que a estratégia acrescenta à conversa

A aula 8 de `architect-communication` deu cinco partes a um bom não: a necessidade dita de volta, o
não numa frase, o motivo na unidade de quem pede, uma alternativa, e o que mudaria a resposta. Use
essas partes; esta seção não as ensina de novo. O que ela acrescenta é de onde vem o conteúdo de
três delas quando existe uma estratégia.

| parte do não (aula 8 de `architect-communication`) | sem estratégia | com uma |
|---|---|---|
| o motivo | "o time está ocupado" | a política orientadora, e a ação que o pedido atrasaria |
| a alternativa | o que o time conseguir encaixar | algo que atende à necessidade e fica dentro da política |
| o que mudaria a resposta | "quem sabe mais para frente" | uma data, ou uma condição, tirada do próprio plano da estratégia |

A diferença aparece no que quem pede pode fazer em seguida. "O time está ocupado" convida a discutir
o quanto está ocupado. **Um motivo que cita a política leva a discussão para o lugar certo**: se
Júlia acha que reservas de grupo importam mais do que proteger a abertura de vendas, isso é uma
discordância com a estratégia, e ela pertence a Helena Prates, que é dona dela.

## A alternativa cabe na política

Uma alternativa tem dois trabalhos. Ela tem de atender à necessidade por trás do pedido, e tem de
fazer isso sem atravessar a política orientadora. **Uma alternativa que falha no segundo teste é o
mesmo pedido, menor.** "Uma versão mais simples das reservas de grupo" ainda acrescenta reservas ao
caminho da reserva, então esbarra na mesma objeção oferecendo menos.

Mateus perguntou do que o festival precisava de fato, e a resposta foi que grupos de amigos querem
sentar juntos. Essa necessidade não exige um tipo novo de reserva. As casas já separam assentos pela
Bilheteria, o aplicativo que usam na porta: uma casa pode reservar um bloco para um grupo e vendê-lo
com um código de grupo, e cada amigo então compra um ingresso comum. Nada de novo toca o caminho da
reserva, e o checkout não muda.

Ela é pior do que a funcionalidade. O festival tem de montar os blocos à mão, e um grupo não escolhe
os próprios assentos no mapa. **Uma boa alternativa é honesta sobre o que deixa de lado**, porque
quem pede vai descobrir de qualquer jeito, e uma alternativa vendida demais hoje é um motivo para
não confiar na próxima.

## O custo, em duas moedas

A primeira moeda é a que a seção anterior calculou: umas 90 horas, um quarto de uma sprint do
Checkout, R$ 13.500 a R$ 150 a hora. Diga isso com clareza, com a conta, para que quem pede possa
conferir.

A segunda moeda é a da própria estratégia. As 90 horas saem da mudança do Checkout para a nova
interface de reservas, que a remoção das travas está esperando; a cada sprint que a remoção das
travas escorrega, a dívida da reserva de assentos cobra mais 31 horas de juros, R$ 4.650 (aula 5).
E a própria funcionalidade poria reservas novas num caminho que ainda não passou pelo teste de
carga de uma abertura. **A segunda moeda é o que torna o não uma resposta estratégica** em vez de
uma de agenda: ela diz do que a empresa estaria abrindo mão, nos termos que a empresa escolheu.

Diga quem pode passar por cima dele. Se o festival importar o bastante, alguém com autoridade sobre o
roadmap de produto e sobre a estratégia técnica pode decidir assumir o custo. Na Coreto, isso é uma
conversa entre Júlia e Helena, com os números na mesa, e a aula 22 de `people-leadership` trata de
ter essa conversa sem transformá-la numa briga entre dois times.

## A data diz quando a resposta muda

"Mais para frente" não dá a quem pede nada com que planejar. Uma data dá, e uma estratégia
normalmente tem uma para oferecer, porque suas ações têm datas. **A remoção das travas foi planejada
para dois trimestres a partir de 1º de março, então termina no fim de agosto.** As reservas de
grupo poderiam entrar no planejamento da primeira sprint do Checkout em setembro — desde que o teste
de carga, até lá, reproduza uma abertura com reservas de grupo e o caminho aguente.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Quatro caixas da esquerda para a direita. 1º de março: o time de Reservas começa. De março a agosto: dois trimestres tirando as travas de linha. A condição: o teste de carga passa numa reprodução de abertura com reservas de grupo. Setembro: a primeira sprint em que as reservas de grupo podem começar.\"><defs><marker id=\"notyet-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"150\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95\" y=\"68\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">1º de março</text><text x=\"95\" y=\"94\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o time de Reservas</text><text x=\"95\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">começa</text><path d=\"M172 90 L188 90\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#notyet-ah)\"></path><rect x=\"190\" y=\"40\" width=\"190\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"285\" y=\"68\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">de março a agosto</text><text x=\"285\" y=\"94\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">dois trimestres tirando</text><text x=\"285\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">as travas de linha</text><path d=\"M382 90 L398 90\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#notyet-ah)\"></path><rect x=\"400\" y=\"40\" width=\"160\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"480\" y=\"68\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">a condição</text><text x=\"480\" y=\"94\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o teste de carga passa</text><text x=\"480\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">numa abertura com</text><text x=\"480\" y=\"126\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">reservas de grupo</text><path d=\"M562 90 L578 90\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#notyet-ah)\"></path><rect x=\"580\" y=\"40\" width=\"120\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"640\" y=\"68\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">setembro</text><text x=\"640\" y=\"94\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">primeira sprint</text><text x=\"640\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">em que as reservas</text><text x=\"640\" y=\"126\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">de grupo começam</text><text x=\"20\" y=\"180\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a data vem do próprio plano da estratégia; a condição diz o que precisa ser verdade nessa data</text></svg>", "caption": "De onde vem a data do Mateus. As duas primeiras caixas são as ações da aula 1 com suas datas; a caixa tracejada é a condição que transforma a data num sim."}
```

Repare que a data não é uma promessa de construir. É o primeiro ponto em que a objeção desaparece,
e está presa a algo que quem pede consegue ver acontecer. A próxima seção trata dessa amarração, e
do que dizer quando não dá para oferecer data nenhuma.

## A resposta do Mateus

Mateus não respondeu no corredor. Ele escreveu para Júlia na manhã seguinte, com cópia para Davi,
que é dono da estratégia:

> Júlia — sobre as reservas de grupo para o festival.
>
> Não conseguimos construir reservas de grupo neste trimestre. Elas acrescentam reservas novas ao
> caminho da reserva, e a nossa estratégia diz que nada entra ali até o teste de carga mostrar que o
> caminho aguenta uma abertura de vendas.
>
> O que dá para fazer agora: o festival reserva blocos para grupos pela Bilheteria e os vende com um
> código de grupo. Cada amigo compra um ingresso comum, nada muda no checkout, e os grupos sentam
> juntos. Eles não escolhem os próprios assentos no mapa, que é a parte de que estamos abrindo mão.
>
> Quanto custaria um sim: umas 90 horas, um quarto de uma sprint do Checkout (R$ 13.500). Essas
> horas saem da nossa mudança para a nova interface de reservas, que a remoção das travas está
> esperando, e cada sprint que a remoção das travas escorrega custa mais 31 horas de juros na dívida
> da reserva de assentos (R$ 4.650).
>
> Quando a resposta muda: a remoção das travas está planejada para terminar no fim de agosto. Se o
> teste de carga então passar numa reprodução de abertura com reservas de grupo, as reservas de
> grupo podem entrar na nossa primeira sprint de setembro.
>
> Se o festival não puder esperar, a decisão é sua e da Helena, e eu levo esses números para essa
> conversa.

Cada frase pode ser conferida por alguém que não estava na sala. É isso que a torna segura de
encaminhar, e um não sobre o pedido de um cliente sempre é encaminhado.
