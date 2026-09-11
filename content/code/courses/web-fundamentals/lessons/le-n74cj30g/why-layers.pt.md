---
title: Um trabalho para cada, e uma porta estreita
version: 1
---

Tudo que você viu até aqui foi inventado por gente diferente, em épocas diferentes, por motivos
diferentes. O cabo veio da engenharia telefônica. O pacote veio de uma rede de pesquisa. O
endereço veio de um comitê. O navegador veio de um laboratório de física, duas décadas depois do
resto.

Nenhum deles foi projetado pensando nos outros. Todos funcionam juntos nesta noite. Isso não é
sorte, e não é organização: é uma decisão que alguém tomou sobre quem tem direito a saber o quê.

## A alternativa, contada

Suponha que não houvesse camadas — que um programa querendo enviar algo tivesse que saber como
enviar. Não entregar para alguém: de fato pôr no fio, seja lá o que um fio for hoje.

Então um navegador precisaria de uma versão para Ethernet, uma para Wi-Fi, uma para fibra, uma
para rede móvel, uma para satélite. E um cliente de e-mail também, e uma chamada de vídeo, e uma
transferência de arquivo.

Cinco formas de carregar e oito coisas a carregar dão quarenta pedaços de trabalho — e um
quadragésimo primeiro na manhã em que alguém inventar um novo tipo de rádio, mais oito para
ensinar os programas sobre ele.

Com uma camada combinada no meio, a aritmética muda de forma. Cada um dos oito programas aprende
uma coisa só: como entregar uma mensagem para baixo. Cada uma das cinco tecnologias aprende uma
coisa só: como aceitar uma mensagem vinda de cima. Treze pedaços de trabalho, e o rádio novo custa
um — um sobre o qual nenhum programa precisa ser avisado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Cinco protocolos de aplicação no topo se estreitam até uma única camada de internet no meio, que volta a se alargar para cinco tecnologias de transporte embaixo. Dá para acrescentar qualquer coisa no topo ou embaixo bastando combinar com o meio.\"> <text x=\"360\" y=\"20\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">qualquer coisa, inventada por qualquer um</text> <rect x=\"20\" y=\"34\" width=\"116\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"78\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a web</text> <rect x=\"152\" y=\"34\" width=\"116\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"210\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">e-mail</text> <rect x=\"284\" y=\"34\" width=\"116\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"342\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">chamada de vídeo</text> <rect x=\"416\" y=\"34\" width=\"116\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"474\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">transferência</text> <rect x=\"548\" y=\"34\" width=\"152\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"624\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">o que vier depois</text> <path d=\"M78 72 L300 132\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M210 72 L330 132\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M342 72 L356 132\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M474 72 L386 132\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M624 72 L416 132\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <rect x=\"248\" y=\"138\" width=\"224\" height=\"52\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">um jeito único de endereçar</text> <text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">e entregar um pacote</text> <path d=\"M300 196 L78 256\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M330 196 L210 256\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M356 196 L342 256\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M386 196 L474 256\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M416 196 L624 256\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <rect x=\"20\" y=\"260\" width=\"116\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"78\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Ethernet</text> <rect x=\"152\" y=\"260\" width=\"116\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"210\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Wi-Fi</text> <rect x=\"284\" y=\"260\" width=\"116\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"342\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fibra</text> <rect x=\"416\" y=\"260\" width=\"116\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"474\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">móvel</text> <rect x=\"548\" y=\"260\" width=\"152\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"624\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">o que vier depois</text> <text x=\"360\" y=\"316\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">qualquer coisa, feita por qualquer um</text> </svg>", "caption": "Combine com o meio e acabou. Nada lá em cima precisa ser avisado sobre nada lá embaixo."}
```

Essa forma tem nome aqui: a **cintura estreita**. Acima dela, qualquer coisa; abaixo dela,
qualquer coisa; no meio, uma coisa com que todo mundo concorda e que ninguém pode contornar.

## Duas regras, e a segunda é a que sustenta tudo

O arranjo só compensa se as regras forem mantidas, e são duas.

A primeira: **uma camada fala com a camada logo acima e a camada logo abaixo.** Não duas abaixo.
Não de lado. A porta é estreita de propósito, porque uma porta estreita é uma porta cujo outro
lado dá para trocar.

A segunda: **uma camada não olha dentro do que recebeu.** Ela pega um pacote de bytes, faz o
próprio trabalho, acrescenta a própria parte e passa adiante. O que aqueles bytes significam é
assunto da camada que os produziu, e da camada correspondente do outro lado.

A segunda regra é a que faz o trabalho. Se um roteador no caminho abrisse sua mensagem e se
comportasse de forma diferente conforme o que ela dissesse, então a mensagem não poderia mudar sem
que os roteadores mudassem junto — e há um bocado de roteadores, de um bocado de donos que nunca
ouviram falar de você. Como o roteador não abre, um protocolo desenhado esta tarde viaja hoje à
noite por equipamento instalado há uma década, que nunca ouviu falar dele e não precisa ouvir.

## O que já foi trocado debaixo dos seus pés

Isso não é um benefício hipotético; já foi cobrado várias vezes na sua vida.

A página que você está lendo foi projetada quando uma casa chegava à internet por uma linha
telefônica a alguns milhares de bits por segundo. Desde então o fundo da pilha foi arrancado e
substituído por ADSL, depois por cabo, depois por fibra, depois — para a maioria das pessoas na
maior parte do tempo — por um rádio até uma caixinha no corredor. Debaixo da rua, o cobre virou
vidro.

Nenhuma linha de nenhuma página web foi reescrita por causa disso. A camada de aplicação não foi
consultada, porque a camada de aplicação não tem direito a opinião sobre do que é feito o fundo da
pilha.

Vale para cima também. Os endereços da aula passada estão sendo substituídos, devagar, e uma
máquina falando IPv6 roda os mesmos navegadores, os mesmos servidores e os mesmos protocolos que
uma falando IPv4. A camada mudou; o que as vizinhas esperavam, não.

## Quanto custa

Três preços, e todos reais.

**Bytes.** Cada camada acrescenta um cabeçalho, e um cabeçalho é espaço pelo qual você paga sem
enviar nada de seu. Numa transferência grande isso é um arredondamento. Em mensagens pequenas e
frequentes, é a maior parte do tráfego.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas barras desenhadas na mesma escala. Na primeira, um byte de conteúdo carrega cinquenta e quatro bytes de cabeçalho. Na segunda, mil quatrocentos e sessenta bytes de conteúdo carregam os mesmos cinquenta e quatro.\"> <text x=\"20\" y=\"26\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">uma tecla enviada sozinha</text> <rect x=\"20\" y=\"38\" width=\"176\" height=\"38\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"108\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">quadro 14</text> <rect x=\"196\" y=\"38\" width=\"252\" height=\"38\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"322\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">IP 20</text> <rect x=\"448\" y=\"38\" width=\"252\" height=\"38\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"574\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TCP 20</text> <text x=\"20\" y=\"98\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">seu byte é a lasca na ponta direita — 1 de 55, menos de dois por cento</text> <text x=\"20\" y=\"146\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">um pacote cheio de um download, mesma escala</text> <rect x=\"20\" y=\"158\" width=\"6.5\" height=\"38\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <rect x=\"26.5\" y=\"158\" width=\"9\" height=\"38\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <rect x=\"35.5\" y=\"158\" width=\"9\" height=\"38\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <rect x=\"44.5\" y=\"158\" width=\"655.5\" height=\"38\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"372\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1460 bytes do que você de fato pediu</text> <text x=\"20\" y=\"218\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">os mesmos 54 bytes de cabeçalho — agora três e meio por cento</text> <text x=\"20\" y=\"240\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">o cabeçalho é um custo fixo, então a conta depende de quanto você põe atrás dele</text> </svg>", "caption": "O custo de cabeçalho nunca muda de tamanho. O que muda é quanto você mandou junto com ele."}
```

**Trabalho.** Cada fronteira é uma passagem de mão: um tamanho a conferir, um cabeçalho a
localizar, bytes a copiar ou contabilizar. Pouco, e feito para cada pacote de cada conexão de cada
máquina, que é como coisas pequenas viram o motivo de um aparelho esquentar.

**Cegueira.** Uma camada que não enxerga o que as vizinhas sabem às vezes chuta, e às vezes chuta
mal. O caso clássico é a perda. A camada de transporte trata um pacote sumido como sinal de que a
rede está congestionada, e diminui o ritmo — o que está certo num fio congestionado e errado no
Wi-Fi, onde um pacote se perde muito mais por causa de um micro-ondas do que por congestionamento.
Diminuir o ritmo não ajuda com o micro-ondas. O transporte não tem como distinguir, porque a
camada que poderia contar não tem permissão para isso.

## A tentação de trapacear

Uma vez que você conhece as regras, começa a notar onde elas são quebradas, e o exemplo mais
claro é um que você viu na aula passada.

Um roteador pertence à camada que cuida de endereços. Um número de porta pertence à camada de
cima. O NAT lê e reescreve os dois — o que quer dizer que um aparelho está esticando o braço para
dentro de um cabeçalho que não é da conta dele, e passa a depender de que esse cabeçalho continue
com o formato que ele espera.

A consequência chega depois, e cai no colo de outra pessoa. Um protocolo de transporte novo,
organizado de outro jeito, encontra milhões de caixas construídas para esticar o braço e achar uma
porta onde uma porta costumava estar. Elas não entendem, então descartam, e o protocolo novo falha
em redes que não fazem ideia de que são a causa. Também não é hipotético: é por isso que o
transporte mais novo em uso comum teve que se disfarçar de um mais antigo para passar, uma
história a que este curso volta quando chegar ao HTTP/3.

Uma violação de camada compra algo na hora e cobra por vinte anos.
