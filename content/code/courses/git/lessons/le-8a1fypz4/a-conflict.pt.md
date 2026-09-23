---
title: Quando os dois lados mudaram as mesmas linhas
version: 1
---

A aula 5 fez o merge de dois branches que tinham mudado arquivos diferentes, e o Git os combinou sem
perguntar. Aqui o branch `sunday` da Ana e o commit do Bruno no `main` mudaram os dois a segunda linha
do `index.html`:

```
ana@vm:~/site$ git merge sunday
Auto-merging index.html
CONFLICT (content): Merge conflict in index.html
Automatic merge failed; fix conflicts and then commit the result.
ana@vm:~/site$ git status
On branch main
You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
	both modified:   index.html

no changes added to commit (use "git add" and/or "git commit -a")
```

**`CONFLICT (content)` quer dizer que o Git combinou tudo o que conseguiu e parou num lugar em que não
conseguiu.** Nenhum commit foi feito. O merge está pausado, e o `git status` diz isso com as próprias
palavras: *you have unmerged paths*, e o `index.html` está *both modified*. Ele também nomeia os dois
caminhos, que são as duas seções seguintes: resolver os conflitos e fazer o commit, ou abortar.

Um conflito não é um erro, e não é sinal de que alguém fez algo errado. Quer dizer que duas pessoas
tomaram decisões diferentes sobre a mesma coisa, e **o Git se recusa a escolher uma por você.** Cinco e
meia ou seis e meia é um fato sobre a padaria, e só quem conhece a padaria sabe responder.

## Lendo os marcadores

O Git escreveu as duas versões no arquivo, cercadas por três tipos de marcador:

```schooling-example
{"language": "html", "file": "index.html", "parts": [{"code": "<h1>Padaria Sol</h1>", "note": "Fora dos marcadores não há disputa: os dois lados concordam com esta linha."}, {"code": "<<<<<<< HEAD\n<p>Bread from half past six.</p>", "note": "Daqui até os sinais de igual é o branch em que você está, o main, que o HEAD nomeia: o horário de inverno do Bruno."}, {"code": "=======\n<p>Bread from half past five; Sundays from seven.</p>\n>>>>>>> sunday", "note": "Dos sinais de igual até as setas é o branch que está entrando, que a última linha nomeia: o horário de domingo da Ana."}, {"code": "<p><a href=\"menu.html\">See the menu</a></p>", "note": "Fora de novo. O Git combinou tudo o que conseguiu e marcou só a linha que não conseguiu decidir."}]}
```

Tudo entre `<<<<<<<` e `=======` é **o seu lado**, o branch em que você estava quando digitou
`git merge`. Tudo entre `=======` e `>>>>>>>` é **o lado deles**, o branch que está entrando, nomeado
no último marcador. As linhas fora dos marcadores foram combinadas sem problema.

**O arquivo do jeito que está não serve para nada.** Um navegador mostraria os marcadores como texto,
um programa não rodaria, e um commit registraria os marcadores como se fossem conteúdo. A próxima
seção é como transformá-lo na única versão que você quer de fato.

## Por que aconteceu aqui e não na aula 5

O Git faz o merge comparando cada lado com o commit do qual os dois nasceram. Onde só um lado mudou
alguma coisa, ele pega esse lado. Onde os dois mudaram linhas **diferentes**, ele pega as duas. Só onde
os dois mudaram **as mesmas** linhas, ou linhas coladas uma na outra, é que ele precisa de uma decisão.
Quanto mais vezes os branches são mesclados, menos disso aparece, e esse é um dos argumentos da
aula 9.
