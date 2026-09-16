---
title: Sete camadas que perderam, e ficaram
version: 1
---

Em 1984 um órgão de padronização publicou um modelo de como uma rede deveria ser construída, em
sete camadas. Era minucioso, era internacional, era para virar a pilha que todo mundo rodaria — e
não virou. O que venceu já estava rodando havia anos e é o assunto da próxima seção.

O modelo ficou assim mesmo, e vale saber por quê antes de aprendê-lo: não porque sua máquina o
esteja rodando, mas porque o mercado pegou os **números** dele e nunca devolveu. As pessoas dizem
*um switch de camada 2*, *um problema de camada 3*, *uma regra de camada 7* todo dia útil, e
querem dizer estas sete.

## As sete

Leia de baixo para cima, porque é a ordem em que uma mensagem as encontra na saída.

| # | camada | a pergunta que ela responde | algo real |
|---|---|---|---|
| 7 | Aplicação | o que esta mensagem quer dizer? | HTTP, SMTP, DNS |
| 6 | Apresentação | como estes bytes estão escritos? | codificações de caracteres, compressão, criptografia |
| 5 | Sessão | esta é a mesma conversa de antes? | retomar uma transferência interrompida |
| 4 | Transporte | qual programa, e chegou tudo? | TCP, UDP, números de porta |
| 3 | Rede | qual máquina, em qual rede, e por qual rota? | IP, roteadores |
| 2 | Enlace | qual placa neste fio, e o quadro sobreviveu? | Ethernet, Wi-Fi, endereços MAC |
| 1 | Física | o que é um um, fisicamente? | voltagens, luz, rádio, o conector |

A camada 1 é onde um bit deixa de ser uma ideia. Um um é uma voltagem no cobre, um pulso de luz no
vidro, um padrão em rádio. Nada nesta camada sabe o que é uma mensagem; sabe distinguir um de
zero, e nada mais.

A camada 2 leva esses bits de uma placa até outra placa **no mesmo fio**, em quadros, com uma
conferência para perceber estrago. É a camada dona dos endereços MAC, que você viu na aula
passada. O alcance dela termina na borda da rede local, sempre.

A camada 3 é o que torna essa borda sobrevivível: endereçamento e roteamento entre redes que nunca
se viram. É a cintura estreita da seção anterior, e é por isso que qualquer coisa disso escala
além de um prédio.

A camada 4 entrega a um **programa** em vez de a uma máquina — é isso que uma porta é — e, numa de
suas duas formas comuns, promete que tudo chega e chega em ordem.

As camadas 5 e 6 são onde o modelo é mais frágil, e é mais honesto dizer isso do que inventar
exemplos. Numa pilha rodando, os trabalhos existem mas não são caixas separadas. A criptografia
que a camada 6 descreve é feita pelo TLS, que um engenheiro chamaria de parte do transporte ou
parte da aplicação conforme a discussão. E a sessão que a camada 5 descreve costuma ser algo que a
aplicação arranjou sozinha com um cookie.

A camada 7 é o protocolo que seu programa de fato fala, e é a única camada que sabe do que se
trata.

## Onde os números se pagam

A contribuição duradoura do modelo é uma forma compartilhada de dizer **até onde uma caixa lê**, e
isso acaba sendo o fato mais útil sobre qualquer equipamento de rede.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"As sete camadas listadas à esquerda. Ao lado, quatro barras de alturas diferentes mostram até onde leem um repetidor, um switch, um roteador e um proxy: camada um, camada dois, camada três e as sete.\"> <rect x=\"14\" y=\"30\" width=\"186\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"107\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">7 Aplicação</text> <rect x=\"14\" y=\"72\" width=\"186\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"107\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">6 Apresentação</text> <rect x=\"14\" y=\"114\" width=\"186\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"107\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">5 Sessão</text> <rect x=\"14\" y=\"156\" width=\"186\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"107\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">4 Transporte</text> <rect x=\"14\" y=\"198\" width=\"186\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"107\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">3 Rede</text> <rect x=\"14\" y=\"240\" width=\"186\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"107\" y=\"257\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">2 Enlace</text> <rect x=\"14\" y=\"282\" width=\"186\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"107\" y=\"299\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">1 Física</text> <rect x=\"230\" y=\"282\" width=\"106\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"283\" y=\"299\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">repetidor</text> <rect x=\"350\" y=\"240\" width=\"106\" height=\"76\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"403\" y=\"257\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">switch</text> <rect x=\"470\" y=\"198\" width=\"106\" height=\"118\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"523\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">roteador</text> <rect x=\"590\" y=\"30\" width=\"116\" height=\"286\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"648\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">proxy</text> <text x=\"460\" y=\"20\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">cada barra para na última camada que aquela caixa abre</text> <text x=\"360\" y=\"338\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">tudo abaixo do topo de uma barra é lido; tudo acima é carregado sem ser aberto</text> </svg>", "caption": "Um equipamento de rede se descreve melhor por até onde ele lê, e esse é o número que as pessoas citam."}
```

Um switch lê até a camada 2: olha um endereço MAC, manda o quadro pela porta certa e nunca abre o
pacote. Um roteador lê até a camada 3: abre o suficiente para ver o endereço de destino, decide o
próximo salto e não vai além. Cada um para exatamente onde o trabalho dele acaba, e é por isso que
um switch não ajuda num problema de roteamento e um roteador não ajuda num MAC duplicado.

O mesmo atalho dá nome a defeitos. *É um problema de camada 1* quer dizer o cabo, o conector, o
rádio — confira a coisa física antes de conferir qualquer coisa esperta. *Camada 8* é uma piada
de vida longa, e quer dizer a pessoa usando o computador; que uma piada sobre uma camada que não
existe seja entendida em todo lugar diz o quanto a numeração pegou.

## Camada 4 e camada 7, as duas que você vai encontrar pelo nome

O lugar onde esses números aparecem no trabalho web comum é na frente de servidores, e a escolha
entre eles é uma escolha de verdade com consequências de verdade.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Dois balanceadores comparados. O que lê até a camada quatro vê apenas um número de porta e manda a conexão para qualquer servidor. O que lê até a camada sete vê o caminho pedido e manda para o grupo de servidores que cuida daquele caminho.\"> <text x=\"176\" y=\"20\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">lendo até a camada 4</text> <rect x=\"34\" y=\"34\" width=\"284\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"176\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tudo que ele vê:</text> <text x=\"176\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">uma conexão na porta 443</text> <path d=\"M120 84 L84 140\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M176 84 L176 140\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M232 84 L268 140\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <rect x=\"34\" y=\"146\" width=\"90\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"79\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">servidor</text> <rect x=\"131\" y=\"146\" width=\"90\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"176\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">servidor</text> <rect x=\"228\" y=\"146\" width=\"90\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"273\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">servidor</text> <text x=\"176\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">qualquer um serve, porque</text> <text x=\"176\" y=\"230\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">ele não consegue distingui-los</text> <text x=\"176\" y=\"258\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">rápido, barato, sem certificado</text> <text x=\"544\" y=\"20\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">lendo até a camada 7</text> <rect x=\"402\" y=\"34\" width=\"284\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"544\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ele também vê:</text> <text x=\"544\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">GET /images/logo.png</text> <path d=\"M488 84 L452 140\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M544 84 L544 140\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M600 84 L636 140\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <rect x=\"402\" y=\"146\" width=\"90\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"447\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/images/</text> <rect x=\"499\" y=\"146\" width=\"90\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"544\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">/api/</text> <rect x=\"596\" y=\"146\" width=\"90\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"641\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o resto</text> <text x=\"544\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">ele escolhe o grupo da esquerda, porque</text> <text x=\"544\" y=\"230\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">leu o caminho e eles diferem</text> <text x=\"544\" y=\"258\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">mais trabalho, e ele guarda seu certificado</text> </svg>", "caption": "O mesmo tráfego, duas caixas, uma diferença: até onde cada uma se dispõe a ler."}
```

Um balanceador de **camada 4** lê até a porta. Ele consegue ver uma conexão chegando para a porta
443 e entregá-la a uma de várias máquinas; não consegue ver o que está sendo pedido, porque a
requisição está dentro, e — se o tráfego for cifrado — não conseguiria ler nem se abrisse. Isso o
torna rápido, barato e indiferente.

Um balanceador de **camada 7** lê a própria requisição. Ele pode mandar `/images/` para um grupo de
máquinas e `/api/` para outro, rotear por nome de host, repetir uma requisição que falhou em outro
servidor e reescrever cabeçalhos na passagem. Para qualquer disso ele tem que decifrar, inspecionar
e cifrar de novo, o que custa trabalho e quer dizer que ele guarda seu certificado.

Nenhum dos dois é o melhor. Eles compram coisas diferentes, e a frase que as pessoas usam para
decidir — *a gente precisa rotear pela URL?* — é uma pergunta sobre até qual camada você tem que
ler.

## O que guardar

Não os sete nomes em ordem, embora sejam fáceis o bastante. Guarde a **forma**: cada camada tem um
trabalho, cada uma conhece apenas as vizinhas, e todo aparelho se define por até onde ele se dispõe
a olhar.

A próxima seção é o modelo que de fato roda na sua máquina, e tem quatro camadas. Você vai
descobrir que as sete cabem dentro dele sem muito esforço.
