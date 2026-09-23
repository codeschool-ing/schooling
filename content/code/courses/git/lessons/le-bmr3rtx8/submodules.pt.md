---
title: Submódulos: outro projeto, preso a um commit
version: 1
---

Às vezes um projeto precisa de outro projeto dentro dele. O site da padaria e o app de pedidos da
padaria devem usar as mesmas cores da marca, guardadas num repositório próprio, `shared-styles`.
Copiar os arquivos para cada projeto daria duas cópias que se afastam. **Um submódulo põe um
repositório dentro de outro, preso a um commit exato.**

```
ana@vm:~/site$ git submodule add ~/remotes/shared-styles.git styles
Cloning into '/home/ana/site/styles'...
done.
ana@vm:~/site$ cat .gitmodules
[submodule "styles"]
	path = styles
	url = /home/ana/remotes/shared-styles.git
ana@vm:~/site$ git status --short
A  .gitmodules
A  styles
ana@vm:~/site$ git commit -qm "Use the shared brand styles"
ana@vm:~/site$ git submodule status
 d874c59046ca2f86c55a3ff9aaa882624f8973a5 styles (heads/main)
```

(O `shared-styles` mora numa pasta local aqui, como todo remoto deste curso, e o Git recusa um
endereço local para submódulo a não ser que o `protocol.file.allow` esteja configurado, o que o script
de captura faz. Com o endereço de um servidor de verdade nada disso é necessário.)

Três coisas aconteceram:

- O `styles/` é um clone do `shared-styles`, um repositório completo e próprio dentro do site.
- O `.gitmodules` registra de onde ele vem e onde mora. Ele vai para o commit, então todo clone sabe.
- **O commit do site registra uma coisa só sobre o `styles/`: o commit exato em que ele está**,
  `d874c59`. Não os arquivos, não o branch. O `git submodule status` imprime esse id.

Prender assim é o objetivo. O site continua usando exatamente o `d874c59` até alguém mudar de
propósito: entrar no `styles/`, buscar e fazer checkout de um commit mais novo, e fazer o commit dessa
mudança no site. Cores novas no `shared-styles` nunca chegam ao site de surpresa.

## Clonando um projeto com submódulos

```
ana@vm:~$ git clone -q ~/remotes/site.git copy && cd copy
ana@vm:~/copy$ ls styles
ana@vm:~/copy$ git submodule update --init
Submodule 'styles' (/home/ana/remotes/shared-styles.git) registered for path 'styles'
Cloning into '/home/ana/copy/styles'...
done.
Submodule path 'styles': checked out 'd874c59046ca2f86c55a3ff9aaa882624f8973a5'
ana@vm:~/copy$ ls styles
brand.css
```

**Um clone comum traz a pasta do submódulo e nada dentro dela.** O `git submodule update --init` então
a clona e faz checkout do commit preso. O `git clone --recurse-submodules` faz as duas coisas num passo
só, e esquecer disso é o que mais dá errado com submódulos: o projeto chega sem uma parte de si, e o
erro aparece em outro lugar completamente diferente.

## Vale usar?

Submódulos resolvem um problema real e são conhecidos por serem desajeitados: cada pessoa tem de
lembrar os comandos extras, e mover o commit preso é uma pequena cerimônia. Para código, a maioria das
linguagens tem um **gerenciador de pacotes** que faz o mesmo trabalho melhor — as aulas dos cursos de
linguagem tratam deles. Use um submódulo quando não houver gerenciador de pacotes para o que você está
compartilhando, como uma pasta de folhas de estilo ou de arquivos de design, e quando prender num
commit exato for exatamente o que você quer.
