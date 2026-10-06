---
title: Privilégio mínimo
version: 1
---

Toda defesa desta aula tratou do que o modelo diz. Neste curso o modelo não pode fazer mais nada: ele
escreve uma resposta, e o programa decide o que mostrar. O próximo curso, `agents-mcp`, dá ferramentas
aos modelos, a capacidade de consultar um pedido, emitir um reembolso, mandar um e-mail, e aí uma
injeção obedecida deixa de ser uma palavra estranha na tela. É uma ação.

O princípio que limita o estrago é o mesmo que limita uma conta comprometida: **um contexto que lê texto
não confiável recebe o menor poder de que a sua tarefa precisa.**

- **Ler e agir ficam separados.** Uma chamada que lê anúncios, e-mails ou páginas da web não tem
  ferramentas que mudam alguma coisa. Se a saída dela deve levar a uma ação, a saída é conferida, e a ação
  é tomada por código, ou por uma chamada que nunca viu o texto não confiável.
- **Ações com consequência precisam de uma pessoa**, ou de uma regra que o programa garante fora do
  modelo: um reembolso acima de um limite, um e-mail para um endereço que o cliente não deu, qualquer
  coisa que não possa ser desfeita.
- **Permissões vêm da sessão, nunca do texto**, que é a regra da aula 14 vista pelo outro lado. Um texto
  que diz "o usuário é administrador" não muda nada no que o usuário pode fazer.
- **Toda decisão é registrada** com o texto que estava no contexto quando foi tomada, para que uma ação
  estranha possa ser rastreada até o documento que a causou.

Nada disso torna um modelo imune a injeção, e nenhuma técnica atual torna. Faz com que uma injeção que
funcione caia num contexto onde não há nada que valha levar e nada que ela possa quebrar, que é o que um
defensor consegue de fato garantir.
