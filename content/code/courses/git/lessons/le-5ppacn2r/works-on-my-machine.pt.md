---
title: Na minha máquina funciona
version: 1
---

O ticket #34 pede para o cardápio mostrar quais itens têm alergênicos. A Ana põe uma imagem na página e
abre no navegador. A imagem aparece. Aqui está o que ela digitou no caminho:

```
ana@vm:~/site$ git status --short
 M menu.html
?? images/
ana@vm:~/site$ git commit -qam 'Show allergens on the menu' -m 'Refs #34'
ana@vm:~/site$ ./check-links.sh && echo all links found
all links found
ana@vm:~/site$ git push -q -u origin 34-allergens
```

Duas linhas de `git status`, e ela leu só a primeira. `?? images/` quer dizer **não rastreado**: o Git nunca
foi avisado dessa pasta, então o `commit -a` a deixou de fora. O check dela passa, porque no disco dela a
imagem existe. O branch sobe sem ela.

## Uma máquina que não é a sua

O jeito mais rápido de ver o que todo mundo vai receber é **clonar o branch num diretório novo**, como se
você fosse um colega no primeiro dia:

```
ana@vm:~/site$ git clone -q --branch 34-allergens ~/remotes/site.git /tmp/fresh
ana@vm:~/site$ cd /tmp/fresh
ana@vm:/tmp/fresh$ ls
check-links.sh	index.html  menu.html  style.css
ana@vm:/tmp/fresh$ ./check-links.sh && echo all links found
missing: images/allergens.png
```

A imagem não está lá, e o mesmo check que passou um minuto antes agora falha. Nada no código mudou; só a
máquina. A correção são dois comandos, e o `git status` voltando vazio é o sinal de que nada ficou para
trás:

```
ana@vm:~/site$ git status --short
?? images/
ana@vm:~/site$ git add images/allergens.png
ana@vm:~/site$ git commit -qm 'Add the allergens picture' -m 'Refs #34'
ana@vm:~/site$ git status --short
```

## Os suspeitos de sempre

Um arquivo que nunca foi adicionado é a forma mais comum, e há outras, todas com a mesma forma (algo
verdadeiro na máquina de quem escreveu e em nenhum outro lugar):

- **Uma configuração ou um segredo** num arquivo local, ou numa variável de ambiente, de que o código
  depende em silêncio. A aula 10 deixou os segredos fora do repositório de propósito, e é exatamente por
  isso que o código precisa dizer que precisa de um.
- **Uma versão diferente** de uma linguagem, uma biblioteca ou uma ferramenta. O código usa um recurso que
  chegou na versão 3.12, e o servidor roda a 3.10.
- **Dados que só quem escreveu tem**: uma conta de teste, uma linha no banco local, um arquivo na pasta
  Downloads.
- **Maiúsculas em nomes de arquivo.** No Windows e no macOS, `Menu.html` e `menu.html` em geral são o mesmo
  arquivo; no servidor Linux que roda o site, são dois, e o link quebra.

## Quem paga

Quando o "na minha máquina funciona" chega à equipe, **o custo passa de quem escreveu para outra pessoa**,
e cresce no caminho. O Bruno gasta vinte minutos para descobrir que a imagem nunca foi enviada. Se ninguém
tivesse aberto o branch, o Diego acharia testando, ou um cliente acharia no site. A Ana teria poupado tudo
isso com um `git status` lido até o fim.
