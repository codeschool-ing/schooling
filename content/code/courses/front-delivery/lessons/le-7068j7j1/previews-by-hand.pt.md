---
title: Dois previews lado a lado, à mão
version: 1
---

**O preview de um host é um build de um branch, publicado num caminho ou endereço que ninguém mais usa.**
Nada nele precisa do host, e fazer à mão uma vez mostra exatamente o que o host automatiza: fazer checkout
de um branch sem sair do que você está, construí-lo para o próprio caminho, e servir os dois builds ao
mesmo tempo.

## Um branch para mostrar

Uma mudança que vale um preview: o título do planner em verde, num branch próprio.

```
ana@dev:~/planner$ git switch -q -c green-heading
ana@dev:~/planner$ echo 'h1 { color: #2f6f4e; }' >> src/style.css
ana@dev:~/planner$ git commit -qam "A green heading"
ana@dev:~/planner$ git switch -q main
```

## Cada branch numa pasta própria

O `git worktree` faz o checkout de um branch em outra pasta enquanto o repositório fica onde está, que é
como uma máquina de build segura dois branches ao mesmo tempo sem um pisar no outro. Construa o `main` e o
branch, cada um com `--base` igual ao caminho de onde o preview vai ser servido, e ponha os dois sob uma
pasta. `--outDir` grava o build num lugar que não é `dist/`, e `--emptyOutDir` deixa o Vite limpar essa
pasta antes, o que ele se recusa a fazer por padrão com uma pasta fora do projeto:

```
ana@dev:~/planner$ rm -rf ~/previews && mkdir ~/previews
ana@dev:~/planner$ git worktree add -q ~/previews-src/green-heading green-heading
ana@dev:~/planner$ npx vite build --base=/main/ --outDir ~/previews/main --emptyOutDir > /dev/null
ana@dev:~/planner$ (cd ~/previews-src/green-heading && npm ci > /dev/null && npx vite build --base=/green-heading/ --outDir ~/previews/green-heading --emptyOutDir > /dev/null)
ana@dev:~/planner$ ls ~/previews
green-heading
main
```

Sirva a pasta com o `host.mjs`, a partir do primeiro terminal:

```
ana@dev:~/planner$ node host.mjs ~/previews 8080
serving /home/ana/previews on http://127.0.0.1:8080
```

e peça os dois, a partir de um segundo:

```
ana@dev:~/planner$ curl -s http://127.0.0.1:8080/main/ | grep -o 'assets/[^"]*\.css'
assets/index-DXSNtWuR.css
ana@dev:~/planner$ curl -s http://127.0.0.1:8080/green-heading/ | grep -o 'assets/[^"]*\.css'
assets/index-BnjBSOGU.css
ana@dev:~/planner$ css=$(curl -s http://127.0.0.1:8080/green-heading/ | grep -o 'assets/[^"]*\.css')
ana@dev:~/planner$ curl -s http://127.0.0.1:8080/green-heading/$css | grep -o 'h1{[^}]*}'
h1{color:#2f6f4e}
```

**Dois builds, dois caminhos, duas folhas de estilo, servidos ao mesmo tempo por um servidor.** O CSS do
branch leva a cor e o do `main` não. Abra `http://127.0.0.1:8080/main/` e
`http://127.0.0.1:8080/green-heading/` em duas abas e os títulos diferem; cada link em cada um fica dentro
do próprio preview, porque cada um foi construído com o próprio caminho base. É o subcaminho da aula 1,
posto para trabalhar.

## O que o host acrescenta a isso

O host faz exatamente esses passos a cada push, e mais três coisas que você não fez:

- **um endereço por preview** em vez de um caminho, `<branch>.<project>.pages.dev`, então o `--base` fica
  `/` e nada no build difere do de produção;
- **o link, postado no pull request**, para ninguém precisar saber o padrão;
- **a limpeza** quando o pull request fecha, ou depois de um tempo definido.

Remova a worktree e a pasta quando terminar; o branch fica, e a próxima aula trabalha no `main`:

```
ana@dev:~/planner$ git worktree remove ~/previews-src/green-heading
ana@dev:~/planner$ rm -rf ~/previews ~/previews-src
ana@dev:~/planner$ git branch
  green-heading
* main
```
