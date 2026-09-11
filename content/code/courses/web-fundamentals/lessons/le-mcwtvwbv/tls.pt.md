---
title: O que o S acrescenta
version: 1
---

Tudo até aqui foi texto legível viajando por fios que não são seus. O café, o prédio, o provedor,
cada rede entre aqui e o servidor — todos eles manuseiam isso, e nada no protocolo impediu nenhum
deles de ler.

O HTTPS é o mesmo protocolo com uma camada embaixo que conserta isso, e ele conserta três coisas
separadas. A maioria das pessoas sabe citar uma.

## Três promessas

**Confidencialidade.** Ninguém no caminho consegue ler o que você mandou nem o que voltou.

**Integridade.** Ninguém no caminho consegue alterar sem ser detectado. Esta é a promessa que as
pessoas esquecem, e é a que tem mais história atrás: provedores já injetaram publicidade em páginas
passando pelas suas redes, e redes já reescreveram links. Ler é invisível; alterar é o que de fato
chega ao visitante.

**Identidade.** A máquina que responde consegue provar que controla o nome que você pediu. Sem isso
as outras duas não valem nada — uma conversa cifrada com quem interceptou você continua sendo uma
conversa com quem interceptou você.

A terceira é a que o certificado faz, e o vídeo depois desta seção é sobre os limites do que ele
prova.

## O que acontece antes da primeira requisição

A conexão tem que ser negociada antes de qualquer HTTP ser falado, e o custo dessa negociação é algo
que você consegue medir.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"As trocas antes de uma requisição poder ser enviada. Duas idas e voltas são gastas combinando uma cifra, apresentando o certificado e estabelecendo uma chave; só depois delas a primeira requisição HTTP anda.\"> <rect x=\"20\" y=\"26\" width=\"200\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"120\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">seu navegador</text> <rect x=\"500\" y=\"26\" width=\"200\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"600\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o servidor</text> <path d=\"M120 66 L120 292\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\" fill=\"none\"></path> <path d=\"M600 66 L600 292\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\" fill=\"none\"></path> <text x=\"360\" y=\"86\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">estas são as versões e cifras que eu falo</text> <path d=\"M124 96 L596 96\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <text x=\"360\" y=\"128\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">esta, então — e aqui está meu certificado</text> <path d=\"M596 138 L124 138\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <text x=\"360\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">conferido; aqui está o material da nossa chave</text> <path d=\"M124 180 L596 180\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <text x=\"360\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">combinado — tudo depois disto é cifrado</text> <path d=\"M596 222 L124 222\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <text x=\"360\" y=\"254\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">GET / HTTP/1.1</text> <path d=\"M124 264 L596 264\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path> <text x=\"360\" y=\"306\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">duas idas e voltas antes de um único byte da sua requisição andar — num link de 100 ms, 200 ms</text> </svg>", "caption": "A criptografia não é a parte para lembrar. As idas e voltas são, porque são o que você paga."}
```

Os dois lados combinam qual versão e qual cifra vão usar, o servidor apresenta seu certificado, o
cliente confere, e os dois estabelecem uma chave que só eles têm. Daí em diante tudo é cifrado com
ela.

A parte que vale lembrar é o formato e não a criptografia: **isto custa idas e voltas**, e uma ida e
volta custa a latência da aula três. Num link com 100 ms de latência, uma troca a mais são 100 ms
durante os quais nada seu andou. A versão mais nova do protocolo foi desenhada para fazer isso em
uma troca em vez de duas, e tem um modo que manda a primeira requisição sem troca alguma quando os
dois já conversaram antes — o que diz o quanto aquele tempo valia para alguém.

Duas coisas seguem daí para o resto do curso. Conexões valem a pena reaproveitar, porque a parte cara
acontece uma vez por conexão. E uma página montada a partir de seis hosts diferentes paga esse custo
seis vezes.

## O que continua visível

A criptografia esconde o conteúdo da conversa, e é aqui que o modelo mental das pessoas costuma ser
generoso demais.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Duas colunas listando o que um observador no caminho da rede ainda vê e o que a criptografia esconde. Visível: o endereço, o nome do site, os horários e o volume. Escondido: o caminho, o conteúdo, o que foi digitado e o que voltou.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">ainda visível a qualquer um no caminho</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o endereço ao qual você se conectou</text> <rect x=\"20\" y=\"80\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o nome do site que você pediu</text> <rect x=\"20\" y=\"124\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">quando, e por quanto tempo</text> <rect x=\"20\" y=\"168\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">quantos bytes andaram em cada direção</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">escondido deles</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">qual página dele você pediu</text> <rect x=\"380\" y=\"80\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">tudo que você digitou nele</text> <rect x=\"380\" y=\"124\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">seus cookies, e quem você é</text> <rect x=\"380\" y=\"168\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">tudo o que voltou</text> <text x=\"360\" y=\"236\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a linha passa entre qual site e qual página</text> <text x=\"360\" y=\"258\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">e quase todo conselho confiante sobre isto erra o lado dessa linha</text> </svg>", "caption": "A criptografia esconde a conversa, não o fato de você tê-la tido nem com quem."}
```

Um observador no caminho ainda vê o endereço a que você se conectou e — em quase toda instalação — o
**nome** que você pediu, que é enviado antes de a criptografia começar para o servidor saber qual
certificado apresentar. Ele vê quando você se conectou, quanto tempo ficou e quantos bytes andaram
em cada direção.

Isso basta para saber que você visitou um site específico, mais ou menos quanto leu e por quanto
tempo. Não basta para saber qual página, o que você digitou, com que conta você está entrado ou o
que voltou.

A distância entre *qual site* e *qual página* é toda a diferença de privacidade, e vale ser preciso
sobre ela, porque um bocado de conselho confiante na internet erra numa direção ou na outra.

## Quando a conferência falha

Um navegador recusando um certificado está mostrando um de um número pequeno de problemas distintos,
e eles não são igualmente graves.

**Vencido.** As datas do certificado passaram. Quase sempre uma renovação automática que parou de
funcionar, e quase sempre culpa do próprio site em vez de um ataque.

**O nome errado.** O certificado é válido e é para outro nome — `example.com` apresentado para
`www.example.com`, o caso mais comum. Um erro de configuração, e indistinguível da coisa real para
um navegador, e é por isso que ele recusa.

**Um emissor que ele não conhece.** A cadeia termina em algum lugar que não está na lista do
navegador. Numa rede corporativa isso muitas vezes é deliberado: o empregador instalou uma raiz
própria para que seus equipamentos possam ler o tráfego dos funcionários. Numa rede de café quer
dizer outra coisa bem diferente, e essa diferença não é algo que o navegador consiga resolver por
você.

A única coisa que vale tirar desta lista é que clicar para passar do aviso não conserta nada; é
recusar as três promessas de uma vez, para aquela visita.

## A página que está meio cifrada

Uma página servida por HTTPS pode pedir uma imagem, um script ou uma folha de estilo por HTTP puro,
e se pedir, as garantias acabaram para aquela parte dela.

Um script é o caso grave: quem consegue alterá-lo em trânsito consegue fazer o que a página faz, o
que torna o cadeado da página ao redor uma mentira ativa. Navegadores hoje se recusam a carregar essa
combinação, e silenciosamente promovem ou bloqueiam as mais brandas.

Importa aqui porque costuma ser acidental — um endereço digitado com o esquema errado anos atrás,
num arquivo que ninguém abre.

## Por que virou o padrão

Durante a maior parte da vida da web o HTTPS era para páginas de pagamento. Certificados custavam
dinheiro e renovar era um trabalho manual que alguém esquecia.

Duas coisas mudaram. Certificados ficaram gratuitos e automáticos, então o motivo para não se
incomodar sumiu. E navegadores começaram a marcar HTTP puro como *não seguro* na barra de endereços,
o que transformou uma escolha técnica invisível em algo que visitantes conseguem ver.

Hoje um site em HTTP puro é tratado como defeito por navegadores, por buscadores e por qualquer um
olhando a barra de endereços, e o trabalho de consertar é quase todo um arquivo de configuração. Há
mais uma peça que vale conhecer: um site que já migrou costuma mandar também um cabeçalho pedindo
que o navegador recuse HTTP puro para aquele nome no futuro, para que nem o primeiro redirecionamento
siga sendo uma oportunidade para alguém no meio.
