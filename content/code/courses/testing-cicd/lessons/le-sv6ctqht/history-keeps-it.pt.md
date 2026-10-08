---
title: Tirado do código, ainda no histórico
version: 2
---

O vazamento mais comum é o mais simples: um segredo commitado no repositório. Acontece com as melhores
intenções, guardar a configuração da produção ao lado do código para ela ter versão como todo o resto,
e a reação usual, apagar o arquivo no commit seguinte, não desfaz nada.

Eis essa sequência num branch descartável do `shipquote`. Um commit acrescenta `deploy/production.env`
com a URL da transportadora e o token; vinte minutos depois outro commit o tira:

```sh
git switch -c add-deploy-config
mkdir deploy
printf 'SHIPQUOTE_CARRIER_URL=http://127.0.0.1:9092\nSHIPQUOTE_CARRIER_TOKEN=lab-live-token\n' > deploy/production.env
git add deploy
git commit -m "Keep the production settings with the code"
git rm -q deploy/production.env
git commit -m "Remove the production settings again"
```

E o que sobra dele:

```
ana@laptop:~/shipquote$ git log --oneline -3
9c9d357 Remove the production settings again
ee23fb4 Keep the production settings with the code
cd46eb9 Ask the carrier when the environment names one
ana@laptop:~/shipquote$ ls deploy/production.env
ls: cannot access 'deploy/production.env': No such file or directory
ana@laptop:~/shipquote$ git log --oneline -S lab-live-token
9c9d357 Remove the production settings again
ee23fb4 Keep the production settings with the code
ana@laptop:~/shipquote$ git show HEAD~1:deploy/production.env
SHIPQUOTE_CARRIER_URL=http://127.0.0.1:9092
SHIPQUOTE_CARRIER_TOKEN=lab-live-token
```

A cópia de trabalho não tem mais o arquivo. **O histórico tem**: `git log -S` lista todo commit que
acrescentou ou tirou a string, e `git show` imprime o arquivo exatamente como foi commitado, token
incluído. Quem clonou ou buscou o repositório naqueles vinte minutos, e quem algum dia ler o histórico,
tem o valor. Num serviço hospedado, forks, caches e os backups do próprio serviço também têm.

(`git switch main` e `git branch -D add-deploy-config` guardam o branch descartável.)

## O que decorre disso

**Trate um segredo que chegou a um commit como vazado**, aconteça o que acontecer depois: um commit
seguinte, um force push, um repositório privado. Reescrever o histórico para tirá-lo vale a pena para
impedir que se espalhe mais, e não recolhe as cópias já feitas. Então a ordem é a que a seção 10
estabelece: trocar o segredo primeiro, limpar depois.

## Achando antes de chegarem

`git log -S <string>` é como você procura no próprio histórico um valor que conhece. Para valores que
você não conhece, **scanners de segredos** procuram as formas que segredos têm: o prefixo que um
fornecedor põe nos tokens, o cabeçalho de uma chave privada, uma string de alta entropia ao lado da
palavra `password`. Eles rodam como hook de pré-commit na máquina de quem desenvolve, como passo na
CI, e como serviço na plataforma de hospedagem, que em repositórios públicos muitas vezes avisa o
fornecedor para o token ser revogado em minutos. Na trilha `devsecops`, a aula 6 de `secure-pipeline`
trata a fundo da busca de segredos no repositório e no histórico dele.

A defesa mais barata é estrutural: **guardar segredos em arquivos que o repositório ignora**, ou fora
da cópia de trabalho de vez. Os ambientes do `shipquote` guardam os deles em `~/envs/<nome>/config.env`,
que não está em repositório nenhum; entradas `*.env` no `.gitignore` e um scanner no hook de
pré-commit são o cinto e o suspensório de sempre.
