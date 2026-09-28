---
title: O dia em que acontece
version: 1
---

Se um segredo chegou a um repositório que outras pessoas conseguem ler, a ordem do que você faz importa mais
do que qualquer outra coisa nesta aula.

1. **Revogue, primeiro.** Troque a senha, apague a chave, emita um token novo, no serviço que o emitiu. Este é
   o único passo que torna o valor vazado inútil, e cada minuto antes dele é um minuto em que alguém pode
   estar usando. Faça antes de mexer no git.
2. **Confira se foi usado.** Os logs do serviço, a página de cobrança, a lista de sessões recentes. Uma chave
   de nuvem usada durante a noite aparece como uma conta; uma senha de e-mail usada aparece como mensagens
   enviadas que você não enviou.
3. **Ponha o segredo novo onde ele pertence**: o ambiente, a segunda seção desta aula, e nunca um arquivo no
   repositório.
4. **Depois, se quiser, limpe o histórico.** Ferramentas como o `git filter-repo` reescrevem todo commit para
   remover um arquivo ou uma string, e um push forçado substitui o branch. Este passo é opcional e vem por
   último, porque não recolhe as cópias que já foram clonadas, copiadas ou guardadas pelos programas de
   varredura. Deixa o histórico arrumado; não torna o segredo secreto de novo.

As pessoas invertem a ordem porque o histórico é o que parece constrangedor. Mas um histórico limpo com uma
chave não revogada continua sendo uma porta aberta, e uma chave revogada num histórico bagunçado é
inofensiva.

Num portfólio vale mais um passo: **conte**, no pull request ou na retrospectiva. *Uma chave entrou num commit
em 3 de junho, foi revogada em uma hora, e o histórico foi limpo* é evidência exatamente do critério que
quem avalia procura.
