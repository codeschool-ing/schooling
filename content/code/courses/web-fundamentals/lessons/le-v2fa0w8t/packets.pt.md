---
title: O pacote
version: 1
---

Nada na internet viaja inteiro. Nem uma página, nem uma fotografia, nem um arquivo, nem uma frase
que você digitou num chat. Tudo é cortado em pedaços antes, e os pedaços viajam separados.

Isso não é uma otimização que alguém acrescentou depois. É a decisão fundadora, e quase tudo nesta
aula — e boa parte do resto deste curso — decorre dela.

## O que a internet se recusa a fazer

Antes da internet havia a rede telefônica, e a rede telefônica funcionava **reservando um
caminho**.

Quando você fazia uma ligação interurbana, os equipamentos ao longo da rota escolhiam um circuito
e o mantinham aberto: um caminho elétrico contínuo do seu aparelho até o do outro, só seu, durante
toda a ligação. Não importava se você estava falando ou calado. O caminho estava comprometido.

Esse desenho tem uma virtude enorme. Uma vez que o circuito existe, tudo que entra numa ponta sai
na outra, em ordem, num ritmo constante, sem nada a pensar a respeito.

E tem um custo que fica insuportável em escala.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois painéis. À esquerda, um circuito reservado: uma linha contínua de quem liga até quem recebe, com um intervalo de silêncio no meio ainda ocupando a linha inteira. À direita, uma linha compartilhada levando blocos curtos de três remetentes diferentes, intercalados, sem intervalos.\"><rect x=\"8\" y=\"14\" width=\"340\" height=\"214\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"178\" y=\"38\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Um circuito reservado</text><text x=\"178\" y=\"57\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma ligação é dona da linha</text><rect x=\"28\" y=\"86\" width=\"300\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect><text x=\"178\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mantido aberto, ponta a ponta</text><rect x=\"128\" y=\"126\" width=\"104\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"3 3\"></rect><text x=\"180\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ninguém falando</text><text x=\"178\" y=\"186\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o silêncio custa o mesmo que a fala</text><text x=\"178\" y=\"208\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">e mais ninguém pode usá-la</text><rect x=\"372\" y=\"14\" width=\"340\" height=\"214\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"542\" y=\"38\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Uma linha compartilhada</text><text x=\"542\" y=\"57\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">três conversas, intercaladas</text><rect x=\"392\" y=\"86\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"86\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><rect x=\"508\" y=\"86\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"566\" y=\"86\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--phosphor-dim)\" fill-opacity=\".4\" stroke=\"var(--phosphor-dim)\"></rect><rect x=\"624\" y=\"86\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><text x=\"542\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cada bloco carrega o próprio destino</text><text x=\"542\" y=\"186\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">a pausa de um é capacidade para outro</text><text x=\"542\" y=\"208\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nada fica reservado</text></svg>", "caption": "A troca que a internet fez. Um caminho reservado é simples e fica ocioso a maior parte do tempo; um compartilhado é complicado e nunca fica ocioso."}
```

Uma conversa é quase toda silêncio. Você pausa, pensa, escuta. Num circuito reservado cada uma
dessas pausas é um pedaço da rede que existe, custa dinheiro e não carrega nada. Para atender mil
ligações simultâneas você precisa de mil caminhos, esteja alguém falando ou não.

A internet recusou o arranjo inteiro. **Não existe um caminho entre você e a máquina que serve esta
página.** Nada foi reservado quando você a abriu e nada será liberado quando você a fechar. A linha
por onde a sua mensagem viaja é compartilhada com a de todo mundo, a cada passo, o tempo todo.

E isso cria imediatamente um problema, do qual o resto desta aula é a resposta: se a linha é
compartilhada e nada fica reservado, então **cada pedaço da sua mensagem precisa dizer por si onde
está indo**. Não há circuito nenhum para carregar esse conhecimento por ele.

## Um pacote é um rótulo e uma carga

Esse pedaço é um **pacote**, e ele tem exatamente duas partes.

O **cabeçalho** é o rótulo. É um conjunto fixo e compacto de campos que dizem para onde o pacote
vai, de onde veio, que tamanho tem e mais algumas coisas de que o maquinário do caminho precisa.

A **carga** é o que ele leva — a fatia da sua mensagem de verdade.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Um pacote desenhado como um retângulo longo dividido em dois. Uma parte estreita à esquerda rotulada cabeçalho, listando origem, destino, tamanho e tempo de vida. Uma parte larga à direita rotulada carga, contendo uma fatia da mensagem.\"><rect x=\"14\" y=\"40\" width=\"692\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"14\" y=\"40\" width=\"246\" height=\"96\" rx=\"4\" fill=\"var(--phosphor)\" fill-opacity=\".1\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"137\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">CABEÇALHO</text><text x=\"483\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">CARGA</text><text x=\"32\" y=\"62\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">de    198.51.100.4</text><text x=\"32\" y=\"80\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">para  203.0.113.7</text><text x=\"32\" y=\"98\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tamanho 1500</text><text x=\"32\" y=\"116\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ttl     58</text><text x=\"483\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">...uma fatia do que você está enviando...</text><text x=\"483\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nada no caminho lê isto</text><text x=\"137\" y=\"164\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">lido a cada passo</text><text x=\"483\" y=\"164\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">lido só no fim</text><text x=\"360\" y=\"192\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o rótulo é pequeno de propósito — ele é pago em todo pacote</text></svg>", "caption": "Todo pacote carrega o próprio endereçamento. Esse é o preço de uma rede que não reserva nada para você."}
```

O cabeçalho é pequeno — tipicamente vinte bytes na camada de endereçamento — e é pequeno por um
motivo que vale notar. Ele viaja em **cada pacote**. Uma página feita de dois mil pacotes paga por
esse rótulo duas mil vezes. Todo campo de um cabeçalho teve que defender a própria existência
contra ser multiplicado pelo tráfego do mundo inteiro.

## O que um roteador lê, e o que ele não lê

Aqui está a parte que surpreende as pessoas, e ela importa para o resto do curso.

Um roteador — uma das máquinas que levam o seu pacote adiante — lê **o cabeçalho**. Na maior parte
das vezes lê um campo do cabeçalho: o destino. Ele olha para onde o pacote vai, decide por onde
mandá-lo adiante, e manda.

**Ele não abre a carga.** Não tem interesse em saber se o seu pacote contém um parágrafo de uma
notícia, um fragmento de uma fotografia ou um quarto de segundo da voz de alguém. Ele não sabe e
não precisa saber.

Esse único fato explica uma quantidade impressionante de coisas:

- **a rede é genérica.** Ninguém teve que ensinar chamadas de vídeo aos roteadores antes de
  chamadas de vídeo poderem existir. Um novo tipo de aplicação é um novo conteúdo para colocar em
  cargas, e o maquinário do meio nunca fica sabendo dele;
- **o HTTPS pode funcionar.** Se o meio tivesse que entender os seus dados, criptografá-los
  quebraria a rede. Como o meio só lê o rótulo, você pode lacrar a carga;
- **e "a rede está lenta para este aplicativo" quase sempre é o diagnóstico errado.** A rede não
  está tratando o seu aplicativo de forma especial. Ela não sabe qual aplicativo é.

## Todo pacote viaja sozinho

A consequência mais difícil de acreditar é esta: **os pedaços de uma mensagem não são um comboio.**
Não estão amarrados. Não há nada os escoltando.

Cada pacote é tratado por conta própria, por cada máquina que encontra, com base no que está no
próprio cabeçalho. Dois pacotes da mesma mensagem, enviados um atrás do outro, podem tomar rotas
diferentes — e se um enlace cair ou uma fila crescer entre o primeiro e o segundo, eles vão.

O que significa que podem chegar **fora de ordem**. Não como defeito. Como comportamento comum.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Uma mensagem cortada em quatro pacotes numerados à esquerda. Duas rotas diferentes no meio: os pacotes um e quatro vão pela rota de cima, os pacotes dois e três pela de baixo. À direita eles chegam na ordem um, três, dois, quatro.\"><rect x=\"10\" y=\"78\" width=\"96\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"58\" y=\"104\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">remetente</text><text x=\"58\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1 2 3 4</text><text x=\"58\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">em ordem</text><rect x=\"272\" y=\"30\" width=\"72\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"308\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">rota A</text><rect x=\"272\" y=\"172\" width=\"72\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"308\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">rota B</text><text x=\"308\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">leva 1 e 4</text><text x=\"308\" y=\"224\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">leva 2 e 3 — e enfileira</text><path d=\"M106 100 C 180 100, 200 47, 266 47\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M106 134 C 180 134, 200 189, 266 189\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M344 47 C 410 47, 430 100, 496 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M344 189 C 410 189, 430 134, 496 134\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"500\" y=\"78\" width=\"96\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"548\" y=\"104\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">destinatário</text><text x=\"548\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1 3 2 4</text><text x=\"548\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">como chegaram</text><rect x=\"610\" y=\"84\" width=\"98\" height=\"66\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".1\" stroke=\"var(--amber)\"></rect><text x=\"659\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">isto é normal,</text><text x=\"659\" y=\"122\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">não é falha</text><text x=\"659\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">alguém reordena</text></svg>", "caption": "Quatro pacotes, duas rotas e uma ordem de chegada que ninguém prometeu. Recolocá-los em ordem é trabalho de alguém — e esta aula termina dizendo de quem."}
```

Então: um pacote pode chegar atrasado, pode chegar fora de ordem e pode **não chegar**. Uma fila em
algum lugar enche e um roteador o descarta, o que não é um mau funcionamento — é o que um roteador
faz quando chega mais do que ele consegue mandar adiante.

Releia essa lista e repare no que a rede está prometendo. Ela está prometendo **tentar**. Essa é a
promessa inteira. Melhor esforço: farei o que for razoável com este pacote, e não vou te avisar se
eu falhar.

Tudo que parece mais confiável do que isso — um arquivo que baixa certo, uma página que renderiza
inteira, uma mensagem que chega uma vez e em uma peça só — é construído **em cima** dessa promessa
pelas duas máquinas das pontas. O meio não participa. Você vai encontrar o maquinário disso em
*Duas maneiras de usar os mesmos pacotes*, no fim desta aula.

## Guardar e encaminhar, e de onde vem a latência

Mais um detalhe mecânico, porque ele explica um número que você vai medir na próxima aula.

Um roteador não começa a mandar um pacote adiante enquanto ele ainda está chegando. Ele **recebe o
pacote inteiro**, depois olha para ele, depois manda. Isso se chama *guardar e encaminhar*, e é
forçado: você não consegue ler um cabeçalho que não chegou por completo, e não consegue conferir se
um pacote está íntegro antes de ter tudo.

Então cada salto acrescenta um pequeno atraso próprio — o tempo de receber o pacote, mais o tempo
que ele passa esperando atrás do que mais estiver na fila para o mesmo enlace de saída.

Uma dúzia de saltos, cada um com a sua pausinha, é uma parte significativa do que você vai medir
depois como **latência**. Não é atrito num fio. É uma fila de decisões, tomadas uma máquina por
vez.

## O que um pacote não tem

Vale ser explícito sobre o que um pacote não é, porque cada item é algo que as pessoas supõem.

Um pacote não tem **conexão**. Não há nada no cabeçalho dizendo "isto pertence à conversa que eu e
você estamos tendo". A ideia de conexão existe só na memória das duas máquinas das pontas — você
vai ver exatamente como em *Endereço mais porta*.

Um pacote não tem **ordem**. Nada no cabeçalho de endereçamento diz "eu sou o quarto". Algo acima
dele diz, e esse algo não é da rede.

Um pacote não tem **garantia**. Ninguém assinou o recebimento e ninguém vai te dizer se ele foi
descartado.

E um pacote não tem **rota**. Ele não carrega um plano de por onde ir. Carrega um destino, e cada
máquina que encontra toma a própria decisão independente sobre para onde mandá-lo em seguida. Essa
decisão é o assunto de *Atravessar uma rede à qual você não pertence*, duas seções à frente.

## Onde isto te deixa

A internet não carrega a sua mensagem. Ela carrega pedaços rotulados dela, um por vez,
independentemente, numa linha que compartilha com todo mundo, e tem permissão para perdê-los.

Toda outra ideia desta aula é um conserto para alguma coisa nessa frase. O **quadro** é como um
pedaço sobrevive a um passo da viagem. A **MTU** é o tamanho que um pedaço pode ter. O **socket** é
como um pedaço acha o programa certo depois de chegar. E o **TCP** é como duas máquinas constroem
ordem e confiabilidade a partir de uma rede que não oferece nenhuma das duas.
