---
title: As palavras depois do valor
version: 1
---

Um cookie é um nome e um valor, e depois uma lista de atributos que a maioria dos tutoriais pula.
Eles não são enfeite. Três deles são a diferença entre uma sessão e a sessão de outra pessoa.

```
Set-Cookie: session=8f3c1a9e; Max-Age=3600; Path=/; Secure; HttpOnly; SameSite=Lax
```

## Quanto tempo ele vive

`Max-Age` é um número de segundos; `Expires` é uma data. Não defina nenhum dos dois e você tem um
**cookie de sessão**, que o navegador guarda até a janela fechar — um nome mal escolhido, porque não
tem nada a ver com as sessões de duas leituras adiante.

A escolha não é só técnica. Um cookie que sobrevive ao navegador fechado é a diferença entre
*continuar conectado* e entrar de novo toda manhã, e numa máquina compartilhada essas são promessas
bem diferentes. Sites que lidam com dinheiro costumam escolher o curto de propósito.

Apagar um é o mesmo mecanismo ao contrário: mande o cookie de novo com uma data no passado, e o
navegador o descarta. Não existe instrução de *apagar*, e é por isso que sair é algo que o servidor
tem que fazer deliberadamente.

## `Secure`

Mande este cookie por HTTPS e nunca por HTTP puro.

Sem ele, uma requisição a um endereço puro — um link digitado, um favorito antigo, um
redirecionamento que ninguém limpou — manda o valor pela rede às claras, para quem estiver no
caminho ler. A conexão que vazou não precisa ser uma que importava; basta ela acontecer uma vez.

## `HttpOnly`

O navegador esconde este cookie dos scripts. O `document.cookie` não vai mostrá-lo, então um script
não consegue lê-lo, copiá-lo nem mandá-lo a lugar nenhum.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Um script injetado numa página lê o cookie de sessão e o manda para outro lugar. Com HttpOnly definido, o mesmo script roda e o cookie é invisível para ele.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">sem HttpOnly</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um script injetado roda na página</text> <rect x=\"20\" y=\"86\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">document.cookie — legível</text> <rect x=\"20\" y=\"136\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o valor vai embora, e a conta também</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">com HttpOnly</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o mesmo script roda na página</text> <rect x=\"380\" y=\"86\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">document.cookie — vazio</text> <rect x=\"380\" y=\"136\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">uma página pichada em vez de uma roubada</text> <text x=\"360\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">não impede o script; tira o que o script estava ali para pegar</text> <text x=\"360\" y=\"248\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">o navegador segue mandando o cookie nas requisições — só se recusa a mostrá-lo à página</text> </svg>", "caption": "Dois desfechos do mesmo ataque, separados por uma palavra num cabeçalho."}
```

Isto existe por causa de um ataque, e ele já levou um bocado de contas. Em algum lugar do site há um
ponto em que texto de um visitante é mostrado a outro — um comentário, um nome, um termo de busca
ecoado de volta. Se esse texto entra na página sem ser escapado, um visitante consegue deixar um
script ali, e o script roda no navegador do próximo visitante com toda a autoridade daquela página.
A primeira coisa que um script desses faz é ler o cookie de sessão e mandá-lo embora. Daí em
diante, quem o recebeu é aquela pessoa.

O `HttpOnly` não impede o script de rodar. Ele torna a coisa mais valiosa da página ilegível para o
script, e transforma uma conta roubada numa página pichada.

A regra é curta: **o cookie que identifica o visitante é `HttpOnly`, sempre.** Se o código da página
precisa saber quem está conectado, pergunte ao servidor; não guarde a resposta em lugar de onde um
script possa levá-la.

## `SameSite`

O mais novo deles, e o que precisa de uma história.

Seu navegador anexa os cookies de um site a qualquer requisição indo para aquele site — inclusive a
requisições que a página de *outro* site causou. Uma página em qualquer lugar pode conter uma imagem
cujo endereço é o seu banco, ou um formulário que envia para ele, e historicamente o navegador
anexaria seus cookies àquela requisição, porque as regras da seção anterior nunca mencionaram de
onde a requisição veio.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A página de outro site provoca uma requisição ao seu banco. Pelas regras antigas o navegador anexa seus cookies a ela. Com SameSite em Lax ele não anexa, enquanto um link que você clica ainda chega logado.\"> <rect x=\"20\" y=\"30\" width=\"220\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"130\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">alguma outra página,</text> <text x=\"130\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">aberta em outra aba</text> <path d=\"M246 56 L436 56\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path> <text x=\"341\" y=\"42\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">provoca uma requisição</text> <rect x=\"442\" y=\"30\" width=\"258\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"571\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">seu banco, onde você está logado</text> <rect x=\"20\" y=\"108\" width=\"330\" height=\"76\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"185\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">as regras antigas</text> <text x=\"185\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">cookies anexados: está autenticada</text> <rect x=\"370\" y=\"108\" width=\"330\" height=\"76\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"535\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SameSite=Lax</text> <text x=\"535\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">sem cookies: é uma desconhecida</text> <text x=\"360\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">e um link que você clica até o banco ainda chega logado</text> <text x=\"360\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">que é a diferença entre Lax e Strict, e por que Lax é o que se usa</text> </svg>", "caption": "A defesa era trabalho da aplicação. Isto a moveu para dentro do navegador, e a tornou o padrão."}
```

Então uma página que você visita enquanto está conectado em outro lugar podia fazer, em silêncio,
uma requisição em seu nome, autenticada como você. Isso se chama falsificação de requisição entre
sites, e se defender disso costumava ser inteiramente trabalho da aplicação.

O `SameSite` move a defesa para dentro do navegador.

`Strict` quer dizer que o cookie é anexado só a requisições do seu próprio site. Seguro, e tem uma
aresta: siga um link para o seu site vindo de qualquer outro lugar — um e-mail, um resultado de
busca — e o cookie não é enviado, então você chega deslogado.

`Lax` é o meio-termo, e o padrão nos navegadores atuais. O cookie é enviado quando você **navega**
até o site clicando num link, e não em requisições de fundo que a página de outro site faz. Isso
mantém o link do e-mail funcionando e fecha a falsificação.

`None` quer dizer o comportamento antigo, e os navegadores só aceitam com `Secure`. É uma exigência
real para algumas coisas — fluxos de pagamento que saem e voltam, um widget embutido no site de
outra pessoa — e é uma decisão a tomar deliberadamente, não um valor a copiar de um resultado de
busca.

## `Domain`, e alargar de propósito

Deixado de fora, um cookie volta exatamente ao host que o definiu. Acrescente
`Domain=codeschool.ing` e ele vai para aquele host **e para todo subdomínio dele** — `app.`, `api.`,
`console.`, e o que for criado ano que vem.

Isso é de vez em quando o que você quer e é uma decisão maior do que parece. Um cookie dividido
entre subdomínios é legível pelo que estiver rodando no menos cuidadoso deles, e subdomínios são
exatamente as coisas que se entregam a um terceirizado, a uma ferramenta de marketing ou a uma
página de status.

A armadilha relacionada tem nome que vale reconhecer: um subdomínio que deixou de ser usado, cujo
nome ainda aponta para um provedor onde qualquer um pode reivindicá-lo, vira uma página no seu
domínio administrada por um estranho — segurando seus cookies alargados. Chama-se tomada de
subdomínio, e é um bom motivo para não alargar nada sem razão.

## Dois prefixos que impõem o resto

Um mecanismo pequeno, recente e genuinamente útil: se o **nome** de um cookie começa com `__Host-`,
o navegador se recusa a aceitá-lo a menos que ele seja `Secure`, tenha `Path=/` e não tenha `Domain`
nenhum. O `__Secure-` é o mais fraco, exigindo apenas `Secure`.

Parece um truque e resolve um problema real. Todo o resto desta leitura é um atributo que o servidor
define, então um erro é silencioso — o cookie funciona, com menos proteção do que se pretendia. Um
prefixo move a exigência para um lugar que o navegador confere, o que transforma *a gente esqueceu*
em *não funcionou*, e esses são defeitos bem diferentes de se ter.

## A combinação para lembrar

Para o cookie que diz quem alguém é: `Secure`, `HttpOnly`, `SameSite=Lax`, um `Max-Age` escolhido de
propósito, e um valor que seja um identificador em vez de informação.

Cada um desses quatro fecha algo que já custou a conta de gente real, e nenhum deles custa nada para
escrever.
