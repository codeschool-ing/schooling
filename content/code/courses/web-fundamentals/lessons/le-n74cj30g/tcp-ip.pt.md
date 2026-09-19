---
title: As quatro que de fato rodam
version: 1
---

Enquanto o modelo de sete camadas era escrito, algo mais simples já carregava tráfego entre
universidades, e fazia isso havia anos. Tinha quatro camadas, nenhum comitê por trás, uma
implementação livre que qualquer um podia copiar, e não tentava descrever tudo.

É o que sua máquina está rodando agora, e tem o nome de dois de seus protocolos: TCP/IP.

## As quatro

| camada | o que ela faz | o que roda ali |
|---|---|---|
| Aplicação | o protocolo que seu programa fala | HTTP, DNS, SMTP, SSH |
| Transporte | para qual programa, e chegou tudo? | TCP, UDP |
| Internet | para qual máquina, por qual rota? | IP, e os erros que ele reporta |
| Enlace | para dentro deste fio em particular | Ethernet, Wi-Fi, e a placa |

Quatro em vez de sete, e a diferença não é bem uma discordância. É que três das sete foram
dobradas em uma, e outras duas em outra.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"O modelo de sete camadas à esquerda ao lado do modelo de quatro à direita. As três de cima das sete correspondem à única camada de aplicação, transporte e rede batem uma a uma, e as duas de baixo correspondem à única camada de enlace.\"> <text x=\"150\" y=\"20\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">as sete, como publicadas</text> <text x=\"540\" y=\"20\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">as quatro, como rodam</text> <rect x=\"30\" y=\"32\" width=\"240\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"150\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">7 Aplicação</text> <rect x=\"30\" y=\"66\" width=\"240\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"150\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">6 Apresentação</text> <rect x=\"30\" y=\"100\" width=\"240\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"150\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">5 Sessão</text> <rect x=\"30\" y=\"140\" width=\"240\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"150\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">4 Transporte</text> <rect x=\"30\" y=\"180\" width=\"240\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"150\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">3 Rede</text> <rect x=\"30\" y=\"220\" width=\"240\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"150\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">2 Enlace</text> <rect x=\"30\" y=\"254\" width=\"240\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"150\" y=\"269\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">1 Física</text> <path d=\"M276 47 L414 74\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\"></path> <path d=\"M276 81 L414 81\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\"></path> <path d=\"M276 115 L414 88\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\"></path> <path d=\"M276 155 L414 155\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\"></path> <path d=\"M276 195 L414 195\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\"></path> <path d=\"M276 235 L414 262\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\"></path> <path d=\"M276 269 L414 269\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\"></path> <rect x=\"420\" y=\"32\" width=\"266\" height=\"98\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect> <text x=\"553\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Aplicação</text> <text x=\"553\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">HTTP, DNS, SMTP, SSH</text> <rect x=\"420\" y=\"140\" width=\"266\" height=\"30\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect> <text x=\"553\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Transporte — TCP, UDP</text> <rect x=\"420\" y=\"180\" width=\"266\" height=\"30\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect> <text x=\"553\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Internet — IP</text> <rect x=\"420\" y=\"220\" width=\"266\" height=\"64\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect> <text x=\"553\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Enlace</text> <text x=\"553\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Ethernet, Wi-Fi, a placa</text> <text x=\"360\" y=\"312\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">as duas camadas do meio batem uma a uma; as pontas foram dobradas, por dois motivos diferentes</text> </svg>", "caption": "As quatro não são uma versão rival das sete. São as sete com as duas pontas entregues a outra pessoa.", "same": ["Internet — IP"]}
```

As três de cima se juntam porque a divisão nunca foi observada na prática: um programa que fala
HTTP também decide a própria codificação, a própria compressão e a própria ideia de conversa. Não
havia fronteira ali para guardar, então este modelo não desenha nenhuma e deixa essas decisões
para quem escrever o protocolo.

As duas de baixo se juntam pelo motivo oposto — não porque a divisão seja imaginária, mas porque
ela é de outra pessoa. O que é um um, fisicamente, e como quadros vão para o fio são decididos
juntos por quem projetou a Ethernet ou o Wi-Fi. Este modelo diz *ponha no fio* e se recusa a
especificar o fio, que é exatamente a cintura estreita da primeira seção, vista de baixo.

## Por que este venceu

Quatro motivos, e só o último é sobre o projeto.

Ele estava **rodando**. Um modelo é um argumento; código funcionando que carrega um arquivo entre
dois prédios não é.

Ele era **livre para copiar**. Chegou dentro de um sistema operacional que as universidades já
tinham, com uma interface de programação — sockets, que você viu na aula dois — contra a qual
qualquer um conseguia escrever numa tarde.

Ele **especificava menos**. Onde o modelo de sete camadas tentava dizer como tudo deveria
funcionar, este descrevia o meio e deixava as duas pontas por conta de outros. Menos para combinar
é menos para discutir, e padrões morrem em discussões.

E ele **já tinha a cintura**. Uma camada de internet, obrigatória, no meio; tudo acima e abaixo
negociável. Isso não é um acaso feliz do projeto, é o projeto.

## A camada de transporte tem duas portas

A camada sobre a qual você vai fazer uma escolha de verdade é o transporte, porque há dois
protocolos ali e eles prometem coisas diferentes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"A camada de transporte desenhada como uma caixa com duas portas. Pela porta da esquerda, TCP, que numera, tenta de novo e entrega na ordem. Pela porta da direita, UDP, que envia e para por aí.\"> <rect x=\"150\" y=\"24\" width=\"420\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"360\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">seu programa tem algo a enviar</text> <path d=\"M280 68 L212 104\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <path d=\"M440 68 L508 104\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <rect x=\"40\" y=\"110\" width=\"300\" height=\"128\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".14\" stroke=\"var(--phosphor)\"></rect> <text x=\"190\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">TCP</text> <text x=\"190\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">combina antes de falar</text> <text x=\"190\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">numera cada pedaço</text> <text x=\"190\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">pede de novo o que se perdeu</text> <text x=\"190\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">entrega na ordem</text> <rect x=\"380\" y=\"110\" width=\"300\" height=\"128\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".14\" stroke=\"var(--amber)\"></rect> <text x=\"530\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">UDP</text> <text x=\"530\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">sem combinar nada</text> <text x=\"530\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">sem numeração</text> <text x=\"530\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">sem segunda tentativa</text> <text x=\"530\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">na ordem em que chegar</text> <text x=\"190\" y=\"262\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">uma página, um arquivo, um e-mail</text> <text x=\"530\" y=\"262\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">uma consulta, uma chamada, uma transmissão</text> <text x=\"360\" y=\"284\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">uma camada, duas promessas — você escolhe pelo que vale um atraso para você</text> </svg>", "caption": "As duas saem pela mesma camada. A diferença é o que cada uma se dispõe a prometer sobre o que vem depois."}
```

O **TCP** monta uma conexão primeiro, numera o que envia, percebe o que não chegou, pede de novo e
entrega ao outro lado um fluxo na ordem certa. Tudo que você carregou num navegador hoje veio por
aqui. O que você paga é tempo — um aperto de mão antes de qualquer conteúdo andar — e espera,
porque um fluxo em ordem quer dizer que um pedaço faltando segura os pedaços de trás.

O **UDP** envia a mensagem e para por aí. Sem conexão, sem numeração, sem repetição, sem ordem. O
que chega, chegou; o que se perdeu, perdeu-se, e nada avisa.

Isso soa estritamente pior até você achar os casos em que não é. Uma consulta de DNS é uma
perguntinha e uma respostinha: montar uma conexão custaria mais do que mandar a pergunta duas
vezes se a primeira sumisse. Uma chamada de voz fica pior com TCP do que sem ele — uma sílaba que
chega atrasada não serve, e parar a chamada para esperar por ela transforma um estalo num
congelamento. Para qualquer coisa ao vivo, *atrasado* e *perdido* são a mesma coisa, e não há
sentido em pagar para trocar um pelo outro.

## Onde fica o HTTPS?

Pergunta justa, e a resposta honesta é que ele não encaixa.

O TLS — a parte que transforma HTTP em HTTPS — fica acima do transporte e abaixo da aplicação.
Pega um fluxo do TCP e devolve à aplicação um fluxo cifrado e conferido. Não é uma das quatro, não
tem número nas sete, e quem precisa de um número mesmo assim diz *camada 6*, ou *camada 4,5* dando
de ombros.

Este é o momento de reparar em algo sobre modelos em geral. São mapas, e um mapa que discorda do
terreno está errado a respeito do mapa. O TLS está rodando em quase toda conexão que você faz,
então um modelo sem lugar para ele tem uma lacuna; o modelo continua útil, e a lacuna continua lá.
Saber quais partes de um modelo sustentam e quais só arrumam é quase tudo que significa conhecer o
modelo.

## O que está rodando na sua máquina

Neste momento, para a página à sua frente, a pilha é mais ou menos esta, de cima para baixo: o
protocolo do próprio site acima do HTTP, acima do TLS, acima do TCP, acima do IP, acima do que
quer que esteja levando isso para dentro do prédio.

Cada um deles é substituível sem que os outros sejam avisados, e a próxima seção mostra o
mecanismo que torna a substituição possível: cada camada embrulha o que recebeu, em vez de
reescrever.
