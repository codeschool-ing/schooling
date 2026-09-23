---
title: Show, blame, e achando o commit
version: 1
---

O log diz que um commit existe. Mais três comandos levam você de *algum lugar deste arquivo* até *o
commit exato, e o motivo dele*.

## git show: um commit, inteiro

```
ana@vm:~/site$ git show HEAD~3
commit 1b2d576126103b29221b62bff65378012554c501
Author: Bruno Lima <bruno@example.com>
Date:   Wed Sep 16 16:25:00 2026 -0300

    Put the prices up for September

diff --git a/menu.html b/menu.html
index 88e1ab8..ca66507 100644
--- a/menu.html
+++ b/menu.html
@@ -1,3 +1,3 @@
 <h1>Menu</h1>
-<p>French bread, 0.80</p>
-<p>Rye bread, 1.20</p>
+<p>French bread, 0.90</p>
+<p>Rye bread, 1.35</p>
```

**O `git show` é a entrada do log de um commit seguida do diff dele** contra o pai. Dois preços
subiram, cada um mostrado como uma linha removida e uma acrescentada, com o nome do Bruno e o motivo
dele em cima. É isso que você abre quando alguém fala *"a mudança de preços de setembro"* e você quer
vê-la.

Ponha um caminho depois do commit, separado por dois-pontos, e você recebe o arquivo como ele era
naquele commit:

```
ana@vm:~/site$ git show HEAD~3:menu.html
<h1>Menu</h1>
<p>French bread, 0.90</p>
<p>Rye bread, 1.35</p>
```

Esse é o cardápio da quarta à noite, com pão de centeio e tudo. Nada no disco mudou: o `git show` só
imprime. A aula 4 é como trazer uma versão antiga de volta.

## git blame: quem escreveu cada linha

```
ana@vm:~/site$ git blame menu.html
c3e07c2c (Ana Souza  2026-09-14 14:10:00 -0300 1) <h1>Menu</h1>
1b2d5761 (Bruno Lima 2026-09-16 16:25:00 -0300 2) <p>French bread, 0.90</p>
31a6298b (Ana Souza  2026-09-17 10:15:00 -0300 3) <p>Cheese roll, 2.50</p>
```

**Toda linha do arquivo, com o commit que a mudou por último**, o autor e quando. A linha 2 é do
Bruno, da mudança de preços; a linha 3 é da Ana, do dia em que o pão de queijo entrou. Leve
qualquer um desses ids curtos ao `git show` e você tem a mensagem que a explica.

O nome é a pior coisa do comando. O uso de verdade é o contrário de culpar alguém: você acha uma
linha que parece errada, e o blame leva você ao commit, que muitas vezes diz por que ela está certa,
ou pelo menos a quem perguntar. O `-L 2,3` limita a um intervalo de linhas, o que importa num
arquivo de mil.

## git log -S: quando a linha sumiu

O blame só vê linhas que existem agora. O pão de centeio não está no cardápio, então o blame não
consegue dizer para onde ele foi. **O `-S` procura no histórico commits que acrescentaram ou
removeram um trecho de texto**:

```
ana@vm:~/site$ git log -S "Rye" --oneline
eadf998 Take rye bread off until the flour arrives
95e3b9d Add rye bread to the menu
```

Dois commits: o que pôs *Rye* e o que tirou, com o motivo na mensagem. É o jeito mais rápido de
responder *"quando isso sumiu?"*, e o pessoal chama de picareta, *pickaxe*.

Esses quatro — `log`, `diff`, `show` e `blame` — com o `-S` para o que não está mais lá, respondem
quase toda pergunta que se pode fazer a um histórico.
