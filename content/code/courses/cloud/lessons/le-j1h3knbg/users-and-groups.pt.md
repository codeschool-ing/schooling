---
title: Usuários e grupos, as identidades das pessoas
version: 1
---

Um **usuário** é uma identidade de longa duração para uma pessoa. Ele tem um nome e pode ter dois
tipos de credencial: uma senha para entrar no console, e uma ou mais chaves de acesso para a linha de
comando e para programas. Longa duração quer dizer que ele existe até alguém apagá-lo, e o mesmo vale
para toda credencial que ele guarda. Uma chave de acesso criada em março funciona em dezembro, a menos
que alguém tenha feito algo a respeito no meio do caminho.

Um usuário por pessoa, e nunca um compartilhado. Um usuário chamado `dev` com que quatro pessoas
entram é o problema do root de novo, em tamanho menor: o log registra `dev`, e ninguém consegue dizer
qual das quatro fez uma chamada.

## Permissões vão no grupo, não na pessoa

O hábito que dá errado é anexar permissões a cada pessoa conforme ela chega. Pense num time de oito
em que todo mundo precisa das mesmas três políticas: ler o bucket de relatórios, gerenciar as máquinas
virtuais do time, ler os logs. Anexadas uma pessoa por vez, são 24 anexações. A nona pessoa a entrar
recebe "o mesmo que o Bruno", e alguém copia a lista do Bruno, incluindo a política que ele manteve do
projeto que deixou no ano passado. Ninguém decidiu que a nona pessoa deveria ter aquilo; veio por
semelhança.

**Um grupo é um conjunto de usuários ao qual se anexam políticas.** O time vira um grupo com três
políticas, e o acesso de uma pessoa são os grupos a que ela pertence:

| | por pessoa | com um grupo |
|---|---|---|
| anexações para oito pessoas | 24 | 3 |
| alguém entra | copiar a lista de outra pessoa | pôr no grupo |
| o time perde uma permissão | remover oito vezes | remover uma vez |
| alguém muda de time | descobrir o que era dele e o que era do time | trocar os grupos |

Um grupo é uma forma de distribuir permissões e nada mais. Na AWS ele não faz login, não tem
credenciais próprias, e uma política não pode nomear um grupo como o principal de que está falando;
grupos também não podem conter outros grupos. Se uma política precisa dizer "os analistas", ela diz
isso sendo anexada ao grupo dos analistas.

## A saída de uma pessoa deveria ser uma mudança só

O teste do arranjo é o dia em que alguém sai. Com grupos, as permissões saem junto com as
participações, e apagar o usuário leva o resto. Sem grupos, alguém precisa achar cada anexação, e a
que escapa é a que ninguém lembra de ter dado.

Há uma armadilha dentro do próprio usuário. **A senha do console e as chaves de acesso são credenciais
separadas, e remover uma deixa a outra funcionando.** Desativar o login no console de alguém no último
dia não faz nada com a chave de acesso no laptop dessa pessoa; um script que a usou na sexta ainda
funciona na segunda. A mudança completa é desativar e apagar as chaves também, ou apagar o usuário,
que leva tudo o que ele guarda.

O passo seguinte é não ter usuários de longa duração para pessoas. O login acontece uma vez, no
provedor de identidade da própria organização, com um segundo fator, e a conta de nuvem entrega
credenciais temporárias; a saída passa a ser uma mudança num lugar só, para toda conta que a pessoa
alcançava. Faltam duas peças para isso funcionar, uma role e uma relação de confiança entre sistemas,
e elas são a próxima seção e a de federação.
