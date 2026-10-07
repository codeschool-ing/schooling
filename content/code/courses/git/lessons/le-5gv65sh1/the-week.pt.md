---
title: A semana que este curso lê, feita na sua máquina
version: 1
---

Um histórico só fica interessante de ler quando tem algum comprimento, e duas pessoas nele. Daqui
em diante, a maioria das aulas parte do mesmo: uma semana de trabalho no site da padaria, nove
commits de Ana e Bruno. Os commits do Bruno você não consegue fazer trabalhando sozinho, então um
programa curto faz a semana inteira por você. Aqui está ele, todo:

```bash
#!/usr/bin/env bash
# make-site.sh: the bakery's site after a week of work by Ana and Bruno.
# Every date and every name is written down here, so the commits come out
# with the same ids as the ones this course prints.
set -e
if [ -e ~/site ]; then
  echo "~/site already exists. Move it aside or delete it, then run this again." >&2
  exit 1
fi
mkdir ~/site && cd ~/site && git init -q -b main

# commit WHEN NAME EMAIL MESSAGE: stage every change and commit it as NAME, at WHEN
commit() {
  git add -A
  GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1" \
  GIT_AUTHOR_NAME="$2" GIT_COMMITTER_NAME="$2" \
  GIT_AUTHOR_EMAIL="$3" GIT_COMMITTER_EMAIL="$3" \
    git commit -q -m "$4"
}
ana()   { commit "$1" 'Ana Souza' ana@example.com "$2"; }
bruno() { commit "$1" 'Bruno Lima' bruno@example.com "$2"; }

printf '<h1>Padaria Sol</h1>\n<p>Bread from six in the morning.</p>\n' > index.html
ana 2026-09-14T09:05:00-03:00 'Add the home page'
printf 'h1 { color: darkorange; }\n' > style.css
ana 2026-09-14T10:20:00-03:00 'Give the heading its colour'
printf '<h1>Menu</h1>\n<p>French bread, 0.80</p>\n' > menu.html
ana 2026-09-14T14:10:00-03:00 'Add the menu'
printf '<p>Rye bread, 1.20</p>\n' >> menu.html
bruno 2026-09-15T11:02:00-03:00 'Add rye bread to the menu'
sed -i 's/six in the morning/half past five/' index.html
ana 2026-09-16T09:40:00-03:00 'Open at half past five'
sed -i 's/0.80/0.90/; s/1.20/1.35/' menu.html
bruno 2026-09-16T16:25:00-03:00 'Put the prices up for September'
printf '<p>Cheese roll, 2.50</p>\n' >> menu.html
ana 2026-09-17T10:15:00-03:00 'Add cheese rolls'
sed -i '/Rye bread/d' menu.html
bruno 2026-09-18T08:50:00-03:00 'Take rye bread off until the flour arrives'
printf '<p><a href="menu.html">See the menu</a></p>\n' >> index.html
ana 2026-09-18T15:30:00-03:00 'Link the menu from the home page'
```

Três comandos nele são novos, e cada um faz o papel de algo que você faria num editor.
`printf '…' > arquivo` escreve um arquivo com exatamente aquelas linhas, sendo `\n` o fim de uma
linha, e `>>` as acrescenta ao fim do arquivo em vez disso. `sed -i 's/velho/novo/' arquivo` troca
`velho` por `novo` dentro do arquivo, e `sed -i '/Rye bread/d'` apaga a linha que menciona o pão de
centeio. O resto é o Git que você conhece da aula 2, com um acréscimo: as variáveis `GIT_AUTHOR_…`
e `GIT_COMMITTER_…`, que dizem ao Git quem fez um commit e quando, passando por cima das suas
configurações naquele comando só.

## Fazendo a semana

Abra um arquivo vazio no nano com `nano ~/make-site.sh`, cole o programa nele, depois salve com
Ctrl+O e Enter e saia com Ctrl+X. A aula 2 deixou um `~/site` seu, e o programa se recusa a
sobrescrevê-lo, então tire esse do caminho antes:

```
ana@vm:~$ mv site site-lesson-2
ana@vm:~$ bash make-site.sh
ana@vm:~$ cd site
ana@vm:~/site$ git log --oneline -3
6555c9b Link the menu from the home page
eadf998 Take rye bread off until the flour arrives
31a6298 Add cheese rolls
```

**Os seus ids devem ser estes ids.** A aula 1 disse que um id é calculado a partir de tudo o que um
commit guarda, e cada parte destes commits está escrita no programa: os arquivos, os nomes, as datas
e as mensagens. Então o `6555c9b` desta página é o `6555c9b` da sua máquina, e cada transcrição
desta aula vai bater com a sua caractere por caractere.

Isso deixa de valer no primeiro commit que você mesmo fizer. O seu commit leva o seu nome e o
momento em que você o fez, então o id dele é só seu, e o de tudo que vier depois também. Quando as
próximas aulas mostrarem um id que você não tem, ache o commit pela mensagem.

## Começar de novo

Várias aulas mudam este histórico, e algumas o quebram de propósito. Para ter a semana de volta
exatamente como era, apague a pasta e rode o programa de novo:

```
ana@vm:~$ rm -rf ~/site && bash ~/make-site.sh
```

O `rm -rf` apaga sem perguntar, o que é certo para uma cópia de treino que você reconstrói num
segundo e errado para qualquer outra coisa. As aulas 4 a 17 dizem no começo quando querem uma semana
nova.
