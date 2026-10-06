---
title: A versão é escrita uma vez
version: 1
---

Um programa rodando deveria conseguir dizer o que é. Quando algo dá errado em produção, a primeira
pergunta é **qual código está rodando**, e a resposta precisa vir do programa, e não da memória de
alguém sobre o último deploy. O `shipquote` responde em `/version`, e a resposta vem de um lugar só: a
tag do git.

Essa é a regra que o repositório que publica este curso segue, e o `CLAUDE.md` dele a põe numa linha:
*a tag é o único lugar onde uma versão é escrita*. Nem um arquivo a manter em sintonia com a tag, nem
uma constante no código; o build lê a tag e a carimba no artefato.

```
ana@laptop:~/shipquote$ tar -xzOf dist/shipquote-1.4.0.tar.gz shipquote-1.4.0/shipquote/VERSION; echo
1.4.0
ana@laptop:~/shipquote$ python3 -c 'from shipquote.version import VERSION; print(VERSION)'
dev
```

O artefato carrega um arquivo, `shipquote/VERSION`, com `1.4.0`, e mais nada. Na cópia de trabalho
esse arquivo não existe, então `shipquote.version` cai para `dev`. **Um programa que ninguém montou diz
que é `dev`**, nunca um palpite, que é exatamente o que você quer ver numa linha de log vinda do
notebook de alguém.

## Um build que não é release

O que acontece com um commit sem tag? Aqui uma mudança é commitada num branch descartável e montada:

```
ana@laptop:~/shipquote$ git describe --tags
v1.4.0-1-g7c77050
ana@laptop:~/shipquote$ ops/build.sh
dist/shipquote-dev-7c77050.tar.gz
```

O `git describe` diz que o commit está **um depois de `v1.4.0`**, com o hash `7c77050`. O build o chama
de `dev-7c77050`: um nome que não se confunde com um release e que ainda diz exatamente qual commit é.
Durante um incidente, "dev-7c77050" é uma resposta; "1.4.0, provavelmente com a correção da Ana" não
é.

## Versões semânticas

`1.4.0` segue o **versionamento semântico**: MAJOR.MINOR.PATCH. Um release de patch corrige algo sem
mudar comportamento de que alguém dependa; um release minor acrescenta algo e não quebra nada; um
release major pode quebrar quem chama. Os números são uma promessa a quem depende do programa, o que
para um serviço são principalmente os próprios clientes e para uma biblioteca é todo mundo que a
importa.

Dois hábitos do workflow de release deste repositório valem copiar. A tag é conferida antes de
qualquer coisa ser montada: precisa ter a forma certa, ser **maior que todos os releases anteriores**,
e estar na `main`, porque um release que ninguém integrou não pode ser reproduzido a partir da
`main`. E depois do build, o workflow **pergunta ao binário que versão ele é** e compara a resposta com
a tag, então um erro de carimbo reprova o release em vez de chegar aos usuários.
