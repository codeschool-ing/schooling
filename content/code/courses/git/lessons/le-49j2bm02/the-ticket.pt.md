---
title: Antes do código: o ticket
version: 2
---

**Toda mudança que uma equipe faz começa em algum lugar fora do código.** Um cliente reclama, um gestor
pede alguma coisa, alguém do time nota um bug enquanto corrige outro. A aula 8 chamou o lugar onde isso é
escrito de issue; a maioria das equipes chama de **ticket**, e a aula 15 mostra o quadro onde eles vivem.
Esta aula segue um ticket do momento em que é escrito até o momento em que a mudança dele está rodando.

## O que o ticket diz

A padaria fecha nos feriados e o site nunca diz isso. O Bruno escreve:

> **#23 Os feriados não aparecem no site**
>
> Dois clientes vieram em 7 de setembro e encontraram a porta fechada. A página inicial mostra o
> horário, mas não diz nada sobre feriados.
>
> Pronto quando: a página inicial disser que fechamos nos feriados, e o aviso for fácil de ver.

Três partes, e cada uma tem motivo para estar ali:

- **O título diz o que está errado**, não como corrigir. *"Pôr um parágrafo no index.html"* decidiria a
  resposta antes de alguém olhar a pergunta.
- **A descrição diz o que aconteceu e por que importa.** Quem pegar isso na semana que vem, ou no ano que
  vem, precisa mais do motivo que das instruções.
- **A última linha diz como todo mundo vai saber que terminou.** As equipes chamam isso de *critérios de
  aceite*. Sem eles, "pronto" quer dizer o que quem faz o trabalho decidir, e a aula 16 é sobre os tickets
  que começaram sem nenhum.

## Pegando o ticket

A Ana pega: atribui a si mesma, para ninguém começar o mesmo trabalho, e move para *em andamento*. Daqui
em diante, **o número `23` é o fio.** Ele vai para o nome do branch, para cada commit, para o pull request,
e ainda está lá na release:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 344\" role=\"img\" aria-label=\"A vida de uma tarefa, de cima para baixo. Ticket número 23, os feriados não aparecem no site: por que o trabalho existe. O branch 23-holiday-notice, com o nome do ticket. Commits com Refs #23, cada um apontando de volta. Pull request 24, cuja descrição diz Closes #23, então fecha o ticket quando entrar. A revisão: comentários, depois uma aprovação, por outra pessoa. O merge, Merge pull request #24, onde o ticket fecha. A release, tag v1.1, onde a tarefa termina.\"><defs><marker id=\"jn-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30 28 L30 304\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"30\" cy=\"28\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"48\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">ticket</text><rect x=\"170\" y=\"13\" width=\"280\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"182\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">#23 Os feriados não aparecem no site</text><text x=\"466\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">por que o trabalho existe</text><circle cx=\"30\" cy=\"74\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"48\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">branch</text><rect x=\"170\" y=\"59\" width=\"280\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"182\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">23-holiday-notice</text><text x=\"466\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">com o nome do ticket</text><circle cx=\"30\" cy=\"120\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"48\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">commits</text><rect x=\"170\" y=\"105\" width=\"280\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"182\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Refs #23</text><text x=\"466\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cada um aponta de volta</text><circle cx=\"30\" cy=\"166\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"48\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">pull request</text><rect x=\"170\" y=\"151\" width=\"280\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"182\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">#24  Closes #23</text><text x=\"466\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">fecha o #23 quando entrar</text><circle cx=\"30\" cy=\"212\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"48\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">revisão</text><rect x=\"170\" y=\"197\" width=\"280\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"182\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">comentários, depois uma aprovação</text><text x=\"466\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">outra pessoa lê</text><circle cx=\"30\" cy=\"258\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"48\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">merge</text><rect x=\"170\" y=\"243\" width=\"280\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"182\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Merge pull request #24</text><text x=\"466\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o ticket fecha aqui</text><circle cx=\"30\" cy=\"304\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"48\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">release</text><rect x=\"170\" y=\"289\" width=\"280\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"182\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">v1.1</text><text x=\"466\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">a tarefa termina aqui</text></svg>", "caption": "O número do ticket passa por todos os passos, e é assim que uma linha de código ainda leva ao seu motivo um ano depois.", "same": ["ticket", "branch", "commits", "pull request", "merge", "release"]}
```

Nada disso é imposto pelo Git. É um hábito, e ele se paga no dia em que alguém roda `git blame` no aviso
de feriado (aula 3), acha o commit, lê `Refs #23` e chega ao ticket com a história do Bruno sobre a porta
fechada. Sem o número, a pessoa acha uma linha de HTML e tem de adivinhar por que ela está ali.

## A mesma tarefa na sua máquina

O resto desta aula acompanha o terminal da Ana, e três coisas nele ainda não estão na sua máquina:
uma cópia compartilhada com a `v1.0` marcada, a tarefa #21 do Bruno já integrada, e um serviço de
hospedagem para fazer o merge dos pull requests. A primeira é o arranjo da aula 7, a partir de uma
semana nova:

```bash
cd ~ && rm -rf ~/site ~/remotes ~/platform && bash ~/make-site.sh && cd ~/site
git tag -a v1.0 -m 'The site as it went live'
git init -q --bare ~/remotes/site.git
git remote add origin ~/remotes/site.git
git push -q -u origin main v1.0
```

O serviço de hospedagem é um site, e o que ele faz quando alguém aperta *Merge pull request* é Git
comum, rodado numa cópia própria. Este programa curto faz o mesmo, para você fazer o papel do botão
num terminal. Salve-o como `~/merge-button.sh`:

```bash
#!/usr/bin/env bash
# merge-button.sh BRANCH NUMBER AUTHOR TITLE: what a hosting service does when
# somebody presses "Merge pull request", played by its own copy of the project.
set -e
[ -d ~/platform/site ] || git clone -q ~/remotes/site.git ~/platform/site
cd ~/platform/site
git fetch -q origin
git merge -q --ff-only origin/main
git -c user.name=GitHub -c user.email=noreply@github.com merge -q --no-ff "origin/$1" \
  -m "Merge pull request #$2 from $3/$1" -m "$4"
git push -q origin main
git push -q origin --delete "$1"
```

Ele faz o commit de merge com o nome que o GitHub usa e a mensagem que o GitHub escreve, e depois apaga
o branch da cópia compartilhada, que é a outra metade do botão. Agora a tarefa do Bruno, feita no dia
anterior: você faz o papel dele, na sua cópia, e envia o branch dele:

```bash
git switch -q -c 21-rye-bread-back
printf '<p>Rye bread, 1.35</p>\n' >> menu.html
git -c user.name='Bruno Lima' -c user.email=bruno@example.com commit -qam 'Put rye bread back on the menu' -m 'Refs #21'
git push -q origin 21-rye-bread-back
git switch -q main && git branch -q -D 21-rye-bread-back
```

E o pull request dele, o #22, integrado naquela tarde:

```bash
bash ~/merge-button.sh 21-rye-bread-back 22 bruno 'Put rye bread back on the menu'
```
