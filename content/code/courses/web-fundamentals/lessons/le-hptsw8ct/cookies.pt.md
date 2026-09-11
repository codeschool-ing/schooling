---
title: Um pedacinho de texto que volta
version: 1
---

Um cookie é um texto que o servidor dá ao navegador e o navegador devolve, em toda requisição
seguinte, sem ser pedido de novo. Essa frase é o mecanismo inteiro. Todo o resto sobre cookies são
regras sobre quando a devolução acontece.

## Definindo um, e recebendo de volta

O servidor acrescenta um cabeçalho a uma resposta:

```
Set-Cookie: session=8f3c1a9e; Path=/; Max-Age=3600
```

O navegador guarda. Daí em diante, toda requisição àquele site leva:

```
Cookie: session=8f3c1a9e
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"O servidor manda um cabeçalho Set-Cookie uma vez. O navegador guarda o valor e o anexa a toda requisição seguinte àquele site, sem ser pedido.\"> <rect x=\"20\" y=\"30\" width=\"300\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"170\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a primeira resposta, uma vez</text> <rect x=\"20\" y=\"76\" width=\"300\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"170\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Set-Cookie: session=8f3c1a9e</text> <path d=\"M326 93 L394 93\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <rect x=\"400\" y=\"76\" width=\"300\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"550\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o navegador anota</text> <text x=\"20\" y=\"146\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">e então, por conta própria, sem nada na página decidir:</text> <rect x=\"20\" y=\"158\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Cookie: session=8f3c1a9e — na próxima página</text> <rect x=\"20\" y=\"194\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Cookie: session=8f3c1a9e — e na folha de estilo</text> <rect x=\"20\" y=\"230\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Cookie: session=8f3c1a9e — e em cada uma das sessenta imagens</text> </svg>", "caption": "Entregue uma vez, devolvido para sempre, em tudo. É por isso que um cookie grande é um imposto sobre cada requisição."}
```

Duas coisas sobre aquela segunda linha valem reparo imediato.

Ela é enviada **automaticamente**, pelo navegador, sem código nenhum envolvido e sem nada na página
decidir. Um cookie definido na segunda-feira é anexado a uma requisição na sexta porque o navegador
o vem segurando, e não porque algo pediu.

E é enviada em **toda** requisição que casa com as regras — a página, a folha de estilo, cada
imagem, cada chamada que um script faz em segundo plano. Um cookie de dois kilobytes numa página
com sessenta recursos são cento e vinte kilobytes de upload que não carregam informação que alguém
tenha querido. Essa é a primeira regra prática: **cookies são pequenos de propósito, e o limite é
de uns quatro kilobytes cada.**

## Quais requisições o recebem

Três coisas decidem, e misturá-las é a fonte habitual do *por que meu cookie não está sendo
enviado*.

**O nome do site.** Por padrão, um cookie definido por `codeschool.ing` volta para `codeschool.ing`
e para mais nada. Um cookie pode ser alargado para cobrir subdomínios, com um atributo `Domain`, e
nunca pode ser alargado para um site que não é seu — uma regra que o navegador impõe contra uma
lista publicada do que conta como sufixo público, e é por isso que ninguém consegue definir um
cookie para `.com`.

**O caminho.** `Path=/admin` quer dizer que o cookie é anexado sob `/admin` e em nenhum outro
lugar. É um recurso de organização e não de segurança, porque uma página em `/` ainda alcança
`/admin` numa aba do navegador.

**Se ele expirou**, que é a próxima seção.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três testes que um navegador aplica antes de anexar um cookie: o nome do site, o caminho e se ele expirou. Três coisas que ele não testa: o método, se um script ou um link causou a requisição, e de qual página a requisição veio.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">o que o navegador confere</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">este é o site que o definiu?</text> <rect x=\"20\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o caminho está sob o Path dele?</text> <rect x=\"20\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">ele expirou?</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">o que ele não confere</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">qual método a requisição usa</text> <rect x=\"380\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">se um script ou um clique a causou</text> <rect x=\"380\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">de qual página a requisição veio</text> <text x=\"360\" y=\"200\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a coluna da direita é toda a razão de os atributos existirem</text> <text x=\"360\" y=\"226\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">e a última linha dela é o que o SameSite veio responder</text> </svg>", "caption": "As regras padrão são sobre para onde o cookie vai. Nada nelas é sobre de onde a requisição veio."}
```

Repare no que *não* está nessa lista: o método, se a requisição veio de um link ou de um script, e
se a página de onde a requisição veio é sua. Essas ausências são toda a razão de os atributos da
próxima seção existirem.

## Cookies definidos pela página

Um script rodando na página também lê e escreve cookies, pelo `document.cookie`, e vale saber que
isso existe para você reconhecer e, em geral, não usar.

Qualquer coisa que um script escreve, outro script da mesma página lê — inclusive um script que
chegou dentro de um anúncio ou de uma biblioteca de terceiros. O cookie mais importante da maioria
dos sites é o que diz quem você é, e a seção inteira a seguir é sobre manter scripts longe dele.

## Primeira parte, terceira parte, e o que todo mundo discute

Um cookie pertence a quem o definiu, e se essa pessoa é o site da barra de endereços decide como
ele é chamado.

Um cookie de **primeira parte** é definido pelo site que você está olhando. A sessão que mantém
você logado, a que guarda sua escolha de idioma neste site — esses.

Um cookie de **terceira parte** é definido por algo *embutido* na página e carregado de outro
lugar: um anúncio, um script de analytics, um vídeo embutido. O host dele define o próprio cookie,
e aqui está a parte que tornou isso valioso: esse mesmo host está embutido em milhares de outros
sites, então ele vê o mesmo navegador chegando em todos eles e consegue juntar as visitas num único
registro de por onde alguém andou.

Ninguém projetou isso. Cai de duas regras comuns — uma página pode carregar coisas de outro lugar,
e um host pode definir um cookie para si — se encontrando. É o recurso acidental mais consequente
da história da web.

Os navegadores vêm fechando isso há anos, em velocidades diferentes e com compromissos diferentes,
e a posição prática hoje é que um cookie de terceira parte é algo que você deve esperar que não
funcione. Se um recurso que você está construindo depende de um, ele está num cronograma que outra
pessoa controla.

## O banner

Já que é daqui que eles vêm, vale dizer o que os banners de consentimento de fato são.

A lei europeia — e a lei brasileira de proteção de dados ao lado dela — exige consentimento antes
de guardar coisas no aparelho de alguém para finalidades que a pessoa não pediu. Um cookie que
mantém você logado não é uma dessas: é necessário para algo que o visitante pediu, e não precisa de
banner. Um cookie que existe para montar um perfil de por onde você anda precisa.

Essa distinção é por que um banner bem feito tem um *recusar* tão fácil quanto o aceitar, e por que
tantos são mal feitos. É também a razão para saber qual dos seus cookies é qual: os que o site não
funciona sem são seus para definir livremente, e o resto é uma decisão sobre dados de outra pessoa
em vez de um detalhe técnico.

## O problema de tamanho, visto direito uma vez

Há um modo de falhar que vale reconhecer porque a mensagem de erro aponta para a coisa errada.

Cookies se acumulam. O analytics acrescenta um, um framework de teste acrescenta dois, a aplicação
acrescenta três, um recurso antigo deixou um para trás. Todos são enviados em toda requisição,
todos contam contra um limite do servidor para o tamanho total dos cabeçalhos, e um dia uma
requisição passa dele.

O que o visitante vê é um `400` sobre um cabeçalho grande demais, em toda página, sem como navegar
para fora — porque toda requisição que ele faz leva a mesma pilha. O site não está fora do ar para
mais ninguém, e limpar os cookies resolve na hora, o que é algo que quase nenhum visitante vai
descobrir sozinho.

A lição está no que guardar: **um identificador, e o estado por trás dele no servidor.** Essa é a
leitura depois da próxima, e é o arranjo que mantém um cookie em trinta bytes enquanto o site
existir.
