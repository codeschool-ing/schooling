---
title: Uma mensagem vestindo quatro cabeçalhos
version: 1
---

Uma camada tem que acrescentar algo — seus números de porta, seus endereços — e não tem permissão
para entender o que recebeu. Esses dois fatos deixam exatamente um movimento disponível: **ponha o
que recebeu dentro de algo seu, e escreva por fora.**

Isso é encapsulamento, e é o mecanismo inteiro. Nada é reescrito na descida. É embrulhado, e
embrulhado de novo, e na outra ponta desembrulhado na ordem inversa.

## Quatro embrulhos, contados em bytes

Pegue uma requisição pequena — a linha de abertura e um par de cabeçalhos, uns quarenta bytes de
texto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Quatro faixas, cada uma mais larga que a de cima. A faixa do topo são quarenta bytes de requisição. Abaixo, os mesmos bytes com um cabeçalho de transporte de vinte bytes na frente, depois um cabeçalho de internet de vinte bytes na frente daquele, depois um cabeçalho de enlace de quatorze bytes na frente e uma conferência de quatro bytes no fim.\"> <text x=\"394\" y=\"26\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">o que a aplicação escreveu</text> <rect x=\"394\" y=\"32\" width=\"278\" height=\"38\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"533\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">GET / HTTP/1.1 ...</text> <text x=\"533\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">40 bytes</text> <text x=\"256\" y=\"94\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">um segmento — 60 bytes</text> <rect x=\"256\" y=\"100\" width=\"138\" height=\"38\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"325\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">cabeçalho TCP</text> <text x=\"325\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">portas, 20 bytes</text> <rect x=\"394\" y=\"100\" width=\"278\" height=\"38\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".12\" stroke=\"var(--phosphor-dim)\"></rect> <text x=\"533\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">os 40 bytes, sem abrir</text> <text x=\"117\" y=\"162\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">um pacote — 80 bytes</text> <rect x=\"117\" y=\"168\" width=\"139\" height=\"38\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"186\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">cabeçalho IP</text> <text x=\"186\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">endereços, 20</text> <rect x=\"256\" y=\"168\" width=\"416\" height=\"38\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".12\" stroke=\"var(--phosphor-dim)\"></rect> <text x=\"464\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">o segmento, sem abrir</text> <text x=\"20\" y=\"230\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">um quadro — 98 bytes, e é isto que vai para o fio</text> <rect x=\"20\" y=\"236\" width=\"97\" height=\"38\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"68\" y=\"249\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">enlace, 14</text> <text x=\"68\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">MACs</text> <rect x=\"117\" y=\"236\" width=\"555\" height=\"38\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".12\" stroke=\"var(--phosphor-dim)\"></rect> <text x=\"394\" y=\"255\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">o pacote, sem abrir</text> <rect x=\"672\" y=\"236\" width=\"28\" height=\"38\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"292\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">a lasca da ponta direita é a conferência do enlace, a única parte posta atrás de você</text> </svg>", "caption": "Nada é reescrito na descida. Cada camada põe o que recebeu dentro de algo seu."}
```

A aplicação entrega quarenta bytes para baixo e para por aí.

O transporte põe um cabeçalho próprio na frente: de qual porta isto veio, para qual porta vai,
onde este pedaço fica no fluxo e uma conferência. Vinte bytes no mínimo. O que ele entrega para
baixo são sessenta bytes, e ele não distingue o cabeçalho dele do seu texto — só conhece o total.

A camada de internet faz o mesmo: mais vinte bytes na frente, com o endereço de origem, o endereço
de destino e uma contagem de saltos. Recebe sessenta bytes, passa oitenta adiante, e não tem
opinião sobre o que eram os primeiros vinte daqueles sessenta.

A camada de enlace embrulha mais uma vez, com os dois endereços MAC, e acrescenta uma conferência
**no fim** também — a única das quatro a pôr alguma coisa atrás de você. Noventa e oito bytes vão
para o fio, quarenta dos quais você escreveu.

O produto de cada camada tem nome próprio, e vale conhecer os nomes porque mensagens de erro os
usam: o que o transporte produz é um **segmento**, o que a camada de internet produz é um
**pacote**, o que vai para o fio é um **quadro**. Os mesmos bytes, três nomes, conforme o envelope
a partir do qual você conta.

## Cada cabeçalho é endereçado ao seu correspondente

Aqui está a ideia que faz o resto se encaixar.

Um cabeçalho não é escrito para a camada de baixo, e não é escrito para as máquinas do caminho.
É escrito para **a mesma camada na outra ponta**. O cabeçalho de transporte é um bilhete da camada
de transporte da sua máquina para a camada de transporte do servidor. As camadas de baixo o levam
sem ler, exatamente como o correio leva uma carta sem lê-la.

Então há dois tipos de movimento neste desenho, e confundi-los é o nó habitual de quem está
começando. **Na vertical**, dentro de uma máquina, as camadas passam pacotes para cima e para
baixo — isso é encanamento. **Na horizontal**, cada camada mantém uma conversa com a
correspondente do outro lado do mundo, usando um cabeçalho que nada no meio abre. A conversa
horizontal é a de verdade. O movimento vertical existe para torná-la possível.

## O que sobrevive a um salto, e o que não

Entre você e um servidor há talvez quinze roteadores, e os envelopes não sobrevivem todos à
viagem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"A mesma mensagem em três pontos da viagem. O cabeçalho de enlace é diferente todas as vezes, o cabeçalho de internet mantém seus endereços e só a contagem de saltos cai, e o cabeçalho de transporte e o conteúdo são idênticos o tempo todo.\"> <text x=\"20\" y=\"30\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">saindo do seu notebook</text> <rect x=\"20\" y=\"38\" width=\"150\" height=\"44\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"95\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cabeçalho de enlace</text> <text x=\"95\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">para seu roteador</text> <rect x=\"170\" y=\"38\" width=\"160\" height=\"44\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"250\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cabeçalho IP</text> <text x=\"250\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">saltos restantes 64</text> <rect x=\"330\" y=\"38\" width=\"160\" height=\"44\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"410\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cabeçalho TCP</text> <rect x=\"490\" y=\"38\" width=\"210\" height=\"44\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"595\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sua requisição</text> <text x=\"20\" y=\"122\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">saindo do seu roteador, em outro fio</text> <rect x=\"20\" y=\"130\" width=\"150\" height=\"44\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"95\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">jogado fora, refeito</text> <text x=\"95\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">para o próximo roteador</text> <rect x=\"170\" y=\"130\" width=\"160\" height=\"44\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"250\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">mesmos endereços</text> <text x=\"250\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">saltos restantes 63</text> <rect x=\"330\" y=\"130\" width=\"160\" height=\"44\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"410\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">não aberto</text> <rect x=\"490\" y=\"130\" width=\"210\" height=\"44\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"595\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">não aberto</text> <text x=\"20\" y=\"214\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">chegando ao servidor, treze saltos depois</text> <rect x=\"20\" y=\"222\" width=\"150\" height=\"44\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"95\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">feito pela última vez</text> <text x=\"95\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">para a placa do servidor</text> <rect x=\"170\" y=\"222\" width=\"160\" height=\"44\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"250\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">mesmos endereços</text> <text x=\"250\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">saltos restantes 50</text> <rect x=\"330\" y=\"222\" width=\"160\" height=\"44\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"410\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">aberto enfim</text> <rect x=\"490\" y=\"222\" width=\"210\" height=\"44\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"595\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">idêntico ao que foi enviado</text> <text x=\"360\" y=\"296\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">a coluna da esquerda é nova a cada salto; tudo à direita dela é carregado, não lido</text> </svg>", "caption": "Quatorze quadros foram feitos e destruídos para mover uma mensagem. A mensagem em si nunca foi tocada."}
```

O **quadro** é destruído e refeito em cada salto, sem exceção. Ele só foi endereçado à próxima
placa deste fio, e assim que o pacote atravessa esse fio ele está acabado. O roteador o tira, lê o
pacote e monta um quadro completamente novo para o próximo fio — endereços MAC novos, e
possivelmente uma tecnologia diferente, já que o quadro que chegou por Wi-Fi pode sair por fibra.

O **pacote** sobrevive, quase. Os endereços dele são o ponto todo e não são tocados. Um campo muda
a cada salto: uma contagem de saltos que começa perto de 64 e cai de um em um, para que um pacote
preso num laço morra em vez de rodar para sempre. Quando você roda um traceroute e vê uma lista de
roteadores, essa contagem regressiva é o truque usado para produzi-la.

O **segmento** e seus bytes não são abertos por nada no caminho. Exceto pelo NAT, que abre o
segmento para reescrever uma porta — e agora você sabe dizer exatamente o que há de errado nisso:
é um aparelho da camada de internet lendo um cabeçalho endereçado a outra pessoa.

## O desembrulho

No servidor a coisa roda ao contrário, e cada camada faz uma pergunta antes de subir mais.

A placa confere o MAC de destino do quadro — *isto é para mim?* — e a conferência do fim: um
quadro estragado no caminho é descartado aqui, em silêncio, e as camadas de cima nunca ficam
sabendo que ele existiu. A camada de internet confere o endereço de destino — *isto é para mim?* —
e olha um byte do cabeçalho dela que diz o que há dentro, para saber que deve passar o conteúdo ao
TCP e não a outra coisa. O transporte confere a porta de destino — *qual programa?* —, põe os
pedaços de volta na ordem e entrega um fluxo ao programa.

O programa recebe os mesmos quarenta bytes que foram enviados. Quatro embrulhos, quatro
desembrulhos, quinze quadros montados e destruídos, e o texto chega inalterado, sem ter sido
entendido por nada no meio.

Esse é o retorno que a primeira seção prometeu, e ele é inteiramente mecânico: uma camada não
consegue corromper o que se recusa a abrir.
