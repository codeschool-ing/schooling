---
title: O que acontece quando o orçamento acaba
version: 1
---

Um orçamento só é útil se gastá-lo muda alguma coisa. **A política de orçamento de erros diz o quê, e
é combinada antes de ser necessária**, entre quem constrói funcionalidades e quem atende o plantão,
porque no dia em que ela vale eles vão querer coisas opostas.

Uma política típica tem três níveis:

| orçamento que resta na janela | o que a equipe faz |
|---|---|
| bastante | lança versões normalmente; experimentos e migrações arriscadas estão liberados |
| menos de um quarto | lançamentos precisam de um plano de reversão; o próximo sprint leva um item de confiabilidade |
| nenhum | só correções e trabalho de confiabilidade são lançados até o orçamento se recuperar |

Três propriedades a fazem funcionar:

- **Ela é mecânica.** O número decide, não um debate numa reunião. Um congelamento que precisa da
  aprovação de alguém a cada vez é um congelamento que não acontece.
- **Ela funciona nas duas direções.** Um orçamento que nunca é gasto diz que o objetivo está frouxo
  demais, ou que a equipe está cautelosa demais: ela poderia lançar mais rápido, fazer aquela
  migração, ou desligar a redundância cara de que ninguém precisou. Orçamento não gasto é velocidade
  desperdiçada.
- **Ela tem as exceções por escrito.** Uma correção de segurança é lançada seja o que for que o
  orçamento diga, e uma queda causada por um provedor de que todos dependem pode ser excluída, mas só
  se a política disser isso de antemão.

O que a política *não* é é uma punição. Ela não diz quem gastou o orçamento, e o postmortem da aula
18 é o lugar de entender por que ele foi gasto. **É uma regra sobre ritmo, não sobre pessoas**: quando
o sistema anda pouco confiável, as próximas mudanças são feitas com mais cuidado.
