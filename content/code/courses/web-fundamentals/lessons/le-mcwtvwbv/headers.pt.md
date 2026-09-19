---
title: As linhas do meio
version: 1
---

Entre a linha inicial e a linha em branco fica uma lista de pares `Nome: valor`. É ali que mora
quase tudo que é interessante sobre uma requisição, e há só alguns que você precisa reconhecer
nesta altura.

## `Content-Type`, que decide o que a coisa *é*

Uma resposta é um monte de bytes. O `Content-Type` é a única coisa que diz o que eles significam.

```
Content-Type: text/html; charset=utf-8
```

Duas partes. O tipo — `text/html`, `application/json`, `image/png` — e muitas vezes um parâmetro,
aqui a codificação de caracteres.

Erre isso e nada mais salva.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Os mesmos bytes enviados duas vezes com tipos de conteúdo diferentes. Declarados como HTML são desenhados como um título; declarados como texto puro as marcações aparecem como caracteres.\"> <rect x=\"20\" y=\"26\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">os bytes no fio: &lt;h1&gt;Preço&lt;/h1&gt;</text> <rect x=\"20\" y=\"84\" width=\"330\" height=\"120\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect> <text x=\"185\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Content-Type: text/html</text> <text x=\"185\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-weight=\"600\" font-size=\"22\" fill=\"var(--paper)\">Preço</text> <text x=\"185\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">desenhado como título</text> <rect x=\"370\" y=\"84\" width=\"330\" height=\"120\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".14\" stroke=\"var(--amber)\"></rect> <text x=\"535\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Content-Type: text/plain</text> <text x=\"535\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&lt;h1&gt;Preço&lt;/h1&gt;</text> <text x=\"535\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mostrado como os caracteres que são</text> <text x=\"360\" y=\"230\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">o navegador fez o que mandaram nas duas vezes; só um dos dois rótulos estava certo</text> </svg>", "caption": "Nada nos bytes diz o que eles são. Um cabeçalho diz, e tudo adiante acredita nele.", "same": ["Preço"]}
```

Os mesmos bytes, rotulados `text/html`, viram um título; rotulados `text/plain`, são mostrados como
os caracteres que são. Nenhum dos dois é falha do navegador: ele fez o que mandaram, e o que
mandaram estava errado.

A metade do `charset` se comporta mal mais silenciosamente. Declare `utf-8` e envie outra coisa e os
caracteres acentuados viram um punhado de interrogações e quadradinhos — o defeito que só aparece
em idiomas que quem construiu não fala, e é por isso que ele sobrevive tanto tempo em tantos
sistemas.

Duas regras saem daí, e são curtas. **Diga o que é, sempre.** E quando estiver produzindo texto em
qualquer idioma que tenha acentos, **diga `utf-8`**.

## `Content-Length`, e seus dois modos de falhar

O tamanho do corpo em bytes, que é como a outra ponta sabe onde uma resposta acaba.

É contado em **bytes, não em caracteres**, e num idioma com letras acentuadas esses não são o mesmo
número. Uma string de doze caracteres visíveis pode ter quatorze bytes, e um tamanho calculado
contando caracteres é uma resposta cujo fim quem recebe vai esperar para sempre.

A outra falha é mais sutil: um tamanho maior que a realidade deixa uma conexão pendurada, e um
tamanho menor que a realidade deixa bytes sobrando para serem lidos como o começo do que vier a
seguir. Os dois são o tipo de defeito que se comporta de forma diferente conforme haja um proxy no
caminho, o que os torna memoráveis de depurar.

## `Host`, que transformou uma máquina em muitas

Já mencionado e vale dizer mais uma vez com clareza: o `Host` nomeia o site. O endereço achou a
máquina; este cabeçalho escolhe qual das centenas de sites nela você queria.

Sem ele, um servidor podia hospedar um site por endereço. Com ele, uma máquina pequena responde por
mil nomes, e faz isso desde o dia em que o HTTP/1.1 passou a exigi-lo.

## `User-Agent`, que é quase todo ficção

Todo navegador envia uma linha se descrevendo. Aqui está uma real, desmontada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma string de user agent real desmontada linha a linha. Quatro dos seus seis fragmentos são alegações de ser outros navegadores, acumuladas por décadas. Duas são verdade: o sistema por baixo e o navegador que de fato pede.\"> <text x=\"20\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">uma string real, um fragmento por linha</text> <rect x=\"20\" y=\"32\" width=\"220\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"130\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Mozilla/5.0</text> <text x=\"256\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">um navegador descontinuado em 2008</text> <rect x=\"20\" y=\"74\" width=\"220\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"130\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">(X11; Linux x86_64)</text> <text x=\"256\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">verdade — o sistema por baixo</text> <rect x=\"20\" y=\"116\" width=\"220\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"130\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AppleWebKit/537.36</text> <text x=\"256\" y=\"134\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">o motor que o Safari usa, e este não é</text> <rect x=\"20\" y=\"158\" width=\"220\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"130\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">(KHTML, like Gecko)</text> <text x=\"256\" y=\"176\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">mais dois motores, e nenhum deles é este</text> <rect x=\"20\" y=\"200\" width=\"220\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"130\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Chrome/140.0.0.0</text> <text x=\"256\" y=\"218\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">verdade — o navegador que de fato pede</text> <rect x=\"20\" y=\"242\" width=\"220\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"130\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Safari/537.36</text> <text x=\"256\" y=\"260\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Safari de novo, caso uma vez não bastasse</text> </svg>", "caption": "Cada alegação aqui foi acrescentada porque algum site um dia recusou servir um navegador que não reconheceu."}
```

Dois fragmentos daquilo são verdade. O resto é uma cadeia de alegações de ser outros navegadores,
acumuladas por trinta anos por um motivo: sites conferiam a string e se recusavam a servir o que não
reconhecessem. Então cada navegador novo alegava ser os anteriores, sempre, até a string virar um
registro arqueológico de quais navegadores um dia valeu a pena fingir ser.

Duas conclusões práticas. **Não decida o que enviar com base nessa string** — é o hábito que criou a
bagunça, e a resposta moderna é perguntar o que o navegador consegue fazer em vez de como ele se
chama. E quando você vir uma estranha num log, lembre que qualquer um pode enviar qualquer coisa
ali; é uma alegação, não uma medição.

## Requisição, resposta, e os que vão nas duas direções

Alguns cabeçalhos só fazem sentido numa direção. O `Accept` é uma requisição pedindo um formato; o
`Content-Type` descreve um corpo, então aparece numa resposta e em qualquer requisição que tenha um.
O `Date` aparece nos dois. `Server` e `Set-Cookie` são só de resposta.

Três detalhes mecânicos que economizam uma tarde cada.

**Nomes ignoram maiúsculas.** `content-type` e `Content-Type` são o mesmo cabeçalho, e softwares
diferentes escrevem diferente.

**Um cabeçalho pode aparecer mais de uma vez**, e para a maioria deles isso é o mesmo que um
cabeçalho com os valores separados por vírgula. O `Set-Cookie` é a exceção famosa, que é parte de
por que cookies são chatos de tratar.

**Valores são texto, e texto tem limites.** Servidores limitam o tamanho total dos cabeçalhos —
muitas vezes perto de oito kilobytes — e passar disso rende uma resposta sobre um cabeçalho grande
demais em vez de qualquer coisa sobre o que você estava tentando fazer. É quase sempre um cookie que
cresceu.

## Seus próprios cabeçalhos

Você pode inventar um. `X-Request-Id` e parentes são texto comum que qualquer coisa que não os
espere ignora.

A convenção era que um cabeçalho privado começasse com `X-`, e essa convenção foi retirada, porque
`X-` cabeçalhos demais viraram padrão e depois tiveram que manter um prefixo dizendo que não eram.
Escolha um nome que não colida e use sem o prefixo.
