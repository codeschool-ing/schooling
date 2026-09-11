---
title: Lendo um nome da direita
version: 1
---

`app.codeschool.ing` parece que deveria ser lido do jeito que você lê uma frase. É ao contrário: a
parte que mais importa está no fim, e cada ponto é um passo para dentro de algo que a parte à
direita dele delegou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"O nome staging.api.codeschool.ing lido da direita: a raiz invisível, depois o domínio de topo ing, depois o domínio registrado codeschool, depois dois subdomínios. Cada nível delega ao que está à sua esquerda.\"> <text x=\"360\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">leia da direita, porque é a ordem em que é respondido</text> <rect x=\"20\" y=\"40\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"95\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">staging</text> <rect x=\"182\" y=\"40\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"257\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">api</text> <rect x=\"344\" y=\"40\" width=\"180\" height=\"46\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"434\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">codeschool</text> <rect x=\"536\" y=\"40\" width=\"104\" height=\"46\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"588\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">ing</text> <rect x=\"652\" y=\"40\" width=\"48\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"4 3\"></rect> <text x=\"676\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">.</text> <text x=\"676\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a raiz</text> <text x=\"588\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o TLD</text> <text x=\"434\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o que você registra</text> <text x=\"257\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">seu para inventar</text> <text x=\"95\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">e este também</text> <rect x=\"20\" y=\"140\" width=\"680\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a raiz sabe quem administra ing, e mais nada</text> <text x=\"360\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">quem administra ing sabe quais servidores respondem por codeschool</text> <text x=\"360\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">esses servidores sabem tudo que está à esquerda</text> <text x=\"360\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">ninguém guarda a lista inteira, e nunca guardou</text> </svg>", "caption": "Cada ponto é uma delegação. Cada nível sabe uma coisa: a quem perguntar em seguida."}
```

## As partes

Lá na direita, depois de um ponto que ninguém digita, está a **raiz**. Ela é real, é escrita como um
rótulo vazio, e a única razão de você nunca a ver é que o software a acrescenta por você.

Depois o **domínio de topo**: `ing`, `com`, `br`, `org`. Há mais de mil, e vêm em tipos
reconhecíveis — o punhado original, os de duas letras que pertencem a países, e as várias centenas
mais novos que são palavras. Cada um é administrado por uma organização que decide o que entra
debaixo dele.

Depois o **domínio** que você registra: `codeschool`. Esta é a parte que alguém pagou, e o par
`codeschool.ing` é o assunto da próxima leitura.

E à esquerda disso, **subdomínios**: `app`, `www`, `api`, `mail`, e qualquer outro que você queira,
inclusive com vários pontos — `staging.api.codeschool.ing` é perfeitamente comum. Esses não custam
nada e são seus para inventar, que é o fato mais útil desta leitura.

## Delegação é o projeto inteiro

Cada nível entrega a responsabilidade ao nível abaixo, e para de se importar.

A raiz não sabe que `codeschool.ing` existe. Ela sabe quem administra `ing`, e é tudo que ela já
soube. Quem administra `ing` não sabe o que há dentro de `codeschool.ing`; sabe quais servidores
foram nomeados como respondendo por ele. E esses servidores conhecem os subdomínios, porque é ali
que as pessoas donas do domínio os colocaram.

É isto que o vídeo de abertura quis dizer com um banco de dados sem centro. Não existe lista. Existe
uma cadeia de *pergunte àquele ali*, e cada passo dela é responsabilidade de outra pessoa, e é por
isso que o sistema seguiu funcionando através de trinta anos de crescimento que ninguém planejou.

## `www` é um subdomínio como outro qualquer

Vale dizer com clareza, porque causa confusão de verdade: `www` não é especial. É um subdomínio que
alguém criou, por convenção, numa época em que as máquinas de uma empresa eram nomeadas pelo que
faziam — `www` para o servidor web, `ftp` para transferência de arquivos, `mail` para o servidor de
correio.

Então `example.com` e `www.example.com` são dois nomes diferentes, e um site tem que decidir qual é
o de verdade e mandar o outro para lá. Qual dos dois você escolhe quase não importa; não escolher
nenhum é o que produz duas cópias de um site, dois conjuntos de cookies, e buscadores tratando-os
como lugares separados.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Um site que responde tanto no domínio puro quanto no nome www sem redirecionar produz duas cópias: dois conjuntos de cookies, duas entradas nos resultados de busca e dois lugares para manter corretos.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">os dois respondem, nenhum redireciona</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">example.com e www.example.com</text> <rect x=\"20\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">dois conjuntos de cookies, duas sessões</text> <rect x=\"20\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">duas entradas num resultado de busca</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">um é canônico, o outro redireciona</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">um nome, e um 301 vindo do outro</text> <rect x=\"380\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um conjunto de cookies, uma sessão</text> <rect x=\"380\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">um lugar para manter correto</text> <text x=\"360\" y=\"200\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">qual dos dois você escolhe importa muito pouco</text> <text x=\"360\" y=\"226\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">não escolher nenhum é o que custa, e custa em três lugares de uma vez</text> </svg>", "caption": "São dois nomes diferentes. Software os trata como dois sites diferentes, porque são."}
```

A escolha tem uma pequena aresta prática que vale conhecer. Um nome sem nada à esquerda — um
**domínio puro** — tem uma restrição que você vai encontrar na leitura sobre registros: ele não pode
ser apontado para outro nome do jeito comum, só para um endereço. Provedores contornaram isso com
extensões próprias, e é a razão de alguma documentação de hospedagem insistir discretamente no
`www`.

## Regras sobre os caracteres

Curtas, e cada uma poupa uma discussão.

Rótulos — as partes entre pontos — vão até 63 caracteres, e o nome inteiro até 255. Letras, dígitos e
hifens; nenhum hífen no começo ou no fim. Maiúsculas são completamente ignoradas: `CodeSchool.ing` e
`codeschool.ing` são o mesmo nome, sempre.

Nomes em outros alfabetos existem e funcionam — `café.fr`, nomes em árabe, em chinês — e são
carregados por uma tradução para o alfabeto restrito que acontece dentro do resolvedor, produzindo
os nomes de aparência estranha começados em `xn--` que você talvez já tenha visto num log.

Esse mecanismo tem uma consequência de segurança que merece uma linha: alguns caracteres de um
alfabeto são visualmente idênticos a caracteres de outro, então dá para registrar um nome visualmente
idêntico a um famoso. Navegadores se defendem mostrando a forma traduzida quando um nome mistura
alfabetos de forma suspeita, e é a razão de um site legítimo às vezes aparecer como um `xn--`
ininteligível.

## Onde a fronteira da propriedade realmente fica

Uma sutileza, porque ela decide algo que você viu na aula passada.

Um navegador precisa saber onde o território de um dono acaba, para que uma página em
`shop.example.com` não consiga definir um cookie para `example.com` se esses pertencerem a pessoas
diferentes. Para a maioria dos nomes a regra parece óbvia — um rótulo à esquerda do TLD é o domínio
registrado — e para um bocado deles ela está errada.

`example.co.uk` é um registro; `co.uk` não é algo que alguém possua. `seunome.github.io` é um
registro de certo tipo; `github.io` distribui nomes a estranhos, e um cookie definido para ele
alcançaria todos eles.

Então navegadores trazem uma lista publicada dessas fronteiras — a **lista de sufixos públicos** —
mantida aberta e atualizada conforme novos arranjos aparecem. É ela que impede um cookie de ser
definido para `.com`, e é por isso que um provedor que distribui subdomínios a clientes pede para
entrar nela.

Duas coisas seguem daí. A regra do *que conta como um site* é uma lista e não um algoritmo. E se
você um dia distribuir subdomínios a pessoas que não são você, a lista é algo em que você precisa
estar.

## O que isso compra para você, hoje

Duas coisas para levar ao resto da aula.

**Uma compra, nomes ilimitados.** Comprar `codeschool.ing` quer dizer que todo nome debaixo dele é
seu para criar, de graça, na hora, sem terceiros envolvidos. Um ambiente novo, um serviço novo, um
endereço específico de um cliente — todos são uma linha num arquivo que você já controla.

**Nada num nome diz para onde ele aponta.** `app.codeschool.ing` e `www.codeschool.ing` podem estar
em continentes diferentes, em provedores diferentes, e o nome não dá pista nenhuma. Um nome é uma
pergunta, e as próximas leituras são sobre quem responde.
