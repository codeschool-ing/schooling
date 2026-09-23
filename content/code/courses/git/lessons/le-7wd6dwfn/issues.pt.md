---
title: Issues: trabalho escrito antes de começar
version: 1
---

Todo serviço de hospedagem tem um **rastreador de issues**: uma lista de coisas que alguém quer que
sejam feitas, cada uma com um número. GitHub e GitLab as chamam de issues, equipes no Bitbucket usam
mais o Jira, e a aula 15 chama a mesma coisa de ticket. O nome muda; a ideia não.

Uma issue tem:

- **um título** que diz o que está errado ou o que se quer, numa linha;
- **uma descrição** com detalhe suficiente para outra pessoa começar: o que acontece, o que deveria
  acontecer, como ver;
- **um número**, `#12`, que é como todo o resto se refere a ela;
- **um responsável**, a pessoa que vai fazer, e **etiquetas** — *bug*, *cardápio*, *urgente* — para
  achá-la no meio de outras duzentas.

**O número é a parte que importa para o Git.** Uma mensagem de commit ou um pull request que menciona
`#12` vira um link no site, então a issue junta toda mudança feita para ela. GitHub e GitLab vão além:
um pull request cuja descrição diz `Closes #12` fecha a issue automaticamente quando entra no branch
principal. O histórico então responde *por que isso mudou?* apontando para a conversa em que o motivo
foi combinado.

## O que uma issue não é

Não é lugar para a solução. *"O horário de domingo não está na página inicial"* é uma boa issue; uma
lista das linhas a mudar não é, porque decide a resposta antes de alguém olhar. A discussão do *como*
pertence ao pull request, ao lado do código.

E não é uma promessa. Uma issue pode ser fechada sem mudança nenhuma, porque o problema não era real,
ou já estava resolvido, ou não vale a pena resolver. Fechá-la com uma frase dizendo qual é o caso faz
parte do trabalho; a aula 16 volta ao ticket que não deveria ter sido começado.

## Para que isso, num site de padaria de duas pessoas

Porque a alternativa é uma mensagem no chat. *"Dá para pôr o horário de domingo?"* num chat some numa
semana, não tem status e não pode ser ligada a um commit. Uma issue é onde o pedido, a decisão e a
mudança acabam juntos, e um ano depois essa é a diferença entre saber por que o site diz *7:00* e
chutar.
