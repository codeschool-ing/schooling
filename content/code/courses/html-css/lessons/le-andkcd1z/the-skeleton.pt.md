---
title: O documento de onde toda página parte
version: 1
---

Toda página HTML que você escrever parte das mesmas doze linhas. Aqui estão elas para a primeira página do sebo, com a função de cada parte ao lado:

```schooling-example
{"language": "html", "file": "skeleton.html", "parts": [
 {"code": "<!doctype html>", "note": "Diz que a página é HTML moderno. Sem isso o navegador recorre a um conjunto de regras mais antigo, seção 06."},
 {"code": "<html lang=\"en\">", "note": "O elemento raiz: todo o resto está dentro dele. `lang` diz a língua do conteúdo, que decide a voz que um leitor de tela usa e como as palavras são hifenizadas."},
 {"code": "  <head>\n    <meta charset=\"utf-8\">\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n    <title>Andorinha Books</title>\n  </head>", "note": "Informações sobre a página, nenhuma delas desenhada. A codificação de caracteres, como dimensionar a página no celular (as duas na seção 08) e o título que o navegador mostra na aba."},
 {"code": "  <body>\n    <h1>Andorinha Books</h1>\n    <p>Second-hand books in Pinheiros, São Paulo.</p>\n  </body>", "note": "A página em si: tudo o que o leitor vê está aqui dentro."},
 {"code": "</html>", "note": "Fecha a raiz, e o documento termina."}
]}
```

Abra o arquivo num navegador e você tem um título e uma frase numa página branca: exatamente o que o body diz, desenhado com os estilos padrão do navegador. Tudo acima de `<body>` é invisível, e mesmo assim é lido por todo navegador que abre a página.

## A árvore que o navegador monta

O navegador não guarda o texto. Ele o lê uma vez, de cima para baixo, e monta uma **árvore** de elementos: o **DOM**, que a aula 10 de `web-fundamentals` apresentou. O arquivo acima vira isto:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"O documento esqueleto como árvore. html é a raiz, com lang igual a en. Tem dois filhos: head, que guarda o meta charset, o meta viewport e o title, e body, que guarda o h1 e o parágrafo. Nada do head é desenhado na página; tudo no body é o que o leitor vê.\"><rect x=\"410\" y=\"66\" width=\"296\" height=\"210\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><rect x=\"14\" y=\"66\" width=\"352\" height=\"200\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><line x1=\"360\" y1=\"48\" x2=\"190\" y2=\"90\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"360\" y1=\"48\" x2=\"530\" y2=\"90\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"190\" y1=\"118\" x2=\"70\" y2=\"166\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"190\" y1=\"118\" x2=\"190\" y2=\"166\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"190\" y1=\"118\" x2=\"318\" y2=\"166\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"530\" y1=\"118\" x2=\"470\" y2=\"166\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"530\" y1=\"118\" x2=\"600\" y2=\"166\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><rect x=\"283.4\" y=\"20\" width=\"153.2\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;html lang=&quot;en&quot;&gt;</text><rect x=\"154.4\" y=\"90\" width=\"71.2\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"190\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;head&gt;</text><rect x=\"494.4\" y=\"90\" width=\"71.2\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;body&gt;</text><rect x=\"11\" y=\"166\" width=\"118\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;meta charset&gt;</text><rect x=\"128\" y=\"166\" width=\"124\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"190\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;meta viewport&gt;</text><rect x=\"275\" y=\"166\" width=\"86\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"318\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;title&gt;</text><rect x=\"440\" y=\"166\" width=\"60\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;h1&gt;</text><rect x=\"570\" y=\"166\" width=\"60\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">&lt;p&gt;</text><text x=\"318\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Andorinha Books</text><text x=\"470\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Andorinha Books</text><text x=\"600\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Second-hand books…</text><text x=\"190\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sobre a página: nada aqui é desenhado</text><text x=\"540\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a página em si: o que o leitor vê</text></svg>", "caption": "Todo elemento tem exatamente um pai, e o documento inteiro pende do elemento html."}
```

Três palavras para posições na árvore aparecem em toda aula de CSS, então vale fixá-las agora. `<head>` e `<body>` são **filhos** de `<html>`, e `<html>` é o **pai** deles. `<h1>` e `<p>` são **irmãos**, porque têm o mesmo pai. E todo elemento dentro de `<body>`, em qualquer profundidade, é um dos seus **descendentes**. A aula 5 escolhe elementos exatamente por essas relações: "um parágrafo que é filho de uma section" é um seletor CSS.

A árvore também é o que um leitor de tela usa, e `probe tree` imprime a visão dele. Para o esqueleto ele encontrou um título de nível 1 e um parágrafo, e nada do head, o que está correto:

```
ana@laptop:~/site$ probe skeleton.html title tree
title: "Andorinha Books"
- heading "Andorinha Books" [level=1]
- paragraph: Second-hand books in Pinheiros, São Paulo.
```

`head` e `body` não aparecem: são estrutura, e nada no head é conteúdo. A primeira linha vem de outro passo, `title`, que imprime o nome do documento inteiro: o nome que um leitor de tela anuncia quando a página abre.

## A indentação é para você

O navegador ignora a indentação, e as linhas significariam o mesmo escritas numa linha só, comprida. Ela está ali porque quem lê o arquivo precisa ver que elemento está dentro de qual. Dois espaços por nível é comum e é o que este curso usa; o que importa é o arquivo ser consistente, porque uma indentação inconsistente esconde uma tag de fechamento faltando melhor do que qualquer outra coisa.
