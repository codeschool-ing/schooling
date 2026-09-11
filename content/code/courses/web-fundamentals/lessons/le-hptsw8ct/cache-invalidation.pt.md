---
title: Desfazendo um cache que você pediu
version: 1
---

Você mandou todo navegador do mundo guardar a folha de estilo por um ano. Fazem seis horas e a folha
de estilo está errada.

Não existe instrução que alcance o navegador de alguém e remova um arquivo. A cópia está no disco
dessa pessoa, está fresca, e enquanto não ficar velha o navegador dela não vai perguntar nada a
você. Você tem o mesmo problema do redirecionamento permanente da aula passada, pelo mesmo motivo:
**não dá para servir uma correção a quem não está perguntando.**

## A saída não é invalidar

É fazer da coisa nova um **endereço diferente**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Manter o mesmo nome de arquivo quer dizer que o tempo de cache é uma promessa que tem que ser curta. Pôr uma impressão digital do conteúdo no nome quer dizer que um build novo é um endereço novo, então o antigo pode ficar um ano em cache sem risco.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">o mesmo nome sempre</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app.css</text> <rect x=\"20\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um cache longo é uma promessa arriscada</text> <rect x=\"20\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um curto custa uma requisição toda vez</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">uma impressão digital no nome</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app.7f3c2a9.css</text> <rect x=\"380\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um ano é seguro: este conteúdo é fixo</text> <rect x=\"380\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um build novo é um nome que ninguém tem</text> <text x=\"360\" y=\"206\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">nada é invalidado; o endereço antigo só deixa de ser citado</text> <text x=\"360\" y=\"234\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">e é por isso que a página que os nomeia não pode ficar muito em cache</text> </svg>", "caption": "Os caracteres no meio do nome de um arquivo gerado não são enfeite. São o que torna um cache de um ano seguro."}
```

Dê a cada arquivo gerado um nome contendo uma impressão digital do conteúdo — `app.7f3c2a9.css` — e
duas coisas viram verdade ao mesmo tempo. Aquele endereço pode ficar um ano em cache sem risco,
porque aquele conteúdo exato nunca vai mudar. E um build novo produz um nome novo, que nenhum
navegador jamais viu, então todo navegador o busca na hora.

Nada é invalidado. O arquivo antigo simplesmente deixa de ser citado, e expira em silêncio no próprio
prazo enquanto ninguém espera por ele.

É isso que toda ferramenta de build está fazendo quando produz nomes de arquivo com uma sequência de
caracteres no meio, e vale saber que a sequência não é enfeite: é o que torna o cache de um ano
seguro.

## Então um arquivo tem que ter vida curta

Se os nomes mudam, algo tem que contar ao navegador os nomes novos, e esse algo não pode ele próprio
ficar um ano em cache.

A página é o ponto de entrada. Ela é pequena, muda a cada deploy, e leva os endereços de todo o
resto. Então o arranjo é:

| o quê | instrução | por quê |
|---|---|---|
| a página HTML | `no-cache` | sempre conferida; em geral respondida `304` |
| arquivos com hash | `max-age=31536000, immutable` | o nome garante o conteúdo |
| imagens e fontes com nome próprio | um `max-age` longo | mudam raramente, e dá para renomear |
| respostas de uma interface | decidido por endereço | algumas são públicas, a maioria é `private` |

O `immutable` merece uma linha: ele diz ao navegador para nem fazer uma requisição condicional quando
o visitante aperta recarregar. Sem ele, um recarregar revalida tudo, que é exatamente a ida e volta
que você estava tentando evitar.

## O que dá para purgar, e o que não

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma CDN e um cache dentro da sua própria rede podem ser esvaziados sob demanda. O cache do navegador de um visitante não dá para alcançar.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">seus para esvaziar</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"42\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a CDN — um purge, segundos a minutos</text> <rect x=\"20\" y=\"86\" width=\"320\" height=\"42\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um cache dentro da sua própria rede</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">não são seus</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"42\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o navegador de cada visitante</text> <rect x=\"380\" y=\"86\" width=\"320\" height=\"42\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um proxy no empregador de alguém</text> <text x=\"360\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">generoso na borda, preciso no navegador</text> <text x=\"360\" y=\"200\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">um erro à esquerda é um botão; um erro à direita é uma espera que não dá para encurtar</text> </svg>", "caption": "A assimetria decide a política inteira: um lado tem desfazer e o outro não."}
```

Uma CDN é um cache com o qual você tem conta, então dá para esvaziar: todo provedor tem um purge, e
leva de segundos a minutos. O mesmo vale para um cache dentro da sua própria rede.

O navegador de um visitante não é seu, e não existe purge. O que você prometeu, prometeu.

Essa é a assimetria inteira, e ela decide como ter cuidado: **seja generoso com tempos de cache na
borda, e preciso com eles no navegador.** Um erro na borda é um botão. Um erro num navegador é um
número de visitantes que você não consegue contar, segurando um arquivo que você não alcança, pelo
tempo que você mandou.

## O cache que o seu próprio código controla

Há mais um, e ele merece ser nomeado porque as falhas dele são memoráveis.

Um **service worker** é um pedaço do seu próprio código que o navegador roda entre a página e a
rede, e ele consegue servir requisições de um repositório que administra. É o que faz um site
funcionar sem conexão e o que faz alguns sites abrirem instantaneamente.

É também um cache com os seus bugs dentro. A falha clássica é um service worker que cacheia a página
e a si mesmo, incorretamente, de modo que um visitante que carregou a versão quebrada é servido com a
versão quebrada para sempre — por um código que você escreveu, rodando no navegador dele, que já não
pergunta nada a você. Sites já precisaram publicar uma versão deliberadamente autodesinstalável para
se recuperar.

A regra por ora é saber o que é quando você vir um no painel, e tratar acrescentar um como uma decisão
em vez de uma caixinha para marcar.

## Por que este bug nunca se reproduz

A última coisa, e é a razão de problemas de cache demorarem tanto para serem corrigidos.

A pessoa depurando é a pessoa que vem recarregando o site o dia inteiro, muitas vezes com o cache
desativado nas ferramentas de desenvolvedor. O navegador dela não guarda nada antigo. As pessoas
afetadas são as que visitaram há uma semana e não voltaram desde então, e não há como virar uma delas
a não ser limpando tudo e esperando.

Então o hábito útil é conferir os cabeçalhos em vez do comportamento: pergunte qual instrução o
servidor de fato mandou, leia, e decida se é o que você quis dizer. A resposta está na resposta, e é
a mesma para todo mundo — o que é mais do que se pode dizer do sintoma.
