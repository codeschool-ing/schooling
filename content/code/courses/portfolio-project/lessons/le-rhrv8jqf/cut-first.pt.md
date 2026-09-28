---
title: O que cortar primeiro
version: 1
---

Nem toda funcionalidade custa o mesmo. Algumas ficam num canto do projeto; outras atravessam ele
inteiro. **Corte primeiro o que multiplica**: as funcionalidades que acrescentam trabalho a todas as
outras.

| funcionalidade | o que ela multiplica |
|---|---|
| contas e login | toda rota precisa de uma verificação, toda tela de um estado logado e deslogado, todo teste de um usuário |
| papéis e permissões | toda ação precisa de *quem pode fazer isto*, e todo teste roda uma vez por papel |
| notificações por e-mail | um servidor ou provedor de e-mail, modelos, falhas para tentar de novo, e um jeito de testar que não envie nada |
| uma área de administração | uma segunda interface, com seus formulários, validação e controle de acesso |
| vários idiomas | toda frase duas vezes, e todo layout testado com a mais longa |
| várias organizações | toda tabela e toda consulta ganham um *de qual*, e um erro vaza dados entre elas |

Nenhuma dessas é má ideia, e todas são comuns em sistemas reais. É justamente esse o problema: num projeto
de seis semanas, qualquer uma delas pode tomar metade do tempo, e **nenhuma é o ponto** da maioria dos
projetos. Quem avalia já viu mil logins; não viu a sua regra.

Então a ordem é: corte o que multiplica, depois o que é grande, depois o que é só agradável. O primeiro
corte costuma liberar mais tempo do que todos os outros juntos, e é por isso que a primeira decisão do
loanbook no briefing da aula 4 foi *quem pega emprestado é um nome digitado*.
