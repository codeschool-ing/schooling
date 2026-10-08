---
title: Conferindo o HTML com um validador
version: 2
---

Você já viu o navegador consertar três tipos de erro sem dizer nada. **Um validador** é o programa que diz: ele lê o seu arquivo contra as regras do HTML e lista cada lugar em que o arquivo as quebra. Ele não desenha a página e não adivinha.

Este curso usa o `html-validate`, um validador que roda na sua própria máquina, o que a seção 03 instalou em `~/site` junto com o seu `.htmlvalidate.json`. A alternativa mais conhecida é o Nu HTML Checker do W3C, em `validator.w3.org`, que você usa colando uma página num formulário; os dois concordam sobre o que é HTML e discordam em algumas questões de estilo.

## A página quebrada, lida por um validador

Aqui está o `broken.html` da seção 09, a página que parecia certa:

```
ana@laptop:~/site$ npx html-validate -f text broken.html
/home/ana/site/broken.html:2:2: error [close-order] Unclosed element '<html>'
/home/ana/site/broken.html:8:2: error [close-order] Unclosed element '<p>'
/home/ana/site/broken.html:9:2: error [close-order] Unclosed element '<p>'
/home/ana/site/broken.html:9:2: error [element-permitted-content] <p> element is not permitted as content under <b>
/home/ana/site/broken.html:9:15: error [close-order] Unclosed element '<i>'
/home/ana/site/broken.html:9:33: error [close-order] End tag '</b>' seen but there were open elements
/home/ana/site/broken.html:10:2: error [element-permitted-content] <p> element is not permitted as content under <b>
/home/ana/site/broken.html:10:15: error [element-permitted-content] <div> element is not permitted as content under <b>
/home/ana/site/broken.html:11:2: error [close-order] End tag '</body>' seen but there were open elements
```

Cada linha é um arquivo, uma linha e uma coluna, o nome de uma regra entre colchetes e o que está errado. Ele encontrou os três consertos da seção 09: os `<p>` implicitamente dentro do `<b>`, o `</b>` encontrado com o `<i>` ainda aberto, e a `<div>` que um `<b>` não pode conter, na linha 10.

Ele também apontou os `<p>` não fechados nas linhas 8 e 9, e isso é questão de estilo, não da linguagem. **O HTML deixa você omitir o `</p>`**: o padrão diz que um parágrafo termina quando o próximo bloco começa, e o navegador segue isso. A predefinição deste validador aponta mesmo assim, porque numa página que fecha todo elemento o próximo erro fica fácil de ver. O curso concorda com ele, e toda página daqui em diante fecha os seus parágrafos.

## A página em branco

```
ana@laptop:~/site$ npx html-validate -f text unclosed-title.html
/home/ana/site/unclosed-title.html:5:8: error [parser-error] failed to tokenize "Opening ho...", expected </title>.
```

Uma linha, na linha 5, coluna 8: o título abriu e a tag de fechamento nunca foi encontrada. É a página cuja janela ficou em branco, e o validador aponta o lugar exato em dois segundos, quando olhar para a tela não teria mostrado nada.

## O doctype que falta

```
ana@laptop:~/site$ npx html-validate -f text quirks.html
/home/ana/site/quirks.html:1:1: error [missing-doctype] Document is missing doctype
```

A página da seção 08 que tinha 4 pixels a menos. O navegador nunca mencionou o modo de compatibilidade, e o validador o nomeia na linha 1.

## Um arquivo limpo não diz nada

```
ana@laptop:~/site$ npx html-validate -f text skeleton.html; echo "exit status $?"
exit status 0
```

**Nenhuma saída e um status de saída 0** é aprovação, e é isso que uma ferramenta de linha de comando quer dizer com sucesso. É também o que torna um validador útil fora da sua máquina: um projeto pode rodá-lo a cada mudança e recusar a que falhar, e assim uma página quebrada nunca chega a ninguém. `testing-cicd` é onde verificações assim são construídas.

## O que um validador não consegue dizer

Um validador confere as regras da linguagem. Ele não consegue dizer que um título não é de verdade um título, que uma página tem três `<h1>` quando queria dizer um, ou que um link diz *clique aqui*. Essas são perguntas sobre significado, e são a aula 2. Ele também não diz nada sobre a aparência da página, que é tudo da aula 5 em diante.
