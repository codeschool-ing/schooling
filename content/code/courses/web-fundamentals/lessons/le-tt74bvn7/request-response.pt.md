---
title: O formato de uma troca
version: 1
---

Um lado pede, o outro responde. Agora olhe de perto para o pedir e o responder, porque eles têm um
formato que se repete em todo lugar — no HTTP, que você conhece na aula 6, mas também em consultas
a banco de dados, nas chamadas que seu celular faz para conferir e-mail, e em protocolos
desenhados antes de a web existir.

## Quatro coisas que uma requisição carrega

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas caixas grandes lado a lado. A da esquerda, marcada REQUISIÇÃO, tem quatro faixas empilhadas: sobre o que se pergunta, que tipo de pergunta é, o contexto, e um corpo opcional. A da direita, marcada RESPOSTA, tem três: como foi, o que veio junto, e o conteúdo. Duas setas as ligam, uma em cada direção.\"><defs>\n<marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker>\n<marker id=\"ahs\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker>\n<marker id=\"ahv\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker>\n<marker id=\"ahn\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker>\n</defs>\n  <rect x=\"14\" y=\"30\" width=\"310\" height=\"228\" rx=\"4\" fill=\"var(--phosphor)\" fill-opacity=\".13\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect>\n  <text x=\"26\" y=\"50\" font-family=\"Archivo, sans-serif\" font-size=\"12\" font-weight=\"700\" fill=\"var(--phosphor)\">REQUISIÇÃO</text>\n  <rect x=\"26\" y=\"62\" width=\"286\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect>\n  <text x=\"38\" y=\"78\" font-family=\"Archivo, sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">sobre o que se pergunta</text>\n  <text x=\"38\" y=\"93\" font-family=\"JetBrains Mono, monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/pedidos/1183</text>\n  <rect x=\"26\" y=\"110\" width=\"286\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect>\n  <text x=\"38\" y=\"126\" font-family=\"Archivo, sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">que tipo de pergunta</text>\n  <text x=\"38\" y=\"141\" font-family=\"JetBrains Mono, monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">uma leitura, ou uma mudança</text>\n  <rect x=\"26\" y=\"158\" width=\"286\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect>\n  <text x=\"38\" y=\"174\" font-family=\"Archivo, sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">contexto para decidir</text>\n  <text x=\"38\" y=\"189\" font-family=\"JetBrains Mono, monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">quem você é · o que você já tem</text>\n  <rect x=\"26\" y=\"206\" width=\"286\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"4 3\"></rect>\n  <text x=\"38\" y=\"222\" font-family=\"Archivo, sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">um corpo, quando existe</text>\n  <text x=\"38\" y=\"237\" font-family=\"JetBrains Mono, monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">só uma mudança carrega um</text>\n\n  <path d=\"M328 132 L388 132\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#ahs)\"></path>\n  <text x=\"358\" y=\"126\" text-anchor=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"10\" font-weight=\"700\" fill=\"var(--phosphor)\">pede</text>\n  <path d=\"M388 166 L328 166\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#ahv)\"></path>\n  <text x=\"358\" y=\"182\" text-anchor=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"10\" font-weight=\"700\" fill=\"var(--phosphor-dim)\">responde</text>\n\n  <rect x=\"396\" y=\"30\" width=\"310\" height=\"228\" rx=\"4\" fill=\"var(--phosphor-dim)\" fill-opacity=\".13\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect>\n  <text x=\"408\" y=\"50\" font-family=\"Archivo, sans-serif\" font-size=\"12\" font-weight=\"700\" fill=\"var(--phosphor-dim)\">RESPOSTA</text>\n  <rect x=\"408\" y=\"62\" width=\"286\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect>\n  <text x=\"420\" y=\"78\" font-family=\"Archivo, sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">como foi</text>\n  <text x=\"420\" y=\"93\" font-family=\"JetBrains Mono, monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">primeiro, para você poder parar de ler aqui</text>\n  <rect x=\"408\" y=\"110\" width=\"286\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect>\n  <text x=\"420\" y=\"126\" font-family=\"Archivo, sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">o que veio junto</text>\n  <text x=\"420\" y=\"141\" font-family=\"JetBrains Mono, monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">o tipo de conteúdo · quanto tempo dura</text>\n  <rect x=\"408\" y=\"158\" width=\"286\" height=\"88\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect>\n  <text x=\"420\" y=\"176\" font-family=\"Archivo, sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">o conteúdo em si</text>\n  <text x=\"420\" y=\"191\" font-family=\"JetBrains Mono, monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">a maior parte, e a última a importar</text>\n  <text x=\"420\" y=\"212\" font-family=\"JetBrains Mono, monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">uma falha também pode carregar um,</text>\n  <text x=\"420\" y=\"226\" font-family=\"JetBrains Mono, monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">e uma boa se explica</text>\n\n  <text x=\"360\" y=\"284\" text-anchor=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">o status vem no topo porque é sobre ele que quem pediu age</text>\n</svg>", "caption": "O que cada lado carrega, e por que a ordem importa: a linha de status vem antes do conteúdo para que quem pediu possa agir sem ler o resto."}
```

Seja qual for o protocolo, uma requisição precisa dizer quatro coisas, ou o outro lado não
consegue agir sobre ela:

1. **Para quem ela é** — o endereço, e o endpoint nele.
2. **O que se quer** — um identificador da coisa sobre a qual se pergunta.
3. **Que tipo de pergunta é esta** — estou lendo algo, ou mudando algo?
4. **Qualquer coisa de que o outro lado precise para decidir** — quem está pedindo, que formato
   consegue ler, o que já tem.

O item quatro é onde mora a maior parte do tamanho de uma requisição real, e é a parte que mais
surpreende quem está começando. Pedir uma página raramente é só "me dê a página". Uma requisição
típica de um navegador carrega uma dúzia ou mais de pedaços de contexto: que línguas você lê, se
você aceita respostas comprimidas, o que identificou você da última vez, em que página você estava
quando clicou.

### Ler e mudar não são o mesmo tipo de pergunta

O item três merece mais atenção do que sua única linha sugere, porque é a distinção da qual quase
toda decisão de projeto construída em cima dela depende.

Algumas requisições **só leem**. Elas podem ser repetidas sem consequência, podem ser guardadas em
cache, um navegador pode refazê-las quando você aperta voltar, e uma máquina em dúvida sobre se
uma chegou pode simplesmente mandar de novo.

Algumas requisições **mudam alguma coisa**. Mandar uma delas duas vezes pode cobrar um cartão duas
vezes, publicar um comentário duas vezes, ou apagar algo que já não existia. Nada nelas pode ser
repetido de forma casual, nada nelas pode ser guardado em cache, e "será que passou?" vira uma
pergunta genuinamente difícil.

O vocabulário disso chega na aula 6 com nomes de verdade. A ideia vale ter agora, porque explica
uma coisa que você já viveu: **por que uma página às vezes avisa antes de recarregar.** O
navegador sabe que a última requisição mudou alguma coisa, e sabe que não pode repeti-la por conta
própria.

## Três coisas que uma resposta carrega

1. **Como foi** — deu certo, falhou, falhou de um jeito que você pode consertar, falhou de um jeito
   que você não pode.
2. **Que tipo de coisa está voltando** — uma página, uma imagem, um dado, nada.
3. **A coisa em si**, se houver uma.

Repare que "como foi" é separado de "a coisa em si", e que vem primeiro. Essa ordem é deliberada e
está em todo lugar: **uma resposta diz se antes de dizer o quê**, para que quem pediu possa
decidir o que fazer sem ler a resposta inteira.

Uma falha com um corpo cheio de texto pedindo desculpas continua sendo uma falha, e o cliente
deveria conseguir saber disso pela primeira linha. É isso que permite a um navegador mostrar uma
página de erro em vez de renderizar a reclamação interna de um servidor, e o que permite a um
script tentar de novo sem interpretar nada.

### As categorias de "como foi"

Sem ensinar os códigos exatos ainda, vale conhecer as famílias, porque elas dividem
responsabilidade:

- **Funcionou.** Aqui está o que você pediu.
- **Procure em outro lugar.** O que você pediu está em outro lugar agora; peça lá.
- **Você errou.** A requisição estava malformada, ou pedia algo que não existe, ou não era
  permitida. *Consertar isso é trabalho do cliente.*
- **Eu errei.** Alguma coisa falhou do meu lado. *Consertar isso é trabalho do servidor, e pedir de
  novo pode simplesmente funcionar.*

Essa última divisão é a útil. A diferença entre "você errou" e "eu errei" diz a um cliente se
tentar de novo é sensato ou inútil, e diz a uma pessoa com qual time conversar.

## A troca termina quando a resposta chega

Uma requisição, uma resposta. E acabou.

Isso parece óbvio e tem uma consequência que surpreende todo mundo na primeira vez: **o servidor
não se lembra de você, por padrão.** A troca terminou. A próxima requisição que você mandar chega
como se fosse de um desconhecido.

Pense no que isso significa para algo tão banal quanto um carrinho de compras. Você adiciona um
item — uma troca, encerrada. Você navega para outra página — uma segunda troca, e, no que diz
respeito ao formato puro, é um desconhecido completamente sem relação pedindo uma página. Alguma
coisa precisa carregar o conhecimento "esta é a mesma pessoa, e ela tem um carrinho" da primeira
troca para a segunda, e nada no formato faz isso de graça.

O maquinário que resolve isso é o assunto inteiro da aula 7. O que esta aula lhe pede que repare é
que **ele precisa existir** — que continuar logado é construído, não natural, e que o esquecimento
é o padrão, não um defeito que alguém deixou de consertar.

Há um benefício real escondido no esquecimento, aliás. Como cada troca é independente, qualquer
máquina que possa respondê-la pode respondê-la — que é o que permite a um site movimentado ter
vinte servidores idênticos e mandar as suas requisições para o que estiver livre. Um servidor que
se lembrasse de você teria que ser *o mesmo servidor* toda vez, e essa restrição é cara.

## O servidor nunca fala primeiro

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 336\" role=\"img\" aria-label=\"Três linhas do tempo. Na primeira o cliente pergunta quatro vezes e três respostas dizem que nada mudou. Na segunda o cliente abre uma linha uma vez e o servidor envia por ela quando quiser. Na terceira, riscada, o servidor tenta falar com um cliente que não pediu nada, e não há para onde enviar.\"><defs>\n<marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker>\n<marker id=\"ahs\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker>\n<marker id=\"ahv\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker>\n<marker id=\"ahn\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker>\n</defs>\n  <text x=\"14\" y=\"20\" font-family=\"Archivo, sans-serif\" font-size=\"11.5\" font-weight=\"700\" fill=\"var(--paper-dim)\">1 · PERGUNTAR SEMPRE</text>\n  <line x1=\"120\" y1=\"42\" x2=\"700\" y2=\"42\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n  <line x1=\"120\" y1=\"84\" x2=\"700\" y2=\"84\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n  <text x=\"112\" y=\"46\" text-anchor=\"end\" font-family=\"JetBrains Mono, monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">cliente</text>\n  <text x=\"112\" y=\"88\" text-anchor=\"end\" font-family=\"JetBrains Mono, monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">servidor</text>\n  \n  <path d=\"M136 44 L170 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ahs)\"></path>\n  <path d=\"M176 82 L210 46\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 2\" marker-end=\"url(#ah)\"></path>\n  <text x=\"173\" y=\"102\" text-anchor=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"9.5\" font-weight=\"400\" fill=\"var(--paper-dim)\">nada mudou</text>\n  <path d=\"M280 44 L314 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ahs)\"></path>\n  <path d=\"M320 82 L354 46\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 2\" marker-end=\"url(#ah)\"></path>\n  <text x=\"317\" y=\"102\" text-anchor=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"9.5\" font-weight=\"400\" fill=\"var(--paper-dim)\">nada mudou</text>\n  <path d=\"M424 44 L458 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ahs)\"></path>\n  <path d=\"M464 82 L498 46\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 2\" marker-end=\"url(#ah)\"></path>\n  <text x=\"461\" y=\"102\" text-anchor=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"9.5\" font-weight=\"400\" fill=\"var(--paper-dim)\">nada mudou</text>\n  <path d=\"M568 44 L602 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ahs)\"></path>\n  <path d=\"M608 82 L642 46\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\" fill=\"none\"  marker-end=\"url(#ahv)\"></path>\n  <text x=\"605\" y=\"102\" text-anchor=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"9.5\" font-weight=\"700\" fill=\"var(--phosphor-dim)\">enfim — algo mudou</text>\n\n  <text x=\"14\" y=\"150\" font-family=\"Archivo, sans-serif\" font-size=\"11.5\" font-weight=\"700\" fill=\"var(--paper-dim)\">2 · PERGUNTAR UMA VEZ, DEIXAR A LINHA ABERTA</text>\n  <line x1=\"120\" y1=\"172\" x2=\"700\" y2=\"172\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n  <line x1=\"120\" y1=\"222\" x2=\"700\" y2=\"222\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n  <text x=\"112\" y=\"176\" text-anchor=\"end\" font-family=\"JetBrains Mono, monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">cliente</text>\n  <text x=\"112\" y=\"226\" text-anchor=\"end\" font-family=\"JetBrains Mono, monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">servidor</text>\n  <path d=\"M136 174 L176 218\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#ahs)\"></path>\n  <text x=\"136\" y=\"244\" font-family=\"Archivo, sans-serif\" font-size=\"9.5\" font-weight=\"700\" fill=\"var(--phosphor)\">quem abriu ainda foi o cliente — uma vez</text>\n  <rect x=\"196\" y=\"188\" width=\"494\" height=\"10\" rx=\"5\" fill=\"var(--phosphor)\" fill-opacity=\".13\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect>\n  <text x=\"443\" y=\"164\" text-anchor=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"9.5\" font-weight=\"700\" fill=\"var(--phosphor-dim)\">e então o servidor envia por ela, quando quiser</text>\n  <path d=\"M330 220 L330 200\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#ahv)\"></path>\n  <path d=\"M470 220 L470 200\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#ahv)\"></path>\n  <path d=\"M610 220 L610 200\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#ahv)\"></path>\n\n  <text x=\"14\" y=\"266\" font-family=\"Archivo, sans-serif\" font-size=\"11.5\" font-weight=\"700\" fill=\"var(--amber)\">3 · O QUE NÃO EXISTE</text>\n  <line x1=\"120\" y1=\"284\" x2=\"700\" y2=\"284\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n  <line x1=\"120\" y1=\"326\" x2=\"700\" y2=\"326\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n  <text x=\"112\" y=\"288\" text-anchor=\"end\" font-family=\"JetBrains Mono, monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">cliente</text>\n  <text x=\"112\" y=\"330\" text-anchor=\"end\" font-family=\"JetBrains Mono, monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">servidor</text>\n  <path d=\"M220 324 L220 286\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ahn)\"></path>\n  <path d=\"M211 306 L229 324\" stroke=\"var(--amber)\" stroke-width=\"2.4\"></path>\n  <path d=\"M229 306 L211 324\" stroke=\"var(--amber)\" stroke-width=\"2.4\"></path>\n  <text x=\"248\" y=\"310\" font-family=\"Archivo, sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">nada foi pedido, então não há para onde enviar</text>\n</svg>", "caption": "As duas maneiras de uma página se atualizar sozinha, e a que não existe. Nas duas que funcionam foi o cliente que abriu a troca — a diferença é quantas vezes."}
```

No formato puro, o servidor não consegue começar nada. Ele não tem como alcançar um cliente que
não lhe pediu alguma coisa.

É por isso que uma página não se atualiza sozinha a não ser que algo tenha sido construído para
isso. Há duas maneiras de contornar, e as duas são arranjos, não exceções:

**O cliente continua perguntando.** "Mudou alguma coisa? Mudou alguma coisa?" — a cada poucos
segundos, para sempre. Simples, funciona em qualquer lugar, e desperdiça: a maioria das respostas
é "não", e cada uma custa uma troca inteira.

**Os dois lados combinam de manter uma linha aberta.** Em vez de uma requisição e uma resposta,
eles montam um canal que fica ali, e o servidor pode enviar por ele quando quiser. É o que chat ao
vivo e placar ao vivo de fato usam. Custa alguma coisa ao servidor manter milhares desses abertos,
e é por isso que não é o padrão para tudo.

As duas começam com um cliente pedindo. **Nada chega sem que alguém tenha pedido** — o pedido às
vezes é só bem mais cedo que a chegada.

## Toda troca tem um piso

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"A mesma operação desenhada duas vezes. Acima, seis requisições uma depois da outra, cada uma esperando a resposta anterior, as esperas somando ao longo da linha. Abaixo, uma requisição que devolve tudo, pela mesma distância.\"><defs>\n<marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker>\n<marker id=\"ahs\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker>\n<marker id=\"ahv\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker>\n<marker id=\"ahn\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker>\n</defs>\n  <text x=\"14\" y=\"26\" font-family=\"Archivo, sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">dez trocas, cada uma esperando a anterior</text>\n  <g stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\">\n    <path d=\"M14 44 L74 44 M74 44 L74 56 M74 56 L14 56\"></path>\n    <path d=\"M14 62 L74 62 M74 62 L74 74 M74 74 L14 74\"></path>\n  </g>\n  <g stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" opacity=\".55\">\n    <path d=\"M14 80 L74 80 M74 80 L74 92 M74 92 L14 92\"></path>\n    <path d=\"M14 98 L74 98 M74 98 L74 110 M74 110 L14 110\"></path>\n  </g>\n  <text x=\"90\" y=\"82\" font-family=\"JetBrains Mono, monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">… dez vezes …</text>\n  <rect x=\"196\" y=\"44\" width=\"500\" height=\"66\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".13\" stroke=\"var(--amber)\" stroke-dasharray=\"4 3\"></rect>\n  <text x=\"446\" y=\"70\" text-anchor=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"13\" font-weight=\"700\" fill=\"var(--amber)\">10 × ida e volta</text>\n  <text x=\"446\" y=\"92\" text-anchor=\"middle\" font-family=\"JetBrains Mono, monospace\" font-size=\"11\" fill=\"var(--amber)\">~600 ms antes de poder mostrar qualquer coisa</text>\n\n  <text x=\"14\" y=\"152\" font-family=\"Archivo, sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">uma troca que pede tudo</text>\n  <path d=\"M14 170 L74 170 M74 170 L74 182 M74 182 L14 182\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path>\n  <rect x=\"196\" y=\"164\" width=\"500\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".13\" stroke=\"var(--phosphor)\"></rect>\n  <text x=\"446\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"13\" font-weight=\"700\" fill=\"var(--phosphor)\">1 × ida e volta · ~60 ms</text>\n  <text x=\"14\" y=\"222\" font-family=\"Archivo, sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">9.000 km são cerca de 60 ms de ida e volta, por fibra, no melhor caso. Nenhuma máquina é mais rápida que isso.</text>\n</svg>", "caption": "A mesma operação, dois desenhos. A distância não muda; o número de vezes que ela é paga, sim."}
```

Uma última propriedade, e é a que faz as pessoas redesenharem coisas.

Uma troca não pode ser mais rápida que o tempo de ir e voltar. Se a máquina a quem você pergunta
está a 9.000 km, a resposta não pode chegar em menos de uns 60 milissegundos por mais rápidos que
sejam os dois lados, porque é aproximadamente o tempo que a luz leva para fazer o trajeto por
fibra — e redes reais são mais lentas que a luz.

Então uma operação construída como dez trocas em fila, cada uma esperando a anterior, tem um piso
de dez idas e voltas. A mesma operação construída como uma troca que pede tudo tem um piso de uma.
É por isso que "tagarela" é um insulto nesta área, e por que a aula 3 gasta seu tempo na diferença
entre *quanto* você consegue mandar e *quanto tempo* leva para ouvir de volta.
