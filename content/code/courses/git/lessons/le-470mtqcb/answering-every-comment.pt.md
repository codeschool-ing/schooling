---
title: Respondendo a cada comentário
version: 1
---

**Todo comentário recebe resposta**, mesmo que a resposta seja uma palavra. Quem revisou e volta a quatro
comentários e acha duas respostas não sabe se os outros dois foram feitos, perdidos ou ignorados.

## O que bloqueia: corrija

O Bruno corrige o campo vazio e, já que está naquela linha, responde também à pergunta: o horário de
funcionamento vai para o input como `min` e `max`:

```
bruno@vm:~/site$ git diff
diff --git a/order.html b/order.html
index 49c300b..3a0bdcf 100644
--- a/order.html
+++ b/order.html
@@ -1,5 +1,5 @@
 <h1>Order ahead</h1>
 <form class="order">
-  <label>Pickup time <input name="pickup" type="time"></label>
+  <label>Pickup time <input name="pickup" type="time" min="06:00" max="19:00" required></label>
   <button>Order</button>
 </form>
bruno@vm:~/site$ git commit -qam 'Require a pickup time within opening hours' -m 'Refs #30'
```

**A correção é um commit novo no mesmo branch.** A aula 11 disse por que não reescrever commits que alguém
já revisou: a Ana teria de ler todos de novo para achar o que mudou. Como commit novo, "o que mudou desde
que eu olhei" é exatamente um commit. Muitas equipes fazem squash no merge de todo jeito (aula 8), então os
commits a mais nunca chegam ao `main` como bagunça.

## O que está fora do escopo: mova

A mudança de cor sai deste branch, também como commit novo, e deixa o `style.css` só com a regra de que o
formulário precisa:

```
bruno@vm:~/site$ git commit -qam 'Leave the heading colour for its own pull request' -m 'Refs #30'
bruno@vm:~/site$ git diff main... -- style.css
diff --git a/style.css b/style.css
index 773418d..588dd5d 100644
--- a/style.css
+++ b/style.css
@@ -1 +1,2 @@
 h1 { color: darkorange; }
+.order label { display: block; }
```

Depois tudo sobe de uma vez:

```
bruno@vm:~/site$ git log --oneline main..
809c6c8 Leave the heading colour for its own pull request
2ff9efa Require a pickup time within opening hours
8b19b3c Style the order form
4156a0f Let customers choose a pickup time
bruno@vm:~/site$ git push
Enumerating objects: 9, done.
Counting objects: 100% (9/9), done.
Delta compression using up to 4 threads
Compressing objects: 100% (6/6), done.
Writing objects: 100% (6/6), 719 bytes | 719.00 KiB/s, done.
Total 6 (delta 2), reused 0 (delta 0), pack-reused 0
To /home/ana/remotes/site.git
   8b19b3c..809c6c8  30-pickup-times -> 30-pickup-times
```

O servidor aqui é a pasta da aula 7, fazendo o papel do GitHub. O pull request agora mostra quatro commits,
e quem revisa pode olhar só os dois últimos. A ideia da cor não se perde: ela ganha um ticket próprio, o
#32, e um branch próprio, começado do `main` para não levar nada do #31:

```
bruno@vm:~/site$ git switch -c 32-heading-colour main
Switched to a new branch '32-heading-colour'
bruno@vm:~/site$ git commit -qam 'Darken the heading colour' -m 'Refs #32'
bruno@vm:~/site$ git push -u origin 32-heading-colour
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 4 threads
Compressing objects: 100% (2/2), done.
Writing objects: 100% (3/3), 294 bytes | 294.00 KiB/s, done.
Total 3 (delta 1), reused 0 (delta 0), pack-reused 0
To /home/ana/remotes/site.git
 * [new branch]      32-heading-colour -> 32-heading-colour
branch '32-heading-colour' set up to track 'origin/32-heading-colour'.
```

Ele virou o pull request #33, e vai ser revisado, e entrar ou não, pelos próprios méritos.

## As respostas

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A ida e volta do pull request 31 entre duas faixas, o Bruno em cima e a Ana embaixo. Em 24 de setembro o Bruno abre o 31 com dois commits, e a Ana o revisa com quatro comentários. Em 25 de setembro o Bruno responde aos quatro e envia dois commits; a Ana relê e aprova; o Bruno faz o merge, e o 31 fecha o ticket 30.\"><defs><marker id=\"rd-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Bruno</text><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Ana</text><rect x=\"84\" y=\"48\" width=\"112\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">abre o #31</text><text x=\"140\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">dois commits</text><path d=\"M180 92 L225 148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rd-ah)\"></path><rect x=\"209\" y=\"148\" width=\"112\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"265\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">revisa</text><text x=\"265\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4 comentários</text><path d=\"M305 148 L350 92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rd-ah)\"></path><rect x=\"334\" y=\"48\" width=\"112\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"390\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">responde aos 4</text><text x=\"390\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">envia 2 commits</text><path d=\"M430 92 L475 148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rd-ah)\"></path><rect x=\"459\" y=\"148\" width=\"112\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"515\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">relê</text><text x=\"515\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">aprova</text><path d=\"M555 148 L600 92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rd-ah)\"></path><rect x=\"584\" y=\"48\" width=\"112\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"640\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">faz o merge</text><text x=\"640\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">#31 fecha o #30</text><path d=\"M327 26 L327 214\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"320\" y=\"30\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">24 de setembro</text><text x=\"334\" y=\"30\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">25 de setembro</text></svg>", "caption": "Uma rodada de comentários e uma de respostas. Todo comentário teve resposta, e nada foi reescrito: as correções são commits novos.", "same": ["Bruno", "Ana"]}
```

As quatro respostas do Bruno, uma em cada conversa:

- *"Corrigido no 2ff9efa, obrigado, boa."*
- *"Boa pergunta: agora limitado a 06:00–19:00, no mesmo commit."*
- *"Mantive Order para combinar com o título, Order ahead. Troco se você fizer questão."*
- *"Movido para o #33."*

Cada uma aponta o que mudou, e a terceira recusa um nit com um motivo, que é exatamente o que um nit
permite. Algumas equipes deixam quem escreveu apertar *Resolve conversation* depois de responder; outras
deixam isso para quem revisou, que sabe se a resposta o satisfez. Os dois jeitos funcionam se todo mundo
fizer igual.
